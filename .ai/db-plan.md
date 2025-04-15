# Schemat bazy danych - World Map App

## 1. Tabele

### continents
```sql
CREATE TABLE continents (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Trigger dla updated_at
CREATE TRIGGER set_timestamp
    BEFORE UPDATE ON continents
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_set_timestamp();
```

### countries
```sql
CREATE TABLE countries (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    continent_id INTEGER NOT NULL REFERENCES continents(id),
    flag_url TEXT,
    blog_url TEXT,
    geojson JSONB NOT NULL,
    search_vector tsvector GENERATED ALWAYS AS (
        to_tsvector('simple', name || ' ' || coalesce((
            SELECT name FROM continents WHERE id = continent_id
        ), ''))
    ) STORED,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_country_name UNIQUE (name)
);

-- Trigger dla updated_at
CREATE TRIGGER set_timestamp
    BEFORE UPDATE ON countries
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_set_timestamp();
```

### user_visited_countries
```sql
CREATE TABLE user_visited_countries (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    country_id INTEGER NOT NULL REFERENCES countries(id) ON DELETE CASCADE,
    visited_at DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, country_id)
);
```

### planned_visits
```sql
CREATE TABLE planned_visits (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    country_id INTEGER NOT NULL REFERENCES countries(id) ON DELETE CASCADE,
    planned_date DATE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, country_id)
);

-- Trigger dla updated_at
CREATE TRIGGER set_timestamp
    BEFORE UPDATE ON planned_visits
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_set_timestamp();
```

### user_map_settings
```sql
CREATE TABLE user_map_settings (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    selected_continent_id INTEGER REFERENCES continents(id),
    other_filters JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Trigger dla updated_at
CREATE TRIGGER set_timestamp
    BEFORE UPDATE ON user_map_settings
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_set_timestamp();
```

## 2. Widoki

### user_statistics
```sql
CREATE MATERIALIZED VIEW user_statistics AS
SELECT 
    user_id,
    COUNT(DISTINCT country_id)::float / (SELECT COUNT(*) FROM countries)::float * 100 as visited_percentage,
    COUNT(DISTINCT c.continent_id)::float / (SELECT COUNT(*) FROM continents)::float * 100 as continents_percentage,
    json_object_agg(
        co.name,
        COUNT(*)
    ) as visits_by_continent
FROM user_visited_countries uvc
JOIN countries c ON uvc.country_id = c.id
JOIN continents co ON c.continent_id = co.id
GROUP BY user_id;

-- Funkcja odświeżania widoku
CREATE OR REPLACE FUNCTION refresh_user_statistics()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY user_statistics;
END;
$$ LANGUAGE plpgsql;
```

## 3. Indeksy

```sql
-- Indeks dla wyszukiwania pełnotekstowego
CREATE INDEX countries_search_idx ON countries USING GIN (search_vector);

-- Indeks dla filtrowania po kontynencie
CREATE INDEX countries_continent_idx ON countries (continent_id);

-- Indeks dla GeoJSON (JSONB)
CREATE INDEX countries_geojson_idx ON countries USING GIN (geojson);

-- Indeks dla dat odwiedzin
CREATE INDEX user_visited_countries_date_idx ON user_visited_countries (visited_at);

-- Indeks dla planowanych wizyt
CREATE INDEX planned_visits_date_idx ON planned_visits (planned_date);
```

## 4. Funkcje pomocnicze

### Wyszukiwanie krajów i kontynentów
```sql
CREATE OR REPLACE FUNCTION search_countries_and_continents(search_term TEXT)
RETURNS TABLE (
    type TEXT,
    id INTEGER,
    name TEXT,
    code TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 'continent', c.id, c.name, c.code
    FROM continents c
    WHERE c.name ILIKE search_term || '%'
    UNION ALL
    SELECT 'country', co.id, co.name, NULL
    FROM countries co
    JOIN continents c ON co.continent_id = c.id
    WHERE c.name ILIKE search_term || '%'
    ORDER BY type DESC, name;
END;
$$ LANGUAGE plpgsql;
```

## 5. Polityki RLS

```sql
-- Włączenie RLS dla wszystkich tabel
ALTER TABLE continents ENABLE ROW LEVEL SECURITY;
ALTER TABLE countries ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_visited_countries ENABLE ROW LEVEL SECURITY;
ALTER TABLE planned_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_map_settings ENABLE ROW LEVEL SECURITY;

-- Polityki dla continents
CREATE POLICY "Continents are viewable by everyone"
    ON continents FOR SELECT
    USING (true);

-- Polityki dla countries
CREATE POLICY "Countries are viewable by everyone"
    ON countries FOR SELECT
    USING (true);

-- Polityki dla user_visited_countries
CREATE POLICY "Users can view their own visited countries"
    ON user_visited_countries FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own visited countries"
    ON user_visited_countries FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own visited countries"
    ON user_visited_countries FOR DELETE
    USING (auth.uid() = user_id);

-- Polityki dla planned_visits
CREATE POLICY "Users can manage their planned visits"
    ON planned_visits FOR ALL
    USING (auth.uid() = user_id);

-- Polityki dla user_map_settings
CREATE POLICY "Users can manage their map settings"
    ON user_map_settings FOR ALL
    USING (auth.uid() = user_id);
```

## 6. Uwagi implementacyjne

1. Automatyczne odświeżanie statystyk:
```sql
-- Dodanie zadania cron do odświeżania statystyk co godzinę
SELECT cron.schedule('0 * * * *', $$
    SELECT refresh_user_statistics();
$$);
```

2. Trigger dla updated_at:
```sql
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

3. Supabase Realtime:
- Włącz śledzenie zmian dla `user_visited_countries`
- Skonfiguruj publikację dla zmian w czasie rzeczywistym

4. Indeksowanie:
- Użyto GIN dla JSONB i tsvector
- Standardowe indeksy B-tree dla kluczy obcych i dat
- Indeksy częściowe mogą być dodane później na podstawie wzorców użycia

5. Skalowalność:
- Materialized view z concurrent refresh
- Efektywne indeksowanie dla częstych zapytań
- Możliwość partycjonowania tabel w przyszłości 
-- Migration: Create World Map App Schema
-- Description: Initial schema creation for World Map App including tables, views, indexes, and RLS policies
-- Affected tables: continents, countries, user_visited_countries, planned_visits, user_map_settings
-- Special considerations: 
--   - Enables RLS on all tables
--   - Creates materialized view for statistics
--   - Sets up triggers for timestamp updates
--   - Configures full-text search and GeoJSON indexing

-- Create trigger function for updated_at timestamps
create or replace function public.trigger_set_timestamp()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

-- Create continents table
create table public.continents (
    id serial primary key,
    name text not null,
    code text not null unique,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Create countries table
create table public.countries (
    id serial primary key,
    name text not null,
    continent_id integer not null references public.continents(id),
    flag_url text,
    blog_url text,
    geojson jsonb not null,
    search_vector tsvector,
    created_at timestamptz default now(),
    updated_at timestamptz default now(),
    constraint unique_country_name unique (name)
);

-- Create function to update search vector
create or replace function public.update_country_search_vector()
returns trigger as $$
begin
    new.search_vector := to_tsvector('simple', 
        new.name || ' ' || coalesce(
            (select name from public.continents where id = new.continent_id),
            ''
        )
    );
    return new;
end;
$$ language plpgsql;

-- Create trigger for search vector updates
create trigger update_country_search_vector
    before insert or update of name, continent_id
    on public.countries
    for each row
    execute function public.update_country_search_vector();

-- Create user_visited_countries table
create table public.user_visited_countries (
    user_id uuid not null references auth.users(id) on delete cascade,
    country_id integer not null references public.countries(id) on delete cascade,
    visited_at date not null,
    created_at timestamptz default now(),
    primary key (user_id, country_id)
);

-- Create planned_visits table
create table public.planned_visits (
    user_id uuid not null references auth.users(id) on delete cascade,
    country_id integer not null references public.countries(id) on delete cascade,
    planned_date date,
    created_at timestamptz default now(),
    updated_at timestamptz default now(),
    primary key (user_id, country_id)
);

-- Create user_map_settings table
create table public.user_map_settings (
    user_id uuid primary key references auth.users(id) on delete cascade,
    selected_continent_id integer references public.continents(id),
    other_filters jsonb default '{}'::jsonb,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Create triggers for updated_at
create trigger set_timestamp
    before update on public.continents
    for each row
    execute procedure public.trigger_set_timestamp();

create trigger set_timestamp
    before update on public.countries
    for each row
    execute procedure public.trigger_set_timestamp();

create trigger set_timestamp
    before update on public.planned_visits
    for each row
    execute procedure public.trigger_set_timestamp();

create trigger set_timestamp
    before update on public.user_map_settings
    for each row
    execute procedure public.trigger_set_timestamp();

-- Create materialized view for user statistics
create materialized view public.user_statistics as
with total_counts as (
    select 
        count(*) as total_countries,
        count(distinct continent_id) as total_continents
    from public.countries
),
visit_counts as (
    select 
        uvc.user_id,
        co.name as continent_name,
        count(*) as visit_count
    from public.user_visited_countries uvc
    join public.countries c on uvc.country_id = c.id
    join public.continents co on c.continent_id = co.id
    group by uvc.user_id, co.name
),
continent_stats as (
    select 
        user_id,
        jsonb_object_agg(continent_name, visit_count) as visits_by_continent
    from visit_counts
    group by user_id
),
user_totals as (
    select 
        uvc.user_id,
        count(distinct uvc.country_id) as visited_countries,
        count(distinct c.continent_id) as visited_continents
    from public.user_visited_countries uvc
    join public.countries c on uvc.country_id = c.id
    group by uvc.user_id
)
select 
    ut.user_id,
    (ut.visited_countries::float / tc.total_countries::float) * 100 as visited_percentage,
    (ut.visited_continents::float / tc.total_continents::float) * 100 as continents_percentage,
    coalesce(cs.visits_by_continent, '{}'::jsonb) as visits_by_continent
from user_totals ut
cross join total_counts tc
left join continent_stats cs on cs.user_id = ut.user_id;

-- Create function to refresh statistics
create or replace function public.refresh_user_statistics()
returns void as $$
begin
    refresh materialized view concurrently public.user_statistics;
end;
$$ language plpgsql;

-- Create search function
create or replace function public.search_countries_and_continents(search_term text)
returns table (
    type text,
    id integer,
    name text,
    code text
) as $$
begin
    return query
    select 'continent', c.id, c.name, c.code
    from public.continents c
    where c.name ilike search_term || '%'
    union all
    select 'country', co.id, co.name, null
    from public.countries co
    join public.continents c on co.continent_id = c.id
    where c.name ilike search_term || '%'
    order by type desc, name;
end;
$$ language plpgsql;

-- Create indexes
create index countries_search_idx on public.countries using gin (search_vector);
create index countries_continent_idx on public.countries (continent_id);
create index countries_geojson_idx on public.countries using gin (geojson);
create index user_visited_countries_date_idx on public.user_visited_countries (visited_at);
create index planned_visits_date_idx on public.planned_visits (planned_date);

-- Enable RLS on all tables
alter table public.continents enable row level security;
alter table public.countries enable row level security;
alter table public.user_visited_countries enable row level security;
alter table public.planned_visits enable row level security;
alter table public.user_map_settings enable row level security;

-- Create RLS policies for continents
create policy "continents are viewable by everyone"
    on public.continents for select
    using (true);

-- Create RLS policies for countries
create policy "countries are viewable by everyone"
    on public.countries for select
    using (true);

-- Create RLS policies for user_visited_countries
create policy "users can view their own visited countries"
    on public.user_visited_countries for select
    using (auth.uid() = user_id);

create policy "users can insert their own visited countries"
    on public.user_visited_countries for insert
    with check (auth.uid() = user_id);

create policy "users can delete their own visited countries"
    on public.user_visited_countries for delete
    using (auth.uid() = user_id);

-- Create RLS policies for planned_visits
create policy "users can manage their planned visits"
    on public.planned_visits for all
    using (auth.uid() = user_id);

-- Create RLS policies for user_map_settings
create policy "users can manage their map settings"
    on public.user_map_settings for all
    using (auth.uid() = user_id); 
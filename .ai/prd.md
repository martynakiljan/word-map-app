# Dokument wymagań produktu (PRD) – Lista Miejsc do Odwiedzenia

## 1. Przegląd produktu

Aplikacja "Lista Miejsc do Odwiedzenia" umożliwia użytkownikom śledzenie odwiedzonych krajów i planowanie przyszłych podróży. Użytkownicy mogą logować się, aby zobaczyć interaktywną mapę świata, dodawać miejsca do odwiedzenia i zaznaczać odwiedzone kraje.

## 2. Problem użytkownika

Podróżnicy często chcą śledzić swoje podróże i planować nowe, ale brakuje im narzędzi do wizualizacji odwiedzonych miejsc w kontekście globalnym.

## 3. Wymagania funkcjonalne

1. **Logowanie i rejestracja**:

   - Użytkownicy muszą się zalogować, aby uzyskać dostęp do aplikacji.
   - Użycie Firebase Authentication lub Auth0.

2. **Interaktywna mapa**:

   - Wyświetlanie mapy świata z konturami krajów.
   - Zaznaczanie odwiedzonych krajów.
   - Kliknięcie na kraj wyświetla szczegóły w popupie.
   - Najechanie na nieodwiedzony kraj przekierowuje do bloga z informacjami o kraju.

3. **Zarządzanie miejscami**:
   - Formularz do dodawania miejsc do odwiedzenia.
   - Formularz do dodawania szczegółów odwiedzonych miejsc.

## 4. Granice produktu

- Aplikacja webowa (brak wersji mobilnej na początek).
- Brak zaawansowanych funkcji społecznościowych (np. współdzielenie miejsc).

## 5. Historyjki użytkowników

- **ID: US-001**: Jako użytkownik chcę się zalogować, aby uzyskać dostęp do mojej mapy miejsc do odwiedzenia.
- **ID: US-002**: Jako użytkownik chcę zaznaczyć odwiedzone kraje na mapie, aby śledzić moje podróże.
- **ID: US-003**: Jako użytkownik chcę dodać szczegóły odwiedzonych miejsc, aby móc je później przeglądać.
- **ID: US-004**: Jako użytkownik chcę móc przeczytać więcej o nieodwiedzonych krajach, aby pomóc mi podjąć decyzję o ich odwiedzeniu.

## 6. Metryki sukcesu

- Liczba aktywnych użytkowników.
- Liczba dodanych miejsc i odwiedzonych krajów.
- Diagramy pokazujące wzrost liczby odwiedzonych krajów i dodanych miejsc w czasie.

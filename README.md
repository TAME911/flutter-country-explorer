# 🌍 Country Explorer — Flutter App
### AAU · Mobile Application Development · Assignment 2 · Track A

## 1. Student Information

| **Name**       | Tamene Wolde |
| **Student ID** | *(ATE/5140/15)* |
| **Track**      | Track A — Country Explorer (RestCountries API) |
| **Instructor** | Abel Tadesse |

## 2. App Description

Country Explorer is a Flutter application that lets users browse, search, and
explore detailed information about every country in the world.  
Data is fetched in real time from the **RestCountries v3.1 API** — no API key needed.

**Key features:**
- Scrollable list of all ~250 countries with flag images, region, and capital
- Real-time search by country name (400 ms debounce — Bonus)
- Full detail screen: capital, population, area, currencies, languages, timezones
- Pagination — 20 countries per "Load More" page (Bonus)
- 5-minute in-memory cache with visible "Cached" badge (Bonus)
- Full error handling for all 5 error types + Retry button

## 3. How to Run Locally

```bash
# 1. Clone the repo
git clone https://github.com/<your-username>/flutter-country-explorer.git
cd flutter-country-explorer

# 2. Install dependencies
flutter pub get

# 3. Run (connect a device or start an emulator first)
flutter run

# 4. Build release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```
> No `.env` file needed — Track A uses a free, key-less API.

## 4. API Endpoints Used

Base URL: `https://restcountries.com`

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/v3.1/all?fields=name,flags,flag,region,subregion,capital,population,area,cca3` | Fetch all countries for home list |
| GET | `/v3.1/name/{name}` | Search countries by name |
| GET | `/v3.1/alpha/{code}` | Fetch full details by ISO alpha-3 code |

## 5. Project Structure

```
lib/
├── main.dart                          ← App entry point + MaterialApp
├── models/
│   └── country.dart                   ← Country model (fromJson, toJson, copyWith)
├── services/
│   ├── country_api_service.dart       ← ALL HTTP logic + 5-min in-memory cache
│   └── api_exception.dart             ← Custom exception for non-200 responses
├── screens/
│   ├── home_screen.dart               ← FutureBuilder list + pagination
│   ├── search_screen.dart             ← Search with 400 ms debounce
│   └── detail_screen.dart            ← Full country detail
└── widgets/
    ├── country_tile.dart              ← Reusable list row widget
    └── error_view.dart               ← Reusable error + Retry widget
```

## 6. Known Limitations & Bugs

- RestCountries has no server-side pagination, so all ~250 countries load in
  one request. Pagination is client-side (slicing the in-memory list).
- The 5-minute cache is in-memory only — cleared when the app is closed.
- Some territories may have incomplete data (e.g. missing capital or area).
- Flag images require an active internet connection; offline shows a placeholder.

## 7. References

- [RestCountries API](https://restcountries.com/)
- [Flutter http package](https://pub.dev/packages/http)
- [Flutter FutureBuilder docs](https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html)
- AAU Mobile App Development lecture slides — Unit 4

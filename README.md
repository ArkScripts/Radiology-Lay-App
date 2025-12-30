# SimpleMed Radiology Info

A cross-platform mobile app (iOS/Android) built with Flutter to explain basic radiology scans in simple, lay terms for NHS patients.

## Purpose

This app helps NHS patients understand common radiology scans (CT, MRI, Ultrasound, X-Ray) by providing:
- Plain English explanations
- Preparation instructions
- Safety information with traffic light indicators
- What to expect during the scan

## Architecture

**Server-Driven UI with Offline-First Design:**

```
Remote JSON (simplemed.co.uk)
         │
         ▼
    DataService ──── Cache (SharedPreferences)
         │
         ▼
    DataProvider (ChangeNotifier)
         │
         ▼
    UI Widgets (Consumer)
```

- **No backend required** - fetches static JSON from URL
- **Offline-first** - caches JSON locally, falls back when offline
- **Image caching** - uses CachedNetworkImage for offline image access
- **Aspect ratio reservation** - prevents layout shifts during image loading

## Project Structure

```
lib/
├── main.dart          # App entry point, UI screens, widgets
├── models.dart        # Data models (AppData, Section, Scan, etc.)
└── data_service.dart  # JSON fetching, caching, state management

assets/
└── radiology_data.json  # Fallback/test data
```

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Dart 3.0+

### Installation

```bash
# Clone the repository
git clone https://github.com/ArkScripts/Radiology-Lay-App.git
cd Radiology-Lay-App

# Get dependencies
flutter pub get

# Run the app
flutter run
```

### Build for Production

```bash
# Android APK
flutter build apk --release

# iOS (requires macOS)
flutter build ios --release
```

## Key Dependencies

| Package | Purpose | Java Equivalent |
|---------|---------|-----------------|
| `http` | HTTP client | OkHttp/HttpURLConnection |
| `shared_preferences` | Local key-value storage | SharedPreferences |
| `cached_network_image` | Image caching | Glide/Picasso |
| `provider` | State management | ViewModel + LiveData |
| `google_fonts` | Typography | Fonts in res/ |

## For Java Developers

The codebase includes detailed comments explaining Dart/Flutter concepts in terms of Java equivalents:

- `Future<T>` → `CompletableFuture<T>`
- `async/await` → CompletableFuture chains or Kotlin Coroutines
- `ChangeNotifier` → ViewModel with LiveData
- `Widget.build()` → Declarative UI (what, not how)
- `factory` constructor → Static factory methods
- `final` → Same as Java's final
- `required` → Non-null parameters

## NHS Branding

Uses official NHS colour palette:
- Primary: `#005EB8` (NHS Blue)
- Secondary: `#003087` (NHS Dark Blue)
- Clean white backgrounds
- Lato font family

## JSON Data Format

```json
{
  "meta": { "version": "1.0" },
  "sections": [
    {
      "category_name": "CT Scans",
      "category_color_hex": "#005EB8",
      "scans": [
        {
          "id": "ct_abdo",
          "title": "CT Abdomen",
          "short_summary": "...",
          "full_description": "...",
          "preparation": { ... },
          "logistics": { ... },
          "safety": { ... },
          "media": { ... }
        }
      ]
    }
  ]
}
```

## License

This project is for educational purposes.

## Contact

admin@simplemed.co.uk

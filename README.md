# Newskit FL

Newskit FL is a cross-platform Flutter news application that helps users discover the latest headlines, search for stories, save favorites, and share articles.

## Key Features

- Browse curated top headlines in the **Today** tab
- Explore news by categories in the **News** tab
- Search for articles by keyword in the **Search** tab
- Save and manage bookmarked articles in the **Saved** tab
- Share news stories using platform share dialogs
- Toggle light and dark modes in the **Settings** tab
- Persistent bookmarks using local storage
- Supports Android, iOS, Linux, macOS, Windows, and Web

## Installation

### Prerequisites

- Flutter SDK installed (recommended stable channel)
- A connected device or emulator/simulator
- A valid NewsAPI API key

### Setup

1. Clone the repository:

```bash
git clone https://github.com/your-repo/newskit_fl.git
cd newskit_fl
```

2. Install dependencies:

```bash
flutter pub get
```

3. Configure your NewsAPI key:

Open `lib/services/news_service.dart` and replace the value of `_apiKey` with your own NewsAPI key.

```dart
static const _apiKey = 'YOUR_API_KEY';
```

4. Run the app:

```bash
flutter run
```

Or choose a device explicitly:

```bash
flutter run -d chrome
flutter run -d emulator-5554
```

### Build for release

- Android APK:

```bash
flutter build apk
```

- iOS app:

```bash
flutter build ios
```

- Web app:

```bash
flutter build web
```

## Project Structure

- `lib/main.dart` — app entrypoint and tab navigation
- `lib/screens/` — main UI screens for Today, News, Search, Saved, and Settings
- `lib/models/` — article data models
- `lib/providers/` — state management with Riverpod
- `lib/services/` — network service layer for NewsAPI requests

## Notes

- The app uses `flutter_riverpod` for state management
- Bookmarks persist via `shared_preferences`
- News data is fetched from `newsapi.org`
- If you add new APIs or services, keep keys secure and do not commit them to source control

## Troubleshooting

- If `flutter pub get` fails, make sure your Flutter SDK is up to date:

```bash
flutter upgrade
```

- If the app fails to fetch news, verify the API key and network connectivity.

- For platform-specific issues, run:

```bash
flutter doctor
```

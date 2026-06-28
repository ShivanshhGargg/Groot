# Groot Flutter Web/PWA

Flutter-first frontend for Groot, the AI Manager MVP described in `Groot.docx`.

## What Is Included

- Flutter web/PWA shell with manifest and install metadata
- Riverpod state management
- go_router routes for auth, home, inbox, memories, workflows, notifications, profile, and settings
- API-ready boundaries for REST integration
- Demo data for early user feedback before the backend is complete
- Design tokens based on the Groot UI design system

## Run Locally

Install Flutter, then run:

```bash
flutter pub get
flutter run -d chrome --dart-define=GROOT_API_BASE_URL=http://localhost:8080/api/v1
```

Build the PWA:

```bash
flutter build web --release --dart-define=GROOT_API_BASE_URL=https://api.groot.ai/api/v1
```

## Project Shape

```text
lib/
|-- app/
|-- core/
|-- features/
|   |-- auth/
|   |-- dashboard/
|   |-- inbox/
|   |-- memories/
|   |-- notifications/
|   |-- profile/
|   `-- workflows/
|-- shared/
`-- main.dart
```

The current repository machine does not have Flutter/Dart installed, so this project was scaffolded manually and should be analyzed after Flutter is installed.

# MindCare 🌿

A bilingual (English & Sinhala) mental-wellness Flutter app.

## Features
- Guided meditations (8 types) with step auto-advance & audio chimes
- Breathing exercises
- Mood check-in & history
- Mini-games, coloring/painting studio, calm music
- Journal, motivational quotes, daily reminders
- Resource library & find-a-doctor/counsellor
- Sinhala chat assistant

## Run the project

```bash
flutter pub get
flutter run                # auto-selects a connected device
flutter run -d windows     # or: android/ios/chrome
```

### Prerequisites
- Flutter SDK (stable) & Dart ≥ 3.11.4
- A device or emulator (or use Windows/Chrome)

## Tests

```bash
flutter test
flutter analyze
```

## Optional: regenerate meditation chimes

```bash
python generate_audio.py
```

## Structure

```
lib/
├── core/        # theme, l10n, router, service locator
├── data/        # Hive, prefs, repositories
├── features/    # mood, meditation, breathing, games, etc.
└── services/    # chat, sync, notifications, analytics stubs
```

> Note: Firebase/analytics/FCM use no-op stubs — no Firebase config needed to run. Meant for mental wellness support, not a substitute for professional care.
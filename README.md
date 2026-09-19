# rest_for_more

A Flutter mobile application for managing and tracking rest routines — built as part of the Mobile Apps semester at Fontys University of Applied Sciences.

## About

**rest_for_more** helps users build and follow structured rest and recovery routines. The app provides an intuitive interface to view active routines, track progress, and switch between different routine plans.

## Features

- 📋 **Routine Screen** — Browse and manage your rest routines
- ✅ **Active Routine Card** — See your currently active routine at a glance
- 🔄 **Routine Switcher** — Quickly switch between different routines
- 📊 **Progress Indicator** — Track completion progress through a routine
- 🎨 **Custom Theme** — Consistent app-wide color system and theming

## Project Structure

```
lib/
├── main.dart                        # App entry point
├── models/
│   └── routine_step.dart            # RoutineStep data model
├── screens/
│   └── routine_screen.dart          # Main routine screen
├── theme/
│   ├── app_colors.dart              # Color palette
│   └── app_theme.dart               # Theme configuration
└── widgets/
    ├── active_routine_card.dart      # Active routine display card
    ├── bottom_action_dock.dart       # Bottom action buttons
    ├── greeting_header.dart          # Greeting header widget
    ├── metadata_chip.dart            # Metadata tag chip
    ├── routine_item_card.dart        # Individual routine item card
    ├── routine_progress_indicator.dart # Progress tracking widget
    └── routine_switcher.dart         # Routine switcher widget
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.13.3`
- Dart SDK `^3.13.3`

### Run the app

```bash
# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

### Supported Platforms

- 📱 Android
- 🍎 iOS
- 🖥️ macOS
- 🐧 Linux
- 🪟 Windows
- 🌐 Web

## Built With

- [Flutter](https://flutter.dev/) — Cross-platform UI framework
- [Dart](https://dart.dev/) — Programming language


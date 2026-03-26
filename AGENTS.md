# Agent Instructions

## Project Overview

- **Name:** Ganz Schön Clever Scorer
- **Type:** Flutter Mobile Application
- **Purpose:** Scoring application for the dice game "Ganz Schön Clever" (That's Pretty Clever)
- **Target Platforms:** iOS, Android, macOS, Linux

## Tech Stack

- **Framework:** Flutter 3.4.1+
- **State Management:** Riverpod (flutter_riverpod)
- **Navigation:** GoRouter
- **Database:** SQLite (sqflite)
- **Additional:** uuid, intl, path_provider

## Key Commands

```bash
# Run the app
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Build for iOS
flutter build ios

# Build for Android
flutter build apk

# Build for macOS
flutter build macos
```

## Architecture

The app follows a layered architecture:

```
lib/
├── main.dart              # App entry point
├── models/                # Data models
│   ├── player.dart
│   ├── score_sheet.dart   # Contains all 6 score areas (yellow, green, orange, purple, blue, bonus)
│   ├── game_session.dart
│   ├── game_summary.dart
│   └── high_score.dart
├── providers/             # Riverpod state management
│   └── game_providers.dart
├── services/              # Database service
│   └── database_service.dart
├── screens/               # UI screens
│   ├── main_menu_screen.dart
│   ├── game_setup_screen.dart
│   ├── score_calculator_screen.dart
│   ├── final_scores_screen.dart
│   ├── game_history_screen.dart
│   ├── high_scores_screen.dart
│   ├── game_details_screen.dart
│   └── cleanup_screen.dart
├── router/                # GoRouter configuration
│   └── app_router.dart
└── theme/                 # App theming
    └── app_theme.dart
```

## Database Schema

- **games:** Stores game sessions (id, uuid, created_at, completed_at, player_count, winner_name, winner_score, notes)
- **players:** Stores player scores per game (game_id, name, final_score, yellow/green/orange/purple/blue totals, fox_count, bonus)
- **high_scores:** Leaderboard entries (game_id, player_name, score, achieved_at)

## Testing

### Unit/Widget Tests

- Test file: `test/widget_test.dart`
- Run tests with: `flutter test`

### Local Testing with Web Mode

To test the app locally in a web browser:

```bash
# Run the app in Chrome
flutter run -d chrome
```

The app will be available at `http://localhost:PORT` (typically http://localhost:55261).

### UI Testing with Playwright CLI

Use the `playwright-cli` skill to interact with the running web app for UI testing, form filling, screenshots, and data extraction.

**Loading the skill:**

```
/skill playwright-cli
```

**Example workflow:**

1. Start the app: `flutter run -d chrome`
2. Load the playwright-cli skill
3. Use playwright commands to navigate pages, fill forms, take screenshots, and verify UI behavior

For more details on available commands, see the playwright-cli skill documentation.

## Code Style

- Uses flutter_lints for code analysis
- Follows Flutter conventions
- No additional comments unless explicitly requested

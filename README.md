# P1ng Todo Manager

A task manager built for students. It keeps assignments, deadlines, reminders, a personal timetable, and focus sessions in a single local application.

I built this because standard reminders are too easy to dismiss. P1ng actively reminds you about a task until you explicitly complete, snooze, or reschedule it.

## Features

- **Persistent Reminders**: Tasks keep notifying you until you act on them.
- **University Timetable**: Manage your class schedule. You can import timetables by uploading a CSV or an image.
- **Focus Sessions**: Built-in timers for study blocks.
- **Local Storage**: Everything is stored in SQLite on your device. There is no account requirement and no backend sync in the MVP.

## Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Database**: SQLite (via Drift)

## Architecture

The project uses a feature-first layered architecture separating Presentation, Application, Domain, and Data.

Because the app is strictly local-first, the database layer relies on Drift for type-safe SQLite persistence. Reminders are scheduled directly on the device OS rather than relying on a push notification server. Timetable imports (CSV and OCR image processing) run through a strict draft-review-confirm pipeline before hitting the database.

Design decisions and architectural boundaries are documented in `docs/`:
- [Product Scope](docs/PRODUCT.md)
- [Architecture & State](docs/ARCHITECTURE.md)
- [Design Constraints](docs/DESIGN.md)
- [Flows](docs/FLOWS.md)

Future plans and upcoming features are tracked in the [Roadmap](docs/ROADMAP.md).

## Development Setup

1. Make sure Flutter is installed.
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

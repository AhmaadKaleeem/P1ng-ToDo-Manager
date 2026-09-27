# Todow — Task Manager for Students

Most productivity apps treat your to-do list like a spreadsheet. Todow treats it like a canvas — a warm, focused space where your day's work lives in one place and stays there until you deal with it.

Built for students who have too many deadlines and too little time to manage them.

---

## What's Shipped

### Task List Interactions
Everything you need to manage your list without lifting a finger from the task:

- **Drag to reorder** — Long-press any task and drag it into position. Order persists across restarts.
- **Swipe to act** — Swipe right to complete (or reopen). Swipe left to delete. No confirmation dialogs.
- **Double-tap to insert** — Double-tap a task to open an inline text field directly below it. Type, Enter to create. Tap away to dismiss.
- **Quick Add bar** — The persistent pill at the bottom of your list. Type a title and submit, or tap `+` to open the full task editor.
- **Quick duplicate** — Clone any task in one tap. Useful for recurring assignments.

### Task Editor
A full editor for when you need more than a title. Set priority, due date, start time, category, subtasks, attachments, and reminder presets — all in one screen.

### Reminders That Actually Work
Todow doesn't let a task quietly expire. Reminders keep firing until you complete, snooze, or reschedule the task. Three built-in presets:
- **Normal** — 1 day before + at deadline
- **Assignment** — 2 days, 1 day, 3 hours, 30 minutes before
- **Critical** — 3 days, 2 days, 1 day, 3h, 1h, 30m, and at deadline

### Timetable
Manage your class schedule by hand, or import it. Supported import formats: CSV and image (OCR). Every import goes through a draft-review-confirm pipeline before it touches the database.

### Focus Sessions
Link a task to a focus session, set a timer, and go. Pause, resume, or end early. Session state survives app restarts.

### Roadmap
Track goals and milestones. Import and export via CSV with a fixed schema.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| State Management | Provider + ChangeNotifier |
| Database | SQLite (via `sqflite`) |
| Animations | `flutter_animate` |
| Swipe Actions | `flutter_slidable` |

---

## Architecture

Clean layered architecture: **Presentation → Controller → Domain → Data**.

- `lib/domain/` — Pure Dart models and repository interfaces. No Flutter imports. Fully testable.
- `lib/data/` — SQLite implementations. Schema migration handled per-version.
- `lib/presentation/` — Screens, controllers (`ChangeNotifier`), and widgets.

Design decisions are in [`docs/DESIGN_SPEC.md`](docs/DESIGN_SPEC.md).  
Product scope and requirements are in [`docs/PRODUCT.md`](docs/PRODUCT.md).  
Architecture details are in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## Development Setup

```bash
# Install dependencies
flutter pub get

# Run (any connected device or emulator)
flutter run

# Run all tests
flutter test

# Static analysis
flutter analyze
```

All 8 tests pass. No issues found.

---

## Design Principles

Todow is a **warm light task canvas**. Cream background (`#F5F1EA`), white cards, soft shadows. No dark mode tropes, no gradients, no gamification. Azure for actions. Amber for attention. Everything else is structural.

See [`docs/DESIGN_SPEC.md`](docs/DESIGN_SPEC.md) for the full visual contract and component recipes.

# Todow

Todow is a task and productivity manager built for students.

## Features

Todow combines multiple student workflows into a single application backed by SQLite:

*   **Task Management**: Create, organize, and track tasks. Supports subtasks, categories, tags, priority levels, and file attachments.
*   **Advanced Interactions**:
    *   Drag and drop to reorder tasks in the active list.
    *   Swipe right to complete or reopen tasks.
    *   Swipe left to delete tasks.
    *   Double tap any task to insert a new one immediately below it.
    *   Quick Add bar for fast entry.
    *   One-tap task duplication for recurring assignments.
*   **Persistent Reminders**: Notifications that continue to alert you until a task is completed, snoozed, or rescheduled. Includes presets for standard, assignment, and critical deadlines.
*   **Constant Reminders**: An optional mode where tasks continually notify you according to a repeat policy until explicitly stopped.
*   **Timetable Integration**: Manage class schedules. Supports manual entry, CSV import, and OCR image import with a draft-and-review flow.
*   **Focus Sessions**: Built-in timers for study blocks. Link sessions directly to tasks and persist elapsed time across app restarts.
*   **Roadmap**: Track long-term goals and milestones with CSV import and export capabilities.

## Technical Architecture

The application follows a clean, feature-first layered architecture:

*   **Presentation**: Flutter UI, Riverpod state management, and `ChangeNotifier` controllers.
*   **Domain**: Pure Dart models, services, and repository interfaces. Contains core business logic and is completely independent of the Flutter framework.
*   **Data**: SQLite persistence via `sqflite`.

For in-depth documentation, see the `docs/` directory:
*   [Product Scope](docs/PRODUCT.md)
*   [Architecture Details](docs/ARCHITECTURE.md)
*   [Design Specifications](docs/DESIGN_SPEC.md)
*   [Core Flows](docs/FLOWS.md)
*   [Roadmap](docs/ROADMAP.md)

## Tech Stack

*   **Framework**: Flutter
*   **State**: Provider
*   **Storage**: SQLite (`sqflite`)
*   **Key Packages**: `flutter_animate`, `flutter_slidable`

## Development Setup

1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Run the application:
   ```bash
   flutter run
   ```

3. Run the test suite:
   ```bash
   flutter test
   ```

4. Verify static analysis:
   ```bash
   flutter analyze
   ```

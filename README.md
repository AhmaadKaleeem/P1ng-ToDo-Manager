# Todow

Students juggle assignments and deadlines across too many tools. Missing a due date happens too easily. Todow is a Flutter based mobile application for students that brings your schedule and tasks into one place.

## Features

### Completed
- **Task Management** Create, edit, complete, reopen, delete, archive. Includes title, description, priority, start/due dates, tags, and subtasks. Search, filter, and sort. Quick duplicate. Clone recurring tasks. Drag to reorder, swipe to act, and double tap to insert.
- **Attachments** Attach local images, PDFs, and files.

### Ongoing
- **Reminders & Presets** Multiple reminders per task (absolute or relative). Snooze, reschedule, and cancel on complete. Presets for NORMAL, ASSIGNMENT, and CRITICAL.
- **Constant Reminder** Continues reminding according to repeat policy until completed, snoozed, or stopped.

### Upcoming
- **Today** Aggregates overdue, today's, upcoming, active reminders, timetable entries, and active focus.
- **Focus Mode** Task-linked sessions, timer, pause/resume/end, presets, and basic distraction controls.
- **Timetable** Manual entry, CSV import, and OCR image import.
- **Roadmap** Goals, milestones, and priorities with CSV import/export.
- **Google Accounts** Multiple accounts, Gmail to tasks, and Google Calendar sync.
- **Academic Tools** Import Google Classroom assignments, attach Google Drive files, and pull timetable data.
- **Sync & Backup** Sync across devices, automatic backups, and offline changes supported.
- **Focus Improvements** Android app blocking, allowed apps during study, and focus history.
- **Advanced Planning** Recurring tasks, weekly/monthly planning, goal tracking, milestone dependencies, and flexible reminder rules.

Everything is stored locally on your device.

## Setup

```bash
flutter pub get
flutter run
```

Run tests:

```bash
flutter test
flutter analyze
```

## Docs

- [Product spec](docs/PRODUCT.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Design spec](docs/DESIGN_SPEC.md)
- [User flows](docs/FLOWS.md)
- [Roadmap](docs/ROADMAP.md)

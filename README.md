# Todow

Todow is a mobile app for students to manage tasks and schedules.

## Features

| Feature | MVP | Details | Status |
|---|---|---|---|
| Task Management | Yes | Create, edit, complete, reopen, delete, archive. Title, description, priority, start/due dates, tags, subtasks. Search, filter, sort. Quick duplicate. Clone recurring tasks. Drag to reorder, swipe to act, double tap to insert. Splash screen skip. | Completed |
| Attachments | Yes | Attach local images, PDFs, files. Open and remove. SQLite stores metadata, local storage holds files. | Completed |
| Reminders & Presets | Yes | Multiple reminders per task (absolute or relative). Snooze, reschedule. Completing task cancels pending. Presets: NORMAL, ASSIGNMENT, CRITICAL. | Ongoing |
| Constant Reminder | Yes | Continues reminding according to repeat policy until completed, snoozed, or stopped. | Ongoing |
| Today | Yes | Aggregates overdue, today's, upcoming, active reminders, timetable entries, active focus. | Future Roadmap |
| Focus Mode | Yes | Task-linked sessions, timer, pause/resume/end, presets, basic distraction controls. | Future Roadmap |
| Timetable | Yes | Manual entry, CSV import, OCR image import. Flow: Upload/Extract, Draft, Review/Edit, Confirm, Persist. | Future Roadmap |
| Roadmap | Yes | Goals, milestones, priorities. CSV import/export with fixed schema. | Future Roadmap |
| Google accounts | No | Multiple accounts, Gmail to tasks, Google Calendar sync. | Future Roadmap |
| Academic tools | No | Import Google Classroom assignments, attach Google Drive files, pull timetable data. | Future Roadmap |
| Sync & backup | No | Sync across devices, automatic backups, offline changes supported. | Future Roadmap |
| Focus improvements | No | Android app blocking, allowed apps during study, focus history. | Future Roadmap |
| Advanced planning | No | Recurring tasks, weekly/monthly planning, goal tracking, milestone dependencies, flexible reminder rules. | Future Roadmap |

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

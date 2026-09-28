# Todow

Todow is a Flutter mobile app for students who need a task manager that gets out of the way. No accounts. No syncing. No subscription tiers. You open it, you see your tasks, you get things done.

---

## What it does

**Task management** that actually feels fast. Every task has a title, description, priority, due date, and category. The list itself has drag-to-reorder so you can manually sequence your day by importance. Swipe right to complete, swipe left to delete — no confirmation dialogs. Double-tap between two tasks to insert a new one exactly there without losing your place.

**Animated check-off and undo.** Tapping the circle on a task draws a strikethrough across the title from left to right, then moves it to the Completed section. Tap the checkmark again and the line retracts in reverse before the task drops back into the active list. No jarring rebuilds.

**Search, filter, and sort.** A persistent search bar sits above your task list. Filter by due status — Overdue, Today, This Week, No Date. Sort by due date, priority, creation time, or title. Reset to manual sort with one tap at the bottom of the sort sheet.

**Relative due labels.** Tasks show dates the way people actually think about them: Today, Tomorrow, Yesterday, Friday, Oct 3, Oct 3 2027. Overdue tasks call it out directly: Overdue · Oct 3. No time-of-day clutter unless a task is due today.

**Roadmap cards.** The home screen shows three project cards at the top — your most active categories — with task counts and a progress bar. Tap to drill into any roadmap.

**Attachments.** Each task can have files attached to it — images, PDFs, local documents. The attachment count shows on the task row. Open or remove them from the editor.

**Reminders.** Set multiple reminders per task, absolute or relative. Completing a task cancels all its pending reminders automatically. Preset reminder schedules for normal assignments, high-priority work, or critical deadlines.

**Quick add.** A text field at the bottom of the task list for fast capture without opening the full editor.

---

Everything is stored locally on your device. No cloud, no account required, works completely offline.

---

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

---

## Docs

- [Product spec](docs/PRODUCT.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Design spec](docs/DESIGN_SPEC.md)
- [User flows](docs/FLOWS.md)
- [Roadmap](docs/ROADMAP.md)

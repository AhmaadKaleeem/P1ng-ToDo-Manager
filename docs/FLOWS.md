# Application Flows

## Reminder Flow

### Scheduling

![Reminder Sequence](../assets/Diagram_Reminder_Sequence.png)

```mermaid
sequenceDiagram
    actor User
    participant UI
    participant TaskService
    participant ReminderEngine
    participant Repo
    participant Scheduler
    participant OS as OS Notification

    User->>UI: Create task + reminders
    UI->>TaskService: Create task
    TaskService->>Repo: Save task
    TaskService->>ReminderEngine: Build schedule
    ReminderEngine->>Repo: Save reminders
    ReminderEngine->>Scheduler: Schedule notifications
    Scheduler->>OS: Register alarms
```

### Reliability Rules
The scheduler must be reconstructable from persistent state. On application startup:
1. Load active tasks & pending reminders.
2. Detect expired/stale schedules.
3. Reconcile and schedule missing notifications.
4. Cancel notifications for completed/cancelled tasks.

## Timetable Import Flow

### Architecture

![Timetable Sequence](../assets/Timetable%20sequence%20diagram.png)

```text
TIMETABLE INPUT (Manual / CSV / OCR Image)
      ↓
Parser / Extraction
      ↓
Timetable Draft
      ↓
Review / Edit by User
      ↓
Validation
      ↓
Confirm
      ↓
Persistence (SQLite)
```

Ambiguous OCR/CSV data should be surfaced to the user. Nothing is saved until confirmed.

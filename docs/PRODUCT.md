# Student Productivity App - MVP 0.1

## Core Product Loop
CAPTURE → ORGANIZE → SCHEDULE → REMIND → FOCUS → COMPLETE

## Product Principles
- **Personal-first**: Useful to one student without requiring an account, server, or cloud service.
- **Local-first**: Core functionality works offline.
- **Reminder reliability**: Reminders are a core product capability, not an optional notification layer.
- **Human control**: Imported/extracted info must be reviewable and editable before saving.
- **Simple first**: Solve the core student workflow without unrelated integrations.
- **Extendable architecture**: Support future integrations via adapters.

## Requirements

### FR-01 Task Management
Create, edit, complete, reopen, delete, archive. Title, description, priority, start date/time, due date/time, tags/categories, subtasks. Search, filter, sort.

### FR-02 Attachments
Support local attachments (images, PDFs, local files). Attach, open, remove. SQLite stores metadata, local storage holds files.

### FR-03 & FR-04 Reminders & Presets
Multiple reminders per task (absolute or relative). Snooze, reschedule. Completing task cancels pending reminders.
Presets:
- NORMAL: 1 day before + deadline
- ASSIGNMENT: 2 days before + 1 day before + 3 hours before + 30 minutes before
- CRITICAL: 3 days, 2 days, 1 day, 3h, 1h, 30m, deadline

### FR-05 Constant Reminder
When enabled, continues reminding according to repeat policy until completed, snoozed, or explicitly stopped.

### FR-07 Today
Aggregates overdue, today's, upcoming, active reminders, timetable entries, and active focus. Not an analytics dashboard.

### FR-08 Focus Mode
Task-linked sessions, timer, pause/resume/end, presets, basic distraction controls.

### FR-09, FR-10, FR-11 Timetable
Manual entry, CSV import, OCR image import.
Flow: Upload/Extract → Draft → Review/Edit → Confirm → Persist.

### FR-12 & FR-13 Roadmap
Goals, milestones, priorities. Supports CSV import/export with fixed schema.

## CSV Specification
**Timetable CSV Columns**: `course,instructor,day,start_time,end_time,room`
**Roadmap CSV Columns**: `roadmap_id,title,description,milestone,due_date,priority,status,reminder`

## Non-Functional Requirements
- **NFR-01 Offline**: Core works without internet.
- **NFR-02 Reliability**: Reminder scheduling must be deterministic and recoverable after restart.
- **NFR-03 Data Integrity**: Completed tasks don't produce pending reminders.
- **NFR-04 Testability**: Domain rules testable without Flutter widgets.

## Acceptance Criteria
- Tasks survive app restart, can be edited/completed. Subtasks work independently.
- Multiple reminders calculate timestamps correctly. Completing task cancels pending. Snoozing/Constant Reminder persist state.
- Focus sessions persist state.
- Timetable CSV/OCR produces editable draft. Not persisted before confirmation.
- Roadmap CSV import/export validates fixed schema.

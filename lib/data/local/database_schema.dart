import 'package:sqflite_common/sqlite_api.dart';

Future<void> createDatabaseSchema(Database db, int version) async {
  await db.execute('''CREATE TABLE tasks (
    id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT NOT NULL,
    status TEXT NOT NULL, priority TEXT NOT NULL, created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL, start_at TEXT, due_at TEXT, category TEXT,
    tags TEXT NOT NULL, reminder_plan TEXT NOT NULL, source_type TEXT NOT NULL,
    source_id TEXT, sort_order INTEGER NOT NULL DEFAULT 0)''');
  await db.execute('''CREATE TABLE subtasks (
    id TEXT PRIMARY KEY, task_id TEXT NOT NULL, title TEXT NOT NULL,
    is_completed INTEGER NOT NULL, sort_order INTEGER NOT NULL,
    FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE)''');
  await db.execute('''CREATE TABLE attachments (
    id TEXT PRIMARY KEY,
    task_id TEXT NOT NULL,
    filename TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    size_bytes INTEGER NOT NULL,
    content_hash TEXT NOT NULL,
    sync_state TEXT NOT NULL DEFAULT 'localOnly',
    remote_id TEXT,
    remote_upload_id TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE)''');
  await db.execute('CREATE INDEX idx_attachments_task_id ON attachments(task_id)');
  await db.execute('CREATE INDEX idx_attachments_remote_id ON attachments(remote_id)');
  await db.execute('''CREATE TABLE scheduled_reminders (
    id TEXT PRIMARY KEY, task_id TEXT NOT NULL, scheduled_at TEXT NOT NULL,
    status TEXT NOT NULL, kind TEXT NOT NULL, snoozed_until TEXT,
    notification_id INTEGER, label TEXT,
    FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE)''');
  await db.execute('''CREATE TABLE timetable_entries (
    id TEXT PRIMARY KEY, course_name TEXT NOT NULL, instructor TEXT NOT NULL,
    weekday INTEGER NOT NULL, start_time TEXT NOT NULL, end_time TEXT NOT NULL,
    room TEXT, color_value INTEGER, category TEXT)''');
  await db.execute('''CREATE TABLE focus_sessions (
    id TEXT PRIMARY KEY, task_id TEXT, task_title TEXT NOT NULL,
    preset TEXT NOT NULL, planned_seconds INTEGER NOT NULL,
    started_at TEXT NOT NULL, status TEXT NOT NULL, paused_at TEXT,
    ended_at TEXT, elapsed_before_pause_seconds INTEGER NOT NULL DEFAULT 0,
    allowed_apps TEXT NOT NULL DEFAULT '')''');
  await db.execute('CREATE INDEX idx_tasks_status ON tasks(status)');
  await db.execute('CREATE INDEX idx_tasks_due_at ON tasks(due_at)');
  await db.execute(
      'CREATE INDEX idx_reminders_task ON scheduled_reminders(task_id)');
  await db.execute(
      'CREATE INDEX idx_reminders_scheduled ON scheduled_reminders(scheduled_at)');
}

Future<void> upgradeDatabaseSchema(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE tasks ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0');
  }
  if (oldVersion < 3) {
    // Migrate legacy attachments table → FR-02 schema
    await db.execute('DROP TABLE IF EXISTS attachments');
    await db.execute('''CREATE TABLE IF NOT EXISTS attachments (
      id TEXT PRIMARY KEY,
      task_id TEXT NOT NULL,
      filename TEXT NOT NULL,
      mime_type TEXT NOT NULL,
      size_bytes INTEGER NOT NULL,
      content_hash TEXT NOT NULL,
      sync_state TEXT NOT NULL DEFAULT ''localOnly'',
      remote_id TEXT,
      remote_upload_id TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE)''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_attachments_task_id ON attachments(task_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_attachments_remote_id ON attachments(remote_id)');
  }
}

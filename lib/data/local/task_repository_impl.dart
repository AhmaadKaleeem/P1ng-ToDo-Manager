import 'package:todow/data/local/app_database.dart';
import 'package:todow/domain/models/attachment.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/reminder.dart';
import 'package:todow/domain/models/subtask.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/models/query.dart';
import 'package:todow/domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<Task> create(Task task) async {
    await _database.db.insert('tasks', task.toMap());
    for (final sub in task.subtasks) {
      final s = sub.taskId == task.id ? sub : Subtask(
        id: sub.id,
        taskId: task.id,
        title: sub.title,
        description: sub.description,
        isCompleted: sub.isCompleted,
        sortOrder: sub.sortOrder,
      );
      await _database.db.insert('subtasks', s.toMap());
    }
    for (final att in task.attachments) {
      await _database.db.insert('attachments', att.toMap());
    }
    return task;
  }

  @override
  Future<void> delete(String id) async {
    await _database.db
        .delete('subtasks', where: 'task_id = ?', whereArgs: [id]);
    await _database.db
        .delete('attachments', where: 'task_id = ?', whereArgs: [id]);
    await _database.db.delete(
      'scheduled_reminders',
      where: 'task_id = ?',
      whereArgs: [id],
    );
    await _database.db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Task?> getById(String id) async {
    final rows = await _database.db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _hydrate(rows.first);
  }

  @override
  Future<List<Task>> getAll({
    TaskStatus? status,
    String? query,
    List<String>? tags,
    TaskSort sort = TaskSort.dueDateAsc,
  }) async {
    final where = <String>[];
    final args = <Object?>[];

    if (status != null) {
      where.add('status = ?');
      args.add(status.name);
    }
    if (query != null && query.trim().isNotEmpty) {
      where.add('(title LIKE ? OR description LIKE ? OR category LIKE ?)');
      final q = '%${query.trim()}%';
      args.addAll([q, q, q]);
    }

    final order = switch (sort) {
      TaskSort.manual => 'sort_order ASC, created_at DESC',
      TaskSort.dueDateAsc => 'due_at IS NULL, due_at ASC',
      TaskSort.dueDateDesc => 'due_at IS NULL, due_at DESC',
      TaskSort.priorityDesc =>
        "CASE priority WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 WHEN 'low' THEN 3 ELSE 4 END",
      TaskSort.createdDesc => 'created_at DESC',
      TaskSort.titleAsc => 'title COLLATE NOCASE ASC',
    };

    final rows = await _database.db.query(
      'tasks',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: order,
    );

    final tasks = <Task>[];
    for (final row in rows) {
      final task = await _hydrate(row);
      if (tags != null && tags.isNotEmpty) {
        if (!task.tags.any(tags.contains)) continue;
      }
      tasks.add(task);
    }
    return tasks;
  }

  @override
  Future<Task> update(Task task) async {
    await _database.db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    await _database.db
        .delete('subtasks', where: 'task_id = ?', whereArgs: [task.id]);
    for (final sub in task.subtasks) {
      final s = sub.taskId == task.id ? sub : Subtask(
        id: sub.id,
        taskId: task.id,
        title: sub.title,
        description: sub.description,
        isCompleted: sub.isCompleted,
        sortOrder: sub.sortOrder,
      );
      await _database.db.insert('subtasks', s.toMap());
    }
    return task;
  }

  Future<Task> _hydrate(Map<String, Object?> row) async {
    final id = row['id']! as String;
    final subRows = await _database.db.query(
      'subtasks',
      where: 'task_id = ?',
      whereArgs: [id],
      orderBy: 'sort_order ASC',
    );
    final attRows = await _database.db.query(
      'attachments',
      where: 'task_id = ?',
      whereArgs: [id],
      orderBy: 'created_at ASC',
    );
    return Task.fromMap(
      row,
      subtasks: subRows.map(Subtask.fromMap).toList(),
      attachments: attRows.map(Attachment.fromMap).toList(),
    );
  }

  @override
  Future<List<ScheduledReminder>> getRemindersForTask(String taskId) async {
    final rows = await _database.db.query(
      'scheduled_reminders',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'scheduled_at ASC',
    );
    return rows.map(ScheduledReminder.fromMap).toList();
  }

  @override
  Future<void> saveReminders(
    String taskId,
    List<ScheduledReminder> reminders,
  ) async {
    await _database.db.delete(
      'scheduled_reminders',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
    final batch = _database.db.batch();
    for (final r in reminders) {
      batch.insert('scheduled_reminders', r.toMap());
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<ScheduledReminder>> getActiveReminders() async {
    final rows = await _database.db.query(
      'scheduled_reminders',
      where: "status IN ('pending', 'snoozed')",
      orderBy: 'scheduled_at ASC',
    );
    return rows.map(ScheduledReminder.fromMap).toList();
  }

  @override
  Future<void> updateReminder(ScheduledReminder reminder) async {
    await _database.db.update(
      'scheduled_reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<void> addAttachment(Attachment attachment) async {
    await _database.db.insert('attachments', attachment.toMap());
  }

  Future<void> removeAttachment(String attachmentId) async {
    await _database.db.delete(
      'attachments',
      where: 'id = ?',
      whereArgs: [attachmentId],
    );
  }
}

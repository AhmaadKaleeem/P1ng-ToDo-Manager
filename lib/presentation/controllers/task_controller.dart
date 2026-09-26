import 'package:flutter/foundation.dart';
import 'package:p1ng_todo_manager/domain/models/enums.dart';
import 'package:p1ng_todo_manager/domain/models/reminder.dart';
import 'package:p1ng_todo_manager/domain/models/subtask.dart';
import 'package:p1ng_todo_manager/domain/models/task.dart';
import 'package:p1ng_todo_manager/domain/reminders/reminder_presets.dart';
import 'package:p1ng_todo_manager/domain/repositories/task_repository.dart';
import 'package:p1ng_todo_manager/domain/services/attachment_service.dart';
import 'package:p1ng_todo_manager/domain/services/reminder_scheduler.dart';
import 'package:uuid/uuid.dart';

class TaskController extends ChangeNotifier {
  TaskController(
    this._repo,
    this._scheduler,
    this._attachments,
  );

  final TaskRepository _repo;
  final ReminderScheduler _scheduler;
  final AttachmentService _attachments;
  static const _uuid = Uuid();

  List<Task> _tasks = [];
  String _query = '';
  TaskSort _sort = TaskSort.dueDateAsc;
  TaskStatus? _filterStatus;
  String? _error;
  bool _loading = false;

  List<Task> get tasks => List.unmodifiable(_tasks);
  String get query => _query;
  TaskSort get sort => _sort;
  String? get error => _error;
  bool get loading => _loading;

  List<Task> get inboxTasks =>
      _tasks.where((t) => t.status == TaskStatus.inbox).toList();

  List<Task> get activeTasks =>
      _tasks.where((t) => t.status == TaskStatus.active).toList();

  List<Task> get overdueTasks => _tasks
      .where((t) => t.isOverdue && t.status == TaskStatus.active)
      .toList();

  List<Task> get todayTasks => _tasks
      .where((t) => t.isDueToday && t.status == TaskStatus.active)
      .toList();

  List<Task> get upcomingTasks {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return _tasks.where((t) {
      if (t.dueAt == null || t.status != TaskStatus.active) return false;
      final dueDay = DateTime(t.dueAt!.year, t.dueAt!.month, t.dueAt!.day);
      return dueDay.isAfter(tomorrow.subtract(const Duration(days: 1))) &&
          !t.isDueToday &&
          !t.isOverdue;
    }).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
  }

  Future<void> loadTasks() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _tasks = await _repo.getAll(
        status: _filterStatus,
        query: _query.isEmpty ? null : _query,
        sort: _sort,
      );
    } catch (e) {
      _error = 'Could not load tasks. Please try again.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setQuery(String value) {
    _query = value;
    loadTasks();
  }

  void setSort(TaskSort sort) {
    _sort = sort;
    loadTasks();
  }

  void setStatusFilter(TaskStatus? status) {
    _filterStatus = status;
    loadTasks();
  }

  Future<Task?> getTask(String id) => _repo.getById(id);

  Future<Task> createTask({
    required String title,
    String description = '',
    TaskStatus status = TaskStatus.active,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueAt,
    DateTime? startAt,
    String? category,
    List<String> tags = const [],
    ReminderPlan? reminderPlan,
    List<Subtask> subtasks = const [],
  }) async {
    if (title.trim().isEmpty) {
      throw TaskValidationException('Title is required.');
    }
    final now = DateTime.now();
    final plan = reminderPlan ?? ReminderPresets.defaultPlan();
    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      description: description.trim(),
      status: status,
      priority: priority,
      createdAt: now,
      updatedAt: now,
      startAt: startAt,
      dueAt: dueAt,
      category: category,
      tags: tags,
      subtasks: subtasks,
      reminderPlan: plan,
    );
    final saved = await _repo.create(task);
    await _scheduler.syncTaskReminders(saved);
    await loadTasks();
    return saved;
  }

  Future<Task> updateTask(Task task) async {
    if (task.title.trim().isEmpty) {
      throw TaskValidationException('Title is required.');
    }
    final updated = task.copyWith(updatedAt: DateTime.now());
    await _repo.update(updated);
    await _scheduler.syncTaskReminders(updated);
    await loadTasks();
    return updated;
  }

  Future<void> completeTask(String id) async {
    final task = await _repo.getById(id);
    if (task == null) return;
    final updated = task.copyWith(
      status: TaskStatus.completed,
      updatedAt: DateTime.now(),
    );
    await _repo.update(updated);
    await _scheduler.cancelTaskReminders(id);
    await loadTasks();
  }

  Future<void> reopenTask(String id) async {
    final task = await _repo.getById(id);
    if (task == null) return;
    final updated = task.copyWith(
      status: TaskStatus.active,
      updatedAt: DateTime.now(),
    );
    await _repo.update(updated);
    await _scheduler.syncTaskReminders(updated);
    await loadTasks();
  }

  Future<void> archiveTask(String id) async {
    final task = await _repo.getById(id);
    if (task == null) return;
    final updated = task.copyWith(
      status: TaskStatus.archived,
      updatedAt: DateTime.now(),
    );
    await _repo.update(updated);
    await _scheduler.cancelTaskReminders(id);
    await loadTasks();
  }

  Future<void> deleteTask(String id) async {
    await _scheduler.cancelTaskReminders(id);
    await _repo.delete(id);
    await loadTasks();
  }

  Future<void> moveToInbox(String id) async {
    final task = await _repo.getById(id);
    if (task == null) return;
    await updateTask(task.copyWith(status: TaskStatus.inbox));
  }

  Future<void> activateFromInbox(String id) async {
    final task = await _repo.getById(id);
    if (task == null) return;
    await updateTask(task.copyWith(status: TaskStatus.active));
  }

  Future<List<ScheduledReminder>> activeReminders() =>
      _repo.getActiveReminders();

  Future<void> attachFile(String taskId, String path, String name) async {
    await _attachments.attachFile(taskId, path, name);
    await loadTasks();
  }

  Future<void> removeAttachment(String taskId, String attachmentId) async {
    final task = await _repo.getById(taskId);
    if (task == null) return;
    final att = task.attachments.where((a) => a.id == attachmentId).firstOrNull;
    if (att != null) await _attachments.deleteAttachment(att);
    await loadTasks();
  }
}

class TaskValidationException implements Exception {
  TaskValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}

import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/reminder.dart';
import 'package:todow/domain/models/task.dart';

enum TaskSort { manual, dueDateAsc, dueDateDesc, priorityDesc, createdDesc, titleAsc }

abstract class TaskRepository {
  Future<List<Task>> getAll({
    TaskStatus? status,
    String? query,
    List<String>? tags,
    TaskSort sort = TaskSort.dueDateAsc,
  });

  Future<Task?> getById(String id);
  Future<Task> create(Task task);
  Future<Task> update(Task task);
  Future<void> delete(String id);

  Future<List<ScheduledReminder>> getRemindersForTask(String taskId);
  Future<void> saveReminders(String taskId, List<ScheduledReminder> reminders);
  Future<List<ScheduledReminder>> getActiveReminders();
  Future<void> updateReminder(ScheduledReminder reminder);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/models/subtask.dart';
import 'package:todow/domain/models/attachment.dart';
import 'package:todow/presentation/controllers/task_controller.dart';
import 'package:todow/domain/repositories/task_repository.dart';
import 'package:todow/domain/services/reminder_scheduler.dart';
import 'package:todow/domain/services/attachment_service.dart';
import 'package:todow/domain/models/reminder.dart';

class MockTaskRepository implements TaskRepository {
  final Map<String, Task> _tasks = {};

  @override
  Future<Task> create(Task task) async {
    _tasks[task.id] = task;
    return task;
  }

  @override
  Future<Task?> getById(String id) async => _tasks[id];

  @override
  Future<List<Task>> getAll({TaskStatus? status, String? query, TaskSort sort = TaskSort.manual, List<String>? tags}) async {
    var list = _tasks.values.toList();
    if (status != null) list = list.where((t) => t.status == status).toList();
    if (sort == TaskSort.manual) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return list;
  }

  @override
  Future<Task> update(Task task) async {
    _tasks[task.id] = task;
    return task;
  }

  @override
  Future<void> delete(String id) async {
    _tasks.remove(id);
  }

  @override
  Future<List<ScheduledReminder>> getActiveReminders() async => [];
  
  @override
  Future<List<ScheduledReminder>> getRemindersForTask(String taskId) async => [];
  
  @override
  Future<void> saveReminders(String taskId, List<ScheduledReminder> reminders) async {}
  
  @override
  Future<void> updateReminder(ScheduledReminder reminder) async {}
}

class MockReminderScheduler implements ReminderScheduler {
  @override
  Future<void> syncTaskReminders(Task task) async {}
  @override
  Future<void> cancelTaskReminders(String taskId) async {}
  Future<void> cancelAll() async {}
  @override
  Future<void> markReminderHandled(String reminderId) async {}
  @override
  Future<void> rescheduleConstantReminder(Task task) async {}
  @override
  Future<void> snoozeReminder(ScheduledReminder reminder, Duration duration) async {}
}

class MockAttachmentService implements AttachmentService {
  @override
  Future<Attachment> attachFile(String taskId, String sourcePath, String originalName) async {
    return Attachment(id: '1', taskId: taskId, fileName: originalName, localPath: sourcePath, mimeType: 'image/png', type: AttachmentType.image, createdAt: DateTime.now(), ocrReady: true);
  }
  @override
  Future<void> deleteAttachment(Attachment attachment) async {}
  Future<void> deleteAllForTask(String taskId) async {}
  Future<void> openAttachment(Attachment attachment) async {}
  @override
  Future<bool> fileExists(Attachment attachment) async => true;
}

void main() {
  test('duplicateTask creates a copy of the task with a new ID and active status', () async {
    final mockRepo = MockTaskRepository();
    final mockScheduler = MockReminderScheduler();
    final mockAttachments = MockAttachmentService();
    
    final controller = TaskController(mockRepo, mockScheduler, mockAttachments);
    
    // Seed mock repo with original task
    final original = Task(
      id: '1', 
      title: 'Buy milk', 
      description: '',
      status: TaskStatus.completed,
      priority: TaskPriority.high,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      dueAt: DateTime(2025),
      subtasks: [
        Subtask(id: 's1', taskId: '1', title: 'Go to store', isCompleted: true, sortOrder: 0)
      ],
      reminderPlan: ReminderPlan(preset: ReminderPreset.normal, offsets: [], constantReminder: false),
    );
    await mockRepo.create(original);
    
    // Perform duplication
    await controller.duplicateTask('1');
    
    // Verify results
    final tasks = await mockRepo.getAll();
    expect(tasks.length, 2, reason: 'A new task should be created');
    
    final duplicate = tasks.firstWhere((t) => t.id != '1');
    expect(duplicate.title, 'Buy milk', reason: 'Title should match');
    expect(duplicate.dueAt, original.dueAt, reason: 'Due date should match');
    expect(duplicate.priority, TaskPriority.high, reason: 'Priority should match');
    expect(duplicate.isCompleted, false, reason: 'Status defaults to active (incomplete)');
    expect(duplicate.subtasks.length, 1, reason: 'Subtasks should be cloned');
    expect(duplicate.subtasks.first.isCompleted, false, reason: 'Cloned subtasks are reset to incomplete');
    expect(duplicate.subtasks.first.id, isNot('s1'), reason: 'Cloned subtasks have new IDs');
    expect(duplicate.subtasks.first.taskId, duplicate.id, reason: 'Cloned subtasks point to new task ID');
  });
}

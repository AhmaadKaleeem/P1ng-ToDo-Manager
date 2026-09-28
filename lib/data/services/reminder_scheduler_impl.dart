import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/reminder.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/reminders/reminder_calculator.dart';
import 'package:todow/domain/repositories/task_repository.dart';
import 'package:todow/domain/services/notification_service.dart';
import 'package:todow/domain/services/reminder_scheduler.dart';

class ReminderSchedulerImpl implements ReminderScheduler {
  ReminderSchedulerImpl(this._tasks, this._notifications);

  final TaskRepository _tasks;
  final NotificationService _notifications;

  int _notificationIdFor(String reminderId) =>
      reminderId.hashCode.abs() % 2147483647;

  @override
  Future<void> syncTaskReminders(Task task) async {
    await cancelTaskReminders(task.id);

    if (task.isCompleted || task.isArchived || task.dueAt == null) {
      return;
    }

    final schedule = ReminderCalculator.buildSchedule(task);
    final persisted = <ScheduledReminder>[];

    for (final reminder in schedule) {
      final notifId = _notificationIdFor(reminder.id);
      await _notifications.scheduleTaskReminder(
        task: task,
        scheduledAt: reminder.scheduledAt,
        notificationId: notifId,
        isConstant: false,
        label: reminder.label,
      );
      persisted.add(reminder.copyWith(notificationId: notifId));
    }

    if (task.hasConstantReminder) {
      final constantId = _notificationIdFor('constant-${task.id}');
      final firstAt = schedule.isNotEmpty
          ? schedule.first.scheduledAt
          : DateTime.now().add(const Duration(minutes: 1));
      await _notifications.scheduleTaskReminder(
        task: task,
        scheduledAt: firstAt.isAfter(DateTime.now())
            ? firstAt
            : DateTime.now().add(const Duration(minutes: 1)),
        notificationId: constantId,
        isConstant: true,
        label: 'Constant reminder active',
      );
      persisted.add(
        ScheduledReminder(
          id: 'constant-${task.id}',
          taskId: task.id,
          scheduledAt: firstAt,
          status: ReminderStatus.pending,
          kind: ReminderKind.constant,
          notificationId: constantId,
          label: 'Constant reminder',
        ),
      );
    }

    await _tasks.saveReminders(task.id, persisted);
  }

  @override
  Future<void> cancelTaskReminders(String taskId) async {
    final existing = await _tasks.getRemindersForTask(taskId);
    final ids = existing
        .where((r) => r.notificationId != null)
        .map((r) => r.notificationId!)
        .toList();
    await _notifications.cancelAllForTask(taskId, ids);
    await _tasks.saveReminders(taskId, const []);
  }

  @override
  Future<void> snoozeReminder(
    ScheduledReminder reminder,
    Duration duration,
  ) async {
    if (reminder.notificationId != null) {
      await _notifications.cancelNotification(reminder.notificationId!);
    }
    final task = await _tasks.getById(reminder.taskId);
    if (task == null) return;

    final snoozedUntil = DateTime.now().add(duration);
    final notifId = _notificationIdFor('${reminder.id}-snooze');
    await _notifications.scheduleTaskReminder(
      task: task,
      scheduledAt: snoozedUntil,
      notificationId: notifId,
      isConstant: reminder.kind == ReminderKind.constant,
      label: 'Snoozed',
    );
    await _tasks.updateReminder(
      reminder.copyWith(
        status: ReminderStatus.snoozed,
        snoozedUntil: snoozedUntil,
        scheduledAt: snoozedUntil,
        notificationId: notifId,
      ),
    );
  }

  @override
  Future<void> markReminderHandled(String reminderId) async {
    final all = await _tasks.getActiveReminders();
    final match = all.where((r) => r.id == reminderId).firstOrNull;
    if (match == null) return;
    if (match.notificationId != null) {
      await _notifications.cancelNotification(match.notificationId!);
    }
    await _tasks.updateReminder(
      match.copyWith(status: ReminderStatus.handled),
    );
  }

  @override
  Future<void> rescheduleConstantReminder(Task task) async {
    if (!task.hasConstantReminder || task.isCompleted) return;
    final constant = (await _tasks.getRemindersForTask(task.id))
        .where((r) => r.kind == ReminderKind.constant && r.isActive)
        .firstOrNull;
    if (constant?.notificationId == null) return;

    await _notifications.scheduleConstantFollowUp(
      task: task,
      notificationId: constant!.notificationId!,
    );
  }

  @override
  Future<void> recoverPendingReminders() async {
    final activeReminders = await _tasks.getActiveReminders();
    final now = DateTime.now();

    for (final reminder in activeReminders) {
      if (reminder.notificationId == null) continue;
      final task = await _tasks.getById(reminder.taskId);
      if (task == null || task.isCompleted || task.isArchived) continue;

      if (reminder.scheduledAt.isBefore(now)) {
        // Missed reminder, fire immediately
        await _notifications.scheduleTaskReminder(
          task: task,
          scheduledAt: now.add(const Duration(seconds: 5)),
          notificationId: reminder.notificationId!,
          isConstant: reminder.kind == ReminderKind.constant,
          label: reminder.label,
        );
      } else {
        // Future reminder, reschedule safely
        await _notifications.scheduleTaskReminder(
          task: task,
          scheduledAt: reminder.scheduledAt,
          notificationId: reminder.notificationId!,
          isConstant: reminder.kind == ReminderKind.constant,
          label: reminder.label,
        );
      }
    }
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}

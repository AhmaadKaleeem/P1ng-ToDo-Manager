import 'package:todow/domain/models/reminder.dart';
import 'package:todow/domain/models/task.dart';

abstract class ReminderScheduler {
  Future<void> syncTaskReminders(Task task);
  Future<void> cancelTaskReminders(String taskId);
  Future<void> snoozeReminder(ScheduledReminder reminder, Duration duration);
  Future<void> markReminderHandled(String reminderId);
  Future<void> rescheduleConstantReminder(Task task);
}

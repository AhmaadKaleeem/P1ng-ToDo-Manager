import 'package:p1ng_todo_manager/domain/models/enums.dart';
import 'package:p1ng_todo_manager/domain/models/reminder.dart';
import 'package:p1ng_todo_manager/domain/models/task.dart';
import 'package:uuid/uuid.dart';

abstract final class ReminderCalculator {
  static const _uuid = Uuid();

  /// Computes scheduled reminder times from a task due date and reminder plan.
  static List<ScheduledReminder> buildSchedule(Task task, {DateTime? now}) {
    final dueAt = task.dueAt;
    if (dueAt == null || task.isCompleted || task.isArchived) {
      return const [];
    }

    final reference = now ?? DateTime.now();
    final reminders = <ScheduledReminder>[];

    for (final offset in task.reminderPlan.allOffsets) {
      final scheduledAt = applyOffset(dueAt, offset);
      if (!scheduledAt.isAfter(reference)) continue;

      reminders.add(
        ScheduledReminder(
          id: _uuid.v4(),
          taskId: task.id,
          scheduledAt: scheduledAt,
          status: ReminderStatus.pending,
          kind: offset.atDeadline
              ? ReminderKind.atDeadline
              : ReminderKind.relative,
          label: offset.label,
        ),
      );
    }

    reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return reminders;
  }

  static DateTime applyOffset(DateTime dueAt, ReminderOffset offset) {
    if (offset.atDeadline) return dueAt;
    return dueAt.subtract(
      Duration(days: offset.days, hours: offset.hours, minutes: offset.minutes),
    );
  }

  static bool isEscalationWindow(DateTime dueAt, DateTime reminderTime) {
    final diff = dueAt.difference(reminderTime);
    return diff <= const Duration(hours: 3);
  }
}

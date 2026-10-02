import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/reminder.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/models/timetable_entry.dart';
import 'package:uuid/uuid.dart';

abstract final class ReminderCalculator {
  static const _uuid = Uuid();

  /// Computes scheduled reminder times from a task due date and reminder plan.
  static List<ScheduledReminder> buildSchedule(
    Task task, {
    DateTime? now,
    List<TimetableEntry> timetable = const [],
  }) {
    final dueAt = task.dueAt;
    if (dueAt == null || task.isCompleted || task.isArchived) {
      return const [];
    }

    final reference = now ?? DateTime.now();
    final reminders = <ScheduledReminder>[];

    for (final offset in task.reminderPlan.allOffsets) {
      var scheduledAt = applyOffset(dueAt, offset);
      
      if (task.reminderPlan.flexibleReminder && timetable.isNotEmpty) {
        scheduledAt = _deferIfInClass(scheduledAt, timetable);
      }
      
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

  static DateTime _deferIfInClass(DateTime time, List<TimetableEntry> classes) {
    var deferred = time;
    bool changed;
    do {
      changed = false;
      for (final cls in classes) {
        final matchesDay = (cls.repeatWeekly && cls.weekday.index == deferred.weekday - 1) || 
            (!cls.repeatWeekly && cls.scheduledDate?.year == deferred.year && cls.scheduledDate?.month == deferred.month && cls.scheduledDate?.day == deferred.day);

        if (matchesDay) {
          final start = DateTime(deferred.year, deferred.month, deferred.day, cls.startTime.hour, cls.startTime.minute);
          final end = DateTime(deferred.year, deferred.month, deferred.day, cls.endTime.hour, cls.endTime.minute);
          
          if (!deferred.isBefore(start) && deferred.isBefore(end)) {
            deferred = end.add(const Duration(minutes: 5));
            changed = true;
          }
        }
      }
    } while (changed);
    return deferred;
  }
}

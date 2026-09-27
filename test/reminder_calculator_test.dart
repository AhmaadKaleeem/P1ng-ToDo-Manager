import 'package:flutter_test/flutter_test.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/reminder.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/reminders/reminder_calculator.dart';

void main() {
  test('calculates an assignment reminder relative to the due time', () {
    final dueAt = DateTime(2026, 9, 25, 23, 59);
    final task = Task(
      id: 'task-1',
      title: 'OS Assignment',
      description: '',
      status: TaskStatus.active,
      priority: TaskPriority.high,
      createdAt: dueAt.subtract(const Duration(days: 4)),
      updatedAt: dueAt.subtract(const Duration(days: 4)),
      dueAt: dueAt,
      reminderPlan: const ReminderPlan(
        preset: ReminderPreset.assignment,
        offsets: [ReminderOffset(days: 2, hours: 0, minutes: 0)],
        constantReminder: false,
      ),
    );

    final schedule = ReminderCalculator.buildSchedule(
      task,
      now: DateTime(2026, 9, 20),
    );

    expect(schedule, hasLength(1));
    expect(schedule.single.scheduledAt, DateTime(2026, 9, 23, 23, 59));
    expect(schedule.single.kind, ReminderKind.relative);
  });
}

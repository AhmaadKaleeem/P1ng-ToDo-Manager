import 'package:todow/domain/models/enums.dart';

class TimetableEntry {
  const TimetableEntry({
    required this.id,
    required this.courseName,
    required this.instructor,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.scheduleKind = TimetableKind.university,
    this.room,
    this.colorValue,
    this.category,
    this.scheduledDate,
    this.repeatWeekly = true,
    this.taskId,
  });

  final String id;
  final String courseName;
  final String instructor;
  final Weekday weekday;
  final DateTime startTime;
  final DateTime endTime;
  final TimetableKind scheduleKind;
  final String? room;
  final int? colorValue;
  final String? category;
  final DateTime? scheduledDate;
  final bool repeatWeekly;
  final String? taskId;

  Map<String, Object?> toMap() => {
        'id': id,
        'course_name': courseName,
        'instructor': instructor,
        'weekday': weekday.index,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'schedule_kind': scheduleKind.name,
        'room': room,
        'color_value': colorValue,
        'category': category,
        'scheduled_date': scheduledDate?.toIso8601String(),
        'repeat_weekly': repeatWeekly ? 1 : 0,
        'task_id': taskId,
      };

  factory TimetableEntry.fromMap(Map<String, Object?> map) => TimetableEntry(
        id: map['id']! as String,
        courseName: map['course_name']! as String,
        instructor: map['instructor']! as String,
        weekday: Weekday.values[map['weekday']! as int],
        startTime: DateTime.parse(map['start_time']! as String),
        endTime: DateTime.parse(map['end_time']! as String),
        scheduleKind: TimetableKind.values.byName(
            map['schedule_kind'] as String? ?? TimetableKind.university.name),
        room: map['room'] as String?,
        colorValue: map['color_value'] as int?,
        category: map['category'] as String?,
        scheduledDate: map['scheduled_date'] == null
            ? null
            : DateTime.parse(map['scheduled_date']! as String),
        repeatWeekly: (map['repeat_weekly'] as int? ?? 1) == 1,
        taskId: map['task_id'] as String?,
      );
}

import 'package:p1ng_todo_manager/domain/models/enums.dart';

class TimetableEntry {
  const TimetableEntry({
    required this.id,
    required this.courseName,
    required this.instructor,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.room,
    this.colorValue,
    this.category,
  });

  final String id;
  final String courseName;
  final String instructor;
  final Weekday weekday;
  final DateTime startTime;
  final DateTime endTime;
  final String? room;
  final int? colorValue;
  final String? category;

  Map<String, Object?> toMap() => {
        'id': id,
        'course_name': courseName,
        'instructor': instructor,
        'weekday': weekday.index,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'room': room,
        'color_value': colorValue,
        'category': category,
      };

  factory TimetableEntry.fromMap(Map<String, Object?> map) => TimetableEntry(
        id: map['id']! as String,
        courseName: map['course_name']! as String,
        instructor: map['instructor']! as String,
        weekday: Weekday.values[map['weekday']! as int],
        startTime: DateTime.parse(map['start_time']! as String),
        endTime: DateTime.parse(map['end_time']! as String),
        room: map['room'] as String?,
        colorValue: map['color_value'] as int?,
        category: map['category'] as String?,
      );
}

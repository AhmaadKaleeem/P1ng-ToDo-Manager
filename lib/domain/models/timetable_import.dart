import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/timetable_entry.dart';

class TimetableDraftEntry {
  const TimetableDraftEntry({
    this.courseName = '',
    this.instructor = '',
    this.room = '',
    this.weekday,
    this.startTime,
    this.endTime,
  });

  final String courseName;
  final String instructor;
  final String room;
  final Weekday? weekday;
  final DateTime? startTime;
  final DateTime? endTime;

  String? get validationError {
    if (courseName.trim().isEmpty) return 'Add a course name.';
    if (weekday == null) return 'Choose a day.';
    if (startTime == null || endTime == null) return 'Add both class times.';
    if (!endTime!.isAfter(startTime!)) {
      return 'End time must follow start time.';
    }
    return null;
  }

  TimetableEntry toEntry(TimetableKind kind, String id) => TimetableEntry(
        id: id,
        courseName: courseName.trim(),
        instructor: instructor.trim(),
        room: room.trim().isEmpty ? null : room.trim(),
        weekday: weekday!,
        startTime: startTime!,
        endTime: endTime!,
        scheduleKind: kind,
      );
}

class TimetableImportDraft {
  const TimetableImportDraft({
    required this.rows,
    this.errors = const [],
  });

  final List<TimetableDraftEntry> rows;
  final List<String> errors;
}

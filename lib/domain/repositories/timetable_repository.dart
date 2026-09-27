import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/timetable_entry.dart';

abstract class TimetableRepository {
  Future<List<TimetableEntry>> getAll();
  Future<List<TimetableEntry>> forWeekday(Weekday weekday);
  Future<TimetableEntry> create(TimetableEntry entry);
  Future<TimetableEntry> update(TimetableEntry entry);
  Future<void> delete(String id);
}

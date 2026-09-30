import 'package:todow/data/local/app_database.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/timetable_entry.dart';
import 'package:todow/domain/repositories/timetable_repository.dart';

class TimetableRepositoryImpl implements TimetableRepository {
  TimetableRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<TimetableEntry> create(TimetableEntry entry) async {
    await _database.db.insert('timetable_entries', entry.toMap());
    return entry;
  }

  @override
  Future<void> createMany(List<TimetableEntry> entries) async {
    await _database.db.transaction((transaction) async {
      for (final entry in entries) {
        await transaction.insert('timetable_entries', entry.toMap());
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    await _database.db.delete(
      'timetable_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<TimetableEntry>> forWeekday(
    Weekday weekday, {
    TimetableKind scheduleKind = TimetableKind.university,
  }) async {
    final rows = await _database.db.query(
      'timetable_entries',
      where: 'weekday = ? AND schedule_kind = ?',
      whereArgs: [weekday.index, scheduleKind.name],
      orderBy: 'start_time ASC',
    );
    return rows.map(TimetableEntry.fromMap).toList();
  }

  @override
  Future<List<TimetableEntry>> getAll() async {
    final rows = await _database.db.query(
      'timetable_entries',
      orderBy: 'weekday ASC, start_time ASC',
    );
    return rows.map(TimetableEntry.fromMap).toList();
  }

  @override
  Future<TimetableEntry> update(TimetableEntry entry) async {
    await _database.db.update(
      'timetable_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    return entry;
  }
}

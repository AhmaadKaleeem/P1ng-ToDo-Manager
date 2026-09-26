import 'package:p1ng_todo_manager/data/local/app_database.dart';
import 'package:p1ng_todo_manager/domain/models/enums.dart';
import 'package:p1ng_todo_manager/domain/models/timetable_entry.dart';
import 'package:p1ng_todo_manager/domain/repositories/timetable_repository.dart';

class TimetableRepositoryImpl implements TimetableRepository {
  TimetableRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<TimetableEntry> create(TimetableEntry entry) async {
    await _database.db.insert('timetable_entries', entry.toMap());
    return entry;
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
  Future<List<TimetableEntry>> forWeekday(Weekday weekday) async {
    final rows = await _database.db.query(
      'timetable_entries',
      where: 'weekday = ?',
      whereArgs: [weekday.index],
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

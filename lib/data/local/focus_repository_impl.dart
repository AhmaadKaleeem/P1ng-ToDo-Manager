import 'package:todow/data/local/app_database.dart';
import 'package:todow/domain/models/focus_session.dart';
import 'package:todow/domain/repositories/focus_repository.dart';
import 'package:sqflite/sqflite.dart';

class FocusRepositoryImpl implements FocusRepository {
  FocusRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<FocusSession?> getActiveSession() async {
    final rows = await _database.db.query(
      'focus_sessions',
      where: "status IN ('running', 'paused')",
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return FocusSession.fromMap(rows.first);
  }

  @override
  Future<List<FocusSession>> getHistory({int limit = 20}) async {
    final rows = await _database.db.query(
      'focus_sessions',
      where: "status = 'ended'",
      orderBy: 'ended_at DESC',
      limit: limit,
    );
    return rows.map(FocusSession.fromMap).toList();
  }

  @override
  Future<FocusSession> saveSession(FocusSession session) async {
    await _database.db.insert(
      'focus_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return session;
  }
}

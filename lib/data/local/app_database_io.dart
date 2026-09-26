import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_schema.dart';

class AppDatabase {
  AppDatabase._();
  static AppDatabase? _instance;
  static Database? _db;

  static Future<AppDatabase> open([String? pathOverride]) async {
    if (_instance != null) return _instance!;
    _instance = AppDatabase._();
    final dbPath =
        pathOverride ?? join(await getDatabasesPath(), 'p1ng_todo_manager.db');
    _db =
        await openDatabase(dbPath, version: 1, onCreate: createDatabaseSchema);
    return _instance!;
  }

  Database get db {
    final database = _db;
    if (database == null) throw StateError('Database not opened.');
    return database;
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
    _instance = null;
  }
}

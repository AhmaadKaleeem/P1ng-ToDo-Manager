import 'package:sqflite_common/sqlite_api.dart';
import 'package:todow/domain/models/attachment.dart';
import 'package:todow/domain/repositories/attachment_repository.dart';

class AttachmentRepositoryImpl implements AttachmentRepository {
  const AttachmentRepositoryImpl(this._db);
  final Database _db;

  static const _table = 'attachments';

  @override
  Future<Attachment> create(Attachment a) async {
    await _db.insert(_table, a.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return a;
  }

  @override
  Future<List<Attachment>> getByTask(String taskId) async {
    final rows = await _db.query(_table,
        where: 'task_id = ?',
        whereArgs: [taskId],
        orderBy: 'created_at ASC');
    return rows.map(Attachment.fromMap).toList();
  }

  @override
  Future<Attachment?> getById(String id) async {
    final rows =
        await _db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Attachment.fromMap(rows.first);
  }

  @override
  Future<void> delete(String id) =>
      _db.delete(_table, where: 'id = ?', whereArgs: [id]);

  @override
  Future<void> deleteByTask(String taskId) =>
      _db.delete(_table, where: 'task_id = ?', whereArgs: [taskId]);

  @override
  Future<int> countByTask(String taskId) async {
    final result = await _db.rawQuery(
        'SELECT COUNT(*) as c FROM $_table WHERE task_id = ?', [taskId]);
    return result.first['c'] as int;
  }

  @override
  Future<Map<String, int>> countsByTaskIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await _db.rawQuery(
        'SELECT task_id, COUNT(*) as c FROM $_table '
        'WHERE task_id IN ($placeholders) GROUP BY task_id',
        ids);
    return {for (final r in rows) r['task_id'] as String: r['c'] as int};
  }
}

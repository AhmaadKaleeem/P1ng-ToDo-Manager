import 'package:todow/data/local/app_database.dart';
import 'package:todow/domain/models/attachment.dart';
import 'package:todow/domain/models/roadmap.dart';
import 'package:todow/domain/models/subtask.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/repositories/roadmap_repository.dart';

class RoadmapRepositoryImpl implements RoadmapRepository {
  RoadmapRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<Roadmap>> getAll() async {
    final rows = await _db.db
        .query('roadmaps', orderBy: 'order_index ASC, created_at ASC');
    return rows.map(Roadmap.fromMap).toList();
  }

  @override
  Future<Roadmap?> getById(String id) async {
    final rows = await _db.db
        .query('roadmaps', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Roadmap.fromMap(rows.first);
  }

  @override
  Future<Roadmap> create(Roadmap roadmap) async {
    await _db.db.insert('roadmaps', roadmap.toMap());
    return roadmap;
  }

  @override
  Future<Roadmap> update(Roadmap roadmap) async {
    await _db.db.update('roadmaps', roadmap.toMap(),
        where: 'id = ?', whereArgs: [roadmap.id]);
    return roadmap;
  }

  @override
  Future<void> reorder(List<Roadmap> roadmaps) async {
    await _db.db.transaction((txn) async {
      for (var i = 0; i < roadmaps.length; i++) {
        await txn.update(
          'roadmaps',
          {'order_index': i},
          where: 'id = ?',
          whereArgs: [roadmaps[i].id],
        );
      }
    });
  }

  @override
  Future<void> delete(String id, {bool deleteTasks = false}) async {
    await _db.db.transaction((txn) async {
      final topics = await txn.query(
        'topics',
        columns: ['id'],
        where: 'roadmap_id = ?',
        whereArgs: [id],
      );
      for (final topic in topics) {
        if (deleteTasks) {
          await txn.delete(
            'tasks',
            where: 'topic_id = ?',
            whereArgs: [topic['id']],
          );
        } else {
          await txn.update(
            'tasks',
            {'topic_id': null},
            where: 'topic_id = ?',
            whereArgs: [topic['id']],
          );
        }
      }
      await txn.delete('topics', where: 'roadmap_id = ?', whereArgs: [id]);
      await txn.delete('roadmaps', where: 'id = ?', whereArgs: [id]);
    });
  }
}

class TopicRepositoryImpl implements TopicRepository {
  TopicRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<Topic>> getByRoadmapId(String roadmapId) async {
    final rows = await _db.db.query('topics',
        where: 'roadmap_id = ?',
        whereArgs: [roadmapId],
        orderBy: 'order_index ASC');
    return rows.map(Topic.fromMap).toList();
  }

  @override
  Future<Topic?> getById(String id) async {
    final rows = await _db.db
        .query('topics', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Topic.fromMap(rows.first);
  }

  @override
  Future<Topic> create(Topic topic) async {
    await _db.db.insert('topics', topic.toMap());
    return topic;
  }

  @override
  Future<Topic> update(Topic topic) async {
    await _db.db.update('topics', topic.toMap(),
        where: 'id = ?', whereArgs: [topic.id]);
    return topic;
  }

  @override
  Future<void> delete(String id) async {
    await _db.db.transaction((txn) async {
      await txn.update(
        'tasks',
        {'topic_id': null},
        where: 'topic_id = ?',
        whereArgs: [id],
      );
      await txn.delete('topics', where: 'id = ?', whereArgs: [id]);
    });
  }
}

class RoadmapTaskRepositoryImpl implements RoadmapTaskRepository {
  RoadmapTaskRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<Task>> getByTopicId(String topicId) async {
    final rows = await _db.db.query('tasks',
        where: 'topic_id = ?',
        whereArgs: [topicId],
        orderBy: 'due_at IS NULL, due_at ASC');
    return _hydrateBatch(rows);
  }

  @override
  Future<List<Task>> getByRoadmapId(String roadmapId,
      {DateTime? from, DateTime? to}) async {
    // Get all topic IDs for this roadmap.
    final topicRows = await _db.db.query('topics',
        columns: ['id'], where: 'roadmap_id = ?', whereArgs: [roadmapId]);
    if (topicRows.isEmpty) return [];
    final ids = topicRows.map((r) => "'${r['id']}'").join(',');

    final where = StringBuffer('topic_id IN ($ids)');
    final args = <Object?>[];
    if (from != null) {
      where.write(' AND due_at >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.write(' AND due_at <= ?');
      args.add(to.toIso8601String());
    }

    final rows = await _db.db.query(
      'tasks',
      where: where.toString(),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'due_at IS NULL, due_at ASC',
    );
    return _hydrateBatch(rows);
  }

  Future<List<Task>> _hydrateBatch(List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return const [];
    
    final taskIds = rows.map((r) => r['id']! as String).toList();
    final subtasksByTask = <String, List<Subtask>>{};
    final attachmentsByTask = <String, List<Attachment>>{};
    
    for (var i = 0; i < taskIds.length; i += 500) {
      final chunk = taskIds.skip(i).take(500).toList();
      final placeholders = List.filled(chunk.length, '?').join(',');
      
      final subRows = await _db.db.query(
        'subtasks',
        where: 'task_id IN ($placeholders)',
        whereArgs: chunk,
        orderBy: 'task_id ASC, sort_order ASC',
      );
      for (final r in subRows) {
        final sub = Subtask.fromMap(r);
        subtasksByTask.putIfAbsent(sub.taskId, () => []).add(sub);
      }
      
      final attRows = await _db.db.query(
        'attachments',
        where: 'task_id IN ($placeholders)',
        whereArgs: chunk,
      );
      for (final r in attRows) {
        final att = Attachment.fromMap(r);
        attachmentsByTask.putIfAbsent(att.taskId, () => []).add(att);
      }
    }

    return rows.map((row) {
      final id = row['id']! as String;
      return Task.fromMap(
        row,
        subtasks: subtasksByTask[id] ?? [],
        attachments: attachmentsByTask[id] ?? [],
      );
    }).toList();
  }
}

class RoadmapImportRepositoryImpl implements RoadmapImportRepository {
  RoadmapImportRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<void> importAll({
    required Roadmap roadmap,
    required List<Topic> topics,
    required List<Task> tasks,
  }) =>
      _db.db.transaction((txn) async {
        await txn.insert('roadmaps', roadmap.toMap());
        for (final topic in topics) {
          await txn.insert('topics', topic.toMap());
        }
        for (final task in tasks) {
          await txn.insert('tasks', task.toMap());
        }
      });
}

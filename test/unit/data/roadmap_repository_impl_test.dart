import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todow/data/local/app_database.dart';
import 'package:todow/data/local/roadmap_repository_impl.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/roadmap.dart';
import 'package:todow/domain/models/task.dart';

void main() {
  late AppDatabase database;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await AppDatabase.open(inMemoryDatabasePath);
  });

  tearDown(() => AppDatabase.close());

  test('deleting a roadmap removes its topics and keeps tasks detached',
      () async {
    final now = DateTime(2026, 9, 29);
    await database.db.insert(
      'roadmaps',
      Roadmap(
        id: 'roadmap-1',
        title: 'Learn Flutter',
        colorIndex: 0,
        createdAt: now,
        updatedAt: now,
      ).toMap(),
    );
    await database.db.insert(
      'topics',
      Topic(
        id: 'topic-1',
        roadmapId: 'roadmap-1',
        title: 'Widgets',
        orderIndex: 0,
        status: TopicStatus.active,
        createdAt: now,
        updatedAt: now,
      ).toMap(),
    );
    await database.db.insert(
      'tasks',
      Task(
        id: 'task-1',
        title: 'Read docs',
        description: '',
        status: TaskStatus.active,
        priority: TaskPriority.medium,
        createdAt: now,
        updatedAt: now,
        topicId: 'topic-1',
      ).toMap(),
    );

    await RoadmapRepositoryImpl(database).delete('roadmap-1');

    expect(await database.db.query('roadmaps'), isEmpty);
    expect(await database.db.query('topics'), isEmpty);
    final tasks = await database.db.query('tasks');
    expect(tasks, hasLength(1));
    expect(tasks.single['topic_id'], isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todow/data/local/app_database.dart';
import 'package:todow/data/local/attachment_repository_impl.dart';
import 'package:todow/domain/models/attachment.dart';

void main() {
  late Database db;
  late AttachmentRepositoryImpl repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            version: 3,
            onCreate: (db, version) async {
              await db.execute('''CREATE TABLE tasks (
                id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT NOT NULL,
                status TEXT NOT NULL, priority TEXT NOT NULL, created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL, start_at TEXT, due_at TEXT, category TEXT,
                tags TEXT NOT NULL, reminder_plan TEXT NOT NULL, source_type TEXT NOT NULL,
                source_id TEXT, sort_order INTEGER NOT NULL DEFAULT 0)''');
              await db.execute('''CREATE TABLE attachments (
                id TEXT PRIMARY KEY,
                task_id TEXT NOT NULL,
                filename TEXT NOT NULL,
                mime_type TEXT NOT NULL,
                size_bytes INTEGER NOT NULL,
                content_hash TEXT NOT NULL,
                sync_state TEXT NOT NULL DEFAULT 'localOnly',
                remote_id TEXT,
                remote_upload_id TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE)''');
            }));
    repo = AttachmentRepositoryImpl(db);
    // insert a dummy task to satisfy foreign key
    await db.insert('tasks', {
      'id': 'task-1',
      'title': 'Test',
      'description': '',
      'status': 'active',
      'priority': 'medium',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'tags': '[]',
      'reminder_plan': '{}',
      'source_type': 'local',
      'sort_order': 0,
    });
    await db.insert('tasks', {
      'id': 'task-2',
      'title': 'Test 2',
      'description': '',
      'status': 'active',
      'priority': 'medium',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'tags': '[]',
      'reminder_plan': '{}',
      'source_type': 'local',
      'sort_order': 0,
    });
  });

  tearDown(() async {
    await db.close();
  });

  Attachment dummyAttachment({String id = 'att-1', String taskId = 'task-1'}) {
    return Attachment(
      id: id,
      taskId: taskId,
      filename: 'file.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 1024,
      contentHash: 'e3b0c44298fc1c149afbf4c8996fb924'
          '27ae41e4649b934ca495991b7852b855',
      syncState: AttachmentSyncState.localOnly,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );
  }

  test('create -> getById returns deep-equal', () async {
    final att = dummyAttachment();
    await repo.create(att);
    final fetched = await repo.getById('att-1');
    expect(fetched, isNotNull);
    expect(fetched!.toMap(), att.toMap());
  });

  test('getByTask returns in insertion order', () async {
    final att1 = dummyAttachment(id: 'att-1').copyWith(createdAt: DateTime(2025, 1, 1));
    final att2 = dummyAttachment(id: 'att-2').copyWith(createdAt: DateTime(2025, 1, 2));
    await repo.create(att2);
    await repo.create(att1);
    final list = await repo.getByTask('task-1');
    expect(list.length, 2);
    expect(list[0].id, 'att-1');
    expect(list[1].id, 'att-2');
  });

  test('delete removes row', () async {
    await repo.create(dummyAttachment());
    await repo.delete('att-1');
    final fetched = await repo.getById('att-1');
    expect(fetched, isNull);
  });

  test('deleteByTask removes only that task\'s rows', () async {
    await repo.create(dummyAttachment(id: 'att-1', taskId: 'task-1'));
    await repo.create(dummyAttachment(id: 'att-2', taskId: 'task-2'));
    await repo.deleteByTask('task-1');
    expect(await repo.getById('att-1'), isNull);
    expect(await repo.getById('att-2'), isNotNull);
  });

  test('countsByTaskIds returns correct map', () async {
    await repo.create(dummyAttachment(id: 'att-1', taskId: 'task-1'));
    await repo.create(dummyAttachment(id: 'att-2', taskId: 'task-1'));
    await repo.create(dummyAttachment(id: 'att-3', taskId: 'task-2'));
    final counts = await repo.countsByTaskIds(['task-1', 'task-2']);
    expect(counts['task-1'], 2);
    expect(counts['task-2'], 1);
  });

  test('restart test: write 2 attachments for 2 tasks, close DB, reopen, both present with correct taskIds', () async {
    final fileDbPath = 'todow_test.db';
    final fileDb = await databaseFactory.openDatabase(fileDbPath,
        options: OpenDatabaseOptions(
            version: 3,
            onCreate: (db, version) async {
              await db.execute('''CREATE TABLE tasks (
                id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT NOT NULL,
                status TEXT NOT NULL, priority TEXT NOT NULL, created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL, start_at TEXT, due_at TEXT, category TEXT,
                tags TEXT NOT NULL, reminder_plan TEXT NOT NULL, source_type TEXT NOT NULL,
                source_id TEXT, sort_order INTEGER NOT NULL DEFAULT 0)''');
              await db.execute('''CREATE TABLE attachments (
                id TEXT PRIMARY KEY,
                task_id TEXT NOT NULL,
                filename TEXT NOT NULL,
                mime_type TEXT NOT NULL,
                size_bytes INTEGER NOT NULL,
                content_hash TEXT NOT NULL,
                sync_state TEXT NOT NULL DEFAULT 'localOnly',
                remote_id TEXT,
                remote_upload_id TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE)''');
            }));
    final fileRepo = AttachmentRepositoryImpl(fileDb);
    await fileDb.insert('tasks', {
      'id': 'task-a',
      'title': 'Test',
      'description': '',
      'status': 'active',
      'priority': 'medium',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'tags': '[]',
      'reminder_plan': '{}',
      'source_type': 'local',
      'sort_order': 0,
    });
    await fileDb.insert('tasks', {
      'id': 'task-b',
      'title': 'Test 2',
      'description': '',
      'status': 'active',
      'priority': 'medium',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'tags': '[]',
      'reminder_plan': '{}',
      'source_type': 'local',
      'sort_order': 0,
    });
    await fileRepo.create(dummyAttachment(id: 'att-a', taskId: 'task-a'));
    await fileRepo.create(dummyAttachment(id: 'att-b', taskId: 'task-b'));
    await fileDb.close();

    final fileDbReopened = await databaseFactory.openDatabase(fileDbPath);
    final fileRepoReopened = AttachmentRepositoryImpl(fileDbReopened);
    final attA = await fileRepoReopened.getById('att-a');
    final attB = await fileRepoReopened.getById('att-b');
    expect(attA, isNotNull);
    expect(attA!.taskId, 'task-a');
    expect(attB, isNotNull);
    expect(attB!.taskId, 'task-b');
    await fileDbReopened.close();
    await databaseFactory.deleteDatabase(fileDbPath);
  });
}

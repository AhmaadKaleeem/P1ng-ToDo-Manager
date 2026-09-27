import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todow/data/local/app_database.dart';
import 'package:todow/data/local/attachment_repository_impl.dart';
import 'package:todow/domain/models/attachment.dart';
import 'package:todow/bootstrap.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late AttachmentRepositoryImpl repo;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = await Directory.systemTemp.createTemp('migration_test');
    db = await AppDatabase.open(inMemoryDatabasePath);
    repo = AttachmentRepositoryImpl(db.db);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Given a DB with attachments using the old path pattern, running the migration moves the disk files to the new pattern', () async {
    final now = DateTime.now();
    final att = Attachment(
      id: 'att-1',
      taskId: 'task-1',
      filename: 'image.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 100,
      contentHash: 'a' * 64,
      syncState: AttachmentSyncState.localOnly,
      createdAt: now,
      updatedAt: now,
    );
    await repo.create(att);

    final taskDir = Directory(p.join(tempDir.path, 'task-1'))..createSync(recursive: true);
    final oldFile = File(p.join(taskDir.path, 'att-1_image.jpg'))..writeAsStringSync('data');
    
    await migrateAttachmentPaths(repo, tempDir.path);
    
    expect(oldFile.existsSync(), isFalse);
    final newFile = File(p.join(taskDir.path, 'att-1.jpg'));
    expect(newFile.existsSync(), isTrue);
  });

  test('Running the migration twice has no effect', () async {
    final now = DateTime.now();
    final att = Attachment(
      id: 'att-2',
      taskId: 'task-2',
      filename: 'doc.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 100,
      contentHash: 'a' * 64,
      syncState: AttachmentSyncState.localOnly,
      createdAt: now,
      updatedAt: now,
    );
    await repo.create(att);

    final taskDir = Directory(p.join(tempDir.path, 'task-2'))..createSync(recursive: true);
    final oldFile = File(p.join(taskDir.path, 'att-2_doc.pdf'))..writeAsStringSync('data');
    
    await migrateAttachmentPaths(repo, tempDir.path);
    await migrateAttachmentPaths(repo, tempDir.path); // Second run
    
    expect(oldFile.existsSync(), isFalse);
    final newFile = File(p.join(taskDir.path, 'att-2.pdf'));
    expect(newFile.existsSync(), isTrue);
  });

  test('A missing old file is logged, not crashed on', () async {
    final now = DateTime.now();
    final att = Attachment(
      id: 'att-3',
      taskId: 'task-3',
      filename: 'missing.txt',
      mimeType: 'text/plain',
      sizeBytes: 100,
      contentHash: 'a' * 64,
      syncState: AttachmentSyncState.localOnly,
      createdAt: now,
      updatedAt: now,
    );
    await repo.create(att);

    // Don't create the file on disk
    expect(() => migrateAttachmentPaths(repo, tempDir.path), returnsNormally);
  });
}

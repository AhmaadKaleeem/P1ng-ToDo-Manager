import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:todow/data/services/file_storage_impl.dart';
import 'package:todow/domain/services/file_storage.dart';

void main() {
  late Directory tempDir;
  late FileStorageImpl storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('storage_test');
    storage = FileStorageImpl(tempDir.path);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('save writes to {taskId}/{id}.{ext}, not {taskId}/{id}_{filename}', () async {
    final sourceFile = File(p.join(tempDir.path, 'source.txt'))..writeAsStringSync('hello');
    
    final savedPath = await storage.save('task-1', 'att-1', sourceFile.path, '.pdf');
    
    final expectedPath = p.join(tempDir.path, 'task-1', 'att-1.pdf');
    expect(savedPath, expectedPath);
    expect(File(expectedPath).existsSync(), isTrue);
  });

  test('absolutePath globs the folder and returns the actual file', () async {
    final destDir = Directory(p.join(tempDir.path, 'task-2'))..createSync(recursive: true);
    final actualFile = File(p.join(destDir.path, 'att-2.jpg'))..writeAsStringSync('img');
    
    final path = await storage.absolutePath('task-2', 'att-2');
    expect(path, actualFile.path);
  });

  test('absolutePath throws AttachmentFileMissingException if no match', () async {
    Directory(p.join(tempDir.path, 'task-3')).createSync(recursive: true);
    
    await expectLater(
      () => storage.absolutePath('task-3', 'att-missing'),
      throwsA(isA<AttachmentFileMissingException>()),
    );
  });
}

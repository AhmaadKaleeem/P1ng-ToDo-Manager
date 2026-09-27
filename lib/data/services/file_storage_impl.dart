import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:todow/domain/services/file_storage.dart';

class FileStorageImpl implements FileStorage {
  Future<String> _root() async {
    final base = await getApplicationDocumentsDirectory();
    return p.join(base.path, 'attachments');
  }

  @override
  Future<String> absolutePath(
      String taskId, String attachmentId, String filename) async {
    final root = await _root();
    return p.join(root, taskId, '${attachmentId}_$filename');
  }

  @override
  Future<String> save(String taskId, String attachmentId, String sourcePath,
      String filename) async {
    final dest = await absolutePath(taskId, attachmentId, filename);
    await Directory(p.dirname(dest)).create(recursive: true);
    await File(sourcePath).copy(dest);
    return dest;
  }

  @override
  Future<void> delete(
      String taskId, String attachmentId, String filename) async {
    final path = await absolutePath(taskId, attachmentId, filename);
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  @override
  Future<void> deleteTaskFolder(String taskId) async {
    final root = await _root();
    final dir = Directory(p.join(root, taskId));
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

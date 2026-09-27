import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:todow/domain/services/file_storage.dart';

class FileStorageImpl implements FileStorage {
  final String _rootPath;
  FileStorageImpl(this._rootPath);

  String get _root => _rootPath;

  @override
  Future<String> absolutePath(String taskId, String attachmentId) async {
    final dir = Directory(p.join(_root, taskId));
    if (!dir.existsSync()) throw AttachmentFileMissingException();
    try {
      final match = dir.listSync().firstWhere(
        (f) => f.path.split(Platform.pathSeparator).last.startsWith('$attachmentId.'),
      );
      return match.path;
    } catch (_) {
      throw AttachmentFileMissingException();
    }
  }

  @override
  String thumbnailPath(String taskId, String attachmentId) {
    return p.join(_root, taskId, '${attachmentId}_thumb.jpg');
  }

  @override
  Future<String> save(String taskId, String attachmentId, String sourcePath,
      String extension) async {
    final dest = p.join(_root, taskId, '$attachmentId$extension');
    await Directory(p.dirname(dest)).create(recursive: true);
    await File(sourcePath).copy(dest);
    return dest;
  }

  @override
  Future<void> delete(String taskId, String attachmentId) async {
    try {
      final path = await absolutePath(taskId, attachmentId);
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Ignored if missing
    }
    
    // Also try to delete thumbnail
    final thumbPath = thumbnailPath(taskId, attachmentId);
    final tf = File(thumbPath);
    if (await tf.exists()) await tf.delete();
  }

  @override
  Future<void> deleteTaskFolder(String taskId) async {
    final dir = Directory(p.join(_root, taskId));
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

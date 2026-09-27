import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:todow/domain/repositories/task_repository.dart';

Future<void> cleanupOrphanedAttachments(TaskRepository taskRepo) async {
  try {
    final base = await getApplicationDocumentsDirectory();
    final attDir = Directory(p.join(base.path, 'attachments'));
    if (!await attDir.exists()) return;

    final folders = attDir.listSync().whereType<Directory>();
    var count = 0;

    for (final folder in folders) {
      final taskId = p.basename(folder.path);
      final task = await taskRepo.getById(taskId);
      if (task == null) {
        await folder.delete(recursive: true);
        count++;
      }
    }
    
    if (count > 0) {
      debugPrint('Orphan cleanup: removed $count folder(s).');
    }
  } catch (e) {
    debugPrint('Orphan cleanup failed: $e');
  }
}

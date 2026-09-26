import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:p1ng_todo_manager/data/local/task_repository_impl.dart';
import 'package:p1ng_todo_manager/domain/models/attachment.dart';
import 'package:p1ng_todo_manager/domain/services/attachment_service.dart';
import 'package:uuid/uuid.dart';

class AttachmentServiceImpl implements AttachmentService {
  AttachmentServiceImpl(this._taskRepo);
  final TaskRepositoryImpl _taskRepo;
  static const _uuid = Uuid();

  Future<Directory> _attachmentsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'attachments'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  AttachmentType _typeFor(String fileName, String mime) {
    final lower = fileName.toLowerCase();
    if (mime.startsWith('image/') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp')) {
      return AttachmentType.image;
    }
    if (lower.endsWith('.pdf') || mime == 'application/pdf') {
      return AttachmentType.pdf;
    }
    return AttachmentType.file;
  }

  @override
  Future<Attachment> attachFile(
      String taskId, String sourcePath, String fileName) async {
    final source = File(sourcePath);
    if (!await source.exists()) throw AttachmentException('File not found.');
    final dir = await _attachmentsDir();
    final id = _uuid.v4();
    final ext = p.extension(fileName);
    final destPath = p.join(dir.path, '$id$ext');
    await source.copy(destPath);
    final mime = _guessMime(ext);
    final attachment = Attachment(
      id: id,
      taskId: taskId,
      fileName: fileName,
      localPath: destPath,
      mimeType: mime,
      type: _typeFor(fileName, mime),
      createdAt: DateTime.now(),
    );
    await _taskRepo.addAttachment(attachment);
    return attachment;
  }

  String _guessMime(String ext) {
    switch (ext.toLowerCase()) {
      case '.pdf':
        return 'application/pdf';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Future<void> deleteAttachment(Attachment attachment) async {
    final file = File(attachment.localPath);
    if (await file.exists()) await file.delete();
    await _taskRepo.removeAttachment(attachment.id);
  }

  @override
  Future<bool> fileExists(Attachment attachment) =>
      File(attachment.localPath).exists();
}

class AttachmentException implements Exception {
  AttachmentException(this.message);
  final String message;
  @override
  String toString() => message;
}

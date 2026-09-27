import 'package:todow/data/local/task_repository_impl.dart';
import 'package:todow/domain/models/attachment.dart';
import 'package:todow/domain/services/attachment_service.dart';

class AttachmentServiceImpl implements AttachmentService {
  AttachmentServiceImpl(this._taskRepo);
  final TaskRepositoryImpl _taskRepo;

  @override
  Future<Attachment> attachFile(
      String taskId, String sourcePath, String fileName) {
    throw AttachmentException(
      'Browser attachments are not available in this build. Use the Android app.',
    );
  }

  @override
  Future<void> deleteAttachment(Attachment attachment) =>
      _taskRepo.removeAttachment(attachment.id);

  @override
  Future<bool> fileExists(Attachment attachment) async => false;
}

class AttachmentException implements Exception {
  AttachmentException(this.message);
  final String message;
  @override
  String toString() => message;
}

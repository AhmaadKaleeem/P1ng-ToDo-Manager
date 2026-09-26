import 'package:p1ng_todo_manager/domain/models/attachment.dart';

abstract class AttachmentService {
  Future<Attachment> attachFile(
      String taskId, String sourcePath, String fileName);
  Future<void> deleteAttachment(Attachment attachment);
  Future<bool> fileExists(Attachment attachment);
}

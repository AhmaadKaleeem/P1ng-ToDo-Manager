abstract class FileStorage {
  Future<String> save(
      String taskId, String attachmentId, String sourcePath, String extension);
  Future<void> delete(String taskId, String attachmentId);
  Future<void> deleteTaskFolder(String taskId);
  Future<String> absolutePath(String taskId, String attachmentId);
  String thumbnailPath(String taskId, String attachmentId);
}

class AttachmentFileMissingException implements Exception {
  @override
  String toString() => 'Attachment file missing on disk';
}

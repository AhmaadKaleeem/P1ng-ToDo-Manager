abstract class FileStorage {
  Future<String> save(
      String taskId, String attachmentId, String sourcePath, String filename);
  Future<void> delete(String taskId, String attachmentId, String filename);
  Future<void> deleteTaskFolder(String taskId);
  Future<String> absolutePath(
      String taskId, String attachmentId, String filename);
}

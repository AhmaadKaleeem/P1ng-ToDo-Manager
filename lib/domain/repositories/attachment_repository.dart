import 'package:todow/domain/models/attachment.dart';

abstract class AttachmentRepository {
  Future<Attachment> create(Attachment a);
  Future<List<Attachment>> getByTask(String taskId);
  Future<Attachment?> getById(String id);
  Future<void> delete(String id);
  Future<void> deleteByTask(String taskId);
  Future<int> countByTask(String taskId);
  Future<Map<String, int>> countsByTaskIds(List<String> ids);
  Future<void> updateFilename(String id, String newFilename);
  Future<List<Attachment>> getAll();
}

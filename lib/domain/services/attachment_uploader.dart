/// Sync seam. Ships as no-op in FR-02; real impl wired in the sync iteration.
abstract class AttachmentUploader {
  Future<void> enqueue(String attachmentId);
  Future<void> cancel(String attachmentId);
  Stream<double> watch(String attachmentId);
}

class NoOpUploader implements AttachmentUploader {
  const NoOpUploader();
  @override
  Future<void> enqueue(String attachmentId) async {}
  @override
  Future<void> cancel(String attachmentId) async {}
  @override
  Stream<double> watch(String attachmentId) => const Stream.empty();
}

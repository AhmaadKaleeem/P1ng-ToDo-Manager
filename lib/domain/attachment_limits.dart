/// File size cap: 50 MB.
const int kMaxAttachmentBytes = 50 * 1024 * 1024;

/// Allowed extensions (lower-case).
const Set<String> kAllowedExtensions = {
  '.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.bmp',
  '.pdf',
  '.doc', '.docx',
  '.xls', '.xlsx',
  '.ppt', '.pptx',
  '.txt', '.md',
};

/// Validates [filename] and [sizeBytes] before a file is copied.
/// Throws [FileTooLargeException] or [UnsupportedFileTypeException].
void validateAttachment(String filename, int sizeBytes) {
  if (sizeBytes > kMaxAttachmentBytes) throw FileTooLargeException(sizeBytes);
  final ext = _ext(filename);
  if (!kAllowedExtensions.contains(ext)) throw UnsupportedFileTypeException(ext);
}

String _ext(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot == -1) return '';
  return filename.substring(dot).toLowerCase();
}

class FileTooLargeException implements Exception {
  const FileTooLargeException(this.sizeBytes);
  final int sizeBytes;
  @override
  String toString() =>
      'File is too large ($sizeBytes bytes). Limit is $kMaxAttachmentBytes bytes.';
}

class UnsupportedFileTypeException implements Exception {
  const UnsupportedFileTypeException(this.extension);
  final String extension;
  @override
  String toString() => 'File type "$extension" is not supported.';
}

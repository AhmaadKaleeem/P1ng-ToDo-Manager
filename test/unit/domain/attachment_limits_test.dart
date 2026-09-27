import 'package:flutter_test/flutter_test.dart';
import 'package:todow/domain/attachment_limits.dart';

void main() {
  const mb50 = 50 * 1024 * 1024;

  test('50MB file accepted', () {
    expect(() => validateAttachment('file.jpg', mb50), returnsNormally);
  });

  test('50MB + 1 byte rejected with FileTooLargeException', () {
    expect(
      () => validateAttachment('file.jpg', mb50 + 1),
      throwsA(isA<FileTooLargeException>()),
    );
  });

  test('.mp4 rejected with UnsupportedFileTypeException', () {
    expect(
      () => validateAttachment('video.mp4', 1024),
      throwsA(isA<UnsupportedFileTypeException>()),
    );
  });

  test('.jpg accepted', () {
    expect(() => validateAttachment('photo.jpg', 1024), returnsNormally);
  });

  test('.pdf accepted', () {
    expect(() => validateAttachment('doc.pdf', 1024), returnsNormally);
  });

  test('.docx accepted', () {
    expect(() => validateAttachment('report.docx', 1024), returnsNormally);
  });

  test('.exe rejected with UnsupportedFileTypeException', () {
    expect(
      () => validateAttachment('setup.exe', 1024),
      throwsA(isA<UnsupportedFileTypeException>()),
    );
  });

  test('uppercase .JPG accepted (case-insensitive)', () {
    expect(() => validateAttachment('PHOTO.JPG', 1024), returnsNormally);
  });
}

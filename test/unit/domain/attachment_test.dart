import 'package:flutter_test/flutter_test.dart';
import 'package:todow/domain/models/attachment.dart';

void main() {
  // Valid baseline
  Attachment valid() => Attachment(
        id: 'a' * 36,
        taskId: 'b' * 36,
        filename: 'file.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 1024,
        contentHash: 'e3b0c44298fc1c149afbf4c8996fb924'
            '27ae41e4649b934ca495991b7852b855',
        syncState: AttachmentSyncState.localOnly,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

  test('valid attachment constructs', () {
    expect(() => valid(), returnsNormally);
  });

  test('empty id throws', () {
    expect(
      () => valid().copyWith(id: ''),
      throwsA(isA<AssertionError>()),
    );
  });

  test('empty taskId throws', () {
    expect(
      () => valid().copyWith(taskId: ''),
      throwsA(isA<AssertionError>()),
    );
  });

  test('empty filename throws', () {
    expect(
      () => valid().copyWith(filename: ''),
      throwsA(isA<AssertionError>()),
    );
  });

  test('negative sizeBytes throws', () {
    expect(
      () => valid().copyWith(sizeBytes: -1),
      throwsA(isA<AssertionError>()),
    );
  });

  test('contentHash not 64 hex chars throws', () {
    expect(
      () => valid().copyWith(contentHash: 'abc'),
      throwsA(isA<AssertionError>()),
    );
  });
}

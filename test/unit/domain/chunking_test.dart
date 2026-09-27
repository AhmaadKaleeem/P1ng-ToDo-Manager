import 'package:flutter_test/flutter_test.dart';
import 'package:todow/domain/chunking.dart';

void main() {
  const mb5 = 5 * 1024 * 1024;

  test('chunksFor(0) returns empty', () {
    expect(chunksFor(0), isEmpty);
  });

  test('chunksFor(1) returns one chunk [0, 1]', () {
    final chunks = chunksFor(1);
    expect(chunks, hasLength(1));
    expect(chunks[0].start, 0);
    expect(chunks[0].end, 1);
    expect(chunks[0].index, 0);
  });

  test('chunksFor(exactly 5MB) returns one chunk', () {
    final chunks = chunksFor(mb5);
    expect(chunks, hasLength(1));
    expect(chunks[0].start, 0);
    expect(chunks[0].end, mb5);
  });

  test('chunksFor(5MB + 1) returns two chunks', () {
    final chunks = chunksFor(mb5 + 1);
    expect(chunks, hasLength(2));
    expect(chunks[0].start, 0);
    expect(chunks[0].end, mb5);
    expect(chunks[1].start, mb5);
    expect(chunks[1].end, mb5 + 1);
  });

  test('chunksFor(50MB) returns 10 chunks', () {
    final size = 50 * 1024 * 1024;
    final chunks = chunksFor(size);
    expect(chunks, hasLength(10));
  });

  test('last chunk end == fileSize', () {
    final size = 50 * mb5 + 777;
    final chunks = chunksFor(size);
    expect(chunks.last.end, size);
  });

  test('sum of chunk sizes == fileSize', () {
    final size = 13 * 1024 * 1024 + 512;
    final chunks = chunksFor(size);
    final sum = chunks.fold<int>(0, (acc, c) => acc + (c.end - c.start));
    expect(sum, size);
  });
}

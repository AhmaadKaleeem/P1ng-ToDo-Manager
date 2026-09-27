import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:todow/domain/hashing.dart';

void main() {
  test('sha256Hex of empty bytes matches known vector', () {
    final result = sha256Hex(Uint8List(0));
    expect(result,
        'e3b0c44298fc1c149afbf4c8996fb924'
        '27ae41e4649b934ca495991b7852b855');
  });

  test('sha256Hex of "abc" matches known vector', () {
    final bytes = Uint8List.fromList('abc'.codeUnits);
    expect(sha256Hex(bytes),
        'ba7816bf8f01cfea414140de5dae2223'
        'b00361a396177a9cb410ff61f20015ad');
  });

  test('sha256Hex of 10KB random bytes is deterministic', () {
    final bytes = Uint8List(10240)..fillRange(0, 10240, 42);
    final first = sha256Hex(bytes);
    final second = sha256Hex(bytes);
    expect(first, second);
    expect(first.length, 64);
  });
}

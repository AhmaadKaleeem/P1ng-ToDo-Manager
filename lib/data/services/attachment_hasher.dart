import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:todow/domain/hashing.dart';

/// Hashes a file off the main isolate.
/// The ONLY place hashing touches the filesystem.
Future<String> hashFile(String path) async {
  return Isolate.run(() {
    final bytes = File(path).readAsBytesSync();
    return sha256Hex(Uint8List.fromList(bytes));
  });
}

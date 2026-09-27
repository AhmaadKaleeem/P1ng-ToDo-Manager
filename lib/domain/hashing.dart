import 'dart:typed_data';

import 'package:crypto/crypto.dart';

String sha256Hex(Uint8List bytes) =>
    sha256.convert(bytes).toString();

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:todow/data/services/thumbnail_generator.dart';

void main() {
  late Directory tempDir;
  late String validSource;
  late String corruptSource;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('thumbnail_test');
    
    // Create valid image
    final image = img.Image(width: 200, height: 200);
    img.fill(image, color: img.ColorRgb8(255, 0, 0));
    final png = img.encodePng(image);
    validSource = p.join(tempDir.path, 'valid.png');
    File(validSource).writeAsBytesSync(png);

    // Create corrupt image
    corruptSource = p.join(tempDir.path, 'corrupt.png');
    File(corruptSource).writeAsStringSync('not an image');
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('generates a 96x96 JPEG from a valid PNG source', () async {
    final outputPath = p.join(tempDir.path, 'thumb.jpg');
    final result = await ThumbnailGenerator().generate(
      sourcePath: validSource,
      outputPath: outputPath,
      size: 96,
      quality: 80,
    );
    expect(result, outputPath);
    
    final bytes = File(outputPath).readAsBytesSync();
    final image = img.decodeImage(bytes);
    expect(image, isNotNull);
    expect(image!.width, 96);
    expect(image.height, 96);
  });

  test('returns null for a corrupt source file', () async {
    final outputPath = p.join(tempDir.path, 'thumb2.jpg');
    final result = await ThumbnailGenerator().generate(
      sourcePath: corruptSource,
      outputPath: outputPath,
      size: 96,
      quality: 80,
    );
    expect(result, isNull);
    expect(File(outputPath).existsSync(), isFalse);
  });
  
  test('does not throw on failure, always returns path or null', () async {
    final outputPath = p.join(tempDir.path, 'thumb3.jpg');
    final result = await ThumbnailGenerator().generate(
      sourcePath: p.join(tempDir.path, 'does_not_exist.png'),
      outputPath: outputPath,
    );
    expect(result, isNull);
  });
}

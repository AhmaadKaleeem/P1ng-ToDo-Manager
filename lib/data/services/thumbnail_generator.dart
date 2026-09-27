import 'dart:io';
import 'package:image/image.dart' as img;

class ThumbnailGenerator {
  Future<String?> generate({
    required String sourcePath,
    required String outputPath,
    int size = 96,
    int quality = 80,
  }) async {
    try {
      final bytes = File(sourcePath).readAsBytesSync();
      final image = img.decodeImage(bytes);
      if (image == null) return null;
      
      final thumbnail = img.copyResizeCropSquare(image, size: size);
      final jpeg = img.encodeJpg(thumbnail, quality: quality);
      
      File(outputPath).writeAsBytesSync(jpeg);
      return outputPath;
    } catch (e) {
      return null;
    }
  }
}

import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CameraUtils {
  /// Saves the image bytes to a file and returns the file path
  static Future<String> saveImage(List<int> imageBytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/intruder_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final filePath =
        '${imagesDir.path}/intruder_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);
    return filePath;
  }

  /// Returns the directory path for saving images
  static Future<String> getImagePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/intruder_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir.path;
  }
}

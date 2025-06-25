import 'package:camera/camera.dart';
import 'camera_utils.dart';

class IntruderCamera {
  /// Captures an intruder selfie, saves it, and returns the file path
  static Future<String?> captureIntruderSelfie() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      // Use the front camera if available
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(frontCamera, ResolutionPreset.medium);
      await controller.initialize();
      final image = await controller.takePicture();
      await controller.dispose();
      // Read image bytes and save using CameraUtils
      final bytes = await image.readAsBytes();
      final path = await CameraUtils.saveImage(bytes);
      return path;
    } catch (e) {
      // Handle errors (e.g., no camera, permission denied)
      return null;
    }
  }
}

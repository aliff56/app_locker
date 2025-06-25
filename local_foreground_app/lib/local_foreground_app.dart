import 'local_foreground_app_platform_interface.dart';

class LocalForegroundApp {
  Future<String?> getPlatformVersion() {
    return LocalForegroundAppPlatform.instance.getPlatformVersion();
  }
}

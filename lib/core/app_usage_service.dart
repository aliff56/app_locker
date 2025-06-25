import 'package:flutter/services.dart';

class AppUsageService {
  static const MethodChannel _channel = MethodChannel('app_locker/app_usage');

  static Future<String?> getForegroundApp() async {
    try {
      final packageName = await _channel.invokeMethod<String>(
        'getForegroundApp',
      );
      return packageName;
    } catch (_) {
      return null;
    }
  }

  static Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } catch (_) {}
  }
}

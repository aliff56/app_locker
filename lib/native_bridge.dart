import 'package:flutter/services.dart';

class NativeBridge {
  static const _channel = MethodChannel('com.example.app_locker/native_bridge');

  static Future<void> updateLockedApps(List<String> packages) async {
    await _channel.invokeMethod('updateLockedApps', packages);
  }

  static Future<void> updatePin(String pin) async {
    await _channel.invokeMethod('updatePin', pin);
  }
}

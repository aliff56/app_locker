import 'package:flutter/services.dart';

class NativeBridge {
  static const _channel = MethodChannel('com.example.app_locker/native_bridge');

  static Future<void> updateLockedApps(List<String> packages) async {
    await _channel.invokeMethod('updateLockedApps', packages);
  }

  static Future<void> updatePin(String pin) async {
    await _channel.invokeMethod('updatePin', pin);
  }

  static Future<void> setAppAlias(String alias) async {
    await _channel.invokeMethod('setAppAlias', {'alias': alias});
  }

  static Future<void> updatePattern(String pattern) async {
    await _channel.invokeMethod('updatePattern', pattern);
  }

  static Future<void> updateLockType(String lockType) async {
    await _channel.invokeMethod('updateLockType', lockType);
  }

  // Device admin helpers
  static Future<bool> isAdminActive() async {
    final result = await _channel.invokeMethod<bool>('isAdmin');
    return result ?? false;
  }

  static Future<void> enableAdmin() async {
    await _channel.invokeMethod('enableAdmin');
  }

  static Future<void> disableAdmin() async {
    await _channel.invokeMethod('disableAdmin');
  }
}

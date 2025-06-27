import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../native_bridge.dart';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final _storage = const FlutterSecureStorage();
  static const _pinKey = 'app_lock_pin';
  static const _isSetupKey = 'is_setup_complete';
  static const _patternKey = 'app_lock_pattern';
  static const _lockTypeKey = 'lock_type';

  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    await NativeBridge.updatePin(pin);
  }

  Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  Future<bool> isPinSet() async {
    final pin = await getPin();
    return pin != null && pin.isNotEmpty;
  }

  Future<void> setSetupComplete(bool complete) async {
    await _storage.write(key: _isSetupKey, value: complete.toString());
  }

  Future<bool> isSetupComplete() async {
    final value = await _storage.read(key: _isSetupKey);
    return value == 'true';
  }

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<void> savePattern(String pattern) async {
    await _storage.write(key: _patternKey, value: pattern);
    await NativeBridge.updatePattern(pattern);
  }

  Future<String?> getPattern() async {
    return await _storage.read(key: _patternKey);
  }

  Future<void> saveLockType(String type) async {
    await _storage.write(key: _lockTypeKey, value: type);
    await NativeBridge.updateLockType(type);
  }

  Future<String> getLockType() async {
    final v = await _storage.read(key: _lockTypeKey);
    return v ?? 'pin';
  }
}

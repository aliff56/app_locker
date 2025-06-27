import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/secure_storage.dart';
import '../../native_bridge.dart';

class LockedAppsManager {
  static final LockedAppsManager _instance = LockedAppsManager._internal();
  factory LockedAppsManager() => _instance;
  LockedAppsManager._internal();

  static const _lockedAppsKey = 'locked_apps_list';
  final _secureStorage = SecureStorage();

  Future<List<String>> getLockedApps() async {
    debugPrint('🚀 [AppLocker] --- LockedAppsManager:getLockedApps ---');
    final json = await _secureStorage.read(_lockedAppsKey);
    if (json == null || json.isEmpty) {
      debugPrint('   [AppLocker] No locked apps found in storage.');
      return [];
    }
    try {
      final List<dynamic> list = jsonDecode(json) as List<dynamic>;
      final apps = list.map((e) => e as String).toList();
      debugPrint('   [AppLocker] Loaded locked apps: $apps');
      return apps;
    } catch (e) {
      debugPrint('   [AppLocker] Error decoding locked apps: $e');
      return [];
    }
  }

  Future<void> _updateAndNotify(List<String> apps) async {
    debugPrint('🚀 [AppLocker] --- LockedAppsManager:_updateAndNotify ---');
    debugPrint('   [AppLocker] Updating storage with: $apps');
    await _secureStorage.write(_lockedAppsKey, jsonEncode(apps));
    debugPrint('   [AppLocker] Notifying native.');
    await NativeBridge.updateLockedApps(apps);
    debugPrint('   [AppLocker] --- LockedAppsManager:_updateAndNotify END ---');
  }

  Future<bool> isAppLocked(String packageName) async {
    final lockedApps = await getLockedApps();
    return lockedApps.contains(packageName);
  }

  Future<void> addLockedApp(String packageName) async {
    debugPrint('🚀 [AppLocker] --- LockedAppsManager:addLockedApp ---');
    debugPrint('   [AppLocker] Adding app: $packageName');
    final apps = await getLockedApps();
    if (!apps.contains(packageName)) {
      apps.add(packageName);
      await _updateAndNotify(apps);
      debugPrint('   [AppLocker] App added successfully.');
    } else {
      debugPrint('   [AppLocker] App already locked.');
    }
    debugPrint('   [AppLocker] --- LockedAppsManager:addLockedApp END ---');
  }

  Future<void> removeLockedApp(String packageName) async {
    debugPrint('🚀 [AppLocker] --- LockedAppsManager:removeLockedApp ---');
    debugPrint('   [AppLocker] Removing app: $packageName');
    final apps = await getLockedApps();
    if (apps.remove(packageName)) {
      await _updateAndNotify(apps);
      debugPrint('   [AppLocker] App removed successfully.');
    } else {
      debugPrint('   [AppLocker] App not found in locked list.');
    }
    debugPrint('   [AppLocker] --- LockedAppsManager:removeLockedApp END ---');
  }
}

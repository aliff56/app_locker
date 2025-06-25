import 'package:app_usage/app_usage.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:installed_apps/installed_apps.dart';

class PermissionsManager {
  static final PermissionsManager _instance = PermissionsManager._internal();
  factory PermissionsManager() => _instance;
  PermissionsManager._internal();

  Future<bool> requestRequiredPermissions() async {
    debugPrint(
      '🚀 [AppLocker] --- PermissionsManager:requestRequiredPermissions ---',
    );
    // Request notification permission first
    final notificationStatus = await Permission.notification.request();
    debugPrint(
      '   [AppLocker] Notification permission status: $notificationStatus',
    );
    if (notificationStatus.isDenied) return false;

    // Request overlay permission
    final overlayStatus = await Permission.systemAlertWindow.request();
    debugPrint('   [AppLocker] Overlay permission status: $overlayStatus');
    if (overlayStatus.isDenied) return false;

    // Request usage stats permission
    final usageStatsStatus = await _requestUsageStatsPermission();
    debugPrint(
      '   [AppLocker] Usage stats permission status: $usageStatsStatus',
    );
    if (!usageStatsStatus) return false;

    // Double check all permissions
    final allOk = await checkAllPermissions();
    debugPrint('   [AppLocker] Final permission check result: $allOk');
    return allOk;
  }

  Future<bool> _requestUsageStatsPermission() async {
    debugPrint(
      '🚀 [AppLocker] --- PermissionsManager:_requestUsageStatsPermission ---',
    );
    try {
      // First check if we already have the permission
      if (await isUsageAccessGranted()) {
        debugPrint('   [AppLocker] Usage access already granted.');
        return true;
      }

      // If not, open settings and guide user
      debugPrint('   [AppLocker] Opening app settings for usage access.');
      await openAppSettings();

      // Wait a bit to let user interact with settings
      await Future.delayed(const Duration(seconds: 2));

      // Check again
      final granted = await isUsageAccessGranted();
      debugPrint(
        '   [AppLocker] Usage access granted after settings: $granted',
      );
      return granted;
    } catch (e) {
      debugPrint(
        '   [AppLocker] ❌ Error requesting usage stats permission: $e',
      );
      return false;
    }
  }

  Future<bool> checkAllPermissions() async {
    debugPrint('🚀 [AppLocker] --- PermissionsManager:checkAllPermissions ---');
    try {
      // Check basic permissions
      final notificationGranted = await Permission.notification.isGranted;
      final overlayGranted = await Permission.systemAlertWindow.isGranted;
      final usageStatsGranted = await isUsageAccessGranted();

      debugPrint(
        '   [AppLocker] Notification: $notificationGranted, Overlay: $overlayGranted, Usage Stats: $usageStatsGranted',
      );

      // Try to actually use the permissions to verify they work
      if (usageStatsGranted) {
        try {
          // Try to get usage stats
          final endDate = DateTime.now();
          final startDate = endDate.subtract(const Duration(minutes: 1));
          await AppUsage().getAppUsage(startDate, endDate);
          debugPrint(
            '   [AppLocker] ✅ Successfully verified usage stats access.',
          );
        } catch (e) {
          debugPrint(
            '   [AppLocker] ❌ Failed to verify usage stats access: $e',
          );
          return false;
        }
      }

      if (overlayGranted) {
        try {
          // Try to get installed apps (needs overlay permission on some devices)
          await InstalledApps.getInstalledApps();
          debugPrint(
            '   [AppLocker] ✅ Successfully verified overlay access (via installed apps).',
          );
        } catch (e) {
          debugPrint('   [AppLocker] ❌ Failed to verify overlay access: $e');
          return false;
        }
      }

      final allGranted =
          notificationGranted && overlayGranted && usageStatsGranted;
      debugPrint(
        '   [AppLocker] All permissions check successful: $allGranted',
      );
      return allGranted;
    } catch (e) {
      debugPrint('   [AppLocker] ❌ Error checking all permissions: $e');
      return false;
    }
  }

  static Future<bool> isUsageAccessGranted() async {
    // No logs here as it's called frequently.
    try {
      // Try to get usage stats as a test
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(minutes: 1));
      await AppUsage().getAppUsage(startDate, endDate);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isOverlayPermissionGranted() async {
    return await Permission.systemAlertWindow.isGranted;
  }

  static Future<bool> isScheduleExactAlarmGranted() async {
    return await Permission.scheduleExactAlarm.isGranted;
  }

  static Future<void> requestCameraPermission() async {
    await Permission.camera.request();
  }

  static Future<void> requestStoragePermission() async {
    await Permission.storage.request();
  }

  static Future<void> requestNotificationPermission() async {
    await Permission.notification.request();
  }

  static Future<void> requestOverlayPermission() async {
    await Permission.systemAlertWindow.request();
  }

  static Future<void> requestScheduleExactAlarmPermission() async {
    await Permission.scheduleExactAlarm.request();
  }
}

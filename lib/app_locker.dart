import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'core/foreground_service.dart';
import 'features/locklist/locked_apps_manager.dart';
import 'features/overlay/overlay_manager.dart';

class AppLocker {
  static final AppLocker _instance = AppLocker._internal();
  factory AppLocker() => _instance;
  AppLocker._internal();

  final _foregroundService = ForegroundService();
  final _lockedAppsManager = LockedAppsManager();
  final _overlayManager = OverlayManager();

  Future<void> initialize() async {
    debugPrint('🚀 [AppLocker] --- AppLocker:initialize ---');
    try {
      // It's crucial to initialize the communication port before starting the service.
      FlutterForegroundTask.initCommunicationPort();

      // Start the foreground service
      await _foregroundService.init();
      debugPrint('   [AppLocker] Foreground service started.');

      // Initialize with current locked apps
      final lockedApps = await _lockedAppsManager.getLockedApps();
      await _foregroundService.updateLockedApps(lockedApps);
      debugPrint('   [AppLocker] Initial locked apps sent to service.');

      // Listen for foreground task events
      FlutterForegroundTask.addTaskDataCallback(_handleMessage);
      debugPrint('   [AppLocker] Task data callback added.');
    } catch (e) {
      debugPrint('   [AppLocker] ❌ Error initializing AppLocker: $e');
      rethrow;
    }
  }

  void _handleMessage(dynamic message) {
    debugPrint('🚀 [AppLocker] --- AppLocker:_handleMessage ---');
    debugPrint('   [AppLocker] Received message: $message');

    if (message is! String) {
      debugPrint(
        '   [AppLocker] Ignoring message of type ${message.runtimeType}',
      );
      return;
    }

    if (message.startsWith('LOCKED:')) {
      final packageName = message.substring(7);
      debugPrint('   [AppLocker] Handling LOCKED message for $packageName');
      _overlayManager.showLockScreen(packageName);
    } else if (message == 'UNLOCKED') {
      debugPrint('   [AppLocker] Handling UNLOCKED message.');
      _overlayManager.hideLockScreen();
    }
  }

  Future<void> stop() async {
    debugPrint('🚀 [AppLocker] --- AppLocker:stop ---');
    try {
      FlutterForegroundTask.removeTaskDataCallback(_handleMessage);
      await _foregroundService.stop();
      debugPrint('   [AppLocker] ✅ AppLocker stopped successfully.');
    } catch (e) {
      debugPrint('   [AppLocker] ❌ Error stopping AppLocker: $e');
      rethrow;
    }
  }

  Future<void> startMonitoring() async {
    // This method is called from main.dart when permissions are granted.
    // The service is already started in initialize(), so we just ensure
    // the locked apps list is up to date.
    debugPrint('🚀 [AppLocker] --- AppLocker:startMonitoring ---');
    final lockedApps = await _lockedAppsManager.getLockedApps();
    await _foregroundService.updateLockedApps(lockedApps);
    debugPrint(
      '   [AppLocker] Monitoring started/refreshed with latest locked apps.',
    );
  }
}

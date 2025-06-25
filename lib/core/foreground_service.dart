import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
// import 'package:app_usage/app_usage.dart'; // No longer needed
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // Import for MethodChannel
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../features/overlay/overlay_manager.dart';
import 'permissions_manager.dart';
import 'dart:math';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(AppLockTaskHandler());
}

class AppLockTaskHandler extends TaskHandler {
  Timer? _timer;
  Timer? _heartbeatTimer;
  final Set<String> _lockedApps = {};
  // bool _hasUsagePermission = false; // No longer needed
  static const _checkInterval = Duration(milliseconds: 500);
  // These are no longer needed
  // static const _usageCheckWindow = Duration(seconds: 2);
  // static const _permissionCheckWindow = Duration(minutes: 1);
  static const _maxRetries = 3;
  int _retryCount = 0;
  ReceivePort? _receivePort;
  SendPort? _sendPort;

  // MethodChannel to call our new native plugin
  static const _platform = MethodChannel(
    'com.example.app_locker/foreground_app',
  );

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('🚀 [AppLocker] --- AppLockTaskHandler:onStart ---');

    // The correct way for this version is to get the sendPort from the global receivePort.
    _receivePort = FlutterForegroundTask.receivePort;
    _sendPort = _receivePort?.sendPort;

    _startMonitoring();
    _startHeartbeat();
    debugPrint('   [AppLocker] Task handler started and monitoring begins.');
  }

  void _startHeartbeat() {
    debugPrint('🚀 [AppLocker] --- AppLockTaskHandler:_startHeartbeat ---');
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      debugPrint(
        '   [AppLocker] ❤️❤️❤️ Foreground service is alive and running. ❤️❤️❤️',
      );
    });
  }

  void _startMonitoring() {
    debugPrint('🚀 [AppLocker] --- AppLockTaskHandler:_startMonitoring ---');
    _timer?.cancel();
    _timer = Timer.periodic(_checkInterval, (_) {
      unawaited(_checkCurrentAppAsync());
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTerminated) async {
    debugPrint('🚀 [AppLocker] --- AppLockTaskHandler:onDestroy ---');
    _timer?.cancel();
    _heartbeatTimer?.cancel();
    _timer = null;
    _heartbeatTimer = null;
    debugPrint(
      '   [AppLocker] Task handler destroyed. isTerminated: $isTerminated',
    );
    if (!isTerminated) {
      debugPrint('   [AppLocker] Service was killed, attempting to restart.');
      unawaited(_attemptRestart());
    }
  }

  Future<void> _attemptRestart() async {
    debugPrint('🚀 [AppLocker] --- AppLockTaskHandler:_attemptRestart ---');
    if (_retryCount >= _maxRetries) {
      debugPrint(
        '   [AppLocker] ❌ Max retry attempts reached for service restart.',
      );
      return;
    }
    _retryCount++;
    debugPrint('   [AppLocker] Restart attempt #$_retryCount');
    try {
      await FlutterForegroundTask.startService(
        notificationTitle: 'App Locker',
        notificationText: 'Restarting service...',
        callback: startCallback,
      );
      _retryCount = 0; // Reset counter on successful restart
      debugPrint('   [AppLocker] ✅ Service restarted successfully.');
    } catch (e) {
      debugPrint('   [AppLocker] ❌ Error restarting service: $e');
      // Exponential backoff for retries
      await Future.delayed(Duration(seconds: pow(2, _retryCount).toInt()));
      unawaited(_attemptRestart());
    }
  }

  @override
  void onButtonPressed(String id) {
    debugPrint(
      '🚀 [AppLocker] --- AppLockTaskHandler:onButtonPressed --- ID: $id',
    );
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // This is called by the service, which in turn calls our timer-based check.
    // No separate logging needed here as _checkCurrentAppAsync is logged.
  }

  Future<void> _checkCurrentAppAsync() async {
    try {
      final String? currentApp = await _platform.invokeMethod(
        'getForegroundApp',
      );

      if (currentApp == null ||
          currentApp.isEmpty ||
          currentApp == 'com.example.app_locker') {
        return;
      }

      debugPrint('   [AppLocker] 🔎 Top app detected via native: $currentApp');

      // --- CORE LOCKING LOGIC ---
      if (_lockedApps.contains(currentApp)) {
        debugPrint(
          '   [AppLocker] 🚨 LOCKED APP DETECTED ON SCREEN: $currentApp',
        );
        _sendPort?.send('LOCKED:$currentApp');
      }
    } on PlatformException catch (e) {
      // This might happen if the service is running but the platform side isn't fully ready.
      // We can safely ignore it for a few cycles.
      debugPrint(
        "   [AppLocker] ⚠️ Failed to get foreground app: '${e.message}'.",
      );
    } catch (e) {
      debugPrint(
        '   [AppLocker] ❌ Unhandled error in _checkCurrentAppAsync: $e',
      );
    }
  }

  @override
  void onReceiveData(Object? data) {
    debugPrint('🚀 [AppLocker] --- AppLockTaskHandler:onReceiveData ---');
    if (data is Map) {
      final type = data['type'];
      final payload = data['data'];
      if (type == 'update_locked_apps' && payload is List) {
        final apps = payload.cast<String>();
        _lockedApps.clear();
        _lockedApps.addAll(apps);
        debugPrint(
          '   [AppLocker] ✅ Updated locked apps list in isolate: $_lockedApps',
        );
      } else {
        debugPrint('   [AppLocker] Received unknown map data: $data');
      }
    } else if (data is String && data.startsWith('UPDATE:')) {
      // Keep this for backward compatibility in case an old message format is sent
      final apps = data.substring(7).split(',');
      _lockedApps.clear();
      _lockedApps.addAll(apps);
      debugPrint(
        '   [AppLocker] ✅ Updated locked apps list in isolate (from string): $_lockedApps',
      );
    } else {
      debugPrint('   [AppLocker] Received unknown data type: $data');
    }
  }
}

class ForegroundService {
  static final ForegroundService _instance = ForegroundService._internal();
  factory ForegroundService() => _instance;
  ForegroundService._internal();

  String? _sendPortName;
  bool _isRunning = false;
  bool _isInitialized = false;
  static const _serviceCheckInterval = Duration(milliseconds: 500);
  static const _maxInitRetries = 3;

  Future<void> init() async {
    debugPrint('🚀 [AppLocker] --- ForegroundService:init ---');
    FlutterForegroundTask.initCommunicationPort();

    if (await FlutterForegroundTask.isRunningService) {
      debugPrint('   [AppLocker] Service already running, trying to restart.');
      await stop();
    }

    _initializeForegroundTask();

    debugPrint('   [AppLocker] Starting foreground task.');
    await FlutterForegroundTask.startService(
      notificationTitle: 'App Locker Running',
      notificationText: 'Monitoring app usage',
      callback: startCallback,
    );
    debugPrint('   [AppLocker] --- ForegroundService:init END ---');
  }

  Future<void> stop() async {
    debugPrint('🚀 [AppLocker] --- ForegroundService:stop ---');
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
      debugPrint('   [AppLocker] Service stopped.');
    } else {
      debugPrint('   [AppLocker] Service was not running.');
    }
    debugPrint('   [AppLocker] --- ForegroundService:stop END ---');
  }

  Future<void> updateLockedApps(List<String> lockedApps) async {
    debugPrint('🚀 [AppLocker] --- ForegroundService:updateLockedApps ---');
    debugPrint(
      '   [AppLocker] Sending updated locked apps to isolate: $lockedApps',
    );
    FlutterForegroundTask.sendDataToTask({
      'type': 'update_locked_apps',
      'data': lockedApps,
    });
    debugPrint('   [AppLocker] --- ForegroundService:updateLockedApps END ---');
  }

  Future<void> _initializeForegroundTask() async {
    debugPrint(
      '🚀 [AppLocker] --- ForegroundService:_initializeForegroundTask ---',
    );
    int retryCount = 0;
    while (retryCount < _maxInitRetries) {
      try {
        FlutterForegroundTask.init(
          androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'notification_channel_id',
            channelName: 'Foreground Service Notification',
            channelDescription:
                'This notification appears when the foreground service is running.',
            channelImportance: NotificationChannelImportance.LOW,
            priority: NotificationPriority.LOW,
          ),
          iosNotificationOptions: const IOSNotificationOptions(
            showNotification: true,
            playSound: false,
          ),
          foregroundTaskOptions: ForegroundTaskOptions(
            eventAction: ForegroundTaskEventAction.repeat(
              const Duration(milliseconds: 500).inMilliseconds,
            ),
            autoRunOnBoot: true,
            allowWakeLock: true,
            allowWifiLock: true,
          ),
        );

        _isInitialized = true;
        debugPrint(
          '   [AppLocker] ✅ Foreground task initialized successfully.',
        );
        break;
      } catch (e) {
        debugPrint(
          '   [AppLocker] ❌ Error initializing foreground task (attempt ${retryCount + 1}): $e',
        );
        retryCount++;
        if (retryCount >= _maxInitRetries) rethrow;
        await Future.delayed(Duration(seconds: pow(2, retryCount).toInt()));
      }
    }
  }

  Future<bool> isServiceRunning() async {
    try {
      final running = await FlutterForegroundTask.isRunningService;
      debugPrint(
        '🚀 [AppLocker] --- ForegroundService:isServiceRunning --- Result: $running',
      );
      return running;
    } catch (e) {
      debugPrint('   [AppLocker] ❌ Error checking service status: $e');
      return false;
    }
  }
}

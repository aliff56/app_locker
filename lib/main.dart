import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'app_locker.dart';
import 'core/permissions_manager.dart';
import 'core/secure_storage.dart';
import 'features/auth/pin_setup_screen.dart';
import 'features/locklist/locked_apps_screen.dart';
import 'features/overlay/overlay_manager.dart';
import 'features/permissions/permission_denied_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppLockerApp());
}

class AppLockerApp extends StatelessWidget {
  const AppLockerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Locker',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const AppLockerHome(),
    );
  }
}

class AppLockerHome extends StatefulWidget {
  const AppLockerHome({Key? key}) : super(key: key);

  @override
  State<AppLockerHome> createState() => _AppLockerHomeState();
}

class _AppLockerHomeState extends State<AppLockerHome>
    with WidgetsBindingObserver {
  static StreamSubscription<dynamic>? _foregroundTaskSubscription;

  final _permissionsManager = PermissionsManager();
  final _secureStorage = SecureStorage();
  final _appLocker = AppLocker();
  bool _isLoading = true;
  bool _hasPermissions = false;
  bool _isSetupComplete = false;

  @override
  void initState() {
    super.initState();
    _initForegroundTask();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlayState = Overlay.of(context);
      if (overlayState != null) {
        OverlayManager().init(overlayState);
      }
    });
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appLocker.stop();
    super.dispose();
  }

  void _initForegroundTask() {
    if (_foregroundTaskSubscription == null) {
      _foregroundTaskSubscription = FlutterForegroundTask.receivePort?.listen((
        message,
      ) {
        if (message is String) {
          OverlayManager().handleNotificationMessage(message);
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    await _requestPermissions();
    await _checkPermissions();
    if (_hasPermissions) {
      await _checkSetup();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _checkPermissions() async {
    final hasPermissions = await _permissionsManager.checkAllPermissions();
    if (hasPermissions == _hasPermissions) return;
    setState(() => _hasPermissions = hasPermissions);
    if (hasPermissions) {
      await _appLocker.initialize();
    } else {
      await _appLocker.stop();
    }
  }

  Future<void> _checkSetup() async {
    final isSetupComplete = await _secureStorage.isSetupComplete();
    setState(() => _isSetupComplete = isSetupComplete);
  }

  Future<void> _requestPermissions() async {
    await PermissionsManager.requestOverlayPermission();
    await _permissionsManager.requestRequiredPermissions();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasPermissions) {
      return PermissionDeniedScreen(
        onRetry: () async {
          setState(() => _isLoading = true);
          await _requestPermissions();
          setState(() => _isLoading = false);
        },
      );
    }

    if (!_isSetupComplete) {
      return PinSetupScreen(
        onSetupComplete: () async {
          await _checkSetup();
          if (_isSetupComplete) {
            await _appLocker.startMonitoring();
          }
        },
      );
    }

    return WithForegroundTask(child: LockedAppsScreen());
  }
}

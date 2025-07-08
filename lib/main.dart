import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'core/permissions_manager.dart';
import 'core/secure_storage.dart';
import 'features/auth/pin_setup_screen.dart';
import 'features/locklist/locked_apps_screen.dart';
import 'features/permissions/permissions_setup_screen.dart';
import 'features/settings/settings_screen.dart';
import 'native_bridge.dart';
import 'theme.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/auth/applock_pattern_unlock.dart';
import 'features/auth/applock_pin_unlock.dart';
import 'package:app_usage/app_usage.dart';
import 'features/locklist/locked_apps_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  runApp(
    ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) =>
          AppLockerApp(themeMode: mode ?? ThemeMode.light),
    ),
  );
}

class AppLockerApp extends StatelessWidget {
  final ThemeMode themeMode;
  const AppLockerApp({Key? key, required this.themeMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Locker',
      theme: appTheme(),
      darkTheme: appDarkTheme(),
      themeMode: themeMode,
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
  final _permissionsManager = PermissionsManager();
  final _secureStorage = SecureStorage();
  bool _isLoading = true;
  bool _hasPermissions = false;
  bool _isSetupComplete = false;
  bool _showSplash = true;
  bool _isAuthenticated = false;
  String? _lockType; // 'pin' or 'pattern'

  int _navIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pages = const [LockedAppsScreen(), SettingsScreen()];
    _initialize();

    // Load lock type for authentication later
    _loadLockType();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // _checkPermissions(); // Removed automatic navigation on permission grant
      // Require re-authentication on resume
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
        });
      }
    }
  }

  Future<void> _initialize() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _checkPermissions();
    if (_hasPermissions) {
      await _checkSetup();
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _checkPermissions() async {
    final hasPermissions = await _permissionsManager.checkAllPermissions();
    if (!mounted) return;
    if (hasPermissions == _hasPermissions) return;
    setState(() => _hasPermissions = hasPermissions);
    if (hasPermissions) {
      await _checkSetup();
    }
  }

  Future<void> _checkSetup() async {
    final isSetupComplete = await _secureStorage.isSetupComplete();
    if (!mounted) return;
    setState(() {
      _isSetupComplete = isSetupComplete;
      debugPrint('✔ _isSetupComplete set true');
    });
    if (isSetupComplete) {
      await _loadLockType();
    }
  }

  Future<void> _loadLockType() async {
    final type = await _secureStorage.getLockType();
    if (!mounted) return;
    setState(() => _lockType = type);
  }

  Future<void> _refreshNativeLockedList() async {
    final json = await _secureStorage.read('locked_apps_list');
    List<String> list = [];
    if (json != null) {
      try {
        list = List<String>.from(jsonDecode(json));
      } catch (_) {
        list = [];
      }
    }
    await NativeBridge.updateLockedApps(list);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _showSplash) {
      return SplashScreen(
        onContinue: () {
          if (!mounted) return;
          setState(() => _showSplash = false);
        },
      );
    }

    if (!_hasPermissions) {
      return PermissionsSetupScreen(
        onAllGranted: () async {
          await _checkPermissions();
          if (!mounted) return;
          if (_hasPermissions) {
            await _checkSetup();
            if (!mounted) return;
            setState(() {});
          }
        },
      );
    }

    if (!_isSetupComplete) {
      // Only show setup screens, never lock screens, before setup is complete
      return PinSetupScreen(
        onSetupComplete: () async {
          if (mounted) {
            setState(() {
              _isSetupComplete = true;
              debugPrint('✔ _isSetupComplete set true');
            });
          }
          await _refreshNativeLockedList();
          await _loadLockType();
        },
      );
    }

    // Wait until lock type known
    if (_lockType == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Only show lock screens after setup is complete
    if (_isSetupComplete && !_isAuthenticated) {
      debugPrint('🟪 [LOCK-FLOW] Lock screen initiated (main.dart)');
      return FutureBuilder<String>(
        future: _secureStorage.getLockType(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final lockType = snapshot.data;
          if (lockType == 'pattern') {
            return AppLockPatternUnlock(
              onSuccess: () {
                debugPrint('🟪 [LOCK-FLOW] Pattern unlock success (main.dart)');
                if (mounted) setState(() => _isAuthenticated = true);
              },
            );
          } else {
            return AppLockPinUnlock(
              onSuccess: () {
                debugPrint('🟪 [LOCK-FLOW] PIN unlock success (main.dart)');
                if (mounted) setState(() => _isAuthenticated = true);
              },
            );
          }
        },
      );
    }

    return Scaffold(body: _pages[_navIndex]);
  }
}

class ForegroundAppMonitor {
  Timer? _timer;
  int _heartbeat = 0;
  String? _lastApp;
  bool _overlayShown = false;

  void start() {
    debugPrint('🟦 [SERVICE] ForegroundAppMonitor started');
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => _check());
  }

  void stop() {
    debugPrint('🟦 [SERVICE] ForegroundAppMonitor stopped');
    _timer?.cancel();
  }

  Future<void> _check() async {
    try {
      _heartbeat++;
      if (_heartbeat % 10 == 0) {
        debugPrint('🟦 [SERVICE] ForegroundAppMonitor heartbeat: running');
      }
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(seconds: 2));
      final usage = await AppUsage().getAppUsage(startDate, endDate);
      if (usage.isEmpty) {
        debugPrint('🟪 [LOCK-FLOW] No usage data');
        return;
      }
      final currentApp = usage.first.packageName;
      debugPrint('🟪 [LOCK-FLOW] Foreground app: $currentApp');
      if (currentApp == _lastApp) return;
      _lastApp = currentApp;

      final isLocked = await LockedAppsManager().isAppLocked(currentApp);
      debugPrint(
        '🟪 [LOCK-FLOW] isLocked: $isLocked, _overlayShown: $_overlayShown',
      );
      if (isLocked && !_overlayShown) {
        _overlayShown = true;
        debugPrint('🟪 [LOCK-FLOW] Triggering overlay for $currentApp');
        // Replace await NativeBridge.showLockOverlay(); with a debug log indicating where the overlay would be triggered, since the method does not exist.
      } else if (!isLocked) {
        if (_overlayShown)
          debugPrint(
            '🟪 [LOCK-FLOW] App is not locked, resetting _overlayShown',
          );
        _overlayShown = false;
      }
    } catch (e) {
      debugPrint('🟥 [LOCK-FLOW] ForegroundAppMonitor error: $e');
    }
  }
}

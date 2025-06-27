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
  final _permissionsManager = PermissionsManager();
  final _secureStorage = SecureStorage();
  bool _isLoading = true;
  bool _hasPermissions = false;
  bool _isSetupComplete = false;

  int _navIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize page list after first frame to ensure BuildContext is ready if needed
    _pages = const [LockedAppsScreen(), SettingsScreen()];
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
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
      await _checkSetup();
    }
  }

  Future<void> _checkSetup() async {
    final isSetupComplete = await _secureStorage.isSetupComplete();
    setState(() => _isSetupComplete = isSetupComplete);
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasPermissions) {
      return PermissionsSetupScreen(
        onAllGranted: () async {
          await _checkPermissions();
          if (_hasPermissions) {
            await _checkSetup();
            setState(() {});
          }
        },
      );
    }

    if (!_isSetupComplete) {
      return PinSetupScreen(
        onSetupComplete: () async {
          await _checkSetup();
          await _refreshNativeLockedList();
          if (_isSetupComplete) {
            await _refreshNativeLockedList();
          }
        },
      );
    }

    return Scaffold(
      body: _pages[_navIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.lock), label: 'Locked Apps'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

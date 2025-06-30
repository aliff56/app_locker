import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom_button.dart';
import '../../data/constants.dart';
import '../auth/pin_setup_screen.dart';
import '../permissions/permissions_setup_screen.dart';
import '../../main.dart';
import 'camouflage_screen.dart';
import '../../core/secure_storage.dart';
import '../auth/pattern_setup_screen.dart';
import '../../native_bridge.dart';
import '../camera/intruder_photos_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentLockType = 'pin';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadLockType();
    _loadAdminStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force portrait orientation on this screen for consistent layout (optional)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // Restore system orientations
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _loadLockType() async {
    final type = await SecureStorage().getLockType();
    if (mounted) setState(() => _currentLockType = type);
  }

  Future<void> _loadAdminStatus() async {
    final status = await NativeBridge.isAdminActive();
    if (mounted) setState(() => _isAdmin = status);
  }

  Future<void> _chooseLockType() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('PIN'),
              onTap: () => Navigator.pop(context, 'pin'),
            ),
            ListTile(
              leading: const Icon(Icons.grid_3x3),
              title: const Text('Pattern'),
              onTap: () => Navigator.pop(context, 'pattern'),
            ),
          ],
        );
      },
    );
    if (selected != null) {
      await SecureStorage().saveLockType(selected);
      setState(() => _currentLockType = selected);
      if (selected == 'pattern') {
        // push pattern setup
        if (context.mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PatternSetupScreen(
                onSetupComplete: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          );
        }
      } else {
        // pin setup
        if (context.mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PinSetupScreen(
                onSetupComplete: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _openPermissions() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PermissionsSetupScreen(
          onAllGranted: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _changePinOrPattern() async {
    if (_currentLockType == 'pattern') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PatternSetupScreen(
            onSetupComplete: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PinSetupScreen(
            onSetupComplete: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    final Color activeColor = const Color(0xFF5B2EFF);
    final Color inactiveColor = Theme.of(context).cardColor;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: active ? activeColor : inactiveColor,
      borderRadius: BorderRadius.circular(32),
      elevation: 0,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Icon(
                icon,
                color: active
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black54),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: active
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(Constants.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Account / Security
          _menuItem(
            icon: Icons.lock_outline,
            label: _currentLockType == 'pattern'
                ? 'Change Pattern'
                : 'Change PIN',
            onTap: _changePinOrPattern,
          ),
          const SizedBox(height: 16),
          _menuItem(
            icon: Icons.security,
            label: 'Check Permissions',
            onTap: _openPermissions,
          ),
          const SizedBox(height: 16),
          _menuItem(
            icon: Icons.shield_outlined,
            label: _isAdmin ? 'Self-Protection: ON' : 'Self-Protection: OFF',
            active: _isAdmin,
            onTap: () async {
              if (_isAdmin) {
                await NativeBridge.disableAdmin();
              } else {
                await NativeBridge.enableAdmin();
              }
              await Future.delayed(const Duration(milliseconds: 500));
              _loadAdminStatus();
            },
          ),
          const SizedBox(height: 24),

          // Appearance
          _menuItem(
            icon: isDark ? Icons.light_mode : Icons.dark_mode,
            label: isDark ? 'Enable Light Mode' : 'Enable Dark Mode',
            onTap: () {
              themeModeNotifier.value = isDark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
            active: isDark,
          ),
          const SizedBox(height: 16),
          _menuItem(
            icon: Icons.app_registration_rounded,
            label: 'Lock Type: ${_currentLockType.toUpperCase()}',
            onTap: _chooseLockType,
            active: true,
          ),
          const SizedBox(height: 24),

          // Utilities
          _menuItem(
            icon: Icons.camera_alt_outlined,
            label: 'Intruder Selfies',
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const IntruderPhotosScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _menuItem(
            icon: Icons.visibility_off_outlined,
            label: 'Camouflage App',
            onTap: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => CamouflageScreen()));
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

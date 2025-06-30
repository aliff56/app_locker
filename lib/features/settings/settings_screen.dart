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
    bool showArrow = false,
  }) {
    const borderColor = Color(0xFFE1E4EC);
    const blue = Color(0xFF162C65);
    final bgColor = active ? blue : Colors.white;
    final textColor = active ? Colors.white : blue;
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: active ? null : Border.all(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: textColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (showArrow) Icon(Icons.chevron_right, color: textColor),
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
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _menuItem(
            icon: Icons.lock_outline,
            label: 'Change PIN',
            onTap: _changePinOrPattern,
          ),
          const SizedBox(height: 16),
          _menuItem(
            icon: Icons.shield_outlined,
            label: _isAdmin
                ? 'Self- Protection : ON'
                : 'Self- Protection : OFF',
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
          const SizedBox(height: 16),
          _menuItem(
            icon: Icons.app_registration_rounded,
            label:
                'Lock Type: ${_currentLockType[0].toUpperCase()}${_currentLockType.substring(1)}',
            active: true,
            onTap: _chooseLockType,
          ),
          const SizedBox(height: 16),
          _menuItem(
            icon: Icons.security,
            label: 'Check Permissions',
            onTap: _openPermissions,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../data/constants.dart';
import '../auth/pin_setup_screen.dart';
import '../permissions/permissions_setup_screen.dart';
import '../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _changePin() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Constants.settingsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomButton(label: Constants.changePinBtn, onPressed: _changePin),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Check Permissions',
              onPressed: _openPermissions,
            ),
            const SizedBox(height: 16),
            _buildThemeToggle(context),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            // ignore: deprecated_member_use
            shadowColor: Colors.black.withOpacity(0.08),
          ),
          onPressed: () {
            themeModeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
          },
          child: Text(isDark ? 'Enable Light Mode' : 'Enable Dark Mode'),
        ),
      ),
    );
  }
}

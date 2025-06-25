import 'package:flutter/material.dart';
import '../../core/secure_storage.dart';
import '../../widgets/custom_button.dart';
import '../../data/constants.dart';
import '../auth/pin_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricFlag();
  }

  Future<void> _loadBiometricFlag() async {
    final bool enabled = await _getBiometricEnabled();
    setState(() => _biometricEnabled = enabled);
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _loading = true);
    await _setBiometricEnabled(value);
    setState(() {
      _biometricEnabled = value;
      _loading = false;
    });
  }

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

  // Local helpers for biometric flag
  Future<bool> _getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  Future<void> _setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Constants.settingsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Constants.biometricSettingLabel,
                  style: const TextStyle(fontSize: 18),
                ),
                Switch(
                  value: _biometricEnabled,
                  onChanged: _loading ? null : _toggleBiometric,
                ),
              ],
            ),
            const SizedBox(height: 24),
            CustomButton(label: Constants.changePinBtn, onPressed: _changePin),
          ],
        ),
      ),
    );
  }
}

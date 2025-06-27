import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../data/constants.dart';
import '../auth/pin_setup_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Constants.settingsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomButton(label: Constants.changePinBtn, onPressed: _changePin),
          ],
        ),
      ),
    );
  }
}

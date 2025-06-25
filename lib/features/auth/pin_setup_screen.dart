import 'package:flutter/material.dart';
import 'pin_screen.dart';

class PinSetupScreen extends StatelessWidget {
  final VoidCallback onSetupComplete;

  const PinSetupScreen({Key? key, required this.onSetupComplete})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup PIN'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Set up a PIN to protect your locked apps',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: PinScreen(isSetup: true, onSuccess: onSetupComplete),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

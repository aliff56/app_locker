import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../auth/pin_screen.dart';

class OverlayScreen extends StatefulWidget {
  final String? lockedApp;
  const OverlayScreen({this.lockedApp, Key? key}) : super(key: key);

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String? _error;

  Future<void> _unlockWithBiometrics() async {
    try {
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Unlock App',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (didAuthenticate) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _error = 'Biometric unlock failed');
      }
    } catch (e) {
      setState(() => _error = 'Biometric error: $e');
    }
  }

  Future<void> _unlockWithPin() async {
    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PinScreen(
          onSuccess: () {
            Navigator.of(context).pop(true);
          },
        ),
      ),
    );
    if (result == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'App Locked',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (widget.lockedApp != null) ...[
                  const SizedBox(height: 8),
                  Text('Unlock required for ${widget.lockedApp!}'),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Unlock with Biometrics'),
                  onPressed: _unlockWithBiometrics,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock),
                  label: const Text('Unlock with PIN'),
                  onPressed: _unlockWithPin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

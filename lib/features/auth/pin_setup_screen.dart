import 'package:flutter/material.dart';
import '../../core/secure_storage.dart';
import '../../widgets/numeric_keypad.dart';
import 'pattern_setup_screen.dart';

class PinSetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;
  const PinSetupScreen({Key? key, required this.onSetupComplete})
    : super(key: key);

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  String _errorText = '';
  bool _isConfirming = false;

  void _onDigit(int n) {
    if (_pin.length >= 4) return;
    setState(() => _pin += n.toString());
    if (_pin.length == 4) {
      _handleComplete();
    }
  }

  void _onBack() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _handleComplete() async {
    if (!_isConfirming) {
      _confirmPin = _pin;
      setState(() {
        _isConfirming = true;
        _pin = '';
      });
      return;
    }
    if (_pin == _confirmPin) {
      await SecureStorage().savePin(_confirmPin);
      await SecureStorage().setSetupComplete(true);
      await Future.delayed(const Duration(milliseconds: 100));
      widget.onSetupComplete();
      debugPrint('✔ onSetupComplete reached (from Pin/Pattern)');
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    } else {
      setState(() {
        _errorText = 'PINs do not match. Try again.';
        _isConfirming = false;
        _pin = '';
      });
    }
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        bool filled = i < _pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? Colors.white : Colors.white.withOpacity(.3),
            border: Border.all(color: Colors.white, width: 2),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162C65),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // App icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 95,
                    height: 95,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildDots(),
            const SizedBox(height: 24),
            Text(
              _isConfirming ? 'Confirm your PIN' : 'Create a PIN',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (_errorText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_errorText, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            NumericKeypad(
              onDigit: _onDigit,
              onBack: _onBack,
              color: Color(0xFF162C65),
            ),
            const SizedBox(height: 24),
            Text(
              'or',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3162B9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await SecureStorage().saveLockType('pattern');
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PatternSetupScreen(
                            onSetupComplete: widget.onSetupComplete,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Go with a pattern lock'),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

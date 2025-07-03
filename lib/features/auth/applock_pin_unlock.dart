import 'package:flutter/material.dart';
import '../../core/secure_storage.dart';
import '../../widgets/numeric_keypad.dart';

class AppLockPinUnlock extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback? onSwitchToPattern;
  const AppLockPinUnlock({
    Key? key,
    required this.onSuccess,
    this.onSwitchToPattern,
  }) : super(key: key);

  @override
  State<AppLockPinUnlock> createState() => _AppLockPinUnlockState();
}

class _AppLockPinUnlockState extends State<AppLockPinUnlock> {
  String _pin = '';
  String _errorText = '';

  Future<void> _handleComplete() async {
    final storedPin = await SecureStorage().getPin();
    if (storedPin == _pin) {
      widget.onSuccess();
    } else {
      setState(() {
        _errorText = 'Incorrect PIN';
        _pin = '';
      });
    }
  }

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
            color: filled ? Colors.white : Colors.white.withOpacity(.2),
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
            const Text(
              'Enter PIN',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildDots(),
            if (_errorText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_errorText, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            NumericKeypad(
              onDigit: _onDigit,
              onBack: _onBack,
              color: const Color(0xFF162C65),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

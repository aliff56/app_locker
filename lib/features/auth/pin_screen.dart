import 'package:flutter/material.dart';
import '../../core/secure_storage.dart';
import '../../widgets/numeric_keypad.dart';
import '../../theme.dart';

class PinScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final void Function(String)? onError;
  final bool isSetup;

  const PinScreen({
    Key? key,
    required this.onSuccess,
    this.onError,
    this.isSetup = false,
  }) : super(key: key);

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String _confirmPin = '';
  String _errorText = '';
  bool _isConfirming = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleComplete() async {
    if (widget.isSetup) {
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
        widget.onSuccess();
      } else {
        final error = 'PINs do not match. Try again.';
        setState(() {
          _errorText = error;
          _isConfirming = false;
          _pin = '';
        });
        widget.onError?.call(error);
      }
    } else {
      final storedPin = await SecureStorage().getPin();
      if (storedPin == _pin) {
        widget.onSuccess();
      } else {
        final error = 'Incorrect PIN';
        setState(() {
          _errorText = error;
          _pin = '';
        });
        widget.onError?.call(error);
      }
    }
  }

  void _onDigit(int n) {
    if (_pin.length >= 4) return;
    setState(() => _pin += n.toString());
    if (_pin.length == 4) _handleComplete();
  }

  void _onBack() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Widget _buildDots() {
    List<Widget> dots = List.generate(4, (i) {
      bool filled = i < _pin.length;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // ignore: deprecated_member_use
          color: filled ? kPrimaryColor : kPrimaryColor.withOpacity(.2),
        ),
      );
    });
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: dots);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              widget.isSetup
                  ? _isConfirming
                        ? 'Confirm your PIN'
                        : 'Set your 4-digit PIN'
                  : 'Enter PIN',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            _buildDots(),
            if (_errorText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(_errorText, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            NumericKeypad(onDigit: _onDigit, onBack: _onBack),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

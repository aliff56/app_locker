import 'package:flutter/material.dart';
import '../../core/secure_storage.dart';

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
  final TextEditingController _pinController = TextEditingController();
  String _confirmPin = '';
  String _errorText = '';
  bool _isConfirming = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _validatePin() async {
    if (widget.isSetup) {
      if (!_isConfirming) {
        _confirmPin = _pinController.text;
        setState(() {
          _isConfirming = true;
          _errorText = '';
          _pinController.clear();
        });
        return;
      }

      if (_pinController.text == _confirmPin) {
        await SecureStorage().savePin(_confirmPin);
        await SecureStorage().setSetupComplete(true);
        widget.onSuccess();
      } else {
        final error = 'PINs do not match. Try again.';
        setState(() {
          _errorText = error;
          _isConfirming = false;
          _pinController.clear();
        });
        widget.onError?.call(error);
      }
    } else {
      final storedPin = await SecureStorage().getPin();
      if (storedPin == _pinController.text) {
        widget.onSuccess();
      } else {
        final error = 'Incorrect PIN';
        setState(() {
          _errorText = error;
          _pinController.clear();
        });
        widget.onError?.call(error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isSetup
                    ? _isConfirming
                          ? 'Confirm PIN'
                          : 'Set PIN'
                    : 'Enter PIN',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: _errorText.isNotEmpty ? _errorText : null,
                ),
                onSubmitted: (_) => _validatePin(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _validatePin,
                child: Text(
                  widget.isSetup
                      ? _isConfirming
                            ? 'Confirm'
                            : 'Next'
                      : 'Unlock',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

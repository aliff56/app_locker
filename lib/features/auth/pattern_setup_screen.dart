import 'package:flutter/material.dart';
import 'package:pattern_lock/pattern_lock.dart';
import '../../core/secure_storage.dart';
import '../../theme.dart';
import 'package:app_locker/features/auth/pin_setup_screen.dart';

class PatternSetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;
  const PatternSetupScreen({super.key, required this.onSetupComplete});

  @override
  State<PatternSetupScreen> createState() => _PatternSetupScreenState();
}

class _PatternSetupScreenState extends State<PatternSetupScreen> {
  List<int>? _tempPattern;
  String _error = '';

  Future<void> _savePattern(List<int> pattern) async {
    await SecureStorage().savePattern(pattern.join('-'));
    await SecureStorage().saveLockType('pattern');
    widget.onSetupComplete();
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
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 64,
                  height: 64,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Create a pattern',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_error, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AspectRatio(
                aspectRatio: 1,
                child: PatternLock(
                  selectedColor: Colors.white,
                  notSelectedColor: Colors.white38,
                  dimension: 3,
                  relativePadding: 0.7,
                  onInputComplete: (input) {
                    if (_tempPattern == null) {
                      setState(() {
                        _tempPattern = input;
                        _error = 'Draw pattern again to confirm';
                      });
                    } else {
                      if (_tempPattern!.join('-') == input.join('-')) {
                        _savePattern(input);
                      } else {
                        setState(() {
                          _tempPattern = null;
                          _error = 'Patterns do not match. Try again.';
                        });
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('or', style: TextStyle(color: Colors.white.withOpacity(0.8))),
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
                    await SecureStorage().saveLockType('pin');
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => PinSetupScreen(
                            onSetupComplete: widget.onSetupComplete,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Go with 4 digit PIN'),
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

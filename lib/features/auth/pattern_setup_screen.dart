import 'package:flutter/material.dart';
import 'package:pattern_lock/pattern_lock.dart';
import '../../core/secure_storage.dart';
import '../../theme.dart';

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
      appBar: AppBar(title: const Text('Set Pattern')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              if (_error.isNotEmpty) ...[
                Text(_error, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: PatternLock(
                      selectedColor: kPrimaryColor,
                      notSelectedColor: Colors.grey,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pattern_lock/pattern_lock.dart';
import '../../core/secure_storage.dart';
import '../../theme.dart';

class PatternUnlockScreen extends StatelessWidget {
  final VoidCallback onSuccess;
  const PatternUnlockScreen({super.key, required this.onSuccess});

  Future<bool> _verify(List<int> input) async {
    final stored = await SecureStorage().getPattern();
    if (stored == null) return false;
    return stored == input.join('-');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unlock')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: PatternLock(
                selectedColor: kPrimaryColor,
                notSelectedColor: Colors.grey,
                dimension: 3,
                relativePadding: 0.7,
                onInputComplete: (input) async {
                  if (await _verify(input)) {
                    onSuccess();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect pattern')),
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pattern_lock/pattern_lock.dart';
import '../../core/secure_storage.dart';

class AppLockPatternUnlock extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback? onSwitchToPin;
  const AppLockPatternUnlock({
    Key? key,
    required this.onSuccess,
    this.onSwitchToPin,
  }) : super(key: key);

  @override
  State<AppLockPatternUnlock> createState() => _AppLockPatternUnlockState();
}

class _AppLockPatternUnlockState extends State<AppLockPatternUnlock> {
  String? _error;

  Future<bool> _verify(List<int> input) async {
    final stored = await SecureStorage().getPattern();
    if (stored == null) return false;
    return stored == input.join('-');
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
              'Enter pattern',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (_error != null && _error!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
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
                  onInputComplete: (input) async {
                    if (await _verify(input)) {
                      widget.onSuccess();
                    } else {
                      setState(() {
                        _error = 'Incorrect pattern';
                      });
                    }
                  },
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

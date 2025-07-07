import 'package:flutter/material.dart';
import 'package:pattern_lock/pattern_lock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/secure_storage.dart';
import '../../theme.dart';

class PatternUnlockScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  const PatternUnlockScreen({super.key, required this.onSuccess});

  @override
  State<PatternUnlockScreen> createState() => _PatternUnlockScreenState();
}

class _PatternUnlockScreenState extends State<PatternUnlockScreen> {
  int _themeIdx = 0;
  final List<List<Color>> _gradients = [
    [Color(0xFFB16CEA), Color(0xFFFF5E69)],
    [Color(0xFFFF5E69), Color(0xFFFFA07A)],
    [Color(0xFF92FE9D), Color(0xFF00C9FF)],
    [Color(0xFFB1B5EA), Color(0xFFB993D6)],
    [Color(0xFF43E97B), Color(0xFF38F9D7)],
    [Color(0xFF667EEA), Color(0xFF64B6FF)],
    [Color(0xFF868686), Color(0xFFA3A3A3)],
    [Color(0xFFF797A6), Color(0xFFF9A8D4)],
  ];

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeIdx = prefs.getInt('selected_theme') ?? 0;
    });
  }

  Future<bool> _verify(List<int> input) async {
    final stored = await SecureStorage().getPattern();
    if (stored == null) return false;
    return stored == input.join('-');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
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
              Text(
                'Draw your pattern',
                style: const TextStyle(
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
      ),
    );
  }
}

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradients[_themeIdx],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: PatternLock(
                  selectedColor: Colors.white,
                  notSelectedColor: Colors.white54,
                  dimension: 3,
                  relativePadding: 0.7,
                  onInputComplete: (input) async {
                    if (await _verify(input)) {
                      widget.onSuccess();
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
      ),
    );
  }
}

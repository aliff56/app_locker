import 'dart:io';

import 'package:flutter/material.dart';
import '../../native_bridge.dart';

class IntruderPhotosScreen extends StatefulWidget {
  const IntruderPhotosScreen({Key? key}) : super(key: key);

  @override
  State<IntruderPhotosScreen> createState() => _IntruderPhotosScreenState();
}

class _IntruderPhotosScreenState extends State<IntruderPhotosScreen> {
  List<String> _paths = [];
  bool _loading = true;
  bool _enabled = true;
  int _threshold = 3;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _loadConfig();
  }

  Future<void> _loadPhotos() async {
    final list = await NativeBridge.getIntruderPhotos();
    if (mounted)
      setState(() {
        _paths = list..sort();
        _loading = false;
      });
  }

  Future<void> _loadConfig() async {
    final cfg = await NativeBridge.getIntruderConfig();
    if (mounted) {
      setState(() {
        _enabled = cfg['enabled'] as bool;
        _threshold = cfg['threshold'] as int;
      });
    }
  }

  Future<void> _saveConfig(bool enabled, int threshold) async {
    await NativeBridge.setIntruderConfig(
      enabled: enabled,
      threshold: threshold,
    );
    _loadConfig();
  }

  Future<void> _delete(String path) async {
    final success = await NativeBridge.deleteIntruderPhoto(path);
    if (success) {
      _loadPhotos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Intruder Selfies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const IntruderSelfieSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _paths.isEmpty
          ? const Center(child: Text('No intruder selfies yet'))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _paths.length,
              itemBuilder: (context, index) {
                final path = _paths[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _PhotoViewer(path: path),
                      ),
                    );
                  },
                  onLongPress: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete photo?'),
                        content: const Text('This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      _delete(path);
                    }
                  },
                  child: Hero(
                    tag: path,
                    child: Image.file(File(path), fit: BoxFit.cover),
                  ),
                );
              },
            ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  final String path;
  const _PhotoViewer({Key? key, required this.path}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: Hero(
          tag: path,
          child: InteractiveViewer(child: Image.file(File(path))),
        ),
      ),
    );
  }
}

// New settings screen for intruder selfie
class IntruderSelfieSettingsScreen extends StatefulWidget {
  const IntruderSelfieSettingsScreen({Key? key}) : super(key: key);

  @override
  State<IntruderSelfieSettingsScreen> createState() =>
      _IntruderSelfieSettingsScreenState();
}

class _IntruderSelfieSettingsScreenState
    extends State<IntruderSelfieSettingsScreen> {
  int _threshold = 3;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final cfg = await NativeBridge.getIntruderConfig();
    if (mounted) {
      setState(() {
        _threshold = cfg['threshold'] as int;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF162C65),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: Colors.white,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    child: InkWell(
                      onTap: _showChancesPicker,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Chances Allowed',
                                    style: TextStyle(
                                      color: Color(0xFF162C65),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_threshold times',
                                    style: const TextStyle(
                                      color: Color(0xFF162C65),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF162C65),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showChancesPicker() async {
    int tempValue = _threshold;
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: StatefulBuilder(
            builder: (context, setState) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      Expanded(
                        flex: 8,
                        child: Center(
                          child: Text(
                            'Chances Allowed',
                            style: const TextStyle(
                              color: Color(0xFF162C65),
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(
                              Icons.close,
                              color: Colors.black87,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(5, (i) {
                    final val = i + 1;
                    return RadioListTile<int>(
                      value: val,
                      groupValue: tempValue,
                      onChanged: (v) => setState(() => tempValue = v!),
                      title: Text(
                        '$val times',
                        style: const TextStyle(
                          color: Color(0xFF162C65),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      activeColor: const Color(0xFF162C65),
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF162C65),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(ctx, tempValue),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (result != null) {
      await _setThreshold(result);
    }
  }

  Future<void> _setThreshold(int value) async {
    setState(() {
      _threshold = value;
    });
    await NativeBridge.setIntruderConfig(enabled: true, threshold: value);
  }
}

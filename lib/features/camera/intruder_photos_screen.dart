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

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final list = await NativeBridge.getIntruderPhotos();
    if (mounted)
      setState(() {
        _paths = list..sort();
        _loading = false;
      });
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
      appBar: AppBar(title: const Text('Intruder Selfies')),
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

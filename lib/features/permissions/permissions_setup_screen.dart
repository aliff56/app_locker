import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/permissions_manager.dart';
import '../../theme.dart';

class PermissionsSetupScreen extends StatefulWidget {
  const PermissionsSetupScreen({Key? key, required this.onAllGranted})
    : super(key: key);

  final VoidCallback onAllGranted;

  @override
  State<PermissionsSetupScreen> createState() => _PermissionsSetupScreenState();
}

class _PermissionsSetupScreenState extends State<PermissionsSetupScreen> {
  bool _overlayGranted = false;
  bool _notificationGranted = false;
  bool _usageGranted = false;
  bool _cameraGranted = false;

  @override
  void initState() {
    super.initState();
    _refreshStatuses();
  }

  Future<void> _refreshStatuses() async {
    final overlay = await Permission.systemAlertWindow.isGranted;
    final notif = await Permission.notification.isGranted;
    final usage = await PermissionsManager.isUsageAccessGranted();
    final cam = await Permission.camera.isGranted;
    if (!mounted) return;
    setState(() {
      _overlayGranted = overlay;
      _notificationGranted = notif;
      _usageGranted = usage;
      _cameraGranted = cam;
    });
  }

  Future<void> _requestOverlay() async {
    await Permission.systemAlertWindow.request();
    _refreshStatuses();
  }

  Future<void> _requestNotification() async {
    await Permission.notification.request();
    _refreshStatuses();
  }

  Future<void> _requestUsage() async {
    await openAppSettings();
    _refreshStatuses();
  }

  Future<void> _requestCamera() async {
    await Permission.camera.request();
    _refreshStatuses();
  }

  Widget _buildCard(String title, bool granted, VoidCallback onGrant) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: const Color(0xFF8792BD),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!granted)
              ElevatedButton(onPressed: onGrant, child: const Text('Grant')),
            if (granted)
              const Icon(Icons.check_circle, color: Color(0xFF1AD36D)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allGranted =
        _overlayGranted &&
        _notificationGranted &&
        _usageGranted &&
        _cameraGranted;
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions required')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'To work properly, App Locker needs the following permissions. Grant each, then press Continue.',
                style: TextStyle(fontSize: 16),
              ),
            ),
            _buildCard('Usage Access', _usageGranted, _requestUsage),
            _buildCard('Overlay Permission', _overlayGranted, _requestOverlay),
            _buildCard(
              'Notification Access',
              _notificationGranted,
              _requestNotification,
            ),
            _buildCard('Camera Permission', _cameraGranted, _requestCamera),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B63B5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: allGranted ? widget.onAllGranted : null,
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

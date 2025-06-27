import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/permissions_manager.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;

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

  @override
  void initState() {
    super.initState();
    _refreshStatuses();
  }

  Future<void> _refreshStatuses() async {
    final overlay = await Permission.systemAlertWindow.isGranted;
    final notif = await Permission.notification.isGranted;
    final usage = await PermissionsManager.isUsageAccessGranted();
    setState(() {
      _overlayGranted = overlay;
      _notificationGranted = notif;
      _usageGranted = usage;
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

  Widget _buildRow(String label, bool granted, VoidCallback onPressed) {
    return ListTile(
      leading: Icon(
        granted ? Icons.check_circle : Icons.cancel,
        color: granted ? Colors.green : Colors.red,
      ),
      title: Text(label),
      trailing: granted
          ? const SizedBox.shrink()
          : ElevatedButton(onPressed: onPressed, child: const Text('Grant')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = _overlayGranted && _notificationGranted && _usageGranted;
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions required')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'To work properly, App Locker needs the following permissions. Grant each, then press Continue.',
              style: TextStyle(fontSize: 16),
            ),
          ),
          _buildRow(
            'Display over other apps',
            _overlayGranted,
            _requestOverlay,
          ),
          _buildRow(
            'Notifications',
            _notificationGranted,
            _requestNotification,
          ),
          _buildRow('Usage access', _usageGranted, _requestUsage),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: allGranted ? widget.onAllGranted : null,
                child: const Text('Continue →'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

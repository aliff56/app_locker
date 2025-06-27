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

  Widget _buildCard(
    String title,
    IconData icon,
    bool granted,
    VoidCallback onGrant,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: granted ? Colors.green : kPrimaryColor),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
            if (!granted)
              ElevatedButton(onPressed: onGrant, child: const Text('Grant')),
            if (granted) const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
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
          _buildCard(
            'Usage Access',
            Icons.visibility,
            _usageGranted,
            _requestUsage,
          ),
          _buildCard(
            'Overlay Permission',
            Icons.layers,
            _overlayGranted,
            _requestOverlay,
          ),
          _buildCard(
            'Notification Access',
            Icons.notifications,
            _notificationGranted,
            _requestNotification,
          ),
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

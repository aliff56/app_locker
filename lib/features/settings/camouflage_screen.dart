import 'package:flutter/material.dart';
import '../../native_bridge.dart';
import '../../theme.dart';

class CamouflageScreen extends StatelessWidget {
  CamouflageScreen({super.key});

  final List<_AliasOption> _options = const [
    _AliasOption(
      alias: 'com.example.app_locker.alias.DefaultAlias',
      label: 'Default',
      iconData: Icons.lock,
    ),
    _AliasOption(
      alias: 'com.example.app_locker.alias.CompassAlias',
      label: 'Compass',
      iconData: Icons.explore,
    ),
    _AliasOption(
      alias: 'com.example.app_locker.alias.CameraAlias',
      label: 'Camera',
      iconData: Icons.camera_alt,
    ),
    _AliasOption(
      alias: 'com.example.app_locker.alias.ClockAlias',
      label: 'Clock',
      iconData: Icons.access_time,
    ),
    _AliasOption(
      alias: 'com.example.app_locker.alias.CalendarAlias',
      label: 'Calendar',
      iconData: Icons.calendar_today,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camouflage App')),
      backgroundColor: Colors.white,
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final opt = _options[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE1E4EC)),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Icon(opt.iconData, color: const Color(0xFF162C65)),
              title: Text(
                opt.label,
                style: const TextStyle(
                  color: Color(0xFF162C65),
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Color(0xFF162C65),
              ),
              onTap: () async {
                await NativeBridge.setAppAlias(opt.alias);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Icon changed to ${opt.label}')),
                  );
                  Navigator.pop(context);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _AliasOption {
  final String alias;
  final String label;
  final IconData iconData;
  const _AliasOption({
    required this.alias,
    required this.label,
    required this.iconData,
  });
}

import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'locked_apps_manager.dart';

class LockedAppsScreen extends StatefulWidget {
  const LockedAppsScreen({super.key});

  @override
  State<LockedAppsScreen> createState() => _LockedAppsScreenState();
}

class _LockedAppsScreenState extends State<LockedAppsScreen> {
  List<String> _lockedApps = [];
  final _lockedAppsManager = LockedAppsManager();
  List<AppInfo>? _installedApps;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLockedApps();
    _loadInstalledApps();
  }

  Future<void> _loadLockedApps() async {
    try {
      final apps = await _lockedAppsManager.getLockedApps();
      if (mounted) {
        setState(() => _lockedApps = apps);
      }
    } catch (e) {
      debugPrint('Error loading locked apps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load locked apps')),
        );
      }
    }
  }

  Future<void> _loadInstalledApps() async {
    setState(() => _isLoading = true);
    try {
      final apps = await InstalledApps.getInstalledApps(true, true);
      if (mounted) {
        setState(() {
          _installedApps = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading installed apps: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load installed apps')),
        );
      }
    }
  }

  Future<void> _showAppSelectionDialog() async {
    if (_installedApps == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait while loading apps...')),
        );
      }
      return;
    }

    final selectedApp = await showDialog<AppInfo>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select App to Lock'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _installedApps!.length,
            itemBuilder: (context, index) {
              final app = _installedApps![index];
              return ListTile(
                leading: app.icon != null
                    ? Image.memory(app.icon!, width: 40, height: 40)
                    : const Icon(Icons.android),
                title: Text(app.name ?? 'Unknown App'),
                subtitle: Text(app.packageName),
                onTap: () => Navigator.of(context).pop(app),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedApp != null && mounted) {
      final packageName = selectedApp.packageName;
      if (!_lockedApps.contains(packageName)) {
        try {
          await _lockedAppsManager.addLockedApp(packageName);
          await _loadLockedApps();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${selectedApp.name ?? "App"} has been locked'),
              ),
            );
          }
        } catch (e) {
          debugPrint('Error adding locked app: $e');
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Failed to lock app')));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('App is already locked')),
          );
        }
      }
    }
  }

  Future<void> _removeApp(String packageName, String? appName) async {
    try {
      await _lockedAppsManager.removeLockedApp(packageName);
      await _loadLockedApps();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${appName ?? "App"} has been unlocked')),
        );
      }
    } catch (e) {
      debugPrint('Error removing locked app: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to unlock app')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Locked Apps')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lockedApps.isEmpty
          ? const Center(
              child: Text(
                'No apps locked yet.\nTap + to lock an app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _lockedApps.length,
              itemBuilder: (context, index) {
                final packageName = _lockedApps[index];
                return FutureBuilder<AppInfo?>(
                  future: InstalledApps.getAppInfo(
                    packageName,
                    BuiltWith.native_or_others,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        leading: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        title: Text('Loading...'),
                      );
                    }

                    final appInfo = snapshot.data;
                    if (appInfo == null) {
                      return ListTile(
                        leading: const Icon(Icons.error_outline),
                        title: Text('App not found: $packageName'),
                        subtitle: const Text('App might have been uninstalled'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeApp(packageName, null),
                        ),
                      );
                    }

                    return ListTile(
                      leading: appInfo.icon != null
                          ? Image.memory(appInfo.icon!, width: 40, height: 40)
                          : const Icon(Icons.android),
                      title: Text(appInfo.name ?? packageName),
                      subtitle: Text(packageName),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeApp(packageName, appInfo.name),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAppSelectionDialog,
        tooltip: 'Add App to Lock',
        child: const Icon(Icons.add),
      ),
    );
  }
}

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

  Future<void> _showAddAppsSheet() async {
    if (_installedApps == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Loading app list...')));
      return;
    }

    final selected = <String>{};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select apps to lock',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _installedApps!.length,
                  itemBuilder: (context, index) {
                    final app = _installedApps![index];
                    final isChecked = selected.contains(app.packageName);
                    return CheckboxListTile(
                      value: isChecked,
                      onChanged: (v) {
                        if (v == true) {
                          selected.add(app.packageName);
                        } else {
                          selected.remove(app.packageName);
                        }
                        (context as Element).markNeedsBuild();
                      },
                      title: Text(app.name ?? app.packageName),
                      secondary: app.icon != null
                          ? Image.memory(app.icon!, width: 40, height: 40)
                          : const Icon(Icons.android),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () async {
                            for (final pkg in selected) {
                              await _lockedAppsManager.addLockedApp(pkg);
                            }
                            await _loadLockedApps();
                            if (mounted) Navigator.pop(context);
                          },
                    child: const Text('Done'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  Widget _buildAppCard(AppInfo app, bool locked) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: ListTile(
        leading: app.icon != null
            ? Image.memory(app.icon!, width: 40, height: 40)
            : const Icon(Icons.android),
        title: Text(app.name ?? app.packageName),
        trailing: IconButton(
          icon: Icon(
            locked ? Icons.lock : Icons.lock_open,
            color: locked ? Colors.green : Colors.grey,
          ),
          onPressed: () async {
            if (locked) {
              await _removeApp(app.packageName, app.name);
            } else {
              await _lockedAppsManager.addLockedApp(app.packageName);
              await _loadLockedApps();
            }
          },
        ),
      ),
    );
  }

  Widget _buildLockedList() {
    return _isLoading
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
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  return _buildAppCard(snapshot.data!, true);
                },
              );
            },
          );
  }

  Widget _buildUnlockedList() {
    if (_isLoading || _installedApps == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final unlocked = _installedApps!
        .where((app) => !_lockedApps.contains(app.packageName))
        .toList();
    if (unlocked.isEmpty) {
      return const Center(child: Text('All apps are locked'));
    }
    return ListView.builder(
      itemCount: unlocked.length,
      itemBuilder: (context, index) => _buildAppCard(unlocked[index], false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Apps'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Locked'),
              Tab(text: 'Unlocked'),
            ],
          ),
        ),
        body: TabBarView(children: [_buildLockedList(), _buildUnlockedList()]),
      ),
    );
  }
}

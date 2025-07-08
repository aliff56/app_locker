import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import '../settings/settings_screen.dart';
import '../camera/intruder_photos_screen.dart';
import '../settings/camouflage_screen.dart';
import 'locked_apps_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:installed_apps/app_info.dart' as InstalledAppInfo;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
  String _filter = 'all';
  bool _showSearch = false;
  String _searchQuery = '';
  static List<AppInfo>? _cachedApps;
  static DateTime? _lastCacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);
  static const String _appsCacheKey = 'installed_apps_cache';
  static const String _appsCacheTimeKey = 'installed_apps_cache_time';
  final List<Map<String, dynamic>> _features = [
    {
      'label': 'Camouflage',
      'asset': 'assets/icon/camouflage.png',
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1C96FF), Color(0xFF88DEFF)],
      ),
      'screen': CamouflageScreen(),
    },
    {
      'label': 'Intruder',
      'asset': 'assets/icon/intruder.png',
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF03C8B4), Color(0xFF6FFBBC)],
      ),
      'screen': IntruderPhotosScreen(),
    },
    {
      'label': 'Themes',
      'asset': 'assets/icon/themes.png',
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF6A3A), Color(0xFFFB8A8E)],
      ),
      'screen': ThemeSelectionScreen(),
    },
    {
      'label': 'Setting',
      'asset': 'assets/icon/settings.png',
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC852FF), Color(0xFFD58CFF)],
      ),
      'screen': SettingsScreen(),
    },
  ];
  final List<Map<String, String>> _filters = [
    {'label': 'All', 'value': 'all'},
    {'label': 'Locked', 'value': 'locked'},
    {'label': 'Social', 'value': 'social'},
    {'label': 'System', 'value': 'system'},
    {'label': 'Hot', 'value': 'hot'},
  ];
  Map<String, Uint8List?> _iconCache = {};

  Future<void> _loadInstalledAppsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_appsCacheKey);
    final cacheTime = prefs.getInt(_appsCacheTimeKey);
    if (jsonStr != null && cacheTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - cacheTime < _cacheDuration.inMilliseconds) {
        try {
          final List<dynamic> decoded = jsonDecode(jsonStr);
          final cached = decoded
              .map(
                (e) => AppInfo(
                  packageName: e['packageName'],
                  name: e['name'],
                  icon: null, // icons are not cached
                  versionName: e['versionName'] ?? '',
                  versionCode: e['versionCode'] ?? 0,
                  builtWith: BuiltWith.native_or_others,
                  installedTimestamp: e['installedTimestamp'] ?? 0,
                ),
              )
              .toList();
          setState(() {
            _installedApps = cached;
            _isLoading = false;
          });
        } catch (e) {
          debugPrint('Error decoding cached app list: $e');
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLockedApps();
    _loadInstalledAppsFromCache();
    _loadInstalledApps(); // Always refresh in background
  }

  @override
  void didUpdateWidget(covariant LockedAppsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the app list changes, reload icons
    if (_installedApps != null && _iconCache.isEmpty) {
      _loadAllAppIcons(_installedApps!);
    }
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

  Future<void> _saveInstalledAppsToCache(List<AppInfo> apps) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(
      apps
          .map(
            (a) => {
              'packageName': a.packageName,
              'name': a.name,
              'versionName': a.versionName,
              'versionCode': a.versionCode,
              'installedTimestamp': a.installedTimestamp,
            },
          )
          .toList(),
    );
    await prefs.setString(_appsCacheKey, jsonStr);
    await prefs.setInt(
      _appsCacheTimeKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<List<AppInfo>> _getLaunchableAppsFromPlatform() async {
    const platform = MethodChannel('com.example.app_locker/native_bridge');
    final List<dynamic> result = await platform.invokeMethod(
      'getLaunchableApps',
    );
    return result
        .map(
          (e) => AppInfo(
            packageName: e['packageName'] as String,
            name: e['name'] as String,
            icon: null,
            versionName: '',
            versionCode: 0,
            builtWith: BuiltWith.native_or_others,
            installedTimestamp: 0,
          ),
        )
        .toList();
  }

  Future<void> _loadAllAppIcons(List<AppInfo> apps) async {
    const platform = MethodChannel('com.example.app_locker/native_bridge');
    final Map result = await platform.invokeMethod('getAllAppIcons');
    setState(() {
      _iconCache.clear();
      _iconCache.addAll(
        result.map(
          (key, value) =>
              MapEntry(key as String, base64Decode(value as String)),
        ),
      );
    });
  }

  Future<void> _loadInstalledApps({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      // Use persistent cache if not forceRefresh and cache is valid
      if (!forceRefresh) {
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = prefs.getString(_appsCacheKey);
        final cacheTime = prefs.getInt(_appsCacheTimeKey);
        if (jsonStr != null && cacheTime != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - cacheTime < _cacheDuration.inMilliseconds) {
            final List<dynamic> decoded = jsonDecode(jsonStr);
            final cached = decoded
                .map(
                  (e) => AppInfo(
                    packageName: e['packageName'],
                    name: e['name'],
                    icon: null, // icons are not cached
                    versionName: e['versionName'] ?? '',
                    versionCode: e['versionCode'] ?? 0,
                    builtWith: BuiltWith.native_or_others,
                    installedTimestamp: e['installedTimestamp'] ?? 0,
                  ),
                )
                .toList();
            setState(() {
              _installedApps = cached;
              _isLoading = false;
            });
            return;
          }
        }
      }
      // Use platform channel to get only launchable apps
      final apps = await _getLaunchableAppsFromPlatform();
      // Filter out AppLock itself
      final filteredApps = apps
          .where((a) => a.packageName != 'com.example.app_locker')
          .toList();
      _cachedApps = filteredApps;
      _lastCacheTime = DateTime.now();
      await _saveInstalledAppsToCache(filteredApps);
      if (mounted) {
        setState(() {
          _installedApps = filteredApps;
          _isLoading = false;
        });
        // Load all icons after setting the app list
        _loadAllAppIcons(filteredApps);
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

  // Use installed_apps for icon fetching
  Future<Uint8List?> getAppIcon(String packageName) async {
    if (_iconCache.containsKey(packageName)) {
      return _iconCache[packageName];
    }
    try {
      // Disk cache path
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/icon_$packageName.png');
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        _iconCache[packageName] = bytes;
        return bytes;
      }
      // Fetch from installed_apps
      final InstalledAppInfo.AppInfo? info = await InstalledApps.getAppInfo(
        packageName,
        BuiltWith.native_or_others,
      );
      if (info != null && info.icon != null) {
        await file.writeAsBytes(info.icon!);
        _iconCache[packageName] = info.icon;
        return info.icon;
      }
    } catch (e) {
      // ignore
    }
    _iconCache[packageName] = null;
    return null;
  }

  Widget _buildAppCard(AppInfo app, bool locked) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: ListTile(
        leading: FutureBuilder<Uint8List?>(
          future: getAppIcon(app.packageName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData &&
                snapshot.data != null) {
              return Image.memory(snapshot.data!, width: 56, height: 56);
            }
            return const Icon(Icons.android, size: 56);
          },
        ),
        title: Text(
          app.name ?? app.packageName,
          style: GoogleFonts.beVietnamPro(
            color: Color(0xFF162C65),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: IconButton(
          icon: locked
              ? const Icon(Icons.lock, color: Colors.green)
              : Image.asset(
                  'assets/icon/vector.png',
                  width: 24,
                  height: 24,
                  color: Colors.grey, // remove if PNG already styled
                ),
          onPressed: () async {
            if (locked) {
              final confirmed = await showDialog<bool>(
                context: context,
                barrierColor: Colors.black54,
                builder: (context) => Dialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Unlock App',
                          style: GoogleFonts.beVietnamPro(
                            color: kBgColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Are you sure you want to unlock this app?',
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.black87,
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: kCardColor,
                                  foregroundColor: kBgColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.beVietnamPro(
                                    color: kBgColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: kBgColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text(
                                  'Unlock',
                                  style: GoogleFonts.beVietnamPro(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
              if (confirmed == true) {
                await _removeApp(app.packageName, app.name);
              }
            } else {
              await _lockedAppsManager.addLockedApp(app.packageName);
              await _loadLockedApps();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162C65),
      body: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _showSearch
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            autofocus: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search apps...',
                              hintStyle: TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: const Color(0xFF223B7A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showSearch = false;
                                    _searchQuery = '';
                                  });
                                },
                              ),
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'App lock',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() => _showSearch = true);
                          },
                        ),
                      ],
                    ),
            ),
          ),
          // Feature buttons row with reduced side padding
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _features
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: _featureButton(context, f),
                    ),
                  )
                  .toList(),
            ),
          ),
          // White container with filter bar and app list
          Expanded(
            child: Stack(
              children: [
                // White container, visually shorter
                Positioned(
                  top: 36,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
                // Filter tabs and app list
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 60,
                        left: 12,
                        right: 12,
                        bottom: 8,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filters
                              .map((f) => _filterButton(f))
                              .toList(),
                        ),
                      ),
                    ),
                    Expanded(child: _buildFilteredList()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureButton(BuildContext context, Map<String, dynamic> f) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => f['screen'] as Widget));
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: f['gradient'] as LinearGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: f.containsKey('asset')
                  ? Image.asset(f['asset'] as String, width: 36, height: 36)
                  : (f['icon'] == FontAwesomeIcons.eyeSlash
                        ? Transform.translate(
                            offset: Offset(-4, 0),
                            child: Icon(
                              f['icon'] as IconData,
                              color: Colors.white,
                              size: 36,
                            ),
                          )
                        : Icon(
                            f['icon'] as IconData,
                            color: Colors.white,
                            size: 36,
                          )),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            f['label'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(Map<String, String> f) {
    final selected = _filter == f['value'];
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = f['value']!),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF162C65) : const Color(0xFFF4F5FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF162C65) : Colors.transparent,
            ),
            boxShadow: [
              if (!selected)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Text(
            f['label']!,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF162C65),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredList() {
    if (_isLoading || _installedApps == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadInstalledApps(forceRefresh: true);
      },
      child: _buildFilteredListContent(),
    );
  }

  Widget _buildFilteredListContent() {
    // Special case for "Locked" filter
    if (_filter == 'locked') {
      List<String> filtered = _lockedApps;
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((pkg) {
          final app = _installedApps!.firstWhere(
            (a) => a.packageName == pkg,
            orElse: () => AppInfo(
              name: pkg,
              icon: null,
              packageName: pkg,
              versionName: '',
              versionCode: 0,
              builtWith: BuiltWith.native_or_others,
              installedTimestamp: 0,
            ),
          );
          return (app.name ?? '').toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              pkg.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
      if (filtered.isEmpty) {
        return const Center(child: Text('No apps locked yet.'));
      }
      return ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final packageName = filtered[index];
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

    // All other filters use unlocked list logic
    List<AppInfo> unlocked = _installedApps!
        .where((app) => !_lockedApps.contains(app.packageName))
        .toList();

    switch (_filter) {
      case 'hot':
        unlocked.sort(
          (a, b) => b.installedTimestamp.compareTo(a.installedTimestamp),
        );
        break;
      case 'social':
        const socials = [
          'facebook',
          'instagram',
          'snapchat',
          'whatsapp',
          'twitter',
          'reddit',
          'tiktok',
          'wechat',
          'telegram',
        ];
        unlocked = unlocked.where((a) {
          final pkg = a.packageName.toLowerCase();
          return socials.any((s) => pkg.contains(s));
        }).toList();
        break;
      case 'system':
        unlocked = unlocked.where(_isSystemApp).toList();
        break;
      case 'all':
      default:
        break;
    }

    if (_searchQuery.isNotEmpty) {
      unlocked = unlocked.where((app) {
        return (app.name ?? '').toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            app.packageName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (unlocked.isEmpty) {
      return const Center(child: Text('No apps found.'));
    }
    return ListView.builder(
      itemCount: unlocked.length,
      itemBuilder: (context, index) => _buildAppCard(unlocked[index], false),
    );
  }

  bool _isSystemApp(AppInfo app) {
    final p = app.packageName;
    return p.startsWith('com.android') ||
        p.startsWith('com.google.android') ||
        p.startsWith('com.samsung') ||
        p.startsWith('com.miui');
  }
}

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  int _selectedTheme = 0;
  final List<List<Color>> _gradients = [
    // 1. Solid blue
    [Color(0xFF162C65), Color(0xFF162C65)],
    // 2. Pink gradient
    [Color(0xFFFF81A4), Color(0xFFCE4E72)],
    // 3. Beige-mint gradient (left-mid to right-mid)
    [Color(0xFFD8AAAE), Color(0xFFA2D1C9)],
    // 4. Blue-lavender gradient (left-mid to right-mid)
    [Color(0xFF8397EF), Color(0xFFCF9FE1)],
    // 5. Emerald-teal gradient (top to bottom)
    [Color(0xFF26D8BF), Color(0xFF228F80)],
    // 6. Aqua-royal gradient (top to bottom)
    [Color(0xFF8AE4FF), Color(0xFF0C6AB2)],
    // 7. Warm grey-violet gradient (top to bottom)
    [Color(0xFFC4BCCC), Color(0xFF806597)],
    // 8. Pink-magenta gradient (top to bottom)
    [Color(0xFFFFA8E2), Color(0xFFEF46B7)],
  ];

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTheme = prefs.getInt('selected_theme') ?? 0;
    });
  }

  Future<void> _applyTheme(int idx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_theme', idx);
    setState(() {
      _selectedTheme = idx;
    });
    // Sync with native SharedPreferences
    const bridge = MethodChannel('com.example.app_locker/native_bridge');
    try {
      await bridge.invokeMethod('setThemeIndex', idx);
    } catch (e) {}

    // Notify native side to close lock screen if open
    const platform = MethodChannel('app.locker/native');
    try {
      await platform.invokeMethod('themeChanged');
    } catch (e) {}

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Theme applied!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Themes'),
        backgroundColor: const Color(0xFF162C65),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 16,
            childAspectRatio: 0.55,
          ),
          itemCount: _gradients.length,
          itemBuilder: (context, idx) {
            final isSelected = _selectedTheme == idx;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _gradients[idx],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: _gradients[idx][0].withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 18),
                  const Icon(Icons.lock, color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter a pattern',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          physics: const NeverScrollableScrollPhysics(),
                          children: List.generate(
                            9,
                            (i) => Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              width: 12,
                              height: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Color(0xFF162C65),
                            size: 36,
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF162C65),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _applyTheme(idx),
                              child: const Text(
                                'Apply',
                                style: TextStyle(
                                  color: Color(0xFF162C65),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

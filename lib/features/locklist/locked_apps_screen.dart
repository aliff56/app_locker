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
  final List<Map<String, dynamic>> _features = [
    {
      'label': 'Camouflage',
      'icon': FontAwesomeIcons.eyeSlash,
      'gradient': LinearGradient(
        colors: [Color(0xFF6DD5FA), Color(0xFF2980F2)],
      ),
      'screen': CamouflageScreen(),
    },
    {
      'label': 'Intruder',
      'icon': FontAwesomeIcons.userSecret,
      'gradient': LinearGradient(
        colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
      ),
      'screen': IntruderPhotosScreen(),
    },
    {
      'label': 'Themes',
      'icon': FontAwesomeIcons.palette,
      'gradient': LinearGradient(
        colors: [Color(0xFFFF9068), Color(0xFFFF4B1F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'screen': ThemeSelectionScreen(),
    },
    {
      'label': 'Setting',
      'icon': FontAwesomeIcons.gear,
      'gradient': LinearGradient(
        colors: [Color(0xFFB36AFF), Color(0xFFFA8EFF)],
      ),
      'screen': SettingsScreen(),
    },
  ];
  final List<Map<String, String>> _filters = [
    {'label': 'All', 'value': 'all'},
    {'label': 'Locked', 'value': 'locked'},
    {'label': 'Social', 'value': 'social'},
    {'label': 'System', 'value': 'system'},
    {'label': 'HOT', 'value': 'hot'},
  ];

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
      final apps = await InstalledApps.getInstalledApps(false, true);
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
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: ListTile(
        leading: app.icon != null
            ? Image.memory(app.icon!, width: 56, height: 56)
            : const Icon(Icons.android, size: 56),
        title: Text(
          app.name ?? app.packageName,
          style: GoogleFonts.plusJakartaSans(
            color: Color(0xFF162C65),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            locked ? Icons.lock : Icons.lock_open,
            color: locked ? Colors.green : Colors.grey,
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
          // Feature buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: f['icon'] == FontAwesomeIcons.eyeSlash
                  ? Transform.translate(
                      offset: Offset(-4, 0),
                      child: Icon(
                        f['icon'] as IconData,
                        color: Colors.white,
                        size: 30,
                      ),
                    )
                  : Icon(f['icon'] as IconData, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            f['label'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
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
            borderRadius: BorderRadius.circular(16),
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
                            size: 32,
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

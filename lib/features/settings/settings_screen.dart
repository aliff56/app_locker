import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom_button.dart';
import '../../data/constants.dart';
import '../auth/pin_setup_screen.dart';
import '../permissions/permissions_setup_screen.dart';
import '../../main.dart';
import 'camouflage_screen.dart';
import '../../core/secure_storage.dart';
import '../auth/pattern_setup_screen.dart';
import '../../native_bridge.dart';
import '../camera/intruder_photos_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../auth/pattern_unlock_screen.dart';
import '../auth/applock_pin_unlock.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  String _currentLockType = 'pin';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLockType();
    _loadAdminStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force portrait orientation on this screen for consistent layout (optional)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Restore system orientations
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAdminStatus();
    }
  }

  Future<void> _loadLockType() async {
    final type = await SecureStorage().getLockType();
    if (mounted) setState(() => _currentLockType = type);
  }

  Future<void> _loadAdminStatus() async {
    final status = await NativeBridge.isAdminActive();
    if (mounted) setState(() => _isAdmin = status);
  }

  Future<void> _chooseLockType() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Lock Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF162C65),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.password, color: Color(0xFF162C65)),
                title: const Text(
                  'PIN',
                  style: TextStyle(color: Color(0xFF162C65)),
                ),
                onTap: () => Navigator.pop(ctx, 'pin'),
              ),
              ListTile(
                leading: const Icon(Icons.grid_3x3, color: Color(0xFF162C65)),
                title: const Text(
                  'Pattern',
                  style: TextStyle(color: Color(0xFF162C65)),
                ),
                onTap: () => Navigator.pop(ctx, 'pattern'),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      await SecureStorage().saveLockType(selected);
      setState(() => _currentLockType = selected);
      if (selected == 'pattern') {
        // push pattern setup
        if (context.mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PatternSetupScreen(
                onSetupComplete: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          );
        }
      } else {
        // pin setup
        if (context.mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PinSetupScreen(
                onSetupComplete: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _openPermissions() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PermissionsSetupScreen(
          onAllGranted: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _changePinOrPattern() async {
    if (_currentLockType == 'pattern') {
      // Require current pattern first
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PatternUnlockScreen(
            onSuccess: () {
              Navigator.of(context).pop(true);
            },
          ),
        ),
      );
      if (verified == true && context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PatternSetupScreen(
              onSetupComplete: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    } else {
      // Require current PIN first
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AppLockPinUnlock(
            onSuccess: () {
              Navigator.of(context).pop(true);
            },
          ),
        ),
      );
      if (verified == true && context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PinSetupScreen(
              onSetupComplete: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _sendFeedbackEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'aag44105@gmail.com',
      query: Uri.encodeFull('subject=App Locker Feedback'),
    );
    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the email app.')),
        );
      }
    }
  }

  Future<void> _showRatingDialog() async {
    const blue = kBgColor;
    int rating = 0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Widget _buildEmoji() {
              late String emoji;
              late String msg;
              late Color iconColor;

              if (rating == 0) {
                emoji = '😃';
                msg = 'Give us a Rating';
                iconColor = kPrimaryColor;
              } else if (rating == 5) {
                emoji = '😁';
                msg = 'We like you too!';
                iconColor = Colors.green;
              } else if (rating == 4) {
                emoji = '😊';
                msg = 'Thanks for the rating!';
                iconColor = Colors.green;
              } else if (rating == 3) {
                emoji = '😐';
                msg = 'Appreciate your feedback!';
                iconColor = kPrimaryColor;
              } else if (rating == 2) {
                emoji = '🙁';
                msg = "We'll try to do better.";
                iconColor = Colors.orange;
              } else {
                emoji = '😞';
                msg = "We're sorry to hear that.";
                iconColor = Colors.redAccent;
              }

              return Column(
                children: [
                  const SizedBox(height: 16),
                  Text(emoji, style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kBgColor,
                    ),
                  ),
                ],
              );
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              title: Center(
                child: Text(
                  'Rate Us !',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kBgColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final selected = index < rating;
                      return IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                        onPressed: () => setState(() => rating = index + 1),
                        icon: Icon(
                          selected
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: selected ? kBgColor : kCardColor,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  _buildEmoji(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBgColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Play Store link coming soon!'),
                            ),
                          );
                        }
                      },
                      child: const Text('Rate on Play Store'),
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'No thanks',
                      style: TextStyle(color: kBgColor),
                    ),
                  ),
                ],
              ),
              actions: const [],
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            );
          },
        );
      },
    );
  }

  Future<void> _shareApp() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share App',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kBgColor,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.share, color: kBgColor),
                title: const Text('Share', style: TextStyle(color: kBgColor)),
                onTap: () {
                  Share.share('LINK');
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_copy, color: kBgColor),
                title: const Text(
                  'Copy Link',
                  style: TextStyle(color: kBgColor),
                ),
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: 'LINK'));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard.')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
    bool showArrow = false,
  }) {
    const borderColor = Color(0xFFE1E4EC);
    const blue = kBgColor;
    final bgColor = active ? blue : Colors.white;
    final textColor = active ? Colors.white : blue;
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: active ? null : Border.all(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: textColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (showArrow) Icon(Icons.chevron_right, color: textColor),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(Constants.settingsTitle)),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _menuItem(
            icon: Icons.lock,
            label: _currentLockType == 'pattern'
                ? 'Change Pattern'
                : 'Change PIN',
            onTap: _changePinOrPattern,
          ),
          const SizedBox(height: 16),
          _menuItem(
            icon: Icons.verified_user_sharp,
            label: _isAdmin
                ? 'Self- Protection : ON'
                : 'Self- Protection : OFF',
            onTap: () async {
              if (_isAdmin) {
                await NativeBridge.disableAdmin();
              } else {
                await NativeBridge.enableAdmin();
              }
              await Future.delayed(const Duration(milliseconds: 500));
              _loadAdminStatus();
            },
            active: _isAdmin,
          ),
          const SizedBox(height: 16),
          _menuItem(
            icon: Icons.app_registration_rounded,
            label:
                'Lock Type: ${_currentLockType[0].toUpperCase()}${_currentLockType.substring(1)}',
            active: true,
            onTap: _chooseLockType,
          ),
          const SizedBox(height: 16),
          _menuItem(
            icon: Icons.shield_sharp,
            label: 'Check Permissions',
            onTap: _openPermissions,
          ),
          const SizedBox(height: 16),
          _menuItem(
            icon: FontAwesomeIcons.shareNodes,
            label: 'Share With Friends',
            onTap: _shareApp,
          ),
          const SizedBox(height: 16),
          _menuItem(
            icon: FontAwesomeIcons.solidMessage,
            label: 'Feedback',
            onTap: _sendFeedbackEmail,
          ),
          const SizedBox(height: 16),
          _menuItem(
            icon: FontAwesomeIcons.solidThumbsUp,
            label: 'Rate Us',
            onTap: _showRatingDialog,
          ),
          const SizedBox(height: 16),
          _menuItem(
            icon: FontAwesomeIcons.fileShield,
            label: 'Privacy Policy',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _menuItem(
            icon: FontAwesomeIcons.doorOpen,
            label: 'Exit',
            onTap: () {
              SystemNavigator.pop();
            },
          ),
        ],
      ),
    );
  }
}

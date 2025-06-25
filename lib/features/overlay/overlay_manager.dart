import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../auth/pin_screen.dart';

class OverlayManager {
  static final OverlayManager _instance = OverlayManager._internal();
  factory OverlayManager() => _instance;
  OverlayManager._internal();

  OverlayEntry? _currentOverlay;
  String? _currentPackage;
  // We no longer need the key, but we will store the state directly.
  static OverlayState? _overlayState;

  void init(OverlayState overlayState) {
    _overlayState = overlayState;
  }

  static const _overlayOpacity = 0.95; // Increased opacity for better security

  Future<void> showLockScreen(String packageName) async {
    debugPrint('🚀 [AppLocker] --- OverlayManager:showLockScreen ---');
    debugPrint(
      '   [AppLocker] Attempting to show lock screen for: $packageName',
    );
    // Don't show if already showing for this package
    if (_currentPackage == packageName && _currentOverlay != null) {
      debugPrint(
        '   [AppLocker] Lock screen already visible for this package.',
      );
      return;
    }

    // Clean up any existing overlay first
    hideLockScreen();

    try {
      // Verify overlay permission before showing
      if (!await Permission.systemAlertWindow.isGranted) {
        debugPrint('   [AppLocker] ❌ Overlay permission not granted.');
        return;
      }

      if (_overlayState == null) {
        debugPrint('   [AppLocker] ❌ OverlayState is not initialized.');
        return;
      }

      _currentPackage = packageName;
      _currentOverlay = OverlayEntry(
        maintainState: true,
        opaque: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false, // Prevent back button
          child: Material(
            color: Colors.black.withOpacity(_overlayOpacity),
            child: SafeArea(
              child: PinScreen(
                onSuccess: () {
                  debugPrint('   [AppLocker] PIN success. Hiding lock screen.');
                  hideLockScreen();
                },
                onError: (error) {
                  // Show error if PIN verification fails
                  debugPrint('   [AppLocker] PIN error: $error');
                  if (_overlayState?.context != null) {
                    ScaffoldMessenger.of(
                      _overlayState!.context,
                    ).showSnackBar(SnackBar(content: Text(error)));
                  }
                },
              ),
            ),
          ),
        ),
      );

      // Use addPostFrameCallback to ensure the context is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_overlayState?.context.mounted == true) {
          try {
            debugPrint('   [AppLocker] Inserting overlay into the tree.');
            _overlayState?.insert(_currentOverlay!);
          } catch (e) {
            debugPrint('   [AppLocker] ❌ Error inserting overlay: $e');
            _cleanup();
          }
        } else {
          debugPrint(
            '   [AppLocker] ❌ Context is not mounted. Cannot insert overlay.',
          );
        }
      });
    } catch (e) {
      debugPrint('   [AppLocker] ❌ Error showing lock screen: $e');
      _cleanup();
    }
  }

  void hideLockScreen() {
    debugPrint('🚀 [AppLocker] --- OverlayManager:hideLockScreen ---');
    try {
      if (_currentOverlay != null) {
        debugPrint('   [AppLocker] Removing current overlay.');
        _currentOverlay?.remove();
        _cleanup();
      } else {
        debugPrint('   [AppLocker] No overlay to hide.');
      }
    } catch (e) {
      debugPrint('   [AppLocker] ❌ Error hiding lock screen: $e');
      _cleanup();
    }
  }

  void _cleanup() {
    debugPrint('🚀 [AppLocker] --- OverlayManager:_cleanup ---');
    _currentOverlay = null;
    _currentPackage = null;
  }

  Future<void> handleNotificationMessage(String message) async {
    debugPrint(
      '🚀 [AppLocker] --- OverlayManager:handleNotificationMessage ---',
    );
    debugPrint('   [AppLocker] Received message: "$message"');
    if (message.startsWith('LOCKED:')) {
      final package = message.substring(7);
      // We no longer need to find the context here, just call the method.
      debugPrint(
        '   [AppLocker] Received lock command for $package. Showing screen.',
      );
      await showLockScreen(package);
    }
  }

  // Check if overlay is currently showing
  bool get isOverlayVisible => _currentOverlay != null;

  // Get current locked package
  String? get currentLockedPackage => _currentPackage;
}

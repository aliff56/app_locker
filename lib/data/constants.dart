import 'package:flutter/material.dart';

class Constants {
  // Colors
  static const Color lockScreenBgColor = Color(0xE6000000);

  // Strings
  static const String pinHint = 'Enter PIN';
  static const String unlockBtn = 'Unlock';
  static const String biometricBtn = 'Unlock with Biometrics';
  static const String invalidPinMsg = 'Invalid PIN. Try again.';
  static const String biometricPromptMsg = 'Authenticate to unlock';
  static const String biometricFailedMsg = 'Biometric authentication failed.';
  static const String failedAttemptsLabel = 'Failed Attempts';
  static const String setPinTitle = 'Set PIN';
  static const String changePinTitle = 'Change PIN';
  static const String enterPinHint = 'Enter new PIN';
  static const String confirmPinHint = 'Confirm new PIN';
  static const String pinTooShortMsg = 'PIN must be at least 4 digits.';
  static const String pinMismatchMsg = 'PINs do not match.';
  static const String savePinBtn = 'Save PIN';
  static const String settingsTitle = 'Settings';
  static const String biometricSettingLabel = 'Enable Biometrics';
  static const String changePinBtn = 'Change PIN';
  static const String permissionDeniedTitle = 'Permission Required';
  static const String permissionDeniedMsg =
      'This permission is required for the app to function. Please grant it in settings.';
  static const String openSettingsBtn = 'Open Settings';
  static const String cameraErrorMsg =
      'Camera error. Please check permissions.';
  static const String storageErrorMsg =
      'Storage error. Please check permissions.';

  // Keys
  static const String failedAttemptsKey = 'failed_attempts';

  // Helper for locked app message
  static String lockedAppMsg(String packageName) => 'Locked App: $packageName';
}

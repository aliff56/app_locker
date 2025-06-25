import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'local_foreground_app_platform_interface.dart';

/// An implementation of [LocalForegroundAppPlatform] that uses method channels.
class MethodChannelLocalForegroundApp extends LocalForegroundAppPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('local_foreground_app');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}

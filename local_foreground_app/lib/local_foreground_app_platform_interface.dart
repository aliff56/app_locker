import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'local_foreground_app_method_channel.dart';

abstract class LocalForegroundAppPlatform extends PlatformInterface {
  /// Constructs a LocalForegroundAppPlatform.
  LocalForegroundAppPlatform() : super(token: _token);

  static final Object _token = Object();

  static LocalForegroundAppPlatform _instance =
      MethodChannelLocalForegroundApp();

  /// The default instance of [LocalForegroundAppPlatform] to use.
  ///
  /// Defaults to [MethodChannelLocalForegroundApp].
  static LocalForegroundAppPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LocalForegroundAppPlatform] when
  /// they register themselves.
  static set instance(LocalForegroundAppPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

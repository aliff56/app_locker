import 'package:flutter_test/flutter_test.dart';
import 'package:local_foreground_app/local_foreground_app.dart';
import 'package:local_foreground_app/local_foreground_app_platform_interface.dart';
import 'package:local_foreground_app/local_foreground_app_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLocalForegroundAppPlatform
    with MockPlatformInterfaceMixin
    implements LocalForegroundAppPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final LocalForegroundAppPlatform initialPlatform =
      LocalForegroundAppPlatform.instance;

  test('$MethodChannelLocalForegroundApp is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLocalForegroundApp>());
  });

  test('getPlatformVersion', () async {
    LocalForegroundApp localForegroundAppPlugin = LocalForegroundApp();
    MockLocalForegroundAppPlatform fakePlatform =
        MockLocalForegroundAppPlatform();
    LocalForegroundAppPlatform.instance = fakePlatform;

    expect(await localForegroundAppPlugin.getPlatformVersion(), '42');
  });
}

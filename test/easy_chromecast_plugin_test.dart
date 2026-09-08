import 'package:flutter_test/flutter_test.dart';
import 'package:easy_chromecast_plugin/easy_chromecast_plugin.dart';
import 'package:easy_chromecast_plugin/easy_chromecast_plugin_platform_interface.dart';
import 'package:easy_chromecast_plugin/easy_chromecast_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEasyChromecastPluginPlatform
    with MockPlatformInterfaceMixin
    implements EasyChromecastPluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final EasyChromecastPluginPlatform initialPlatform = EasyChromecastPluginPlatform.instance;

  test('$MethodChannelEasyChromecastPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEasyChromecastPlugin>());
  });

  test('getPlatformVersion', () async {
    EasyChromecastPlugin easyChromecastPlugin = EasyChromecastPlugin();
    MockEasyChromecastPluginPlatform fakePlatform = MockEasyChromecastPluginPlatform();
    EasyChromecastPluginPlatform.instance = fakePlatform;

    expect(await easyChromecastPlugin.getPlatformVersion(), '42');
  });
}

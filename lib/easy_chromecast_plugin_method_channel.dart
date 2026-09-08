import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'easy_chromecast_plugin_platform_interface.dart';

/// An implementation of [EasyChromecastPluginPlatform] that uses method channels.
class MethodChannelEasyChromecastPlugin extends EasyChromecastPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('easy_chromecast_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}

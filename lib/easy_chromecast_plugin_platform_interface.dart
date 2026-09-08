import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'easy_chromecast_plugin_method_channel.dart';

abstract class EasyChromecastPluginPlatform extends PlatformInterface {
  /// Constructs a EasyChromecastPluginPlatform.
  EasyChromecastPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static EasyChromecastPluginPlatform _instance = MethodChannelEasyChromecastPlugin();

  /// The default instance of [EasyChromecastPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelEasyChromecastPlugin].
  static EasyChromecastPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EasyChromecastPluginPlatform] when
  /// they register themselves.
  static set instance(EasyChromecastPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

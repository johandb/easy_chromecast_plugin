// Dit bestand zorgt ervoor dat de iOS en Android compilers niet crashen op de web-code
class EasyChromecastPluginWeb {
  static Future<void> initializeCast() async {}
  static Future<bool> isConnected() async => false;
  static Future<void> showCastDialog() async {}
  static Future<void> playMedia(String url, String title) async {}
  static Future<void> pauseMedia() async {}
  static Future<void> resumeMedia() async {}
  static Future<void> seekMedia(int positionInSeconds) async {}
  static Future<void> stopMedia() async {}
  static Future<void> setVolume(double volume) async {}
  static Future<void> disconnectDevice() async {}
}

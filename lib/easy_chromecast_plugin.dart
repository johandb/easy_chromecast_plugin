// lib/easy_chromecast_plugin.dart
import 'src/pigeon/cast_api.g.dart';

class EasyChromecastPlugin {
  // Initialiseer de host API die Pigeon voor ons heeft gegenereerd
  final ChromecastHostApi _api = ChromecastHostApi();

  /// Initialiseer de Google Cast SDK op Android.
  /// Moet vroeg in de app-lifecycle worden aangeroepen.
  Future<void> initializeCast() async {
    await _api.initializeCast();
  }

  /// Controleer of er momenteel een actieve verbinding is met een Chromecast.
  Future<bool> isConnected() async {
    return await _api.isConnected();
  }

  /// Start het afspelen van een video op de Chromecast.
  Future<void> playMedia({required String url, required String title}) async {
    final request = CastMediaRequest(url: url, title: title);
    await _api.playMedia(request);
  }
  
  /// Opent het officiële native Android-dialoogvenster om een Chromecast te selecteren.
  Future<void> showCastDialog() async {
    await _api.showCastDialog();
  }  

  /// Stop het afspelen van de huidige media.
  Future<void> stopMedia() async {
    await _api.stopMedia();
  }
}

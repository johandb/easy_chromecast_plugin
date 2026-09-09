// lib/easy_chromecast_plugin.dart
import 'dart:async';
import 'src/pigeon/cast_api.g.dart';

// Voeg 'implements ChromecastFlutterApi' toe zodat deze klasse naar native events kan luisteren
class EasyChromecastPlugin implements ChromecastFlutterApi {
  
  // Initialiseer de Host API die door Pigeon is gegenereerd
  final ChromecastHostApi _api = ChromecastHostApi();

  // StreamController om de status door te geven aan de app
  static final StreamController<bool> _connectionStreamController = StreamController<bool>.broadcast();
  
  /// Publieke stream waar de gebruiker naar kan luisteren voor verbindingsupdates.
  Stream<bool> get onConnectionChanged => _connectionStreamController.stream;
  
  EasyChromecastPlugin() {
    // Let op de hoofdletter 'U' bij setUp
    ChromecastFlutterApi.setUp(this);
  }  
  
  // Dit is de methode die automatisch vanuit Android/iOS wordt aangeroepen via Pigeon
  @override
  void onConnectionStatusChanged(bool isConnected) {
    _connectionStreamController.add(isConnected);
  }

  /// Initialiseer de Google Cast SDK.
  /// Moet vroeg in de app-lifecycle worden aangeroepen.
  Future<void> initializeCast() async {
    await _api.initializeCast();
  }

  /// Controleer of er momenteel een actieve verbinding is met een Chromecast.
  Future<bool> isConnected() async {
    return await _api.isConnected();
  }

  /// Opent het officiële native dialoogvenster om een Chromecast te selecteren.
  Future<void> showCastDialog() async {
    await _api.showCastDialog();
  }  

  /// Start het afspelen van een video op de Chromecast.
  Future<void> playMedia({required String url, required String title}) async {
    final request = CastMediaRequest(url: url, title: title);
    await _api.playMedia(request);
  }

  /// Pauzeer de video die momenteel op de Chromecast afspeelt.
  Future<void> pauseMedia() async {
    await _api.pauseMedia();
  }

  /// Hervat de gepauzeerde video op de Chromecast.
  Future<void> resumeMedia() async {
    await _api.resumeMedia();
  }

  /// Spoel naar een specifieke seconde in de video op de Chromecast.
  Future<void> seekMedia(int positionInSeconds) async {
    await _api.seekMedia(positionInSeconds);
  }
  
  /// Stop het afspelen van de huidige media.
  Future<void> stopMedia() async {
    await _api.stopMedia();
  }
 
  /// Disconnect device 
  Future<void> disconnectDevice() async {
    await _api.disconnectDevice();
  }
}

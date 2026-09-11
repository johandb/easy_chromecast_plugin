import 'dart:async';
import 'package:flutter/foundation.dart'; // Importeer kIsWeb
import 'src/pigeon/cast_api.g.dart';

// FIX: Laad de weblaag conditioneel via het absolute package pad
import 'package:easy_chromecast_plugin/easy_chromecast_plugin_web.dart' 
    if (dart.library.io) 'package:easy_chromecast_plugin/easy_chromecast_plugin_web_stub.dart';

class EasyChromecastPlugin implements ChromecastFlutterApi {
  final ChromecastHostApi _api = ChromecastHostApi();
  static final StreamController<bool> _connectionStreamController = StreamController<bool>.broadcast();
  
  Stream<bool> get onConnectionChanged => _connectionStreamController.stream;
  
  EasyChromecastPlugin();
  
  /// Check the connection change
  @override
  void onConnectionStatusChanged(bool isConnected) {
    _connectionStreamController.add(isConnected);
  }

  /// Initialiseer de Google Cast SDK.
  Future<void> initializeCast() async {
    if (kIsWeb) {
      await EasyChromecastPluginWeb.initializeCast();
    } else {
      ChromecastFlutterApi.setUp(this);
      await _api.initializeCast();
    }
  }

  /// Controleer of er momenteel een actieve verbinding is.
  Future<bool> isConnected() async {
    if (kIsWeb) {
      return await EasyChromecastPluginWeb.isConnected();
    } else {
      return await _api.isConnected();
    }
  }

  /// Opent het dialoogvenster.
  Future<void> showCastDialog() async {
    if (kIsWeb) {
      await EasyChromecastPluginWeb.showCastDialog();
    } else {
      await _api.showCastDialog();
    }
  }  

  /// Start het afspelen van een video.
  Future<void> playMedia({required String url, required String title}) async {
    if (kIsWeb) {
      await EasyChromecastPluginWeb.playMedia(url, title);
    } else {
      final request = CastMediaRequest(url: url, title: title);
      await _api.playMedia(request);
    }
  }

  /// Pause the media
  Future<void> pauseMedia() async {
    if (kIsWeb) { await EasyChromecastPluginWeb.pauseMedia(); } else { await _api.pauseMedia(); }
  }

  /// Continue playing media 
  Future<void> resumeMedia() async {
    if (kIsWeb) { await EasyChromecastPluginWeb.resumeMedia(); } else { await _api.resumeMedia(); }
  }

  /// Seek to a specific position
  Future<void> seekMedia(int positionInSeconds) async {
    if (kIsWeb) { await EasyChromecastPluginWeb.seekMedia(positionInSeconds); } else { await _api.seekMedia(positionInSeconds); }
  }
  
  /// Stop playing media
  Future<void> stopMedia() async {
    if (kIsWeb) { await EasyChromecastPluginWeb.stopMedia(); } else { await _api.stopMedia(); }
  }
 
  /// Disconnect the chromecast device
  Future<void> disconnectDevice() async {
    if (kIsWeb) { await EasyChromecastPluginWeb.disconnectDevice(); } else { await _api.disconnectDevice(); }
  }
}

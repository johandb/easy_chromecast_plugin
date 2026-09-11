import 'dart:async';
// FIX: Veranderd naar de moderne, door Google vereiste js_interop bibliotheek!
import 'dart:js_interop'; 
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class EasyChromecastPluginWeb {
  
  static void registerWith(Registrar registrar) {
    // Succesvol geregistreerd voor de Flutter Web Engine
  }

  static Future<void> initializeCast() async {
    _eval('''
      if (window.cast && cast.framework) {
        var context = cast.framework.CastContext.getInstance();
        context.setOptions({
          receiverApplicationId: chrome.cast.media.DEFAULT_MEDIA_RECEIVER_APP_ID,
          autoJoinPolicy: chrome.cast.AutoJoinPolicy.ORIGIN_SCOPED
        });
        window.isChromecastSdkReady = true;
        console.log('Google Cast Web SDK met succes geactiveerd in Chrome!');
      }
    ''');
  }

  static Future<bool> isConnected() async {
    final result = _eval("window.isChromecastSdkReady && cast.framework.CastContext.getInstance().getCastState() === 'CONNECTED'");
    return result == true;
  }

  static Future<void> showCastDialog() async {
    _eval('''
      if (window.isChromecastSdkReady) {
        cast.framework.CastContext.getInstance().requestSession()
          .then(function() { console.log('Sessie succesvol gestart!'); })
          .catch(function(err) { console.log('Cast popup gesloten of fout: ' + err); });
      } else {
        alert('Google Cast SDK is nog niet gereed in Chrome. Controleer je wifi-verbinding.');
      }
    ''');
  }

  static Future<void> playMedia(String url, String title) async {
    _eval('''
      var castSession = cast.framework.CastContext.getInstance().getCurrentSession();
      if (castSession) {
        var mediaInfo = new chrome.cast.media.MediaInfo('$url', 'video/mp4');
        mediaInfo.metadata = new chrome.cast.media.MovieMediaMetadata();
        mediaInfo.metadata.title = '$title';
        
        var loadRequest = new chrome.cast.media.LoadRequest(mediaInfo);
        castSession.loadMedia(loadRequest);
      }
    ''');
  }

  static Future<void> pauseMedia() async { 
    _eval("cast.framework.CastContext.getInstance().getCurrentSession()?.getMediaSession()?.pause();"); 
  }

  static Future<void> resumeMedia() async { 
    _eval("cast.framework.CastContext.getInstance().getCurrentSession()?.getMediaSession()?.play();"); 
  }

  static Future<void> stopMedia() async { 
    _eval("cast.framework.CastContext.getInstance().getCurrentSession()?.getMediaSession()?.stop();"); 
  }

  static Future<void> disconnectDevice() async { 
    _eval("cast.framework.CastContext.getInstance().getCurrentSession()?.endSession(true);"); 
  }

  static Future<void> seekMedia(int positionInSeconds) async {
    _eval('''
      var mediaSession = cast.framework.CastContext.getInstance().getCurrentSession()?.getMediaSession();
      if (mediaSession) {
        var seekRequest = new chrome.cast.media.SeekRequest();
        seekRequest.currentTime = $positionInSeconds;
        mediaSession.seek(seekRequest);
      }
    ''');
  }

  // Interop helper die eval aanroept via de nieuwe js_interop standaarden
  static dynamic _eval(String source) {
    try {
      return (globalContext.getProperty('eval'.toJS) as JSFunction).call(null, source.toJS);
    } catch (e) {
      print(e);
      return null;
    }
  }
}

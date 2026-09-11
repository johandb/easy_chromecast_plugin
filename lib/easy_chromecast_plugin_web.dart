import 'dart:async';
import 'dart:js' as js;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class EasyChromecastPluginWeb {
  
  // Dit is de methode die de web_plugin_registrant.dart zoekt!
  static void registerWith(Registrar registrar) {
    // Registratie succesvol voor Flutter Web Engine
    js.context.callMethod('eval', ["console.log('EasyChromecastPluginWeb geregistreerd!');"]);
  }

  static Future<void> initializeCast() async {
    int pogingen = 0;
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      pogingen++;
      
      js.context.callMethod('eval', ['''
        if (window.cast && cast.framework) {
          var context = cast.framework.CastContext.getInstance();
          context.setOptions({
            receiverApplicationId: chrome.cast.media.DEFAULT_MEDIA_RECEIVER_APP_ID,
            autoJoinPolicy: chrome.cast.AutoJoinPolicy.ORIGIN_SCOPED
          });
          window.isChromecastSdkReady = true;
          console.log('Google Cast Web SDK met succes geactiveerd in Chrome!');
        }
      ''']);

      final isReady = js.context.callMethod('eval', ["window.isChromecastSdkReady === true"]);
      if (isReady == true || pogingen > 10) {
        timer.cancel();
        if (isReady != true) {
          // FIX: Veranderd van console.log naar Dart's eigen print()
          print('Waarschuwing: Chromecast SDK laden duurt langer dan normaal.');
        }
      }
    });
  }

  static Future<bool> isConnected() async {
    final result = js.context.callMethod('eval', [
      "window.isChromecastSdkReady && cast.framework.CastContext.getInstance().getCastState() === 'CONNECTED'"
    ]);
    return result == true;
  }

  static Future<void> showCastDialog() async {
    js.context.callMethod('eval', ['''
      if (window.isChromecastSdkReady) {
        cast.framework.CastContext.getInstance().requestSession()
          .then(function() { console.log('Sessie succesvol gestart!'); })
          .catch(function(err) { console.log('Cast popup gesloten of fout: ' + err); });
      } else {
        alert('Google Cast SDK is nog niet gereed in Chrome. Controleer je wifi-verbinding.');
      }
    ''']);
  }

  static Future<void> playMedia(String url, String title) async {
    js.context.callMethod('eval', ['''
      var castSession = cast.framework.CastContext.getInstance().getCurrentSession();
      if (castSession) {
        var mediaInfo = new chrome.cast.media.MediaInfo('$url', 'video/mp4');
        mediaInfo.metadata = new chrome.cast.media.MovieMediaMetadata();
        mediaInfo.metadata.title = '$title';
        
        var loadRequest = new chrome.cast.media.LoadRequest(mediaInfo);
        castSession.loadMedia(loadRequest);
      }
    ''']);
  }

  static Future<void> pauseMedia() async { 
    js.context.callMethod('eval', ["cast.framework.CastContext.getInstance().getCurrentSession()?.getMediaSession()?.pause();"]); 
  }

  static Future<void> resumeMedia() async { 
    js.context.callMethod('eval', ["cast.framework.CastContext.getInstance().getCurrentSession()?.getMediaSession()?.play();"]); 
  }

  static Future<void> stopMedia() async { 
    js.context.callMethod('eval', ["cast.framework.CastContext.getInstance().getCurrentSession()?.getMediaSession()?.stop();"]); 
  }

  static Future<void> disconnectDevice() async { 
    js.context.callMethod('eval', ["cast.framework.CastContext.getInstance().getCurrentSession()?.endSession(true);"]); 
  }

  static Future<void> seekMedia(int positionInSeconds) async {
    js.context.callMethod('eval', ['''
      var mediaSession = cast.framework.CastContext.getInstance().getCurrentSession()?.getMediaSession();
      if (mediaSession) {
        var seekRequest = new chrome.cast.media.SeekRequest();
        seekRequest.currentTime = $positionInSeconds;
        mediaSession.seek(seekRequest);
      }
    ''']);
  }
}

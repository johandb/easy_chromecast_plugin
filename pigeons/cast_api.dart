// pigeons/cast_api.dart
import 'package:pigeon/pigeon.dart';

// Configuratiesectie voor de codegenerator
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/pigeon/cast_api.g.dart',
  dartOptions: DartOptions(),
  dartPackageName: 'easy_chromecast_plugin',
  kotlinOut: 'android/src/main/kotlin/com/jdbs/iptv/easy_chromecast_plugin/CastApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.jdbs.iptv.easy_chromecast_plugin'),
  swiftOut: 'ios/Classes/CastApi.g.swift',
))

// De data die we naar Kotlin sturen
class CastMediaRequest {
  final String url;
  final String title;

  CastMediaRequest({required this.url, required this.title});
}

// De interface die je straks in Kotlin gaat implementeren
@HostApi()
abstract class ChromecastHostApi {
  void initializeCast();
  bool isConnected();
  void showCastDialog(); 
  void playMedia(CastMediaRequest request);
  void stopMedia();
  void disconnectDevice();
  
  void pauseMedia();
  void resumeMedia();
  void seekMedia(int positionInSeconds);
  void setVolume(double volume);
}

// Native -> Dart (Wat Android/iOS kunnen aanroepen naar Dart)
@FlutterApi()
abstract class ChromecastFlutterApi {
  void onConnectionStatusChanged(bool isConnected);
  
  void onMediaStatusChanged(String playerState); 
}


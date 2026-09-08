// pigeons/cast_api.dart
import 'package:pigeon/pigeon.dart';

// Configuratiesectie voor de codegenerator
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/pigeon/cast_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/src/main/kotlin/com/jdbs/iptv/easy_chromecast_plugin/CastApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.jdbs.iptv.easy_chromecast_plugin'),
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
  
  void pauseMedia();
  void resumeMedia();
  void seekMedia(int positionInSeconds);
}


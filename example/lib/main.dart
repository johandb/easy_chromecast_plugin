import 'package:easy_chromecast_plugin/easy_chromecast_plugin.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Maak een instantie aan van jouw eigen plugin
  final _plugin = EasyChromecastPlugin();
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    // Initialiseer de Cast SDK zodra de app start
    _plugin.initializeCast();
  }

  Future<void> _checkConnection() async {
    final connected = await _plugin.isConnected();
    setState(() {
      _isConnected = connected;
    });
  }

  void _startStreaming() {
    // Dit is een officiële, CORS-vrije Apple HLS test-stream (Adaptive Bitrate)
    // Chromecast-ontvangers spelen dit type streams vele malen stabieler af dan rauwe MP4's
    _plugin.playMedia(
      url: 'http://mystream.mp4',
      title: 'A Christmas Carol',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Easy Chromecast Test')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Verbonden met Chromecast: $_isConnected'),
              const SizedBox(height: 20),

              // NIEUWE KNOP: Opent het Chromecast selectievenster
              ElevatedButton(
                onPressed: () async {
                  await _plugin.showCastDialog();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Zoek & Verbind Chromecast', style: TextStyle(color: Colors.white)),
              ),

              const SizedBox(height: 10),
              ElevatedButton(onPressed: _checkConnection, child: const Text('Check Status')),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _startStreaming, child: const Text('Stream Video naar Cast')),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: () => _plugin.stopMedia(), child: const Text('Stop Media')),
            ],
          ),
        ),
      ),
    );
  }
}

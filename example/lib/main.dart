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
  final _plugin = EasyChromecastPlugin();
  bool _isConnected = false;

  // We houden lokaal de geschatte afspeeltijd bij om +30 seconden te kunnen spoelen
  int _currentPositionInSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Initialiseer de Cast SDK direct bij het opstarten
    _plugin.initializeCast();
  }

  Future<void> _checkConnection() async {
    final connected = await _plugin.isConnected();
    setState(() {
      _isConnected = connected;
    });
  }

  void _startStreaming() {
    // Reset de timer bij het starten van een nieuwe film
    _currentPositionInSeconds = 0;

    // De werkende MP4 IPTV URL van je provider
    _plugin.playMedia(url: 'http://mystream.mp4', title: 'IPTV Easy Movie Test');
  }

  void _seekForward30Seconds() {
    setState(() {
      // Verhoog de positie met 30 seconden en stuur het commando naar Kotlin
      _currentPositionInSeconds += 30;
    });
    _plugin.seekMedia(_currentPositionInSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: const Text('Easy Chromecast Test'), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Kaart
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Status: ${_isConnected ? "CONNECTED" : "DISCONNECTED"}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _checkConnection,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Check Connection Status'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Verbindingsknop
              ElevatedButton.icon(
                onPressed: () => _plugin.showCastDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.cast),
                label: const Text('1. Search & Connect DIW7022'),
              ),
              const SizedBox(height: 10),

              // Start Stream Knop
              ElevatedButton.icon(
                onPressed: _startStreaming,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.play_circle_fill),
                label: const Text('2. Stream MP4 to KPN Box'),
              ),
              const SizedBox(height: 30),

              // AFSTANDSBEDIENING SECTIE (Zichtbaar als interface element) [1]
              const Text(
                'KPN Box Remote Control',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Card(
                color: Colors.grey[100],
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                  child: Column(
                    children: [
                      // Rij met hoofdknoppen: Pause, Play/Resume, Stop [1]
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton.filledTonal(
                            onPressed: () => _plugin.pauseMedia(),
                            iconSize: 36,
                            icon: const Icon(Icons.pause),
                            tooltip: 'Pause',
                          ),
                          IconButton.filled(
                            onPressed: () => _plugin.resumeMedia(),
                            iconSize: 44,
                            icon: const Icon(Icons.play_arrow),
                            tooltip: 'Play',
                          ),
                          IconButton.filledTonal(
                            onPressed: () => _plugin.stopMedia(),
                            iconSize: 36,
                            icon: const Icon(Icons.stop),
                            style: IconButton.styleFrom(foregroundColor: Colors.red),
                            tooltip: 'Stop',
                          ),
                          IconButton.filledTonal(
                            onPressed: () async {
                              // 1. Stuur de stop-opdracht naar Kotlin (de TV-box stopt de video)
                              await _plugin.stopMedia();

                              // 2. Reset de lokale Flutter UI-state
                              setState(() {
                                _currentPositionInSeconds = 0; // Zet de afspeeltijd terug naar start
                              });

                              // 3. Optioneel: vraag de actuele verbindingsstatus op om de UI synchroon te houden
                              await _checkConnection();
                            },
                            iconSize: 36,
                            icon: const Icon(Icons.stop),
                            style: IconButton.styleFrom(foregroundColor: Colors.red),
                            tooltip: 'Stop Media (Keep Connected)',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Rij voor het spoelen [1]
                      ElevatedButton.icon(
                        onPressed: _seekForward30Seconds,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10)),
                        icon: const Icon(Icons.forward_30),
                        label: Text('Seek forward (+30s) -> Active: $_currentPositionInSeconds s'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

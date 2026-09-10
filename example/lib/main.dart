import 'dart:async';

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

  // Maak een variabele aan om de stream-abonnement bij te houden
  StreamSubscription<bool>? _connectionSubscription;

  // We houden lokaal de geschatte afspeeltijd bij om +30 seconden te kunnen spoelen
  int _currentPositionInSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Initialiseer de Cast SDK direct bij het opstarten
    _plugin.initializeCast();

    // VOEG DIT TOE: Luister live naar verbindingswisselingen
    _connectionSubscription = _plugin.onConnectionChanged.listen((connected) {
      print("****** CONNECTED: $connected");
      setState(() {
        _isConnected = connected;
      });

      if (connected) {
        // Zodra er verbinding is gemaakt via de Cast Dialog, starten we direct de video!
        _startStreaming();
      } else {
        // Optioneel: reset de positie als de verbinding verbroken wordt
        setState(() {
          _isConnected = false;
          _currentPositionInSeconds = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    // BELANGRIJK: Ruim de stream netjes op om memory leaks te voorkomen
    _connectionSubscription?.cancel();
    super.dispose();
  }

  // De handmatige check kan blijven bestaan als fallback, maar is in principe overbodig geworden
  Future<void> _checkConnection() async {
    final connected = await _plugin.isConnected();
    setState(() {
      _isConnected = connected;
    });
  }

  void _startStreaming() {
    // Reset de timer bij het starten van een nieuwe film
    _currentPositionInSeconds = 0;
    print("******* START STREAMING");

    // De werkende MP4 IPTV URL van je provider
    _plugin.playMedia(url: 'https://www.jdbs.nl/iptv/movie/demo/demo/20301.mp4', title: 'IPTV Easy Movie Test');
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
                      Text(
                        _isConnected ? "Video wordt automatisch afgespeeld..." : "Verbind met een apparaat om te starten",
                        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
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

              // Handmatige Start Stream Knop (Nu optioneel, omdat het ook automatisch gaat)
              ElevatedButton.icon(
                onPressed: _isConnected ? _startStreaming : null, // Alleen klikbaar als verbonden
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.play_circle_fill),
                label: const Text('Handmatig streamen herstarten'),
              ),
              const SizedBox(height: 30),

              // AFSTANDSBEDIENING SECTIE
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton.filledTonal(
                            onPressed: _isConnected ? () => _plugin.pauseMedia() : null,
                            iconSize: 36,
                            icon: const Icon(Icons.pause),
                            tooltip: 'Pause',
                          ),
                          IconButton.filled(
                            onPressed: _isConnected ? () => _plugin.resumeMedia() : null,
                            iconSize: 44,
                            icon: const Icon(Icons.play_arrow),
                            tooltip: 'Play',
                          ),
                          IconButton.filledTonal(
                            onPressed: _isConnected
                                ? () async {
                                    await _plugin.disconnectDevice();
                                    setState(() {
                                      _currentPositionInSeconds = 0;
                                      _isConnected = false;
                                    });
                                  }
                                : null,
                            iconSize: 36,
                            icon: const Icon(Icons.stop),
                            style: IconButton.styleFrom(foregroundColor: Colors.red),
                            tooltip: 'Stop Media & Disconnect',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Rij voor het spoelen
                      ElevatedButton.icon(
                        onPressed: _isConnected ? _seekForward30Seconds : null,
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

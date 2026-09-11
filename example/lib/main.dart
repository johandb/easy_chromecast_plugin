import 'dart:async';

import 'package:easy_chromecast_plugin/easy_chromecast_plugin.dart';
import 'package:flutter/material.dart';

import 'chromecast_controller.dart'; // Zorg dat dit bestand klopt met je overlay

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Chromecast Demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      // FIX: We starten direct door naar een apart HomeScreen component
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _plugin = EasyChromecastPlugin();
  bool _isConnected = false;
  StreamSubscription<bool>? _connectionSubscription;
  int _currentPositionInSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Initialiseer de Cast SDK
    _plugin.initializeCast();

    // Luister live naar de Chromecast verbinding status
    _connectionSubscription = _plugin.onConnectionChanged.listen((connected) {
      print("****** CONNECTED: $connected");
      setState(() {
        _isConnected = connected;
      });

      if (connected) {
        // Nu we in een aparte widget zitten, heeft 'context' ALTIJD toegang tot de MaterialApp!
        _startStreaming();
      } else {
        setState(() {
          _isConnected = false;
          _currentPositionInSeconds = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  void _startStreaming() async {
    _currentPositionInSeconds = 0;
    print("******* START STREAMING");

    _plugin.playMedia(url: 'https://www.jdbs.nl/iptv/movie/demo/demo/20301.mp4', title: 'IPTV Easy Movie Test');

    if (mounted) {
      print("******* AFSTANDSBEDIENING OPENEN");

      // FIX: Door hier 'await' te gebruiken, wacht Flutter totdat het venster sluit!
      await ChromecastControllerOverlay().showRemoteControl(context, _plugin, "IPTV Easy Movie Test");

      // DIT WORDT PAS UITGEVOERD ALS DE SHEET GESLOTEN IS (of de film afgelopen is):
      print("******* VENSTER IS GESLOTEN, VERBREEK VERBINDING MET DIW7022");
      await _plugin.disconnectDevice();

      // Update de UI status netjes terug naar disconnected
      setState(() {
        _isConnected = false;
        _currentPositionInSeconds = 0;
      });
    }
  }

  void _seekForward30Seconds() {
    setState(() {
      _currentPositionInSeconds += 30;
    });
    _plugin.seekMedia(_currentPositionInSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Easy Chromecast Demo'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Status Kaart (CONNECTED / DISCONNECTED)
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

            // 2. Verbindingsknop (Zoeken & Verbinden)
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

            // 3. Handmatige Start Stream Knop (Als fallback)
            ElevatedButton.icon(
              onPressed: _isConnected ? _startStreaming : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.play_circle_fill),
              label: const Text('Handmatig streamen herstarten'),
            ),

            // OPMERKING: De complete KPN Box Remote Control Card die hieronder stond, is nu succesvol verwijderd!
          ],
        ),
      ),
    );
  }
}

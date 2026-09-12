import 'dart:async';

import 'package:easy_chromecast_plugin/easy_chromecast_plugin.dart';
import 'package:flutter/material.dart';

class ChromecastControllerOverlay {
  Timer? _progressTimer;
  StreamSubscription<String>? _mediaSubscription;
  bool _isPlaying = true;
  bool _showVolumeSlider = false; // FIX: Houdt bij of de volumebalk zichtbaar is
  double _currentVolume = 0.5;
  int _currentPositionInSeconds = 0;
  final int _totalDurationInSeconds = 45;

  Future<void> showRemoteControl(BuildContext context, EasyChromecastPlugin plugin, String videoTitle) {
    _mediaSubscription = plugin.onMediaStatusUpdate.listen((status) {
      if (status == "FINISHED") {
        print("******* FILM IS AFGELOPEN, SLUIT AFSTANDSBEDIENING AUTOMATISCH");
        _progressTimer?.cancel();
        _mediaSubscription?.cancel();
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    });

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      // Iets donkerder grijs voor een luxe uitstraling
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bcc) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            if (_progressTimer == null && _isPlaying) {
              _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (_currentPositionInSeconds < _totalDurationInSeconds) {
                  setModalState(() {
                    _currentPositionInSeconds++;
                  });
                } else {
                  timer.cancel();
                }
              });
            }

            String formatDuration(int seconds) {
              final duration = Duration(seconds: seconds);
              final hours = duration.inHours;
              final mins = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
              final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
              return hours > 0 ? "$hours:$mins:$secs" : "$mins:$secs";
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Bovenbalk
                  Row(
                    children: [
                      const Icon(Icons.cast_connected, color: Colors.blue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Nu aan het casten", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(
                              videoTitle,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          _progressTimer?.cancel();
                          _mediaSubscription?.cancel();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey[700], height: 24),

                  // 2. Live Voortgangsbalk (Slider)
                  Slider(
                    value: _currentPositionInSeconds.toDouble(),
                    min: 0,
                    max: _totalDurationInSeconds.toDouble(),
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey[700],
                    onChanged: (double value) {
                      setModalState(() {
                        _currentPositionInSeconds = value.toInt();
                      });
                    },
                    onChangeEnd: (double value) async {
                      await plugin.seekMedia(value.toInt());
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatDuration(_currentPositionInSeconds), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          "-${formatDuration(_totalDurationInSeconds - _currentPositionInSeconds)}",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Knoppenbalk (Nu inclusief de Volume-knop helemaal rechts!)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 30s Terug
                      IconButton(
                        icon: const Icon(Icons.replay_30, color: Colors.white, size: 32),
                        onPressed: () async {
                          setModalState(() {
                            _currentPositionInSeconds = (_currentPositionInSeconds - 30).clamp(0, _totalDurationInSeconds);
                          });
                          await plugin.seekMedia(_currentPositionInSeconds);
                        },
                      ),
                      // Start / Pauze
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.blue,
                        child: IconButton(
                          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 26),
                          onPressed: () async {
                            if (_isPlaying) {
                              await plugin.pauseMedia();
                              _progressTimer?.cancel();
                              _progressTimer = null;
                            } else {
                              await plugin.resumeMedia();
                            }
                            setModalState(() {
                              _isPlaying = !_isPlaying;
                            });
                          },
                        ),
                      ),
                      // Stop
                      IconButton(
                        icon: const Icon(Icons.stop, color: Colors.red, size: 32),
                        onPressed: () async {
                          _progressTimer?.cancel();
                          _mediaSubscription?.cancel();
                          await plugin.stopMedia();
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      // 30s Vooruit
                      IconButton(
                        icon: const Icon(Icons.forward_30, color: Colors.white, size: 32),
                        onPressed: () async {
                          setModalState(() {
                            _currentPositionInSeconds = (_currentPositionInSeconds + 30).clamp(0, _totalDurationInSeconds);
                          });
                          await plugin.seekMedia(_currentPositionInSeconds);
                        },
                      ),
                      // FIX: De nieuwe Volume Toggle Knop naast de 30s vooruit!
                      IconButton(
                        icon: Icon(
                          _showVolumeSlider ? Icons.volume_up : Icons.volume_down_outlined,
                          color: _showVolumeSlider ? Colors.blue : Colors.white,
                          size: 32,
                        ),
                        tooltip: 'Volume regelaar',
                        onPressed: () {
                          setModalState(() {
                            _showVolumeSlider = !_showVolumeSlider; // Klapt open of dicht
                          });
                        },
                      ),
                    ],
                  ),

                  // 4. DYNAMISCHE VOLUMEREGELING BALK
                  // Met AnimatedSize schuift de balk prachtig en soepel open of dicht!
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _showVolumeSlider
                        ? Padding(
                            padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                            child: Row(
                              children: [
                                Icon(_currentVolume == 0 ? Icons.volume_mute : Icons.volume_down, color: Colors.grey),
                                Expanded(
                                  child: Slider(
                                    value: _currentVolume,
                                    min: 0.0,
                                    max: 1.0,
                                    activeColor: Colors.white,
                                    inactiveColor: Colors.grey[700],
                                    onChanged: (double value) async {
                                      setModalState(() {
                                        _currentVolume = value;
                                      });
                                      await plugin.setVolume(value);
                                    },
                                  ),
                                ),
                                const Icon(Icons.volume_up, color: Colors.grey),
                              ],
                            ),
                          )
                        : const SizedBox(width: double.infinity, height: 0), // Volledig onzichtbaar en neemt 0 ruimte in
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      _progressTimer?.cancel();
      _mediaSubscription?.cancel();
    });
  }
}

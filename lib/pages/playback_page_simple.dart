// lib/pages/playback_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:file_picker/file_picker.dart';

class PlaybackPage extends StatefulWidget {
  final PlatformFile? file;

  const PlaybackPage({super.key, this.file});

  @override
  State<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  bool _isPlaying = false;
  bool _isPaused = false;
  double _currentPosition = 0.0;
  final double _totalDuration = 180.0; // æ¨¡æ“¬3?†é??„æ??²é•·åº?

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.file?.name ?? 'MIDI ?­æ”¾??,
          style: TextStyle( ,
                        trackHeight: 4.0,
                      ),
                      child: Slider(
                        value: _currentPosition,
                        max: _totalDuration,
                        onChanged: _isPlaying ? (value) {
                          setState(() {
                            _currentPosition = value;
                          });
                        } : null,
                      ),
                    ),
                    
                    // ?‚é?é¡¯ç¤º
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(_currentPosition),
                            style: TextStyle( ,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _isPlaying = false;
        _isPaused = true;
      } else {
        _isPlaying = true;
        _isPaused = false;
        // æ¨¡æ“¬?­æ”¾?²åº¦
        _simulatePlayback();
      }
    });
  }

  void _restart() {
    setState(() {
      _currentPosition = 0.0;
      _isPlaying = true;
      _isPaused = false;
    });
    _simulatePlayback();
  }

  void _stop() {
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _currentPosition = 0.0;
    });
  }

  void _simulatePlayback() {
    if (_isPlaying && !_isPaused) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_isPlaying && !_isPaused && mounted) {
          setState(() {
            _currentPosition += 1.0;
            if (_currentPosition >= _totalDuration) {
              _currentPosition = _totalDuration;
              _isPlaying = false;
            }
          });
          if (_isPlaying) {
            _simulatePlayback();
          }
        }
      });
    }
  }

  String _formatTime(double seconds) {
    final int minutes = (seconds / 60).floor();
    final int remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getStatusText() {
    if (_isPlaying) {
      return '?­æ”¾ä¸?..';
    } else if (_isPaused) {
      return 'å·²æš«??;
    } else if (_currentPosition > 0) {
      return 'å·²å?æ­?;
    } else {
      return 'æº–å??­æ”¾';
    }
  }
}


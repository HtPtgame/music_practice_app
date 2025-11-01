import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/services/midi_player_service.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:file_picker/file_picker.dart';

class PlaybackPage extends StatefulWidget {
  final PlatformFile? file;
  const PlaybackPage({super.key, this.file});

  @override
  State<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  final MidiPlayerService _midiService = MidiPlayerService();
  StreamSubscription? _playingStateSubscription;
  StreamSubscription? _progressSubscription;

  bool _isLoading = true;
  bool _isPlaying = false;

  double _currentPosition = 0.0;
  double get _totalDuration => _midiService.totalDurationMs / 1000.0; // 秒

  @override
  void initState() {
    super.initState();
    _initialize();

    _playingStateSubscription =
        _midiService.playingStateStream.listen((isPlaying) {
      if (mounted) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    });

    _progressSubscription = _midiService.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _currentPosition = progress * _totalDuration;
        });
      }
    });
  }

  Future<void> _initialize() async {
    await _midiService.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _playingStateSubscription?.cancel();
    _progressSubscription?.cancel();
    _midiService.stop();
    super.dispose();
  }

  void _togglePlayPause() {
    if (widget.file?.path == null) return;

    if (_isPlaying) {
      _midiService.pause();
    } else {
      if (_currentPosition > 0) {
        _midiService.resume();
      } else {
        _midiService.play(widget.file!.path!);
      }
    }
  }

  void _restart() async {
    if (widget.file?.path == null) return;
    await _midiService.stop();
    await Future.delayed(const Duration(milliseconds: 200));
    _midiService.play(widget.file!.path!);
  }

  void _stop() {
    _midiService.stop();
  }

  String _formatTime(double seconds) {
    final int minutes = (seconds / 60).floor();
    final int remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: const Text(
          '播放 MIDI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/library'),
        ),
        backgroundColor: AppColors.dynamicBackground,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = MediaQuery.of(context).size.height;
                
                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: screenWidth * 0.05,
                      right: screenWidth * 0.05,
                      top: screenHeight * 0.02,
                      bottom: MediaQuery.of(context).padding.bottom + 100,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Card(
                          color: AppColors.dynamicCard,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.06),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: screenWidth * 0.7,
                                  height: screenWidth * 0.7,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.music_note,
                                        size: screenWidth * 0.2,
                                        color: AppColors.dynamicPrimary,
                                      ),
                                      SizedBox(height: screenHeight * 0.02),
                                      Text(
                                        widget.file?.name ?? '未知檔案',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.04,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.dynamicTextDark,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (widget.file != null) ...[
                                        SizedBox(height: screenHeight * 0.01),
                                        Text(
                                          '檔案大小: ${(widget.file!.size / 1024).toStringAsFixed(1)} KB',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.03,
                                            color: AppColors.dynamicTextLight,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                Container(
                                  height: 2,
                                  width: screenWidth * 0.7,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: screenHeight * 0.04),
                                Slider(
                                  value: _currentPosition,
                                  max: _totalDuration,
                                  onChanged: null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatTime(_currentPosition),
                                        style: TextStyle(fontSize: screenWidth * 0.035),
                                      ),
                                      Text(
                                        _formatTime(_totalDuration),
                                        style: TextStyle(fontSize: screenWidth * 0.035),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.04),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      onPressed: _isLoading ? null : _restart,
                                      icon: const Icon(Icons.replay),
                                      iconSize: screenWidth * 0.09,
                                      color: AppColors.dynamicTextDark,
                                      tooltip: '重新播放',
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.dynamicPrimary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: _isLoading ? null : _togglePlayPause,
                                        icon: Icon(
                                          _isPlaying ? Icons.pause : Icons.play_arrow,
                                        ),
                                        iconSize: screenWidth * 0.12,
                                        color: Colors.white,
                                        tooltip: _isPlaying ? '暫停' : '播放',
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _isLoading ? null : _stop,
                                      icon: const Icon(Icons.stop),
                                      iconSize: screenWidth * 0.09,
                                      color: AppColors.dynamicTextDark,
                                      tooltip: '停止',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

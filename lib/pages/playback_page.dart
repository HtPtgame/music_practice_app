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
  String _status = '正在初始化...';

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
          _status = isPlaying ? '播放中...' : '已停止';
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
        _status = '準備播放';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.file?.name ?? 'MIDI 播放器',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/library'),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_status),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Card(
                      color: AppColors.card,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Icon(Icons.music_note,
                                size: 80, color: AppColors.primary),
                            const SizedBox(height: 16),
                            Text(
                              widget.file?.name ?? '未知檔案',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (widget.file != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '檔案大小: ${(widget.file!.size / 1024).toStringAsFixed(1)} KB',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      color: AppColors.card,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Slider(
                              value: _currentPosition,
                              max: _totalDuration,
                              onChanged: null,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatTime(_currentPosition)),
                                  Text(_formatTime(_totalDuration)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      color: AppColors.card,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: _isLoading ? null : _restart,
                              icon: const Icon(Icons.replay),
                              iconSize: 36,
                              color: AppColors.textDark,
                              tooltip: '重新播放',
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _isLoading ? null : _togglePlayPause,
                                icon: Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow),
                                iconSize: 48,
                                color: Colors.white,
                                tooltip: _isPlaying ? '暫停' : '播放',
                              ),
                            ),
                            IconButton(
                              onPressed: _isLoading ? null : _stop,
                              icon: const Icon(Icons.stop),
                              iconSize: 36,
                              color: AppColors.textDark,
                              tooltip: '停止',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ...已移除『開始演奏』按鈕區塊...
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPlaying ? Icons.music_note : Icons.music_off,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _status,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

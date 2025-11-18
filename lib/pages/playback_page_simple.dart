// lib/pages/playback_page_simple.dart
import 'package:flutter/material.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:music_practice_app/l10n/app_localizations.dart';

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
  final double _totalDuration = 180.0; // 模擬3分鐘長度

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.file?.name ?? (l10n?.playbackPageTitle ?? 'MIDI 播放器'),
            style: TextStyle(
              color: AppColors.dynamicTextDark,
            ),
          ),
        ),
        backgroundColor: AppColors.dynamicBackground,
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.dynamicTextDark,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 播放進度條
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.dynamicCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // 進度滑桿
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4.0,
                    ),
                    child: Slider(
                      value: _currentPosition,
                      max: _totalDuration,
                      onChanged: _isPlaying
                          ? (value) {
                              setState(() {
                                _currentPosition = value;
                              });
                            }
                          : null,
                      activeColor: AppColors.dynamicPrimary,
                      inactiveColor:
                          AppColors.dynamicTextLight.withOpacity(0.3),
                    ),
                  ),

                  // 時間顯示
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(_currentPosition),
                          style: TextStyle(
                            color: AppColors.dynamicTextLight,
                          ),
                        ),
                        Text(
                          _formatTime(_totalDuration),
                          style: TextStyle(
                            color: AppColors.dynamicTextLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 控制按鈕
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 重新開始按鈕
                IconButton(
                  onPressed: _restart,
                  icon: Icon(
                    Icons.replay,
                    size: 32,
                    color: AppColors.dynamicTextDark,
                  ),
                ),

                // 播放/暫停按鈕
                IconButton(
                  onPressed: _togglePlayPause,
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 48,
                    color: AppColors.dynamicPrimary,
                  ),
                ),

                // 停止按鈕
                IconButton(
                  onPressed: _stop,
                  icon: Icon(
                    Icons.stop,
                    size: 32,
                    color: AppColors.dynamicTextDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 狀態顯示
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.dynamicCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusText(),
                style: TextStyle(
                  color: AppColors.dynamicTextDark,
                  fontSize: 16,
                ),
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
        // 模擬播放進度
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
    final l10n = AppLocalizations.of(context);
    if (_isPlaying) {
      return l10n?.playbackPagePlaying ?? '播放中...';
    } else if (_isPaused) {
      return l10n?.playbackPagePaused ?? '已暫停';
    } else if (_currentPosition > 0) {
      return l10n?.playbackPageStopped ?? '已停止';
    } else {
      return '';
    }
  }
}

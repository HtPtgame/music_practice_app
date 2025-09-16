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
  final double _totalDuration = 180.0; // 模擬3分鐘的歌曲長度

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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 檔案資訊區域
            Card(
              color: AppColors.card,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.music_note,
                      size: 80,
                      color: AppColors.primary,
                    ),
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
            
            const SizedBox(height: 40),
            
            // 播放進度區域
            Card(
              color: AppColors.card,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // 進度條
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.primary.withValues(alpha: 0.3),
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.2),
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
                    
                    // 時間顯示
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(_currentPosition),
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _formatTime(_totalDuration),
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 播放控制區域
            Card(
              color: AppColors.card,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 重新播放按鈕
                    IconButton(
                      onPressed: _restart,
                      icon: const Icon(Icons.replay),
                      iconSize: 36,
                      color: AppColors.textDark,
                      tooltip: '重新播放',
                    ),
                    
                    // 主要播放/暫停按鈕
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _togglePlayPause,
                        icon: Icon(
                          _isPlaying 
                            ? Icons.pause 
                            : Icons.play_arrow,
                        ),
                        iconSize: 48,
                        color: Colors.white,
                        tooltip: _isPlaying ? '暫停' : '播放',
                      ),
                    ),
                    
                    // 停止按鈕
                    IconButton(
                      onPressed: _stop,
                      icon: const Icon(Icons.stop),
                      iconSize: 36,
                      color: AppColors.textDark,
                      tooltip: '停止',
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // 狀態顯示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
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
                    _getStatusText(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
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
    if (_isPlaying) {
      return '播放中...';
    } else if (_isPaused) {
      return '已暫停';
    } else if (_currentPosition > 0) {
      return '已停止';
    } else {
      return '準備播放';
    }
  }
}

import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// 播放控制元件
/// 
/// Phase 3 重構: 從 PracticePage 提取的 UI 元件
class PlaybackControlsWidget extends StatelessWidget {
  final bool isPlaying;
  final bool isPaused;
  final bool isRecording;
  final double playbackPosition;
  final double playbackDuration;
  final String? audioPath;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;

  const PlaybackControlsWidget({
    super.key,
    required this.isPlaying,
    required this.isPaused,
    required this.isRecording,
    required this.playbackPosition,
    required this.playbackDuration,
    this.audioPath,
    this.onPlay,
    this.onPause,
    this.onResume,
    this.onStop,
  });

  String _formatDuration(double seconds) {
    final int minutes = seconds.floor() ~/ 60;
    final int secs = seconds.floor() % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volume_up,
                    color: AppColors.dynamicPrimary, size: 28),
                const SizedBox(width: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n?.practicePlaybackControl ?? '播放控制',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 播放進度條
            if (audioPath != null && (isPlaying || playbackPosition > 0)) ...[
              Column(
                children: [
                  // 進度條
                  Slider(
                    value: playbackDuration > 0
                        ? (playbackPosition / playbackDuration).clamp(0.0, 1.0)
                        : 0.0,
                    onChanged: null, // 暫時不支援拖動
                    activeColor: AppColors.dynamicPrimary,
                    inactiveColor: Colors.grey[300],
                  ),
                  // 時間顯示
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(playbackPosition),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _formatDuration(playbackDuration),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // 播放控制按鈕
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 播放/暫停按鈕
                ElevatedButton.icon(
                  onPressed: (!isRecording && audioPath != null)
                      ? (isPlaying
                          ? (isPaused ? onResume : onPause)
                          : onPlay)
                      : null,
                  icon: Icon(
                    isPlaying
                        ? (isPaused ? Icons.play_arrow : Icons.pause)
                        : Icons.play_arrow,
                  ),
                  label: Text(
                    isPlaying
                        ? (isPaused
                            ? (l10n?.practiceResume ?? '繼續')
                            : (l10n?.practicePause ?? '暫停'))
                        : (l10n?.practicePlayRecording ?? '播放錄音'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPlaying ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),

                // 停止按鈕（僅在播放時顯示）
                if (isPlaying) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop),
                    label: Text(l10n?.practiceStopPlayback2 ?? '停止'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// 錄音控制元件
/// 
/// Phase 3 重構: 從 PracticePage 提取的 UI 元件
class RecordingControlsWidget extends StatelessWidget {
  final bool isRecording;
  final bool isPlaying;
  final bool enableCountdown;
  final int recordingDurationSeconds;
  final String? audioPath;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final ValueChanged<bool>? onCountdownChanged;

  const RecordingControlsWidget({
    super.key,
    required this.isRecording,
    required this.isPlaying,
    required this.enableCountdown,
    required this.recordingDurationSeconds,
    this.audioPath,
    this.onStartRecording,
    this.onStopRecording,
    this.onCountdownChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        // 倒數計時開關
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                l10n?.practiceEnableCountdown ?? '3秒倒數計時',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: enableCountdown,
              onChanged: (isRecording || isPlaying) ? null : onCountdownChanged,
              activeColor: AppColors.dynamicPrimary,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Column(
          children: [
            // 狀態顯示器
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isRecording
                      ? Icons.fiber_manual_record
                      : Icons.stop_circle_outlined,
                  color: isRecording ? Colors.red : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isRecording
                      ? '${l10n?.practiceRecording ?? '正在錄音'}... $recordingDurationSeconds${l10n?.practiceSeconds ?? 's'}'
                      : (audioPath != null
                          ? (l10n?.practiceRecordingSuccess ?? '錄音完成')
                          : (l10n?.practiceNoRecording ?? '未錄音')),
                  style: TextStyle(
                    fontSize: 16,
                    color: isRecording
                        ? Colors.red
                        : (audioPath != null ? Colors.green : Colors.grey),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 錄音按鈕
            ElevatedButton.icon(
              onPressed: isRecording ? onStopRecording : onStartRecording,
              icon: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
              label: Text(
                isRecording
                    ? (l10n?.practiceStopRecord ?? '停止')
                    : (audioPath != null
                        ? (l10n?.practiceRerecord ?? '重新錄音')
                        : (l10n?.practiceRecord ?? '開始錄音')),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isRecording ? Colors.grey : Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

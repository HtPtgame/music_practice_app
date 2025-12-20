import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// 模式切換元件
/// 
/// Phase 3 重構: 從 PracticePage 提取的 UI 元件
class ModeSelectorWidget extends StatelessWidget {
  final bool isRecordMode;
  final bool isRecording;
  final bool isPlaying;
  final ValueChanged<bool>? onModeChanged;

  const ModeSelectorWidget({
    super.key,
    required this.isRecordMode,
    required this.isRecording,
    required this.isPlaying,
    this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSwitch = !isRecording && !isPlaying;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 錄音模式按鈕
          Expanded(
            child: GestureDetector(
              onTap: canSwitch ? () => onModeChanged?.call(true) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isRecordMode
                      ? AppColors.dynamicPrimary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mic,
                      size: 18,
                      color: isRecordMode ? Colors.white : Colors.grey[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n?.practiceRecordMode ?? '錄音',
                      style: TextStyle(
                        color: isRecordMode ? Colors.white : Colors.grey[700],
                        fontWeight: isRecordMode
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 上傳模式按鈕
          Expanded(
            child: GestureDetector(
              onTap: canSwitch ? () => onModeChanged?.call(false) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: !isRecordMode
                      ? AppColors.dynamicPrimary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: 18,
                      color: !isRecordMode ? Colors.white : Colors.grey[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n?.practiceUploadMode ?? '上傳',
                      style: TextStyle(
                        color: !isRecordMode ? Colors.white : Colors.grey[700],
                        fontWeight: !isRecordMode
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

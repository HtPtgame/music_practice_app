import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// 分析控制元件
/// 
/// Phase 3 重構: 從 PracticePage 提取的 UI 元件
class AnalysisControlsWidget extends StatelessWidget {
  final bool isRecording;
  final bool isAnalyzing;
  final String? audioPath;
  final bool hasMidiFile;
  final VoidCallback? onAnalyze;

  const AnalysisControlsWidget({
    super.key,
    required this.isRecording,
    required this.isAnalyzing,
    this.audioPath,
    required this.hasMidiFile,
    this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      color: (audioPath != null && hasMidiFile)
          ? null
          : Colors.purple.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics_outlined,
                    color: Colors.purple, size: 28),
                const SizedBox(width: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n?.practiceAnalyze ?? '演奏分析',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l10n?.practiceAnalysisDescription ??
                      '使用頻譜分析技術驗證您的演奏\n比對音準、節奏,並給予評分和建議',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.dynamicTextDark.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: (!isRecording &&
                      audioPath != null &&
                      !isAnalyzing &&
                      hasMidiFile)
                  ? onAnalyze
                  : null,
              icon: isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.analytics_outlined),
              label: Text(
                isAnalyzing
                    ? (l10n?.practiceAnalyzing ?? '分析中...')
                    : (l10n?.practiceAnalyze ?? '分析演奏'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

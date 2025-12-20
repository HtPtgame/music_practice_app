import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// 分析進度對話框
/// 
/// Phase 3 重構: 從 PracticePage 提取的 UI 元件
class AnalysisProgressDialog extends StatelessWidget {
  final double progress;
  final String phase;

  const AnalysisProgressDialog({
    super.key,
    required this.progress,
    required this.phase,
  });

  /// 顯示分析進度對話框
  static Future<void> show(BuildContext context, {
    required double progress,
    required String phase,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnalysisProgressDialog(
        progress: progress,
        phase: phase,
      ),
    );
  }

  /// 根據進度取得分析階段描述
  static String getPhaseDescription(BuildContext context, double progress) {
    final l10n = AppLocalizations.of(context);
    if (progress < 0.2) {
      return l10n?.practiceAnalysisPhase1 ?? '正在解析 MIDI 標準答案...';
    }
    if (progress < 0.6) {
      return l10n?.practiceAnalysisPhase2 ?? '正在分析音訊頻譜...';
    }
    if (progress < 0.8) {
      return l10n?.practiceAnalysisPhase3 ?? '正在驗證音符準確性...';
    }
    if (progress < 1.0) {
      return l10n?.practiceAnalysisPhase4 ?? '正在分類錯誤類型...';
    }
    return l10n?.practiceAnalysisPhase5 ?? '分析完成!';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.analytics, color: Colors.purple),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(l10n?.practiceAnalyzingTitle ?? '演奏分析中'),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
          const SizedBox(height: 16),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            phase,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

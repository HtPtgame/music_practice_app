import 'package:flutter/material.dart';
import 'package:veloria/services/piano_score_engine.dart';

/// 🎹 即時練習反饋小部件
/// 顯示即時比對的進度、準確率、判定結果與統計資訊
class RealtimeFeedbackWidget extends StatelessWidget {
  final bool enabled;
  final double progress;
  final double accuracy;
  final int correctCount;
  final int wrongCount;
  final int missCount;
  final int noiseCount;
  final String lastJudgment;
  final JudgmentResult? lastJudgmentType;

  const RealtimeFeedbackWidget({
    Key? key,
    required this.enabled,
    required this.progress,
    required this.accuracy,
    required this.correctCount,
    required this.wrongCount,
    required this.missCount,
    required this.noiseCount,
    required this.lastJudgment,
    this.lastJudgmentType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                '🎹 即時練習反饋',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 進度條
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('進度', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 8,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 準確率
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('準確率', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${(accuracy * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _getAccuracyColor(accuracy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 最新判定
          if (lastJudgment.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getJudgmentColor(lastJudgmentType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getJudgmentColor(lastJudgmentType),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getJudgmentIcon(lastJudgmentType),
                    color: _getJudgmentColor(lastJudgmentType),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lastJudgment,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _getJudgmentColor(lastJudgmentType),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 統計資訊
          const Text(
            '統計',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('✅ 正確', correctCount, Colors.green),
              _buildStatItem('❌ 錯誤', wrongCount, Colors.red),
              _buildStatItem('⏭️ 跳過', missCount, Colors.orange),
              _buildStatItem('🔇 雜訊', noiseCount, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.9) return Colors.green;
    if (accuracy >= 0.7) return Colors.orange;
    return Colors.red;
  }

  Color _getJudgmentColor(JudgmentResult? judgment) {
    switch (judgment) {
      case JudgmentResult.correct:
        return Colors.green;
      case JudgmentResult.wrong:
        return Colors.red;
      case JudgmentResult.miss:
        return Colors.orange;
      case JudgmentResult.noise:
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getJudgmentIcon(JudgmentResult? judgment) {
    switch (judgment) {
      case JudgmentResult.correct:
        return Icons.check_circle;
      case JudgmentResult.wrong:
        return Icons.cancel;
      case JudgmentResult.miss:
        return Icons.skip_next;
      case JudgmentResult.noise:
        return Icons.volume_off;
      default:
        return Icons.music_note;
    }
  }
}

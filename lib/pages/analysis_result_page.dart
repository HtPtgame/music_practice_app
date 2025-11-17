import 'package:flutter/material.dart';
import 'package:music_practice_app/services/audio_analysis/models/analysis_report.dart';
import 'package:music_practice_app/services/audio_analysis/models/performance_error.dart';
import 'package:music_practice_app/utils/app_colors.dart';

/// Week 4 Phase 1: 演奏分析結果頁面
///
/// 顯示完整的分析報告,包括:
/// - 總分和評級 (S/A/B/C/D)
/// - 統計數據 (正確/錯音/漏音/節奏問題)
/// - 錯誤詳情列表
/// - 練習建議
///
/// 使用 Week 3 的頻譜分析結果
class AnalysisResultPage extends StatelessWidget {
  final AnalysisReport report;
  final String? midiFileName;
  final String? audioFileName;

  const AnalysisResultPage({
    super.key,
    required this.report,
    this.midiFileName,
    this.audioFileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('演奏分析報告', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.dynamicPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 總分卡片
              _buildScoreCard(),
              const SizedBox(height: 16),

              // 2. 統計數據
              _buildStatisticsCard(),
              const SizedBox(height: 16),

              // 3. 錯誤詳情
              if (report.errors.isNotEmpty) ...[
                _buildErrorsCard(),
                const SizedBox(height: 16),
              ],

              // 4. 練習建議
              _buildSuggestionCard(),
              const SizedBox(height: 16),

              // 5. 操作按鈕
              _buildActionButtons(context),

              // 6. 底部安全區域 padding (避免被系統導航欄遮擋)
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 總分卡片
  Widget _buildScoreCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 評級徽章
            _buildGradeBadge(),
            const SizedBox(height: 16),

            // 總分
            Text(
              report.overallScore.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // 準確率和節奏分
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildScoreItem(
                  '準確率',
                  '${(report.accuracy * 100).toStringAsFixed(1)}%',
                  Icons.check_circle,
                ),
                _buildScoreItem(
                  '節奏',
                  report.rhythmScore.toStringAsFixed(1),
                  Icons.music_note,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 評級徽章
  Widget _buildGradeBadge() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getGradeColor(report.grade),
        boxShadow: [
          BoxShadow(
            color: _getGradeColor(report.grade).withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              report.grade,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              '級',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 分數項目
  Widget _buildScoreItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 統計數據卡片
  Widget _buildStatisticsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                '⭐ 統計數據 ⭐',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 20, thickness: 1),
            const SizedBox(height: 4),
            _buildStatRow(
              '✅ 正確',
              '${report.correctNotes}/${report.totalNotes}',
              Colors.green[700]!,
            ),
            _buildStatRow(
              '❌ 漏音',
              '${report.missedNotes}',
              Colors.red[700]!,
            ),
            _buildStatRow(
              '🔴 錯音',
              '${report.wrongNotes}',
              Colors.red[700]!,
            ),
            _buildStatRow(
              '⏪ 搶拍',
              '${report.earlyNotes}',
              Colors.blue[700]!,
            ),
            _buildStatRow(
              '⏩ 拖拍',
              '${report.lateNotes}',
              Colors.blue[700]!,
            ),
          ],
        ),
      ),
    );
  }

  /// 統計行
  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 錯誤詳情卡片
  Widget _buildErrorsCard() {
    // 限制顯示錯誤數量
    final displayErrors = report.errors.take(20).toList();
    final hasMore = report.errors.length > 20;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '⚠️  錯誤詳情',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasMore)
                  Text(
                    '(顯示前 20 個,共 ${report.errors.length} 個)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 20, thickness: 1),
            const SizedBox(height: 4),
            ...displayErrors.asMap().entries.map((entry) {
              final index = entry.key;
              final error = entry.value;
              return _buildErrorItem(index + 1, error);
            }),
          ],
        ),
      ),
    );
  }

  /// 錯誤項目
  Widget _buildErrorItem(int index, PerformanceError error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index.toString().padLeft(2)}.  ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              '${_getErrorIcon(error.type)} ${error.message}',
              style: TextStyle(
                fontSize: 14,
                color: _getErrorColor(error.type),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 練習建議卡片
  Widget _buildSuggestionCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  '練習建議',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 20, thickness: 1),
            const SizedBox(height: 4),
            ...report.generateSuggestions().map((suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    suggestion,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// 操作按鈕
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.refresh),
            label: const Text('重新練習'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: 導航到樂譜頁面
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('樂譜功能開發中...')),
              );
            },
            icon: const Icon(Icons.music_note),
            label: const Text('查看樂譜'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// 獲取評級顏色
  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'S':
        return Colors.purple[700]!;
      case 'A':
        return Colors.green[700]!;
      case 'B':
        return Colors.blue[700]!;
      case 'C':
        return Colors.orange[700]!;
      case 'D':
      default:
        return Colors.red[700]!;
    }
  }

  /// 獲取錯誤圖標
  String _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.missedNote:
        return '❌';
      case ErrorType.wrongNote:
        return '🔴';
      case ErrorType.earlyTiming:
        return '⏪';
      case ErrorType.lateTiming:
        return '⏩';
      default:
        return '⚠️';
    }
  }

  /// 獲取錯誤顏色
  Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.missedNote:
        return Colors.red[700]!;
      case ErrorType.wrongNote:
        return Colors.red[700]!;
      case ErrorType.earlyTiming:
        return Colors.blue[700]!;
      case ErrorType.lateTiming:
        return Colors.blue[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}

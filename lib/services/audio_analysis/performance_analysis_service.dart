import 'models/analysis_report.dart';

/// 演奏分析服務接口
///
/// 整合音訊分析、MIDI解析、音符驗證,生成完整分析報告
abstract class IPerformanceAnalyzer {
  /// 分析錄音與MIDI標準答案的比對
  ///
  /// [wavPath] WAV 錄音檔案路徑
  /// [midiPath] MIDI 標準答案檔案路徑
  /// [onProgress] 進度回調 (0.0 - 1.0)
  /// 返回 [AnalysisReport] 完整分析報告
  Future<AnalysisReport> analyze(
    String wavPath,
    String midiPath, {
    void Function(double progress)? onProgress,
  });
}

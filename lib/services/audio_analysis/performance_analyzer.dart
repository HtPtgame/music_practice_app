import 'package:music_practice_app/services/audio_analysis/performance_analysis_service.dart';
import 'package:music_practice_app/services/audio_analysis/audio_analyzer_service_impl.dart';
import 'package:music_practice_app/services/audio_analysis/midi_parser_service.dart';
import 'package:music_practice_app/services/audio_analysis/note_verification_service_impl.dart';
import 'package:music_practice_app/services/audio_analysis/note_detector_service.dart';
import 'package:music_practice_app/services/audio_analysis/error_classification_service_impl_v2.dart';
import 'package:music_practice_app/services/audio_analysis/auto_alignment_service.dart';
import 'package:music_practice_app/services/audio_analysis/models/analysis_report.dart';
import 'package:music_practice_app/services/audio_analysis/models/performance_error.dart';
import 'package:music_practice_app/services/audio_analysis/models/confusion_matrix.dart';

/// Week 3 演奏分析器實現 (已回溯 - 2025/10/27)
///
/// 完整流程:
/// 1. 解析 MIDI 標準答案
/// 2. 分析 WAV 錄音頻譜
/// 2.5. 自動檢測錄音起始點並對齊時間軸 (Phase 1A)
/// 3. 檢測所有音符 (不僅驗證)
/// 4. 計算混淆矩陣 (TP/FP/FN)
/// 5. 驗證期望音符是否存在
/// 6. 分類錯誤類型
/// 7. 生成分析報告 (包含 F1 分數)
///
/// 新增功能 (2025/10/25):
/// - Phase 0: 檢測所有演奏音符,計算 Precision/Recall/F1 Score,防止「亂彈高分」問題
/// - Phase 1A: 自動檢測錄音起始點,支持 0-30 秒延遲容錯
///
/// 已停用功能 (2025/10/27):
/// - 動態參數系統 (多彈奏偵測、錯誤音檔偵測、環境雜訊抑制暫時停用)
/// - 原因: 對偵錯功能有負面影響，待後續優化
class PerformanceAnalyzer implements IPerformanceAnalyzer {
  final _midiParser = MidiParserService();
  final _audioAnalyzer = AudioAnalyzerServiceImpl();
  final _noteVerifier = NoteVerificationServiceImpl();
  final _noteDetector = NoteDetectorService(); // Phase 0 - 檢測所有音符
  final _autoAlignment = AutoAlignmentService(); // Phase 1A - 自動對齊
  final _errorClassifier = ErrorClassificationServiceImpl();

  @override
  Future<AnalysisReport> analyze(
    String wavPath,
    String midiPath, {
    double? energyThreshold, // 動態能量閾值（2025/10/27）
    double? timingTolerance, // 動態時間容錯（2025/10/27）
    void Function(double progress)? onProgress,
  }) async {
    final startTime = DateTime.now();

    try {
      // 步驟 1: 解析 MIDI (15%)
      onProgress?.call(0.0);
      final timeline = await _midiParser.parseFile(midiPath);

      if (timeline.events.isEmpty) {
        throw Exception('MIDI 文件中沒有音符');
      }
      onProgress?.call(0.15);

      // 步驟 2: 分析音訊 (30%)
      final spectrogram = await _audioAnalyzer.analyze(wavPath);
      onProgress?.call(0.45);

      // 步驟 2.5: 自動對齊時間軸 (Phase 1A - 5%)
      // 檢測錄音的實際起始點,並調整 MIDI 時間軸以匹配
      // 這解決了「延遲 10 秒才開始演奏」的問題
      final actualStart = _autoAlignment.detectActualStart(spectrogram);
      final alignedTimeline =
          _autoAlignment.alignMidiTimeline(timeline, actualStart);
      onProgress?.call(0.50);

      // 參數調優 Round 1: 設定音符範圍限制 (2025/10/25)
      // 從 MIDI 檔案中提取實際使用的音符範圍，避免掃描不必要的音符
      final midiNotes = alignedTimeline.events.map((e) => e.midiNote).toList();
      if (midiNotes.isNotEmpty) {
        final minNote = midiNotes.reduce((a, b) => a < b ? a : b);
        final maxNote = midiNotes.reduce((a, b) => a > b ? a : b);
        _noteDetector.setNoteRange(minNote: minNote, maxNote: maxNote);
      }

      // 步驟 3: 檢測所有音符 (Phase 0 - 15%)
      // 這是關鍵改進:不僅驗證,還要檢測出所有演奏的音符
      final allDetectedNotes = await _noteDetector.detectAll(spectrogram);
      onProgress?.call(0.65);

      // 步驟 4: 驗證期望音符 (15%)
      // 使用對齊後的時間軸進行驗證 (Phase 1A)
      // 傳入動態參數 (2025/10/27)
      final verificationResults = await _noteVerifier.verifyAll(
        alignedTimeline, // 使用對齊後的時間軸!
        spectrogram,
        energyThreshold: energyThreshold, // 傳入動態能量閾值
        timingTolerance: timingTolerance, // 傳入動態時間容錯
      );
      onProgress?.call(0.80);

      // 步驟 5: 計算混淆矩陣 (Phase 0 - 5%)
      final correctNotes = verificationResults.values.where((v) => v).length;
      final totalExpected = alignedTimeline.events.length; // 使用對齊後的數量
      final totalDetected = allDetectedNotes.length;

      final confusionMatrix = ConfusionMatrix.fromDetectionResults(
        totalExpectedNotes: totalExpected,
        totalDetectedNotes: totalDetected,
        correctlyMatched: correctNotes,
      );

      print('🎯 混淆矩陣計算完成:');
      print('   TP (正確): $correctNotes');
      print('   FP (多彈): ${confusionMatrix.falsePositive}');
      print('   FN (漏音): ${confusionMatrix.falseNegative}');
      print(
          '   Precision: ${(confusionMatrix.precision * 100).toStringAsFixed(1)}%');
      print('   Recall: ${(confusionMatrix.recall * 100).toStringAsFixed(1)}%');
      print(
          '   F1 Score: ${(confusionMatrix.f1Score * 100).toStringAsFixed(1)}%');

      onProgress?.call(0.85);

      // 步驟 6: 分類錯誤 (5%)
      // 傳入動態時間容錯 (2025/10/27)
      final errors = await _errorClassifier.classifyErrors(
        expectedTimeline: alignedTimeline, // 使用對齊後的時間軸!
        spectrogram: spectrogram,
        verificationResults: verificationResults,
        timingTolerance: timingTolerance, // 傳入動態時間容錯
      );

      // 步驟 7: 統計各類錯誤 (5%)
      int missedCount = 0;
      int wrongCount = 0;
      int earlyCount = 0;
      int lateCount = 0;

      for (final error in errors) {
        switch (error.type) {
          case ErrorType.missedNote:
            missedCount++;
            break;
          case ErrorType.wrongNote:
            wrongCount++;
            break;
          case ErrorType.earlyTiming:
            earlyCount++;
            break;
          case ErrorType.lateTiming:
            lateCount++;
            break;
          case ErrorType.correct:
            break;
        }
      }

      final processingTime = DateTime.now().difference(startTime);
      onProgress?.call(1.0);

      // 生成報告 (包含混淆矩陣與時間偏移)
      return AnalysisReport(
        totalNotes: totalExpected,
        correctNotes: correctNotes,
        wrongNotes: wrongCount,
        missedNotes: missedCount,
        earlyNotes: earlyCount,
        lateNotes: lateCount,
        errors: errors,
        processingTime: processingTime,
        timeOffset: actualStart, // Phase 1A: 記錄檢測到的時間偏移
        confusionMatrix: confusionMatrix, // Phase 0
        totalDetectedNotes: totalDetected, // Phase 0
      );
    } catch (e) {
      rethrow;
    }
  }
}

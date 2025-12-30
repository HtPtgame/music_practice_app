import 'dart:math';
import 'package:veloria/services/audio_analysis/performance_analysis_service.dart';
import 'package:veloria/services/audio_analysis/audio_analyzer_service_impl.dart';
import 'package:veloria/services/audio_analysis/midi_parser_service.dart';
import 'package:veloria/services/audio_analysis/note_verification_service_impl.dart';
// ✅ 1. 引入 V6 優化版偵測器 (關鍵！)
import 'package:veloria/services/audio_analysis/note_detector_service_optimized.dart'; 
import 'package:veloria/services/audio_analysis/error_classification_service_impl_v2.dart';
import 'package:veloria/services/audio_analysis/auto_alignment_service.dart';
import 'package:veloria/services/audio_analysis/timeline_analysis_service.dart';
import 'package:veloria/services/audio_analysis/models/analysis_report.dart';
import 'package:veloria/services/audio_analysis/models/performance_error.dart';
import 'package:veloria/services/audio_analysis/models/confusion_matrix.dart';
import 'package:veloria/services/audio_analysis/models/spectrogram.dart';

/// 演奏分析器 (V5 最終修正版 - 解決高音量泛音問題)
class PerformanceAnalyzer implements IPerformanceAnalyzer {
  final _midiParser = MidiParserService();
  final _audioAnalyzer = AudioAnalyzerServiceImpl();
  final _noteVerifier = NoteVerificationServiceImpl();
  
  // ✅ 2. 使用 Optimized 版本 (關鍵！)
  final _noteDetector = OptimizedNoteDetectorService(); 
  
  final _autoAlignment = AutoAlignmentService(); 
  final _timelineAnalysis = TimelineAnalysisService();
  final _errorClassifier = ErrorClassificationServiceImpl();

  @override
  Future<AnalysisReport> analyze(
    String wavPath,
    String midiPath, {
    double? energyThreshold,
    double? timingTolerance,
    void Function(double progress)? onProgress,
  }) async {
    final startTime = DateTime.now();

    try {
      // 1. 解析 MIDI
      onProgress?.call(0.0);
      final timeline = await _midiParser.parseFile(midiPath);
      if (timeline.events.isEmpty) throw Exception('MIDI 文件中沒有音符');
      onProgress?.call(0.15);

      // 2. 分析音訊
      final spectrogram = await _audioAnalyzer.analyze(wavPath);
      onProgress?.call(0.45);

      // 3. 🔥 計算自適應參數 (V5 核心修正：看 Peak)
      final adaptiveParams = _calculateAdaptiveParameters(
        spectrogram,
        energyThreshold: energyThreshold,
        timingTolerance: timingTolerance,
      );
      final effectiveEnergyThreshold = adaptiveParams['energyThreshold']!;
      final effectiveTimingTolerance = adaptiveParams['timingTolerance']!;
      
      print('🔧 自適應參數 (V5修正):');
      print('   能量閾值: ${effectiveEnergyThreshold.toStringAsFixed(4)} (已針對大音量優化)');
      print('   時間容錯: ${effectiveTimingTolerance.toStringAsFixed(3)}s');

      // 4. 時間軸分析
      TimelineAnalysisResult? timelineResult;
      try {
        timelineResult = await _timelineAnalysis.analyze(
          spectrogram: spectrogram,
          midiTimeline: timeline,
        );
      } catch (e) {
        print('⚠️ 時間軸分析失敗: $e');
      }

      // 5. 自動對齊
      final actualStart = _autoAlignment.detectActualStart(spectrogram);
      final alignedTimeline = _autoAlignment.alignMidiTimeline(timeline, actualStart);
      onProgress?.call(0.50);

      // 設定範圍
      final midiNotes = alignedTimeline.events.map((e) => e.midiNote).toList();
      if (midiNotes.isNotEmpty) {
        final minNote = midiNotes.reduce(min);
        final maxNote = midiNotes.reduce(max);
        _noteDetector.setNoteRange(minNote: minNote, maxNote: maxNote);
      }

      // 6. 檢測所有音符
      final allDetectedNotes = await _noteDetector.detectAll(spectrogram);
      onProgress?.call(0.65);

      // 7. 驗證期望音符
      final verificationResults = await _noteVerifier.verifyAll(
        alignedTimeline,
        spectrogram,
        energyThreshold: effectiveEnergyThreshold, // 傳入正確的高門檻
        timingTolerance: effectiveTimingTolerance,
      );
      onProgress?.call(0.80);

      // 8. 計算混淆矩陣
      final correctNotes = verificationResults.values.where((v) => v).length;
      final totalExpected = alignedTimeline.events.length;
      final totalDetected = allDetectedNotes.length;

      final confusionMatrix = ConfusionMatrix.fromDetectionResults(
        totalExpectedNotes: totalExpected,
        totalDetectedNotes: totalDetected,
        correctlyMatched: correctNotes,
      );

      print('🎯 混淆矩陣:');
      print('   TP: $correctNotes, FP: ${confusionMatrix.falsePositive}, FN: ${confusionMatrix.falseNegative}');

      // 9. 分類錯誤
      final errors = await _errorClassifier.classifyErrors(
        expectedTimeline: alignedTimeline,
        spectrogram: spectrogram,
        verificationResults: verificationResults,
        timingTolerance: effectiveTimingTolerance,
      );

      // 10. 統計與報告
      int missedCount = 0, wrongCount = 0, earlyCount = 0, lateCount = 0;
      for (final error in errors) {
        if (error.type == ErrorType.missedNote) missedCount++;
        else if (error.type == ErrorType.wrongNote) wrongCount++;
        else if (error.type == ErrorType.earlyTiming) earlyCount++;
        else if (error.type == ErrorType.lateTiming) lateCount++;
      }

      final processingTime = DateTime.now().difference(startTime);
      onProgress?.call(1.0);

      return AnalysisReport(
        totalNotes: totalExpected,
        correctNotes: correctNotes,
        wrongNotes: wrongCount,
        missedNotes: missedCount,
        earlyNotes: earlyCount,
        lateNotes: lateCount,
        errors: errors,
        processingTime: processingTime,
        timeOffset: actualStart,
        confusionMatrix: confusionMatrix,
        totalDetectedNotes: totalDetected,
        timelineAnalysis: timelineResult,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 🔥🔥🔥 V5 參數計算邏輯 (修正版) 🔥🔥🔥
  /// 
  /// 針對 MIDI 轉 WAV 這種「底噪極低 (0) 但峰值極高 (>1.0)」的檔案
  /// 強制使用「動態相對門檻」
  Map<String, double> _calculateAdaptiveParameters(
    Spectrogram spectrogram, {
    double? energyThreshold,
    double? timingTolerance,
  }) {
    if (energyThreshold != null && timingTolerance != null) {
      return {'energyThreshold': energyThreshold, 'timingTolerance': timingTolerance};
    }

    // 1. 估計信號峰值 (找出最大聲的地方)
    final signalPeak = _estimateSignalPeak(spectrogram);
    
    // 2. 估計底噪
    final noiseFloor = _estimateNoiseFloor(spectrogram);

    print('📈 V5 分析: Peak=${signalPeak.toStringAsFixed(4)}, Noise=${noiseFloor.toStringAsFixed(6)}');

    // 🔥 關鍵修正：動態相對門檻
    // 如果是普通錄音 (Peak ~0.8)，門檻約 0.28
    // 如果是過載錄音 (Peak ~1.4)，門檻會自動拉高到 0.49，擋住泛音
    double minThreshold = 0.15; // 絕對底限
    double relativeThreshold = signalPeak * 0.35; // 相對門檻 (35% 的峰值)
    
    // 如果發現過載嚴重 (>1.2)，比例再提高一點
    if (signalPeak > 1.2) {
       relativeThreshold = signalPeak * 0.45; // 提高到 45%
    }
    
    // 最終門檻取最大值
    double finalThreshold = max(minThreshold, relativeThreshold);
    
    // 如果底噪很大，也要考慮進去 (傳統邏輯)
    final snr = signalPeak / max(noiseFloor, 0.001);
    double noiseBasedThreshold = noiseFloor * (snr > 20 ? 3.0 : 4.0);
    finalThreshold = max(finalThreshold, noiseBasedThreshold);
    
    // 限制範圍
    final clampedThreshold = finalThreshold.clamp(0.05, 0.85);

    // 時間容錯調整
    final adaptiveTolerance = snr > 15 ? 0.15 : 0.20;

    return {
      'energyThreshold': energyThreshold ?? clampedThreshold,
      'timingTolerance': timingTolerance ?? adaptiveTolerance,
    };
  }

  double _estimateSignalPeak(Spectrogram spectrogram) {
    final energies = <double>[];
    // 抽樣檢查，提升效能
    final step = max(1, spectrogram.timeFrames ~/ 200);
    for (int frame = 0; frame < spectrogram.timeFrames; frame += step) {
      energies.add(_calculateFrameEnergy(spectrogram, frame));
    }
    if (energies.isEmpty) return 0.0;
    energies.sort();
    // 取 95% 分位數作為峰值代表
    return energies[(energies.length * 0.95).floor()];
  }

  double _estimateNoiseFloor(Spectrogram spectrogram) {
    // 取前 0.5 秒估算底噪
    final checkFrames = min(20, spectrogram.timeFrames);
    final energies = <double>[];
    for (int frame = 0; frame < checkFrames; frame++) {
      energies.add(_calculateFrameEnergy(spectrogram, frame));
    }
    if (energies.isEmpty) return 0.0;
    energies.sort();
    return energies[energies.length ~/ 2]; // 中位數
  }

  double _calculateFrameEnergy(Spectrogram spectrogram, int frame) {
    if (frame >= spectrogram.timeFrames) return 0.0;
    double sum = 0.0;
    for (final val in spectrogram.data[frame]) sum += val * val;
    return sqrt(sum / spectrogram.freqBins);
  }
}
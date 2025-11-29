import 'dart:math';
import 'package:music_practice_app/services/audio_analysis/performance_analysis_service.dart';
import 'package:music_practice_app/services/audio_analysis/audio_analyzer_service_impl.dart';
import 'package:music_practice_app/services/audio_analysis/midi_parser_service.dart';
import 'package:music_practice_app/services/audio_analysis/note_verification_service_impl.dart';
import 'package:music_practice_app/services/audio_analysis/note_detector_service.dart';
import 'package:music_practice_app/services/audio_analysis/error_classification_service_impl_v2.dart';
import 'package:music_practice_app/services/audio_analysis/auto_alignment_service.dart';
import 'package:music_practice_app/services/audio_analysis/timeline_analysis_service.dart';
import 'package:music_practice_app/services/audio_analysis/models/analysis_report.dart';
import 'package:music_practice_app/services/audio_analysis/models/performance_error.dart';
import 'package:music_practice_app/services/audio_analysis/models/confusion_matrix.dart';
import 'package:music_practice_app/services/audio_analysis/models/spectrogram.dart';

/// Week 3 演奏分析器實現 (已恢復 v3.4-v3.6 功能 - 2025/11/27)
///
/// 完整流程:
/// 1. 解析 MIDI 標準答案
/// 2. 分析 WAV 錄音頻譜
/// 2.5. 時間軸分析 (Phase 1B - 新增)
/// 2.6. 自動檢測錄音起始點並對齊時間軸 (Phase 1A)
/// 3. 檢測所有音符 (不僅驗證)
/// 4. 計算混淆矩陣 (TP/FP/FN)
/// 5. 驗證期望音符是否存在
/// 6. 分類錯誤類型
/// 7. 生成分析報告 (包含 F1 分數)
///
/// 功能清單:
/// - Phase 0: 檢測所有演奏音符,計算 Precision/Recall/F1 Score,防止「亂彈高分」問題
/// - Phase 1A: 自動檢測錄音起始點,支持 0-30 秒延遲容錯
/// - Phase 1B: 時間軸分析 - 偵測延遲開始、中斷、短錄音、跳過段落
///
/// v3.4-v3.6 恢復功能 (2025/11/27):
/// - 時間軸分析服務 (TimelineAnalysisService)
/// - 短錄音偵測 (durationPenalty)
/// - 節奏評分優化
class PerformanceAnalyzer implements IPerformanceAnalyzer {
  final _midiParser = MidiParserService();
  final _audioAnalyzer = AudioAnalyzerServiceImpl();
  final _noteVerifier = NoteVerificationServiceImpl();
  final _noteDetector = NoteDetectorService(); // Phase 0 - 檢測所有音符
  final _autoAlignment = AutoAlignmentService(); // Phase 1A - 自動對齊
  final _timelineAnalysis = TimelineAnalysisService(); // Phase 1B - 時間軸分析
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

      // 步驟 2.3: 動態閾值計算 (基於 SNR 自適應)
      // 2025/11/29: 解決「內建錄音 vs 上傳錄音」分數差異問題
      // 內建錄音噪音底板低 (~0.027)，上傳錄音噪音高 (~0.194)
      // 使用自適應閾值而非固定值 0.38
      final adaptiveParams = _calculateAdaptiveParameters(
        spectrogram,
        energyThreshold: energyThreshold,
        timingTolerance: timingTolerance,
      );
      final effectiveEnergyThreshold = adaptiveParams['energyThreshold']!;
      final effectiveTimingTolerance = adaptiveParams['timingTolerance']!;
      print('🔧 自適應參數:');
      print('   能量閾值: ${effectiveEnergyThreshold.toStringAsFixed(4)} '
          '(${energyThreshold != null ? "外部指定" : "自動計算"})');
      print('   時間容錯: ${effectiveTimingTolerance.toStringAsFixed(3)}s');

      // 步驟 2.5: 時間軸分析 (Phase 1B - 5%)
      // 分析錄音的整體時間軸特徵：延遲開始、中斷、跳過段落等
      TimelineAnalysisResult? timelineResult;
      try {
        timelineResult = await _timelineAnalysis.analyze(
          spectrogram: spectrogram,
          midiTimeline: timeline,
        );
        print('📊 時間軸分析狀態: ${timelineResult.overallStatus}');
      } catch (e) {
        print('⚠️ 時間軸分析失敗 (非致命): $e');
      }

      // 步驟 2.6: 自動對齊時間軸 (Phase 1A - 5%)
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
      // 傳入自適應參數 (2025/11/29 更新 - 基於 SNR)
      final verificationResults = await _noteVerifier.verifyAll(
        alignedTimeline, // 使用對齊後的時間軸!
        spectrogram,
        energyThreshold: effectiveEnergyThreshold, // 使用自適應能量閾值
        timingTolerance: effectiveTimingTolerance, // 使用自適應時間容錯
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
      // 使用自適應時間容錯 (2025/11/29 更新)
      final errors = await _errorClassifier.classifyErrors(
        expectedTimeline: alignedTimeline, // 使用對齊後的時間軸!
        spectrogram: spectrogram,
        verificationResults: verificationResults,
        timingTolerance: effectiveTimingTolerance, // 使用自適應時間容錯
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

      // 生成報告 (包含混淆矩陣、時間偏移與時間軸分析)
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
        timelineAnalysis: timelineResult, // Phase 1B: 時間軸分析
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 計算自適應參數 (基於信噪比 SNR)
  ///
  /// 問題背景 (2025/11/29):
  /// - 內建錄音: 噪音底板 ~0.027, 固定閾值 0.38 太高 → Recall 63.9%
  /// - 上傳錄音: 噪音底板 ~0.194, 信號段落過度分割 (173段) → FP 5999
  ///
  /// 解決方案:
  /// 根據實際音訊的噪音底板動態調整能量閾值
  /// - 低噪音錄音 → 降低閾值, 提高敏感度
  /// - 高噪音錄音 → 提高閾值, 減少誤判
  Map<String, double> _calculateAdaptiveParameters(
    Spectrogram spectrogram, {
    double? energyThreshold,
    double? timingTolerance,
  }) {
    // 如果外部已指定參數，優先使用
    if (energyThreshold != null && timingTolerance != null) {
      return {
        'energyThreshold': energyThreshold,
        'timingTolerance': timingTolerance,
      };
    }

    // 估計噪音底板（使用前 0.5 秒的中位數能量）
    final noiseFloor = _estimateNoiseFloor(spectrogram);
    
    // 估計信號峰值（使用整體能量的 95 分位數）
    final signalPeak = _estimateSignalPeak(spectrogram);
    
    // 計算信噪比 (SNR)
    final snr = signalPeak / max(noiseFloor, 0.001);
    
    print('📈 音訊特徵分析:');
    print('   噪音底板: ${noiseFloor.toStringAsFixed(6)}');
    print('   信號峰值: ${signalPeak.toStringAsFixed(6)}');
    print('   信噪比 (SNR): ${snr.toStringAsFixed(2)}');

    // 計算自適應能量閾值
    // 策略: 閾值 = 噪音底板 × 倍率，倍率根據 SNR 調整
    //
    // 參考數據:
    // - 內建錄音: 噪音 0.027, 需要閾值約 0.08-0.15 (3-6倍)
    // - 上傳錄音: 噪音 0.194, 需要閾值約 0.58-0.78 (3-4倍)
    //
    // 統一策略: 使用噪音底板的 3-5 倍作為能量閾值
    // 高 SNR (>20): 可以用較低倍率 (3倍)
    // 中 SNR (10-20): 使用中等倍率 (4倍)  
    // 低 SNR (<10): 使用較高倍率 (5倍)
    double multiplier;
    if (snr > 20) {
      multiplier = 3.0;
    } else if (snr > 10) {
      multiplier = 4.0;
    } else {
      multiplier = 5.0;
    }
    
    // 計算自適應閾值
    final adaptiveThreshold = noiseFloor * multiplier;
    
    // 限制在合理範圍內 (0.05 - 0.80)
    final clampedThreshold = adaptiveThreshold.clamp(0.05, 0.80);
    
    print('   SNR 倍率: ${multiplier.toStringAsFixed(1)}');
    print('   計算閾值: ${adaptiveThreshold.toStringAsFixed(4)}');
    print('   最終閾值: ${clampedThreshold.toStringAsFixed(4)}');

    // 時間容錯：根據 SNR 調整
    // 高 SNR → 較嚴格 (0.15s)
    // 低 SNR → 較寬鬆 (0.25s)
    final adaptiveTolerance = snr > 15 ? 0.15 : (snr > 8 ? 0.20 : 0.25);

    return {
      'energyThreshold': energyThreshold ?? clampedThreshold,
      'timingTolerance': timingTolerance ?? adaptiveTolerance,
    };
  }

  /// 估計噪音底板（使用前 0.5 秒的中位數能量）
  double _estimateNoiseFloor(Spectrogram spectrogram) {
    const windowSize = 0.5;
    final windowFrames = (windowSize / spectrogram.timeResolution).round();
    final maxFrames = min(windowFrames, spectrogram.timeFrames);

    final energies = <double>[];
    for (int frame = 0; frame < maxFrames; frame++) {
      energies.add(_calculateFrameEnergy(spectrogram, frame));
    }

    energies.sort();
    return energies.isNotEmpty ? energies[energies.length ~/ 2] : 0.0;
  }

  /// 估計信號峰值（使用整體能量的 95 分位數）
  double _estimateSignalPeak(Spectrogram spectrogram) {
    final energies = <double>[];
    for (int frame = 0; frame < spectrogram.timeFrames; frame++) {
      energies.add(_calculateFrameEnergy(spectrogram, frame));
    }

    if (energies.isEmpty) return 0.0;

    energies.sort();
    final p95Index = (energies.length * 0.95).floor();
    return energies[p95Index.clamp(0, energies.length - 1)];
  }

  /// 計算單幀能量
  double _calculateFrameEnergy(Spectrogram spectrogram, int frame) {
    if (frame < 0 || frame >= spectrogram.timeFrames) return 0.0;

    double totalEnergy = 0.0;
    for (int bin = 0; bin < spectrogram.freqBins; bin++) {
      final magnitude = spectrogram.data[frame][bin];
      totalEnergy += magnitude * magnitude;
    }

    return sqrt(totalEnergy / spectrogram.freqBins);
  }
}

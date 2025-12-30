// 📂 檔名: lib/services/audio_analysis/error_classification_service_impl_v2.dart

import 'package:veloria/services/audio_analysis/models/performance_error.dart';
import 'package:veloria/services/audio_analysis/models/spectrogram.dart';
import 'package:veloria/services/audio_analysis/spectral_flux_onset_detector.dart';

/// 錯誤分類服務實現 (舊版還原 - 固定參數版)
/// 已停用動態參數功能，使用固定節奏容錯窗口
class ErrorClassificationServiceImpl {
  /// 能量檢測閾值
  static const double energyThreshold = 0.08; 

  /// 固定節奏容錯窗口 (秒) - ±100ms
  static const double timingTolerance = 0.10;

  /// Phase 2B: Onset 檢測器
  final _onsetDetector = SpectralFluxOnsetDetector();

  Future<List<PerformanceError>> classifyErrors({
    required dynamic expectedTimeline, // 還原為 dynamic，避免引入問題
    required Spectrogram spectrogram,
    required Map<dynamic, bool> verificationResults,
    double? timingTolerance, // 動態時間容錯
  }) async {
    // 使用動態參數，如果沒有則使用固定預設值
    final tolerance = timingTolerance ?? ErrorClassificationServiceImpl.timingTolerance;

    final errors = <PerformanceError>[];

    // Phase 2B: 預先檢測所有 onset 事件
    final onsets = _onsetDetector.detectOnsets(spectrogram);

    print('🎯 錯誤分類參數:');
    print('   時間容錯: ±${(tolerance * 1000).toStringAsFixed(0)}ms');

    // 檢測漏音
    for (final entry in verificationResults.entries) {
      final dynamic expectedNote = entry.key;
      final wasDetected = entry.value;

      if (!wasDetected) {
        errors.add(PerformanceError(
          type: ErrorType.missedNote,
          expectedNote: expectedNote.midiNote,
          // ⚠️ 修正點：配合新模型，這裡原本是 expectedTime，現在改用 time
          time: expectedNote.startTime, 
          message: '漏音: ${expectedNote.noteName} 在 ${expectedNote.startTime.toStringAsFixed(2)}秒',
          confidence: 0.9,
        ));
      }
    }

    // 檢測節奏錯誤 (Phase 2B: 使用頻譜通量 onset)
    final detectedNotes = verificationResults.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    for (final dynamic expectedNote in detectedNotes) {
      // Phase 2B: 使用頻譜通量找最近的 onset
      final nearestOnset = _onsetDetector.getOnsetNear(
        onsets,
        expectedNote.startTime,
        tolerance * 3, // 搜索範圍
      );

      if (nearestOnset != null) {
        final timeOffset = nearestOnset.time - expectedNote.startTime;

        if (timeOffset.abs() > tolerance) {
          // 使用動態容錯
          final type = timeOffset > 0 ? ErrorType.lateTiming : ErrorType.earlyTiming;
          final direction = timeOffset > 0 ? '晚了' : '早了';
          final offsetMs = (timeOffset.abs() * 1000).toStringAsFixed(0);

          errors.add(PerformanceError(
            type: type,
            expectedNote: expectedNote.midiNote,
            actualNote: expectedNote.midiNote,
            // ⚠️ 修正點：這裡原本是 expectedTime，現在改用 time
            time: expectedNote.startTime,
            actualTime: nearestOnset.time,
            timingOffset: timeOffset,
            message: '節奏偏差: ${expectedNote.noteName} $direction ${offsetMs}ms 在 ${expectedNote.startTime.toStringAsFixed(2)}秒',
            confidence: 0.9, // Phase 2B: 提高置信度
          ));
        }
      }
    }

    // 按時間排序
    errors.sort((a, b) => a.time.compareTo(b.time));

    return errors;
  }
}
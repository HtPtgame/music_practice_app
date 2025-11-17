import 'package:music_practice_app/services/audio_analysis/models/note_event.dart';
import 'package:music_practice_app/services/audio_analysis/models/performance_error.dart';
import 'package:music_practice_app/services/audio_analysis/models/spectrogram.dart';
import 'package:music_practice_app/services/audio_analysis/spectral_flux_onset_detector.dart';

/// 錯誤分類服務實現 (固定參數版 - 2025/10/27)
///
/// 已停用動態參數功能，使用固定節奏容錯窗口
class ErrorClassificationServiceImpl {
  /// 能量檢測閾值
  static const double energyThreshold = 0.08; // 進一步降低以提高靈敏度

  /// 固定節奏容錯窗口 (秒) - ±100ms (已停用動態調整功能)
  static const double timingTolerance = 0.10;

  /// Phase 2B: Onset 檢測器
  final _onsetDetector = SpectralFluxOnsetDetector();

  Future<List<PerformanceError>> classifyErrors({
    required MidiTimeline expectedTimeline,
    required Spectrogram spectrogram,
    required Map<NoteEvent, bool> verificationResults,
    double? timingTolerance, // 動態時間容錯（2025/10/27）
  }) async {
    // 使用動態參數，如果沒有則使用固定預設值
    final tolerance =
        timingTolerance ?? ErrorClassificationServiceImpl.timingTolerance;

    final errors = <PerformanceError>[];

    // Phase 2B: 預先檢測所有 onset 事件
    final onsets = _onsetDetector.detectOnsets(spectrogram);

    print('🎯 錯誤分類參數:');
    print('   時間容錯: ±${(tolerance * 1000).toStringAsFixed(0)}ms');

    // 檢測漏音
    for (final entry in verificationResults.entries) {
      final expectedNote = entry.key;
      final wasDetected = entry.value;

      if (!wasDetected) {
        errors.add(PerformanceError(
          type: ErrorType.missedNote,
          expectedNote: expectedNote.midiNote,
          expectedTime: expectedNote.startTime,
          message:
              '漏音: ${expectedNote.noteName} 在 ${expectedNote.startTime.toStringAsFixed(2)}秒',
          confidence: 0.9,
        ));
      }
    }

    // 檢測節奏錯誤 (Phase 2B: 使用頻譜通量 onset)
    final detectedNotes = verificationResults.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    for (final expectedNote in detectedNotes) {
      // Phase 2B: 使用頻譜通量找最近的 onset
      final nearestOnset = _onsetDetector.getOnsetNear(
        onsets,
        expectedNote.startTime,
        tolerance * 3, // 搜索範圍（使用動態參數）
      );

      if (nearestOnset != null) {
        final timeOffset = nearestOnset.time - expectedNote.startTime;

        if (timeOffset.abs() > tolerance) {
          // 使用動態容錯
          final type =
              timeOffset > 0 ? ErrorType.lateTiming : ErrorType.earlyTiming;
          final direction = timeOffset > 0 ? '晚了' : '早了';
          final offsetMs = (timeOffset.abs() * 1000).toStringAsFixed(0);

          errors.add(PerformanceError(
            type: type,
            expectedNote: expectedNote.midiNote,
            actualNote: expectedNote.midiNote,
            expectedTime: expectedNote.startTime,
            actualTime: nearestOnset.time,
            timingOffset: timeOffset,
            message:
                '節奏偏差: ${expectedNote.noteName} $direction ${offsetMs}ms (Onset)',
            confidence: 0.9, // Phase 2B: 提高置信度
          ));
        }
      }
    }

    // 按時間排序
    // 按時間排序
    errors.sort((a, b) => a.expectedTime.compareTo(b.expectedTime));

    return errors;
  }

  // Phase 2B: 移除舊的簡單能量檢測方法,改用頻譜通量
}

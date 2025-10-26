import 'package:music_practice_app/services/audio_analysis/models/note_event.dart';
import 'package:music_practice_app/services/audio_analysis/models/performance_error.dart';
import 'package:music_practice_app/services/audio_analysis/models/spectrogram.dart';
import 'package:music_practice_app/services/audio_analysis/spectral_flux_onset_detector.dart';

/// 錯誤分類服務實現 (動態參數版 - 2025/10/26)
/// 
/// Round 9: 支援根據樂曲速度動態調整 timingTolerance (0.08~0.20秒)
class ErrorClassificationServiceImpl {
  /// 能量檢測閾值
  static const double energyThreshold = 0.08;  // 進一步降低以提高靈敏度
  
  /// Round 9: 動態參數
  /// 節奏容錯窗口 (秒) - 預設 ±100ms，可根據樂曲速度調整 0.08~0.20秒
  double _timingTolerance = 0.10;
  
  /// 設定動態 timingTolerance (Round 9)
  void setTimingTolerance(double tolerance) {
    _timingTolerance = tolerance.clamp(0.08, 0.20);
    print('🎚️ [ErrorClassifier] timingTolerance 已更新: ±${(_timingTolerance * 1000).toStringAsFixed(0)}ms');
  }
  
  /// 取得當前 timingTolerance
  double get timingTolerance => _timingTolerance;
  
  /// Phase 2B: Onset 檢測器
  final _onsetDetector = SpectralFluxOnsetDetector();

  Future<List<PerformanceError>> classifyErrors({
    required MidiTimeline expectedTimeline,
    required Spectrogram spectrogram,
    required Map<NoteEvent, bool> verificationResults,
  }) async {
    final errors = <PerformanceError>[];
    
    // Phase 2B: 預先檢測所有 onset 事件
    final onsets = _onsetDetector.detectOnsets(spectrogram);
    
    // 檢測漏音
    for (final entry in verificationResults.entries) {
      final expectedNote = entry.key;
      final wasDetected = entry.value;
      
      if (!wasDetected) {
        errors.add(PerformanceError(
          type: ErrorType.missedNote,
          expectedNote: expectedNote.midiNote,
          expectedTime: expectedNote.startTime,
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
    
    for (final expectedNote in detectedNotes) {
      // Phase 2B: 使用頻譜通量找最近的 onset
      final nearestOnset = _onsetDetector.getOnsetNear(
        onsets,
        expectedNote.startTime,
        timingTolerance * 3, // 搜索範圍 ±300ms
      );
      
      if (nearestOnset != null) {
        final timeOffset = nearestOnset.time - expectedNote.startTime;
        
        if (timeOffset.abs() > timingTolerance) {
          final type = timeOffset > 0 ? ErrorType.lateTiming : ErrorType.earlyTiming;
          final direction = timeOffset > 0 ? '晚了' : '早了';
          final offsetMs = (timeOffset.abs() * 1000).toStringAsFixed(0);
          
          errors.add(PerformanceError(
            type: type,
            expectedNote: expectedNote.midiNote,
            actualNote: expectedNote.midiNote,
            expectedTime: expectedNote.startTime,
            actualTime: nearestOnset.time,
            timingOffset: timeOffset,
            message: '節奏偏差: ${expectedNote.noteName} $direction ${offsetMs}ms (Onset)',
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

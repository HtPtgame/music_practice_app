import 'package:music_practice_app/services/audio_analysis/models/note_event.dart';
import 'package:music_practice_app/services/audio_analysis/models/performance_error.dart';
import 'package:music_practice_app/services/audio_analysis/models/spectrogram.dart';

/// 錯誤分類服務實現 (Week 3)
class ErrorClassificationServiceImpl {
  /// 節奏容錯窗口 (秒)
  static const double timingTolerance = 0.20; // ±200ms (對合成音訊更寬容)
  
  /// 能量檢測閾值
  static const double energyThreshold = 0.08;  // 進一步降低以提高靈敏度

  Future<List<PerformanceError>> classifyErrors({
    required MidiTimeline expectedTimeline,
    required Spectrogram spectrogram,
    required Map<NoteEvent, bool> verificationResults,
  }) async {
    final errors = <PerformanceError>[];
    
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
    
    // 檢測節奏錯誤
    final detectedNotes = verificationResults.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    
    for (final expectedNote in detectedNotes) {
      final actualOnset = _detectOnset(
        spectrogram,
        expectedNote.startTime,
        expectedNote.frequency,
      );
      
      if (actualOnset != null) {
        final timeOffset = actualOnset - expectedNote.startTime;
        
        if (timeOffset.abs() > timingTolerance) {
          final type = timeOffset > 0 ? ErrorType.lateTiming : ErrorType.earlyTiming;
          final direction = timeOffset > 0 ? '晚了' : '早了';
          final offsetMs = (timeOffset.abs() * 1000).toStringAsFixed(0);
          
          errors.add(PerformanceError(
            type: type,
            expectedNote: expectedNote.midiNote,
            actualNote: expectedNote.midiNote,
            expectedTime: expectedNote.startTime,
            actualTime: actualOnset,
            timingOffset: timeOffset,
            message: '節奏偏差: ${expectedNote.noteName} $direction ${offsetMs}ms',
            confidence: 0.8,
          ));
        }
      }
    }
    
    // 按時間排序
    errors.sort((a, b) => a.expectedTime.compareTo(b.expectedTime));
    
    return errors;
  }

  /// 檢測音符起始點
  double? _detectOnset(
    Spectrogram spectrogram,
    double expectedTime,
    double frequency,
  ) {
    final searchWindowStart = expectedTime - 0.2;
    final searchWindowEnd = expectedTime + 0.2;
    
    final startFrame = spectrogram.timeToFrame(searchWindowStart);
    final endFrame = spectrogram.timeToFrame(searchWindowEnd);
    final freqBin = spectrogram.freqToBin(frequency);
    
    double maxEnergy = 0.0;
    int maxFrame = startFrame;
    
    // 尋找能量峰值
    for (int frame = startFrame; frame <= endFrame; frame++) {
      final energy = spectrogram.data[frame][freqBin];
      if (energy > maxEnergy) {
        maxEnergy = energy;
        maxFrame = frame;
      }
    }
    
    if (maxEnergy < energyThreshold) {
      return null;
    }
    
    // 尋找能量上升起始點
    for (int frame = maxFrame; frame > startFrame; frame--) {
      final currentEnergy = spectrogram.data[frame][freqBin];
      final prevEnergy = spectrogram.data[frame - 1][freqBin];
      
      if (prevEnergy < currentEnergy * 0.5) {
        return frame * spectrogram.timeResolution;
      }
    }
    
    return maxFrame * spectrogram.timeResolution;
  }
}

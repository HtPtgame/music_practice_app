import 'dart:math';
import 'note_verification_service.dart';
import 'models/spectrogram.dart';
import 'models/note_event.dart';

/// 音符驗證服務實現 (固定參數版 - 2025/10/27)
/// 
/// 使用頻譜模板匹配 + 諧波驗證來判斷音符是否存在
/// 已停用動態參數功能，使用固定閾值
class NoteVerificationServiceImpl implements INoteVerifier {
  // 驗證參數 (固定)
  static const List<double> harmonicWeights = [1.0, 0.5, 0.25];  // 諧波權重 [基頻, 2倍頻, 3倍頻]
  static const int numHarmonics = 3;  // 檢查的諧波數量
  
  /// 固定能量閾值 (已停用動態調整功能)
  static const double energyThreshold = 0.38;

  @override
  Future<bool> verifyNote(
    int midiNote,
    double time,
    Spectrogram spectrogram,
  ) async {
    try {
      // 計算目標頻率
      final frequencies = _calculateHarmonics(midiNote);
      
      // 定位時間幀
      final frameIndex = spectrogram.timeToFrame(time);
      if (frameIndex < 0 || frameIndex >= spectrogram.timeFrames) {
        return false;
      }

      // 提取該幀的頻譜
      final spectrum = spectrogram.data[frameIndex];

      // 諧波驗證
      final harmonicScore = _calculateHarmonicScore(
        spectrum,
        frequencies,
        spectrogram,
      );

      // 判斷是否超過閾值
      return harmonicScore > energyThreshold;
    } catch (e) {
      print('❌ 音符驗證錯誤: $e');
      return false;
    }
  }

  @override
  Future<double> verifyNoteEvent(
    NoteEvent noteEvent,
    Spectrogram spectrogram,
  ) async {
    try {
      // 計算音符持續時間內的平均置信度
      final startFrame = spectrogram.timeToFrame(noteEvent.startTime);
      final endFrame = spectrogram.timeToFrame(noteEvent.endTime);
      
      if (startFrame < 0 || endFrame >= spectrogram.timeFrames) {
        return 0.0;
      }

      final frequencies = _calculateHarmonics(noteEvent.midiNote);
      double totalScore = 0.0;
      int count = 0;

      // 在音符持續時間內採樣多個時間點
      final sampleInterval = max(1, (endFrame - startFrame) ~/ 5); // 最多採樣5個點
      
      for (int frame = startFrame; frame <= endFrame; frame += sampleInterval) {
        final spectrum = spectrogram.data[frame];
        final score = _calculateHarmonicScore(spectrum, frequencies, spectrogram);
        totalScore += score;
        count++;
      }

      // 返回平均置信度 (0-1)
      return count > 0 ? (totalScore / count).clamp(0.0, 1.0) : 0.0;
    } catch (e) {
      print('❌ 音符事件驗證錯誤: $e');
      return 0.0;
    }
  }

  @override
  Future<Map<NoteEvent, bool>> verifyAll(
    MidiTimeline timeline,
    Spectrogram spectrogram, {
    double? energyThreshold,     // 動態能量閾值（2025/10/27）
    double? timingTolerance,     // 動態時間容錯（2025/10/27）
  }) async {
    // 使用動態參數，如果沒有則使用固定預設值
    final threshold = energyThreshold ?? NoteVerificationServiceImpl.energyThreshold;
    
    final results = <NoteEvent, bool>{};
    
    print('🔍 開始驗證 ${timeline.events.length} 個音符...');
    print('   能量閾值: ${threshold.toStringAsFixed(2)}');
    if (timingTolerance != null) {
      print('   時間容錯: ±${(timingTolerance * 1000).toStringAsFixed(0)}ms');
    }
    int verified = 0;

    for (final event in timeline.events) {
      // 使用音符中點時間進行驗證
      final midTime = (event.startTime + event.endTime) / 2;
      final isPresent = await _verifyNoteWithThreshold(
        event.midiNote, 
        midTime, 
        spectrogram, 
        threshold,  // 使用動態閾值
      );
      results[event] = isPresent;
      
      if (isPresent) verified++;
    }

    print('✅ 驗證完成: $verified/${timeline.events.length} 個音符被檢測到');
    
    return results;
  }
  
  /// 使用指定閾值驗證音符（新增方法）
  Future<bool> _verifyNoteWithThreshold(
    int midiNote,
    double time,
    Spectrogram spectrogram,
    double threshold,
  ) async {
    try {
      // 計算目標頻率
      final frequencies = _calculateHarmonics(midiNote);
      
      // 定位時間幀
      final frameIndex = spectrogram.timeToFrame(time);
      if (frameIndex < 0 || frameIndex >= spectrogram.timeFrames) {
        return false;
      }

      // 提取該幀的頻譜
      final spectrum = spectrogram.data[frameIndex];

      // 諧波驗證
      final harmonicScore = _calculateHarmonicScore(
        spectrum,
        frequencies,
        spectrogram,
      );

      // 判斷是否超過指定閾值
      return harmonicScore > threshold;
    } catch (e) {
      print('❌ 音符驗證錯誤: $e');
      return false;
    }
  }

  /// 音高匹配驗證（暫時停用 - 2025/10/27 21:47）
  /// 原因：音高檢測過於嚴格，導致正確樣本被大量誤判
  /// 未來改進方向：使用更魯棒的頻譜分析算法或機器學習模型
  /*
  Future<bool> _verifyPitchMatching(...) async {
    // 實作已註解，保留供未來參考
  }
  */

  /// 計算諧波分數
  /// 
  /// 檢查基頻及其諧波的能量,加權求和
  double _calculateHarmonicScore(
    List<double> spectrum,
    List<double> frequencies,
    Spectrogram spectrogram,
  ) {
    double score = 0.0;

    for (int i = 0; i < numHarmonics && i < frequencies.length; i++) {
      final freq = frequencies[i];
      final freqBin = spectrogram.freqToBin(freq);
      
      if (freqBin >= 0 && freqBin < spectrum.length) {
        // 獲取該頻率的能量
        final energy = spectrum[freqBin];
        
        // 應用諧波權重
        final weight = i < harmonicWeights.length ? harmonicWeights[i] : 0.1;
        score += energy * weight;
      }
    }

    return score;
  }

  /// 計算音符的諧波頻率
  /// 
  /// 返回 [基頻, 2倍頻, 3倍頻, ...]
  List<double> _calculateHarmonics(int midiNote) {
    // A4 (MIDI 69) = 440 Hz
    final f0 = 440.0 * pow(2, (midiNote - 69) / 12.0);
    
    return List<double>.generate(
      numHarmonics,
      (i) => f0 * (i + 1),  // f0, 2*f0, 3*f0, ...
    );
  }

  /// 設置自定義閾值 (用於參數調優) - 已移除，請使用 setEnergyThreshold()
  /// 設置自定義諧波權重
  static List<double> customHarmonicWeights = [...harmonicWeights];
}

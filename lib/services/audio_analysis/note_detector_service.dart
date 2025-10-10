/// 音符檢測服務
/// 
/// 從頻譜圖中檢測所有存在的音符 (peak picking)
/// 而不是僅驗證特定音符是否存在

import 'dart:math';
import 'models/spectrogram.dart';
import 'sequence_matcher_service.dart';

abstract class INoteDetector {
  /// 從頻譜圖中檢測所有音符
  Future<List<DetectedNote>> detectAll(Spectrogram spectrogram);
}

/// 音符檢測服務實現
/// 
/// 使用峰值檢測算法找出頻譜中的顯著音符
class NoteDetectorService implements INoteDetector {
  // 檢測參數
  static const double energyThreshold = 0.25;  // 能量閾值 (平衡點)
  static const int minMidiNote = 21;  // 最低音 (A0)
  static const int maxMidiNote = 108; // 最高音 (C8)
  static const double minNoteDuration = 0.15; // 最短音符時長 (秒)
  static const int numHarmonics = 3;  // 檢查的諧波數量
  static const List<double> harmonicWeights = [1.0, 0.5, 0.25];
  static const int frameSkip = 3;  // 每隔3幀檢測一次 (減少但不過分)

  @override
  Future<List<DetectedNote>> detectAll(Spectrogram spectrogram) async {
    final detectedNotes = <DetectedNote>[];
    
    // 對每個時間幀進行音符檢測 (跳幀處理以提升性能)
    for (int frameIdx = 0; frameIdx < spectrogram.timeFrames; frameIdx += frameSkip) {
      final time = frameIdx * spectrogram.hopSize / spectrogram.sampleRate;
      final spectrum = spectrogram.data[frameIdx];
      
      // 檢測該幀中的所有音符
      final notesInFrame = _detectNotesInFrame(
        spectrum,
        time,
        spectrogram,
      );
      
      detectedNotes.addAll(notesInFrame);
    }

    // 合併相鄰的相同音符
    final mergedNotes = _mergeConsecutiveNotes(detectedNotes);
    
    print('🎵 檢測到 ${mergedNotes.length} 個音符事件');
    
    return mergedNotes;
  }

  /// 檢測單個時間幀中的音符
  List<DetectedNote> _detectNotesInFrame(
    List<double> spectrum,
    double time,
    Spectrogram spectrogram,
  ) {
    final notes = <DetectedNote>[];
    
    // 掃描所有可能的 MIDI 音符
    for (int midiNote = minMidiNote; midiNote <= maxMidiNote; midiNote++) {
      final confidence = _calculateNoteConfidence(
        midiNote,
        spectrum,
        spectrogram,
      );
      
      // 如果置信度超過閾值,認為檢測到該音符
      if (confidence > energyThreshold) {
        notes.add(DetectedNote(
          midiNote: midiNote,
          time: time,
          confidence: confidence,
        ));
      }
    }
    
    return notes;
  }

  /// 計算音符置信度
  /// 
  /// 基於諧波能量加權求和
  double _calculateNoteConfidence(
    int midiNote,
    List<double> spectrum,
    Spectrogram spectrogram,
  ) {
    final frequencies = _calculateHarmonics(midiNote);
    double confidence = 0.0;

    for (int i = 0; i < numHarmonics && i < frequencies.length; i++) {
      final freq = frequencies[i];
      final freqBin = spectrogram.freqToBin(freq);
      
      if (freqBin >= 0 && freqBin < spectrum.length) {
        final energy = spectrum[freqBin];
        final weight = i < harmonicWeights.length ? harmonicWeights[i] : 0.1;
        confidence += energy * weight;
      }
    }

    return confidence;
  }

  /// 合併連續的相同音符
  /// 
  /// 將時間相近、音高相同的檢測結果合併為一個音符
  List<DetectedNote> _mergeConsecutiveNotes(List<DetectedNote> notes) {
    if (notes.isEmpty) return [];

    // 按時間排序
    notes.sort((a, b) => a.time.compareTo(b.time));

    final merged = <DetectedNote>[];
    DetectedNote? current;
    double currentEndTime = 0.0;

    for (final note in notes) {
      if (current == null) {
        // 第一個音符
        current = note;
        currentEndTime = note.time;
      } else if (note.midiNote == current.midiNote && 
                 note.time - currentEndTime < minNoteDuration * 3) {
        // 相同音符,時間相近,合併
        currentEndTime = note.time;
        // 更新為加權中點
        current = DetectedNote(
          midiNote: current.midiNote,
          time: (current.time + note.time) / 2,
          confidence: max(current.confidence, note.confidence),
        );
      } else {
        // 不同音符或時間間隔太大,保存當前音符
        merged.add(current);
        current = note;
        currentEndTime = note.time;
      }
    }

    // 添加最後一個音符
    if (current != null) {
      merged.add(current);
    }

    return merged;
  }

  /// 計算音符的諧波頻率
  List<double> _calculateHarmonics(int midiNote) {
    final f0 = 440.0 * pow(2, (midiNote - 69) / 12.0);
    return List<double>.generate(
      numHarmonics,
      (i) => f0 * (i + 1),
    );
  }
}

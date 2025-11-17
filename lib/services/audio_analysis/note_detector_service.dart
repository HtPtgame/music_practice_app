/// 音符檢測服務 (固定參數版 - 2025/10/27)
///
/// 從頻譜圖中檢測所有存在的音符
/// 已停用動態參數功能，使用固定閾值
library;

import 'dart:math';
import 'models/spectrogram.dart';
import 'sequence_matcher_service.dart';

abstract class INoteDetector {
  /// 從頻譜圖中檢測所有音符
  Future<List<DetectedNote>> detectAll(Spectrogram spectrogram);
}

/// 音符檢測服務實現 (固定參數版)
///
/// 使用峰值檢測算法 + 固定閾值
class NoteDetectorService implements INoteDetector {
  // 檢測參數 (固定)
  static const int minMidiNote = 21; // 最低音 (A0)
  static const int maxMidiNote = 108; // 最高音 (C8)
  static const double minNoteDuration = 0.15; // 最短音符時長 (秒)
  static const int numHarmonics = 3; // 檢查的諧波數量
  static const List<double> harmonicWeights = [1.0, 0.6, 0.3]; // 基頻權重
  static const int frameSkip = 5; // 跳幀以減少運算量
  static const double minConfidenceScore = 0.55; // 🔧 平衡要求
  static const int minHarmonicPeaks = 2; // 🔧 保持較低以提高召回率
  static const int maxNotesPerFrame = 3; // 保留每幀限制

  /// 固定能量閾值 (已停用動態調整功能)
  static const double minEnergyThreshold = 0.38;

  // 音符範圍限制
  static const int noteRangeMargin = 5; // MIDI 音符範圍擴展量 (半音)

  // 動態音符範圍 (根據 MIDI 檔案設定)
  int? _customMinNote;
  int? _customMaxNote;

  /// 設定自訂音符範圍 (參數調優 Round 1)
  ///
  /// 根據 MIDI 檔案中實際使用的音符範圍來限制檢測範圍，
  /// 大幅減少誤報 (避免掃描不必要的音符)
  void setNoteRange({required int minNote, required int maxNote}) {
    _customMinNote =
        (minNote - noteRangeMargin).clamp(minMidiNote, maxMidiNote);
    _customMaxNote =
        (maxNote + noteRangeMargin).clamp(minMidiNote, maxMidiNote);
    print(
        '🎯 音符範圍限制: $_customMinNote - $_customMaxNote (原始: $minNote - $maxNote, 擴展: ±$noteRangeMargin 半音)');
  }

  /// 重置為全範圍檢測
  void resetNoteRange() {
    _customMinNote = null;
    _customMaxNote = null;
    print('🎯 音符範圍重置為全範圍: $minMidiNote - $maxMidiNote');
  }

  /// 取得當前使用的音符範圍
  (int, int) get _effectiveNoteRange {
    return (
      _customMinNote ?? minMidiNote,
      _customMaxNote ?? maxMidiNote,
    );
  }

  @override
  Future<List<DetectedNote>> detectAll(Spectrogram spectrogram) async {
    final detectedNotes = <DetectedNote>[];

    // 對每個時間幀進行音符檢測 (跳幀處理以提升性能)
    for (int frameIdx = 0;
        frameIdx < spectrogram.timeFrames;
        frameIdx += frameSkip) {
      final time = frameIdx * spectrogram.hopSize / spectrogram.sampleRate;
      final spectrum = spectrogram.data[frameIdx];

      // 簡單能量檢查
      final frameEnergy = _calculateFrameEnergy(spectrum);
      if (frameEnergy < minEnergyThreshold) {
        continue; // 跳過低能量幀
      }

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

    return mergedNotes;
  }

  /// 計算整個幀的能量
  double _calculateFrameEnergy(List<double> spectrum) {
    double sum = 0.0;
    for (final magnitude in spectrum) {
      sum += magnitude * magnitude;
    }
    return sqrt(sum / spectrum.length); // RMS
  }

  /// 檢測單個時間幀中的音符
  List<DetectedNote> _detectNotesInFrame(
    List<double> spectrum,
    double time,
    Spectrogram spectrogram,
  ) {
    final notes = <DetectedNote>[];

    // 使用限制的音符範圍
    final (minNote, maxNote) = _effectiveNoteRange;

    // 掃描限制範圍內的 MIDI 音符
    for (int midiNote = minNote; midiNote <= maxNote; midiNote++) {
      final confidence = _calculateNoteConfidence(
        midiNote,
        spectrum,
        spectrogram,
      );

      if (confidence > minConfidenceScore) {
        notes.add(DetectedNote(
          midiNote: midiNote,
          time: time,
          confidence: confidence,
        ));
      }
    }

    // 限制每幀最多檢測的音符數（按信心度排序，只保留前 N 個）
    if (notes.length > maxNotesPerFrame) {
      notes.sort((a, b) => b.confidence.compareTo(a.confidence));
      return notes.sublist(0, maxNotesPerFrame);
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
    int peakCount = 0;

    for (int i = 0; i < numHarmonics && i < frequencies.length; i++) {
      final freq = frequencies[i];
      final freqBin = spectrogram.freqToBin(freq);

      if (freqBin >= 0 && freqBin < spectrum.length) {
        final energy = spectrum[freqBin];

        if (energy > minEnergyThreshold) {
          final weight = i < harmonicWeights.length ? harmonicWeights[i] : 0.1;
          confidence += energy * weight;

          // 檢查是否為局部峰值
          if (_isPeak(spectrum, freqBin)) {
            peakCount++;
          }
        }
      }
    }

    // 要求至少有一定數量的諧波峰值
    if (peakCount < minHarmonicPeaks) {
      confidence *= 0.3;
    }

    return confidence;
  }

  /// 檢查是否為局部峰值
  bool _isPeak(List<double> spectrum, int bin) {
    if (bin <= 0 || bin >= spectrum.length - 1) return false;

    final current = spectrum[bin];
    final prev = spectrum[bin - 1];
    final next = spectrum[bin + 1];

    return current > prev && current > next;
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

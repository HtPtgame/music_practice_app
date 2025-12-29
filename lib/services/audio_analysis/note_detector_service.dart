/// 音符檢測服務 (固定參數版 - 2025/10/27)
///
/// 從頻譜圖中檢測所有存在的音符
/// 已停用動態參數功能，使用固定閾值
library;

import 'dart:math';
import 'models/spectrogram.dart';
import 'sequence_matcher_service.dart';
import 'package:veloria/services/detected_note.dart';


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
  static const List<double> harmonicWeights = [1.0, 0.38, 0.14]; // v2.7: 在v2.5和v2.6之間
  static const int frameSkip = 5; // 跳幀以減少運算量
  static const double minConfidenceScore = 0.62; // v2.7: 從0.58回調至0.62 (適度要求)
  static const int minHarmonicPeaks = 3; // v2.3: 從2提升，需要更多諧波確認
  static const int maxNotesPerFrame = 3; // 保留每幀限制

  /// 固定能量閾值 (已停用動態調整功能)
  /// v2.2: 從 0.38 降至 0.30 (FP過多)
  /// v2.3: 從 0.30 提升至 0.45 (減少諧波誤判)
  /// v2.5: 從 0.45 提升至 0.55 (防止人聲/噪音誤判)
  /// v2.6: 從 0.55 降至 0.48 (平衡準確率與靈敏度) - 過於激進
  /// v2.7: 從 0.48 回調至 0.52 (精細平衡，Recall目標75%+)
  static const double minEnergyThreshold = 0.60;
  
  /// v2.5 新增：諧波比例驗證參數
  /// v2.7 精調：在v2.5和v2.6之間找平衡
  static const double harmonicRatioTolerance = 0.07; // v2.7: 5%→8%→7% (適度放寬)
  static const double minHarmonicRatio = 0.55; // v2.7: 60%→50%→55% (至少55%諧波符合)
  static const double spectralPurityThreshold = 0.22; // v2.7: 0.25→0.20→0.22 (適度要求)

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

  /// 計算音符置信度 (v2.5: 添加諧波比例驗證)
  ///
  /// 基於諧波能量加權求和 + 諧波比例驗證（防止人聲/噪音誤判）
  double _calculateNoteConfidence(
    int midiNote,
    List<double> spectrum,
    Spectrogram spectrogram,
  ) {
    final frequencies = _calculateHarmonics(midiNote);
    double confidence = 0.0;
    int peakCount = 0;
    int validHarmonics = 0; // v2.5: 符合整數倍關係的諧波數

    final fundamentalFreq = frequencies[0];
    final fundamentalBin = spectrogram.freqToBin(fundamentalFreq);
    
    // v2.5: 先檢查基頻是否存在且足夠強
    if (fundamentalBin < 0 || fundamentalBin >= spectrum.length) {
      return 0.0;
    }
    
    final fundamentalEnergy = spectrum[fundamentalBin];
    if (fundamentalEnergy < minEnergyThreshold) {
      return 0.0; // 基頻太弱，直接排除
    }

    for (int i = 0; i < numHarmonics && i < frequencies.length; i++) {
      final expectedFreq = frequencies[i];
      final expectedBin = spectrogram.freqToBin(expectedFreq);

      if (expectedBin >= 0 && expectedBin < spectrum.length) {
        final energy = spectrum[expectedBin];

        if (energy > minEnergyThreshold) {
          // v2.5: 驗證諧波比例關係
          final isValidHarmonic = _validateHarmonicRatio(
            expectedFreq,
            fundamentalFreq,
            i + 1, // 第幾次諧波 (1=基頻, 2=第二諧波...)
          );
          
          if (isValidHarmonic) {
            validHarmonics++;
            final weight = i < harmonicWeights.length ? harmonicWeights[i] : 0.1;
            confidence += energy * weight;

            // 檢查是否為局部峰值
            if (_isPeak(spectrum, expectedBin)) {
              peakCount++;
            }
          }
        }
      }
    }

    // v2.5: 驗證諧波比例關係（防止人聲/噪音）
    final harmonicRatio = validHarmonics / numHarmonics;
    if (harmonicRatio < minHarmonicRatio) {
      return 0.0; // 諧波比例不符，可能是人聲或噪音
    }

    // 要求至少有指定數量的峰值才算是有效音符
    if (peakCount < minHarmonicPeaks) {
      return 0.0; // 無效音符
    }
    
    // v2.5: 頻譜純度檢查（排除寬頻噪音）
    final spectralPurity = _calculateSpectralPurity(
      spectrum,
      spectrogram,
      fundamentalFreq,
    );
    
    if (spectralPurity < spectralPurityThreshold) {
      return 0.0; // 頻譜不純，可能是噪音
    }

    return confidence * spectralPurity; // v2.5: 用頻譜純度加權
  }
  
  /// v2.5: 驗證諧波頻率比例關係
  /// v2.7: 優化 - 高頻諧波適度放寬容忍度
  ///
  /// 檢查實際頻率是否符合理論諧波頻率（整數倍關係）
  /// 人聲/噪音的「諧波」通常不是精確的整數倍
  bool _validateHarmonicRatio(
    double actualFreq,
    double fundamentalFreq,
    int harmonicNumber,
  ) {
    final expectedFreq = fundamentalFreq * harmonicNumber;
    final ratio = actualFreq / expectedFreq;
    
    // v2.7: 高次諧波適度放寬（第3諧波10.5%容忍度）
    final tolerance = harmonicNumber > 2 
        ? harmonicRatioTolerance * 1.5  // 第3諧波以上: 10.5%容忍度
        : harmonicRatioTolerance;        // 基頻和第2諧波: 7%容忍度
    
    return (ratio - 1.0).abs() < tolerance;
  }
  
  /// v2.5: 計算頻譜純度
  ///
  /// 檢查能量是否集中在諧波頻率附近
  /// 寬頻噪音會在整個頻譜分散，純音會集中在諧波位置
  double _calculateSpectralPurity(
    List<double> spectrum,
    Spectrogram spectrogram,
    double fundamentalFreq,
  ) {
    final fundamentalBin = spectrogram.freqToBin(fundamentalFreq);
    if (fundamentalBin < 0 || fundamentalBin >= spectrum.length) {
      return 0.0;
    }
    
    // 計算諧波附近的能量
    double harmonicEnergy = 0.0;
    const windowSize = 3; // 諧波附近±3個in
    
    for (int h = 1; h <= numHarmonics; h++) {
      final harmonicFreq = fundamentalFreq * h;
      final harmonicBin = spectrogram.freqToBin(harmonicFreq);
      
      if (harmonicBin >= 0 && harmonicBin < spectrum.length) {
        // 累加諧波附近的能量
        for (int offset = -windowSize; offset <= windowSize; offset++) {
          final bin = harmonicBin + offset;
          if (bin >= 0 && bin < spectrum.length) {
            harmonicEnergy += spectrum[bin] * spectrum[bin];
          }
        }
      }
    }
    
    // 計算總能量
    double totalEnergy = 0.0;
    for (final mag in spectrum) {
      totalEnergy += mag * mag;
    }
    
    if (totalEnergy < 1e-10) {
      return 0.0;
    }
    
    // 純度 = 諧波能量 / 總能量
    return sqrt(harmonicEnergy / totalEnergy);
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

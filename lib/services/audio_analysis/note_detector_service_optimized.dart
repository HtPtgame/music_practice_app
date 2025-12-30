/// 音符檢測服務 - 優化版 (V4 NMS / 2025-12-28)
///
/// 核心功能：
/// 1. 自適應能量閾值 (Adaptive Threshold)
/// 2. 頻率細化 (Frequency Refinement)
/// 3. NMS 非極大值抑制 (解決 FP=14 的關鍵)
/// 4. 基礎 ML 特徵提取
library;

import 'dart:math';
import 'package:veloria/services/audio_analysis/models/spectrogram.dart';
import 'package:veloria/services/detected_note.dart';

// ⚠️ 注意：如果你已經有真實的 ML 分類器檔案，請取消註解並刪除最下方的 Mock 類別
// import 'audio_type_classifier.dart';
// import '../ml_note_classifier.dart';

class OptimizedNoteDetectorService {
  // 檢測參數
  static const int minMidiNote = 21;
  static const int maxMidiNote = 108;
  static const double minNoteDuration = 0.06;
  static const int numHarmonics = 5;
  static const List<double> harmonicWeights = [1.0, 0.1, 0.05, 0.03, 0.02];
  static const int frameSkip = 1; // 激進跳幀，效能優先

  // 🔥 策略：Recall 優先 (低閾值)，靠 NMS 過濾雜訊
  static const double minConfidenceScore = 0.20; 
  static const int minHarmonicPeaks = 3;
  static const int maxNotesPerFrame = 3;

  bool mlDataCollectionMode = false;

  // 自適應閾值
  AudioClassification? _audioClassification;
  double _adaptiveThreshold = 0.45;
  final _recentEnergies = <double>[];
  static const int energyHistorySize = 50;
  double _adaptiveThresholdMin = 0.25;
  double _adaptiveThresholdMax = 0.70;
  static const double adaptiveThresholdMultiplier = 1.3;

  // 記錄最近音符 (用於泛音抑制)
  final _recentNotes = <DetectedNote>[];
  static const double recentNotesTimeWindow = 1.0;

  // ML 特徵記錄
  final Map<int, double> _previousFrameEnergies = {};
  final Map<int, int> _noteFrameCounts = {};

  // 諧波驗證參數
  static const double harmonicRatioTolerance = 0.07;
  static const double minHarmonicRatio = 0.55;
  static const double spectralPurityThreshold = 0.22;
  static const int noteRangeMargin = 5;

  int? _customMinNote;
  int? _customMaxNote;

  void setNoteRange({required int minNote, required int maxNote}) {
    _customMinNote = (minNote - noteRangeMargin).clamp(minMidiNote, maxMidiNote);
    _customMaxNote = (maxNote + noteRangeMargin).clamp(minMidiNote, maxMidiNote);
  }

  void resetNoteRange() {
    _customMinNote = null;
    _customMaxNote = null;
  }

  (int, int) get _effectiveNoteRange {
    return (_customMinNote ?? minMidiNote, _customMaxNote ?? maxMidiNote);
  }

  /// 檢測所有音符
  Future<List<DetectedNote>> detectAll(Spectrogram spectrogram) async {
    // 1. 設定閾值範圍
    if (mlDataCollectionMode) {
      _adaptiveThresholdMin = 0.10;
      _adaptiveThresholdMax = 0.30;
      _adaptiveThreshold = 0.20;
    } else {
      if (_audioClassification == null) {
        _audioClassification = _classifyAudioType(spectrogram);
        final (minT, maxT) = _audioClassification!.recommendedThresholdRange;
        
        // 根據音訊類型調整
        _adaptiveThresholdMin = _audioClassification!.type == AudioType.synthetic 
            ? max(minT, 0.15) 
            : max(minT, 0.50);
        _adaptiveThresholdMax = maxT;
        _adaptiveThreshold = (minT + maxT) / 2;
        
        print('🎚️ 自適應閾值: ${_adaptiveThresholdMin.toStringAsFixed(2)} - ${_adaptiveThresholdMax.toStringAsFixed(2)}');
      }
    }

    final detectedNotes = <DetectedNote>[];

    // 2. 逐幀掃描
    for (int frameIdx = 0; frameIdx < spectrogram.timeFrames; frameIdx += frameSkip) {
      final time = frameIdx * spectrogram.hopSize / spectrogram.sampleRate;
      final spectrum = spectrogram.data[frameIdx];

      // 更新自適應閾值
      _updateAdaptiveThreshold(spectrum);
      
      double effectiveThreshold = _adaptiveThreshold;
      if (time < 0.5) effectiveThreshold *= 2.0; // 暖機防誤判

      // 快速能量篩選
      final maxEnergy = spectrum.reduce(max);
      if (maxEnergy < effectiveThreshold * 0.3) continue;

      if (_calculateFrameEnergy(spectrum) < effectiveThreshold) continue;

      // 檢測當前幀
      final notesInFrame = _detectNotesInFrame(spectrum, time, spectrogram);

      for (final note in notesInFrame) {
        if (!_isLikelyHarmonic(note)) {
          detectedNotes.add(note);
          _recentNotes.add(note);
          _recentNotes.removeWhere((n) => note.time - n.time > recentNotesTimeWindow);
        }
      }
    }

    // 3. 合併連續音符
    final mergedNotes = _mergeConsecutiveNotes(detectedNotes);

    // 4. 🔥🔥🔥 關鍵：執行 NMS 清理 (解決 FP=14 的核心)
    print('🔍 執行過濾前: ${mergedNotes.length} 個音符');
    final cleanedNotes = _cleanUpDetections(mergedNotes);
    print('✨ 執行過濾後: ${cleanedNotes.length} 個音符');

    return cleanedNotes;
  }

  /// 🧹 鬼影殺手：NMS (非極大值抑制) 清理演算法
  List<DetectedNote> _cleanUpDetections(List<DetectedNote> rawNotes) {
    if (rawNotes.isEmpty) return [];

    // 1. 按照信心度從高到低排序 (強者優先)
    final sortedByConfidence = List<DetectedNote>.from(rawNotes);
    sortedByConfidence.sort((a, b) => b.confidence.compareTo(a.confidence));

    final keptNotes = <DetectedNote>[];
    int removedCount = 0;

    for (final note in sortedByConfidence) {
      bool isOverlap = false;

      // 檢查是否跟已經保留的「強者」衝突
      for (final kept in keptNotes) {
        final timeDiff = (note.time - kept.time).abs();
        
        // 如果時間太近 (< 0.1s)，不管音高相不相同，弱者都要被淘汰
        // 這能有效消除泛音產生的幽靈音符
        if (timeDiff < 0.1) {
          isOverlap = true;
          break;
        }
      }

      if (!isOverlap) {
        keptNotes.add(note);
      } else {
        removedCount++;
      }
    }

    print('🧹 NMS 殺除了 $removedCount 個幽靈音符');

    // 2. 最後按時間排序回來
    keptNotes.sort((a, b) => a.time.compareTo(b.time));
    return keptNotes;
  }

  // ... (保留原本的輔助運算邏輯)
  
  void _updateAdaptiveThreshold(List<double> spectrum) {
    final frameEnergy = _calculateFrameEnergy(spectrum);
    _recentEnergies.add(frameEnergy);
    if (_recentEnergies.length > energyHistorySize) _recentEnergies.removeAt(0);
    
    if (_recentEnergies.length < 10) return;
    
    final sortedEnergies = List<double>.from(_recentEnergies)..sort();
    final median = sortedEnergies[sortedEnergies.length ~/ 2];
    _adaptiveThreshold = (median * adaptiveThresholdMultiplier).clamp(_adaptiveThresholdMin, _adaptiveThresholdMax);
  }

  double _calculateFrameEnergy(List<double> spectrum) {
    double sum = 0.0;
    for (final magnitude in spectrum) sum += magnitude * magnitude;
    return sqrt(sum / spectrum.length);
  }

  List<DetectedNote> _detectNotesInFrame(List<double> spectrum, double time, Spectrogram spectrogram) {
    final notes = <DetectedNote>[];
    final (minNote, maxNote) = _effectiveNoteRange;

    for (int midiNote = minNote; midiNote <= maxNote; midiNote++) {
      final confidence = _calculateNoteConfidence(midiNote, spectrum, spectrogram);
      
      // 使用低閾值 (0.20) 捕捉所有可能，再靠 NMS 過濾
      if (confidence > 0.20) {
        final mlFeatures = _extractMLFeatures(midiNote, spectrum, spectrogram, time);
        
        notes.add(DetectedNote(
          midiNote: midiNote,
          time: time,
          confidence: confidence,
          peakEnergy: mlFeatures['peakEnergy']!,
          harmonicRatio: mlFeatures['harmonicRatio']!,
          onsetStrength: mlFeatures['onsetStrength']!,
          spectralFlatness: mlFeatures['spectralFlatness']!,
          durationFrames: mlFeatures['durationFrames']!.toInt(),
        ));
      }
    }

    if (notes.length > maxNotesPerFrame) {
      notes.sort((a, b) => b.confidence.compareTo(a.confidence));
      return notes.sublist(0, maxNotesPerFrame);
    }
    return notes;
  }

  double _calculateNoteConfidence(int midiNote, List<double> spectrum, Spectrogram spectrogram) {
    final frequencies = _calculateHarmonics(midiNote);
    double confidence = 0.0;
    int peakCount = 0;
    int validHarmonics = 0;

    final fundamentalFreq = frequencies[0];
    final fundamentalBin = spectrogram.freqToBin(fundamentalFreq);

    if (fundamentalBin < 0 || fundamentalBin >= spectrum.length) return 0.0;
    if (spectrum[fundamentalBin] < _adaptiveThreshold) return 0.0;

    for (int i = 0; i < numHarmonics && i < frequencies.length; i++) {
      final expectedFreq = frequencies[i];
      final expectedBin = spectrogram.freqToBin(expectedFreq);

      if (expectedBin >= 0 && expectedBin < spectrum.length) {
        final energy = spectrum[expectedBin];
        if (energy > _adaptiveThreshold) {
          double refinedFreq = expectedFreq;
          if (_isPeak(spectrum, expectedBin)) {
            refinedFreq = _refinePeakFrequency(spectrum, expectedBin, spectrogram);
            peakCount++;
          }
          
          if (_validateHarmonicRatio(refinedFreq, fundamentalFreq, i + 1)) {
            validHarmonics++;
            final weight = i < harmonicWeights.length ? harmonicWeights[i] : 0.1;
            confidence += energy * weight;
          }
        }
      }
    }

    if ((validHarmonics / numHarmonics) < minHarmonicRatio) return 0.0;
    if (peakCount < minHarmonicPeaks) return 0.0;
    
    final spectralPurity = _calculateSpectralPurity(spectrum, spectrogram, fundamentalFreq);
    if (spectralPurity < spectralPurityThreshold) return 0.0;

    return confidence * spectralPurity;
  }

  // 頻率細化 (拋物線插值)
  double _refinePeakFrequency(List<double> spectrum, int peakBin, Spectrogram spectrogram) {
    if (peakBin <= 0 || peakBin >= spectrum.length - 1) return peakBin * spectrogram.frequencyResolution;
    final y1 = spectrum[peakBin - 1];
    final y2 = spectrum[peakBin];
    final y3 = spectrum[peakBin + 1];
    final denominator = 2 * (y1 - 2 * y2 + y3);
    if (denominator.abs() < 1e-10) return peakBin * spectrogram.frequencyResolution;
    final delta = (y1 - y3) / denominator;
    return (peakBin + delta) * spectrogram.frequencyResolution;
  }

  bool _validateHarmonicRatio(double actualFreq, double fundamentalFreq, int harmonicNumber) {
    final expectedFreq = fundamentalFreq * harmonicNumber;
    final ratio = actualFreq / expectedFreq;
    final tolerance = harmonicNumber > 2 ? harmonicRatioTolerance * 1.5 : harmonicRatioTolerance;
    return (ratio - 1.0).abs() < tolerance;
  }

  double _calculateSpectralPurity(List<double> spectrum, Spectrogram spectrogram, double fundamentalFreq) {
    final fundamentalBin = spectrogram.freqToBin(fundamentalFreq);
    if (fundamentalBin < 0 || fundamentalBin >= spectrum.length) return 0.0;
    
    double harmonicEnergy = 0.0;
    const windowSize = 3;
    for (int h = 1; h <= numHarmonics; h++) {
      final harmonicFreq = fundamentalFreq * h;
      final harmonicBin = spectrogram.freqToBin(harmonicFreq);
      if (harmonicBin >= 0 && harmonicBin < spectrum.length) {
        for (int offset = -windowSize; offset <= windowSize; offset++) {
          final bin = harmonicBin + offset;
          if (bin >= 0 && bin < spectrum.length) harmonicEnergy += spectrum[bin] * spectrum[bin];
        }
      }
    }
    double totalEnergy = 0.0;
    for (final mag in spectrum) totalEnergy += mag * mag;
    return totalEnergy < 1e-10 ? 0.0 : sqrt(harmonicEnergy / totalEnergy);
  }

  bool _isPeak(List<double> spectrum, int bin) {
    if (bin <= 0 || bin >= spectrum.length - 1) return false;
    final current = spectrum[bin];
    return current > spectrum[bin - 1] && current > spectrum[bin + 1];
  }

  // 合併連續音符 (起音邏輯)
  List<DetectedNote> _mergeConsecutiveNotes(List<DetectedNote> notes) {
    if (notes.isEmpty) return [];
    notes.sort((a, b) => a.time.compareTo(b.time));
    final merged = <DetectedNote>[];
    DetectedNote? current;
    double currentEndTime = 0.0;

    for (final note in notes) {
      bool isNewAttack = note.onsetStrength > 0.01;
      if (current == null) {
        current = note;
        currentEndTime = note.time;
      } else if (!isNewAttack && note.midiNote == current.midiNote && note.time - currentEndTime < minNoteDuration * 1.2) {
        currentEndTime = note.time;
        current = DetectedNote(
          midiNote: current.midiNote,
          time: (current.time + note.time) / 2,
          confidence: max(current.confidence, note.confidence),
          peakEnergy: current.peakEnergy,
          harmonicRatio: current.harmonicRatio,
          onsetStrength: current.onsetStrength,
          spectralFlatness: current.spectralFlatness,
          durationFrames: current.durationFrames + note.durationFrames,
        );
      } else {
        merged.add(current);
        current = note;
        currentEndTime = note.time;
      }
    }
    if (current != null) merged.add(current);
    return merged;
  }

  List<double> _calculateHarmonics(int midiNote) {
    final f0 = 440.0 * pow(2, (midiNote - 69) / 12.0);
    return List<double>.generate(numHarmonics, (i) => f0 * (i + 1));
  }

  bool _isLikelyHarmonic(DetectedNote candidate) {
    if (_recentNotes.isEmpty) return false;
    for (final recentNote in _recentNotes) {
      final interval = candidate.midiNote - recentNote.midiNote;
      if (interval == 12 || interval == 19 || interval == 24) {
        final timeDiff = (candidate.time - recentNote.time).abs();
        if (timeDiff <= 0.05) return true;
      }
    }
    return false;
  }

  AudioClassification _classifyAudioType(Spectrogram spectrogram) {
    // 簡單的 Mock 分類，預設為 Real Recording
    return AudioClassification(AudioType.realRecording, (0.45, 0.70));
  }

  // ML 特徵提取 (簡化版)
  Map<String, double> _extractMLFeatures(int midiNote, List<double> spectrum, Spectrogram spectrogram, double time) {
    return {
      'peakEnergy': _calculatePeakEnergy(midiNote, spectrum, spectrogram),
      'harmonicRatio': _calculateHarmonicRatio(midiNote, spectrum, spectrogram),
      'onsetStrength': _calculateOnsetStrength(midiNote, spectrum),
      'spectralFlatness': _calculateSpectralFlatness(spectrum),
      'durationFrames': _calculateDurationFrames(midiNote, time).toDouble(),
    };
  }
  
  // (以下為輔助計算 ML 特徵的函式, 保持原本邏輯即可)
  double _calculatePeakEnergy(int midiNote, List<double> spectrum, Spectrogram spectrogram) {
    final frequency = 440.0 * pow(2, (midiNote - 69) / 12.0);
    final binIndex = (frequency * spectrogram.fftSize / spectrogram.sampleRate).round();
    if (binIndex < 0 || binIndex >= spectrum.length) return 0.0;
    return spectrum[binIndex];
  }

  double _calculateHarmonicRatio(int midiNote, List<double> spectrum, Spectrogram spectrogram) {
     final frequency = 440.0 * pow(2, (midiNote - 69) / 12.0);
     final sampleRate = spectrogram.sampleRate;
     final fftSize = spectrogram.fftSize;
     final f0Bin = (frequency * fftSize / sampleRate).round();
     final f2Bin = (frequency * 2 * fftSize / sampleRate).round();
     final f3Bin = (frequency * 3 * fftSize / sampleRate).round();
     double getEnergy(int bin) => (bin >= 0 && bin < spectrum.length) ? spectrum[bin] : 0.0;
     final total = getEnergy(f0Bin) + getEnergy(f2Bin) + getEnergy(f3Bin);
     return total < 1e-10 ? 0.0 : getEnergy(f0Bin) / total;
  }

  double _calculateOnsetStrength(int midiNote, List<double> spectrum) {
     final frequency = 440.0 * pow(2, (midiNote - 69) / 12.0);
     final currentEnergy = _getEnergyAtFrequency(frequency, spectrum);
     final previousEnergy = _previousFrameEnergies[midiNote] ?? 0.0;
     _previousFrameEnergies[midiNote] = currentEnergy;
     return max(0.0, currentEnergy - previousEnergy);
  }

  double _calculateSpectralFlatness(List<double> spectrum) {
    final nonZero = spectrum.where((x) => x > 1e-10).toList();
    if (nonZero.isEmpty) return 0.0;
    final logSum = nonZero.map((x) => log(x)).reduce((a, b) => a + b);
    final geometricMean = exp(logSum / nonZero.length);
    final arithmeticMean = nonZero.reduce((a, b) => a + b) / nonZero.length;
    return arithmeticMean < 1e-10 ? 0.0 : geometricMean / arithmeticMean;
  }

  int _calculateDurationFrames(int midiNote, double time) {
    _noteFrameCounts[midiNote] = (_noteFrameCounts[midiNote] ?? 0) + 1;
    return _noteFrameCounts[midiNote]!;
  }

  double _getEnergyAtFrequency(double frequency, List<double> spectrum) {
    final sampleRate = 44100.0; 
    final fftSize = spectrum.length * 2;
    final binIndex = (frequency * fftSize / sampleRate).round();
    if (binIndex < 0 || binIndex >= spectrum.length) return 0.0;
    return spectrum[binIndex];
  }
}

// ════════════════════════════════════════════
// 🚧 Mock 類別 (為了確保能直接執行，若有真實檔案請刪除)
// ════════════════════════════════════════════

enum AudioType { synthetic, realRecording }

class AudioClassification {
  final AudioType type;
  final (double, double) recommendedThresholdRange;
  AudioClassification(this.type, this.recommendedThresholdRange);
  @override
  String toString() => 'Type: $type, Threshold: $recommendedThresholdRange';
}

class MLNoteClassifier {
  static double getProbability(DetectedNote note) => 0.8; // Mock
  static bool isRealNote(DetectedNote note) => true; // Mock
}
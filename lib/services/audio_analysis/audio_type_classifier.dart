/// 音檔類型自動分類器
///
/// 根據波形特徵自動識別:
/// - Synthetic/MIDI (乾淨、低底噪、高頻能量少)
/// - Real Recording (雜訊、瞬態豐富、高頻噪音多)
/// 
/// 關鍵特徵:
/// 1. 高頻能量比例 (>10kHz) - 最準確的指標
/// 2. 過零率 (Zero Crossing Rate) - 檢測波形毛躁度
/// 3. 底噪水平
/// 4. 動態範圍
library;

import 'dart:math';

/// 音檔類型
enum AudioType {
  /// 合成音檔 (MIDI、軟體生成)
  synthetic,
  
  /// 真實錄音 (麥克風、實體鋼琴)
  realRecording,
}

/// 音檔分類結果
class AudioClassification {
  final AudioType type;
  final double confidence;
  final Map<String, double> features;
  
  /// 建議的檢測閾值範圍
  final (double min, double max) recommendedThresholdRange;
  
  AudioClassification({
    required this.type,
    required this.confidence,
    required this.features,
    required this.recommendedThresholdRange,
  });
  
  @override
  String toString() {
    return 'AudioType: ${type.name} (confidence: ${(confidence * 100).toStringAsFixed(1)}%)\n'
           'Features: ${features.entries.map((e) => '${e.key}=${e.value.toStringAsFixed(3)}').join(', ')}\n'
           'Recommended Threshold: ${recommendedThresholdRange.$1.toStringAsFixed(2)} - ${recommendedThresholdRange.$2.toStringAsFixed(2)}';
  }
}

/// 音檔類型分類器
class AudioTypeClassifier {
  /// 分析音訊樣本並分類類型
  ///
  /// [samples] 音訊樣本 (可以是整個音檔或前 5-10 秒)
  /// [sampleRate] 採樣率
  /// [spectrumData] 可選的頻譜數據 (用於計算高頻能量)
  /// [originalSampleRate] 原始音訊採樣率 (用於高頻分析,默認同 sampleRate)
  static AudioClassification classify(
    List<double> samples, 
    int sampleRate,
    {List<List<double>>? spectrumData, int? originalSampleRate}
  ) {
    // 1. 計算波峰因數 (Crest Factor)
    final crestFactor = _calculateCrestFactor(samples);
    
    // 2. 計算底噪水平 (Noise Floor)
    final noiseFloor = _calculateNoiseFloor(samples);
    
    // 3. 計算動態範圍 (Dynamic Range)
    final dynamicRange = _calculateDynamicRange(samples);
    
    // 4. 計算瞬態密度 (Transient Density)
    final transientDensity = _calculateTransientDensity(samples, sampleRate);
    
    // 5. 計算頻譜平滑度 (Spectral Smoothness)
    final spectralSmoothness = _calculateSpectralSmoothness(samples);
    
    // 🆕 6. 計算過零率 (Zero Crossing Rate)
    final zeroCrossingRate = _calculateZeroCrossingRate(samples);
    
    // 🆕 7. 計算高頻能量比例 (High Frequency Ratio)
    final highFreqRatio = spectrumData != null 
        ? _calculateHighFreqRatio(spectrumData, originalSampleRate ?? sampleRate)
        : 0.0; // 無頻譜數據時使用其他特徵
    
    final features = {
      'crestFactor': crestFactor,
      'noiseFloor': noiseFloor,
      'dynamicRange': dynamicRange,
      'transientDensity': transientDensity,
      'spectralSmoothness': spectralSmoothness,
      'zeroCrossingRate': zeroCrossingRate,
      'highFreqRatio': highFreqRatio,
    };
    
    // 8. 決策邏輯 (多維度判斷)
    final decision = _makeDecision(features);
    
    return AudioClassification(
      type: decision.type,
      confidence: decision.confidence,
      features: features,
      recommendedThresholdRange: decision.type == AudioType.synthetic
          ? (0.10, 0.35)  // MIDI: 極低閾值
          : (0.45, 0.85), // 真實錄音: 高閾值
    );
  }
  
  /// 計算波峰因數 (Peak / RMS)
  ///
  /// - Synthetic: 通常 < 3 (波形平滑)
  /// - Real Recording: 通常 > 5 (有明顯瞬態)
  static double _calculateCrestFactor(List<double> samples) {
    final peak = samples.map((s) => s.abs()).reduce(max);
    final rms = sqrt(samples.map((s) => s * s).reduce((a, b) => a + b) / samples.length);
    
    if (rms < 1e-10) return 0.0; // 避免除以零
    return peak / rms;
  }
  
  /// 計算底噪水平 (最低 5% 樣本的 RMS)
  ///
  /// - Synthetic: < 0.005 (幾乎無底噪)
  /// - Real Recording: > 0.015 (有環境雜音)
  static double _calculateNoiseFloor(List<double> samples) {
    final sorted = List<double>.from(samples.map((s) => s.abs()))..sort();
    final bottomSamples = sorted.sublist(0, sorted.length ~/ 20); // 最低 5%
    
    final rms = sqrt(bottomSamples.map((s) => s * s).reduce((a, b) => a + b) / bottomSamples.length);
    return rms;
  }
  
  /// 計算動態範圍 (dB)
  ///
  /// - Synthetic: 通常 < 40 dB (音量一致)
  /// - Real Recording: 通常 > 60 dB (有強弱變化)
  static double _calculateDynamicRange(List<double> samples) {
    final sorted = List<double>.from(samples.map((s) => s.abs()))..sort();
    
    final peak = sorted.last;
    final noiseFloor = sorted[sorted.length ~/ 20]; // 最低 5%
    
    if (noiseFloor < 1e-10) return 120.0; // 極乾淨
    return 20 * log(peak / noiseFloor) / ln10;
  }
  
  /// 計算瞬態密度 (每秒的突變次數)
  ///
  /// - Synthetic: < 5 次/秒 (起音平滑)
  /// - Real Recording: > 15 次/秒 (敲擊聲、按鍵聲)
  static double _calculateTransientDensity(List<double> samples, int sampleRate) {
    int transients = 0;
    const windowSize = 100; // 更小的窗口捕捉突變
    const threshold = 1.8; // 降低閾值 (能量樣本已經平滑過)
    
    for (int i = windowSize; i < samples.length - windowSize; i += windowSize ~/ 4) {
      final prevEnergy = _calculateWindowEnergy(samples, i - windowSize, windowSize);
      final currEnergy = _calculateWindowEnergy(samples, i, windowSize);
      
      if (prevEnergy > 0 && currEnergy > prevEnergy * threshold) {
        transients++;
      }
    }
    
    final duration = samples.length / (sampleRate / 100.0); // 調整時間計算
    return transients / duration;
  }
  
  /// 計算頻譜平滑度 (相鄰樣本差異的平均值)
  ///
  /// - Synthetic: < 0.1 (平滑過渡)
  /// - Real Recording: > 0.3 (雜訊、干擾)
  static double _calculateSpectralSmoothness(List<double> samples) {
    double totalDiff = 0.0;
    for (int i = 1; i < samples.length; i++) {
      totalDiff += (samples[i] - samples[i - 1]).abs();
    }
    return totalDiff / samples.length;
  }
  
  /// 計算窗口能量
  static double _calculateWindowEnergy(List<double> samples, int start, int size) {
    double sum = 0.0;
    for (int i = start; i < start + size && i < samples.length; i++) {
      sum += samples[i] * samples[i];
    }
    return sqrt(sum / size);
  }
  
  /// 🆕 計算過零率 (Zero Crossing Rate)
  ///
  /// 測量訊號穿越零點的頻率
  /// - Synthetic: < 0.10 (平滑正弦波)
  /// - Real Recording: > 0.15 (雜訊導致頻繁震盪)
  static double _calculateZeroCrossingRate(List<double> samples) {
    int crossings = 0;
    
    for (int i = 1; i < samples.length; i++) {
      // 檢測符號變化 (從正到負或從負到正)
      if ((samples[i] >= 0 && samples[i - 1] < 0) ||
          (samples[i] < 0 && samples[i - 1] >= 0)) {
        crossings++;
      }
    }
    
    return crossings / samples.length;
  }
  
  /// 🆕 計算高頻能量比例 (High Frequency Ratio)
  ///
  /// 分析 10kHz 以上的能量佔比
  /// - MIDI: < 0.02 (高頻迅速衰減)
  /// - Real Recording: > 0.05 (環境白噪音在高頻持續存在)
  static double _calculateHighFreqRatio(List<List<double>> spectrumData, int sampleRate) {
    if (spectrumData.isEmpty) return 0.0;
    
    final spectrumBins = spectrumData[0].length;
    
    // 頻譜長度代表 [0, Nyquist頻率] 範圍
    // Nyquist 頻率 = sampleRate / 2
    final nyquistFreq = sampleRate / 2.0;
    final frequencyResolution = nyquistFreq / spectrumBins;
    
    // 計算 10kHz 對應的 bin 索引
    final highFreqThreshold = 10000.0; // 10kHz
    final highFreqBinStart = (highFreqThreshold / frequencyResolution).round();
    
    print('  🔍 高頻分析: Nyquist=${nyquistFreq}Hz, FreqRes=${frequencyResolution.toStringAsFixed(1)}Hz, 10kHz_Bin=$highFreqBinStart/${spectrumBins}');
    
    if (highFreqBinStart >= spectrumBins) {
      print('     ⚠️  採樣率不足,無法分析 10kHz');
      return 0.0; // 採樣率不足以分析 10kHz
    }
    
    double totalEnergy = 0.0;
    double highFreqEnergy = 0.0;
    
    // 對所有時間幀求平均
    for (final spectrum in spectrumData) {
      for (int i = 0; i < spectrum.length; i++) {
        final energy = spectrum[i] * spectrum[i];
        totalEnergy += energy;
        
        if (i >= highFreqBinStart) {
          highFreqEnergy += energy;
        }
      }
    }
    
    if (totalEnergy < 1e-10) return 0.0;
    
    return highFreqEnergy / totalEnergy;
  }
  
  /// 決策邏輯 (多維度判斷)
  static ({AudioType type, double confidence}) _makeDecision(Map<String, double> features) {
    int syntheticScore = 0;
    int realRecordingScore = 0;
    
    // 🔥 規則 A: 高頻雜訊 (最準確的指標,但不再是唯一決定因素)
    final highFreqRatio = features['highFreqRatio']!;
    if (highFreqRatio > 0.03) {
      // 明顯的高頻雜訊
      realRecordingScore += 5;
      print('  🎤 高頻雜訊檢測: ${(highFreqRatio * 100).toStringAsFixed(2)}% (>3% = 真實錄音)');
    } else if (highFreqRatio < 0.01 && highFreqRatio > 0) {
      syntheticScore += 3;
      print('  🎹 乾淨高頻: ${(highFreqRatio * 100).toStringAsFixed(2)}% (<1% = MIDI)');
    } else {
      print('  ⚖️  灰色地帶高頻: ${(highFreqRatio * 100).toStringAsFixed(2)}%');
    }
    
    // 🔥 規則 B: 瞬態密度 (電腦錄音的關鍵特徵)
    // 即使沒有環境雜訊,敲擊聲和機械聲會產生瞬態
    final transientDensity = features['transientDensity']!;
    if (transientDensity > 0.005) {  // 極低閾值,捕捉任何瞬態
      realRecordingScore += 4;
      print('  ⚡ 瞬態檢測: ${transientDensity.toStringAsFixed(3)} 次/秒 (>0.005 = 真實錄音)');
    }
    
    // 🔥 規則 C: 底噪水平 (第二層防禦)
    final noiseFloor = features['noiseFloor']!;
    if (noiseFloor > 0.015) {
      // 明顯的底噪
      realRecordingScore += 3;
      print('  🔊 底噪檢測: ${noiseFloor.toStringAsFixed(3)} (>0.015 = 有環境雜訊)');
    } else if (noiseFloor < 0.005) {
      syntheticScore += 2;
    }
    
    // 🔥 規則 D: 動態範圍 (MIDI 通常音量一致)
    final dynamicRange = features['dynamicRange']!;
    if (dynamicRange > 50) {
      realRecordingScore += 2;
      print('  📈 大動態範圍: ${dynamicRange.toStringAsFixed(1)} dB (>50dB = 真實錄音)');
    } else if (dynamicRange < 20) {
      syntheticScore += 2;
    }
    
    // 規則 E: 過零率 (補充特徵)
    final zcr = features['zeroCrossingRate']!;
    if (zcr > 0.15) {
      realRecordingScore += 3;
      print('  📊 高過零率: ${(zcr * 100).toStringAsFixed(1)}% (>15% = 波形毛躁)');
    } else if (zcr < 0.08) {
      syntheticScore += 1;
    }
    
    // 規則 F: 波峰因數
    if (features['crestFactor']! < 3.0) {
      syntheticScore += 1;
    } else if (features['crestFactor']! > 5.0) {
      realRecordingScore += 1;
    }
    
    // 規則 G: 頻譜平滑度
    if (features['spectralSmoothness']! < 0.15) {
      syntheticScore += 1;
    } else if (features['spectralSmoothness']! > 0.3) {
      realRecordingScore += 1;
    }
    
    // 總分計算
    final totalScore = syntheticScore + realRecordingScore;
    if (totalScore == 0) {
      return (type: AudioType.realRecording, confidence: 0.5); // 無法判斷,預設真實錄音
    }
    
    if (syntheticScore > realRecordingScore) {
      return (
        type: AudioType.synthetic,
        confidence: syntheticScore / totalScore,
      );
    } else {
      return (
        type: AudioType.realRecording,
        confidence: realRecordingScore / totalScore,
      );
    }
  }
}

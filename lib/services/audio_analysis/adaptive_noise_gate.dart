/// 自適應噪音閘門服務 (Phase 2A)
/// 
/// 動態調整檢測閾值以降低誤報率
/// 解決過度檢測問題 (23,588 vs 25 音符)
library;

import 'dart:math';
import 'models/spectrogram.dart';

/// 自適應噪音閘門
/// 
/// 根據環境噪音自動調整檢測閾值
class AdaptiveNoiseGate {
  /// 噪音估算窗口大小 (秒)
  static const double noiseWindowSize = 0.5;
  
  /// 信噪比最小閾值 (dB) - 參數調優 Round 3 (最優解)
  static const double minSNRdB = 24.0;  // Round 3: 最佳平衡點 (F1=53.8%)
  
  /// 最小絕對能量閾值 - 參數調優 Round 3 (最優解)
  static const double minAbsoluteEnergy = 0.30;  // Round 3: 最佳平衡點
  
  /// 峰值檢測窗口 (頻率 bins)
  static const int peakWindowBins = 3;
  
  late double _noiseFloor;
  late double _dynamicThreshold;
  bool _calibrated = false;

  /// 校準噪音基線
  /// 
  /// 分析前 0.5 秒的頻譜以估算環境噪音水平
  void calibrate(Spectrogram spectrogram) {
    final windowFrames = (noiseWindowSize / spectrogram.timeResolution).round();
    final maxFrames = min(windowFrames, spectrogram.timeFrames);
    
    // 收集所有頻率 bin 的能量值
    final allEnergies = <double>[];
    
    for (int frame = 0; frame < maxFrames; frame++) {
      for (int bin = 0; bin < spectrogram.freqBins; bin++) {
        allEnergies.add(spectrogram.data[frame][bin]);
      }
    }
    
    // 使用 75% 分位數作為噪音基線 (比中位數更保守)
    allEnergies.sort();
    final percentile75Index = (allEnergies.length * 0.75).round();
    _noiseFloor = allEnergies[percentile75Index];
    
    // 計算動態閾值 = 噪音基線 × SNR
    final snrLinear = _dBToLinear(minSNRdB);
    _dynamicThreshold = max(_noiseFloor * snrLinear, minAbsoluteEnergy);
    
    _calibrated = true;
    
    print('🎚️ 自適應噪音閘門已校準:');
    print('   噪音基線 (75%): ${_noiseFloor.toStringAsFixed(6)}');
    print('   動態閾值 (SNR ${minSNRdB}dB): ${_dynamicThreshold.toStringAsFixed(6)}');
    print('   最小絕對能量: $minAbsoluteEnergy');
  }

  /// 檢查頻譜能量是否超過動態閾值
  /// 
  /// 相比固定閾值,這會根據環境噪音自動調整
  bool isAboveThreshold(double energy) {
    if (!_calibrated) {
      throw StateError('必須先調用 calibrate() 校準噪音基線');
    }
    return energy > _dynamicThreshold;
  }

  /// 獲取當前動態閾值
  double get threshold => _calibrated ? _dynamicThreshold : minAbsoluteEnergy;

  /// 檢測頻譜峰值
  /// 
  /// 只有在局部最大值且超過閾值時才認為是真實音符
  bool isPeak(
    List<double> spectrum,
    int centerBin,
    Spectrogram spectrogram,
  ) {
    if (!_calibrated) {
      throw StateError('必須先調用 calibrate() 校準噪音基線');
    }

    final centerEnergy = spectrum[centerBin];
    
    // 1. 檢查是否超過動態閾值
    if (!isAboveThreshold(centerEnergy)) {
      return false;
    }

    // 2. 檢查是否為局部峰值
    final startBin = max(0, centerBin - peakWindowBins);
    final endBin = min(spectrum.length - 1, centerBin + peakWindowBins);

    for (int bin = startBin; bin <= endBin; bin++) {
      if (bin != centerBin && spectrum[bin] > centerEnergy) {
        return false; // 不是局部最大值
      }
    }

    return true; // 是峰值且超過閾值
  }

  /// 計算信噪比 (dB)
  double calculateSNR(double signalEnergy) {
    if (!_calibrated) return 0.0;
    if (_noiseFloor <= 0 || signalEnergy <= 0) return 0.0;
    return _linearTodB(signalEnergy / _noiseFloor);
  }

  /// dB 轉線性
  double _dBToLinear(double dB) => pow(10, dB / 20).toDouble();

  /// 線性轉 dB
  double _linearTodB(double linear) => 20 * log(linear) / ln10;

  /// 重置校準狀態
  void reset() {
    _calibrated = false;
    _noiseFloor = 0.0;
    _dynamicThreshold = minAbsoluteEnergy;
  }
}

/// 頻譜通量 Onset 檢測器 (Phase 2B)
/// 
/// 使用頻譜變化量檢測音符起始點,精度可達 ±50ms
/// 替代單純的能量檢測 (±200ms)
library;

import 'dart:math';
import 'models/spectrogram.dart';

/// Onset 檢測結果
class OnsetEvent {
  final double time;      // 起始時間 (秒)
  final double strength;  // 起始強度

  OnsetEvent({
    required this.time,
    required this.strength,
  });

  @override
  String toString() => 'Onset(${time.toStringAsFixed(3)}s, strength: ${strength.toStringAsFixed(3)})';
}

/// 頻譜通量 Onset 檢測器
/// 
/// 基於頻譜變化量 (Spectral Flux) 檢測音符起始點
class SpectralFluxOnsetDetector {
  /// Onset 檢測閾值倍數
  static const double onsetThresholdMultiplier = 1.5;
  
  /// 最小 Onset 間隔 (秒)
  static const double minOnsetInterval = 0.10;
  
  /// 平滑窗口大小 (幀數)
  static const int smoothWindowSize = 3;

  /// 檢測所有 onset 事件
  /// 
  /// 返回所有檢測到的音符起始點
  List<OnsetEvent> detectOnsets(Spectrogram spectrogram) {
    // 1. 計算頻譜通量
    final spectralFlux = _calculateSpectralFlux(spectrogram);
    
    // 2. 平滑頻譜通量
    final smoothedFlux = _smoothSignal(spectralFlux);
    
    // 3. 動態閾值
    final threshold = _calculateAdaptiveThreshold(smoothedFlux);
    
    // 4. 峰值檢測
    final onsets = _detectPeaks(smoothedFlux, threshold, spectrogram);
    
    print('🎯 Onset 檢測結果:');
    print('   檢測到 ${onsets.length} 個音符起始點');
    print('   平均強度: ${onsets.isEmpty ? 0 : (onsets.map((o) => o.strength).reduce((a, b) => a + b) / onsets.length).toStringAsFixed(3)}');
    
    return onsets;
  }

  /// 計算頻譜通量
  /// 
  /// Spectral Flux = Σ max(0, S(t,f) - S(t-1,f))
  /// 只計算能量增加的部分 (Half-Wave Rectification)
  List<double> _calculateSpectralFlux(Spectrogram spectrogram) {
    final flux = <double>[];
    
    for (int frame = 0; frame < spectrogram.timeFrames; frame++) {
      if (frame == 0) {
        flux.add(0.0); // 第一幀無法計算差值
        continue;
      }
      
      double sum = 0.0;
      for (int bin = 0; bin < spectrogram.freqBins; bin++) {
        final current = spectrogram.data[frame][bin];
        final previous = spectrogram.data[frame - 1][bin];
        final diff = current - previous;
        
        // Half-Wave Rectification: 只計算增加的能量
        if (diff > 0) {
          sum += diff;
        }
      }
      
      flux.add(sum);
    }
    
    return flux;
  }

  /// 平滑信號 (移動平均)
  List<double> _smoothSignal(List<double> signal) {
    final smoothed = <double>[];
    final halfWindow = smoothWindowSize ~/ 2;
    
    for (int i = 0; i < signal.length; i++) {
      final start = max(0, i - halfWindow);
      final end = min(signal.length, i + halfWindow + 1);
      
      double sum = 0.0;
      int count = 0;
      for (int j = start; j < end; j++) {
        sum += signal[j];
        count++;
      }
      
      smoothed.add(sum / count);
    }
    
    return smoothed;
  }

  /// 計算自適應閾值
  /// 
  /// 使用中位數 × 倍數作為動態閾值
  double _calculateAdaptiveThreshold(List<double> flux) {
    final sorted = List<double>.from(flux)..sort();
    final medianIndex = sorted.length ~/ 2;
    final median = sorted[medianIndex];
    
    return median * onsetThresholdMultiplier;
  }

  /// 檢測峰值
  /// 
  /// 找出所有超過閾值的局部最大值
  List<OnsetEvent> _detectPeaks(
    List<double> flux,
    double threshold,
    Spectrogram spectrogram,
  ) {
    final onsets = <OnsetEvent>[];
    final minIntervalFrames = (minOnsetInterval / spectrogram.timeResolution).round();
    int lastOnsetFrame = -minIntervalFrames;
    
    for (int frame = 1; frame < flux.length - 1; frame++) {
      final current = flux[frame];
      final prev = flux[frame - 1];
      final next = flux[frame + 1];
      
      // 檢查是否為局部峰值且超過閾值
      if (current > threshold && current > prev && current >= next) {
        // 檢查是否滿足最小間隔
        if (frame - lastOnsetFrame >= minIntervalFrames) {
          final time = frame * spectrogram.timeResolution;
          onsets.add(OnsetEvent(
            time: time,
            strength: current,
          ));
          lastOnsetFrame = frame;
        }
      }
    }
    
    return onsets;
  }

  /// 獲取指定時間附近的 onset
  /// 
  /// 返回時間誤差在 ±tolerance 內的 onset
  OnsetEvent? getOnsetNear(
    List<OnsetEvent> onsets,
    double targetTime,
    double tolerance,
  ) {
    OnsetEvent? closest;
    double minDiff = double.infinity;
    
    for (final onset in onsets) {
      final diff = (onset.time - targetTime).abs();
      if (diff < tolerance && diff < minDiff) {
        minDiff = diff;
        closest = onset;
      }
    }
    
    return closest;
  }

  /// 計算 onset 時間誤差 (ms)
  double calculateOnsetError(
    OnsetEvent detected,
    double expectedTime,
  ) {
    return (detected.time - expectedTime) * 1000; // 轉換為毫秒
  }
}

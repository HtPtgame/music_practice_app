/// 時間-頻率譜圖數據結構
/// 
/// 用於存儲 STFT (短時距傅立葉變換) 的結果
/// 每一行代表一個時間幀,每一列代表一個頻率bins
class Spectrogram {
  /// 時間幀數量
  final int timeFrames;
  
  /// 頻率bins數量 (通常是 fftSize/2 + 1)
  final int freqBins;
  
  /// 頻譜數據 [timeFrames x freqBins]
  /// data[t][f] = 時間t,頻率f的能量
  final List<List<double>> data;
  
  /// 採樣率 (Hz)
  final int sampleRate;
  
  /// FFT 窗口大小
  final int fftSize;
  
  /// 跳躍大小 (hop size)
  final int hopSize;

  Spectrogram({
    required this.timeFrames,
    required this.freqBins,
    required this.data,
    required this.sampleRate,
    this.fftSize = 2048,
    this.hopSize = 512,
  });

  /// 頻率解析度 (Hz/bin)
  double get frequencyResolution => sampleRate / fftSize;

  /// 時間解析度 (秒/幀)
  double get timeResolution => hopSize / sampleRate;

  /// 將頻率 (Hz) 轉換為 bin 索引
  int freqToBin(double frequency) {
    return (frequency / frequencyResolution).round().clamp(0, freqBins - 1);
  }

  /// 將時間 (秒) 轉換為幀索引
  int timeToFrame(double time) {
    return (time / timeResolution).round().clamp(0, timeFrames - 1);
  }

  /// 獲取指定時間和頻率的能量
  double getEnergy(double time, double frequency) {
    final frameIdx = timeToFrame(time);
    final freqIdx = freqToBin(frequency);
    return data[frameIdx][freqIdx];
  }

  /// 獲取指定時間範圍內,指定頻率的平均能量
  double getAverageEnergy(double startTime, double endTime, double frequency) {
    final startFrame = timeToFrame(startTime);
    final endFrame = timeToFrame(endTime);
    final freqIdx = freqToBin(frequency);
    
    double sum = 0;
    int count = 0;
    for (int f = startFrame; f <= endFrame; f++) {
      sum += data[f][freqIdx];
      count++;
    }
    
    return count > 0 ? sum / count : 0;
  }

  @override
  String toString() {
    return 'Spectrogram(frames: $timeFrames, bins: $freqBins, '
           'freqRes: ${frequencyResolution.toStringAsFixed(2)}Hz, '
           'timeRes: ${(timeResolution * 1000).toStringAsFixed(2)}ms)';
  }
}

/// 音訊處理相關常數
///
/// 集中管理所有音訊處理相關的魔術數字，提高程式碼可維護性
class AudioConstants {
  // 私有建構子，防止實例化
  AudioConstants._();

  // ==================== 音訊參數 ====================
  
  /// 標準採樣率 (Hz)
  static const int standardSampleRate = 16000;
  
  /// 標準位元率 (bps)
  static const int standardBitRate = 256000;
  
  /// 單聲道
  static const int monoChannel = 1;
  
  /// 立體聲
  static const int stereoChannel = 2;

  // ==================== 錄音限制 ====================
  
  /// 最大錄音時長 (秒)
  static const int maxRecordingSeconds = 300; // 5 分鐘
  
  /// 最小錄音時長 (秒)
  static const int minRecordingSeconds = 3;
  
  /// 預設錄音時長 (秒)
  static const int defaultRecordingSeconds = 15;

  // ==================== 分析參數 ====================
  
  /// FFT 大小
  static const int fftSize = 2048;
  
  /// Hop Length
  static const int hopLength = 512;
  
  /// 預設能量閾值
  static const double defaultEnergyThreshold = 0.38;
  
  /// 預設音高容差 (半音)
  static const double defaultPitchTolerance = 0.5;

  // ==================== 時間相關 ====================
  
  /// 倒數計時秒數
  static const int countdownSeconds = 3;
  
  /// 最大延遲時間 (秒)
  static const int maxTimingDelaySeconds = 30;
  
  /// 進度更新間隔 (毫秒)
  static const int progressUpdateIntervalMs = 100;
}

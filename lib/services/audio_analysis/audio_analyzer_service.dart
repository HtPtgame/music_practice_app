import 'dart:typed_data';
import 'models/spectrogram.dart';

/// 音訊分析服務接口
///
/// 負責將 WAV 音訊轉換為時頻譜圖
abstract class IAudioAnalyzer {
  /// 分析 WAV 檔案,生成頻譜圖
  ///
  /// [wavFilePath] WAV 檔案路徑
  /// 返回 [Spectrogram] 時頻譜圖
  Future<Spectrogram> analyze(String wavFilePath);

  /// 分析 WAV 數據,生成頻譜圖
  ///
  /// [wavData] WAV PCM 數據
  /// [sampleRate] 採樣率
  /// 返回 [Spectrogram] 時頻譜圖
  Future<Spectrogram> analyzeData(Uint8List wavData, int sampleRate);
}

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'audio_analyzer_service.dart';
import 'models/spectrogram.dart';

/// 音訊分析服務實現
/// 
/// 使用 STFT (短時距傅立葉變換) 將音訊轉換為時頻譜圖
class AudioAnalyzerServiceImpl implements IAudioAnalyzer {
  // FFT 參數配置
  static const int fftSize = 2048;      // FFT 窗口大小
  static const int hopSize = 512;       // 跳躍大小 (每次移動的樣本數)
  static const int defaultSampleRate = 44100;

  @override
  Future<Spectrogram> analyze(String wavFilePath) async {
    try {
      // 讀取 WAV 文件
      final file = File(wavFilePath);
      if (!await file.exists()) {
        throw Exception('WAV 文件不存在: $wavFilePath');
      }

      final bytes = await file.readAsBytes();
      
      // 解析 WAV 格式
      final wavData = _parseWavFile(bytes);
      
      return analyzeData(wavData.samples, wavData.sampleRate);
    } catch (e) {
      throw Exception('音訊分析失敗: $e');
    }
  }

  @override
  Future<Spectrogram> analyzeData(Uint8List wavData, int sampleRate) async {
    // 將 PCM16 數據轉換為 double 數組 (-1.0 到 1.0)
    final audioSamples = _pcm16ToDouble(wavData);
    
    // 執行 STFT
    final frames = _performSTFT(audioSamples, sampleRate);
    
    // 創建 Spectrogram 對象
    return Spectrogram(
      timeFrames: frames.length,
      freqBins: fftSize ~/ 2 + 1,  // 只保留正頻率部分
      data: frames,
      sampleRate: sampleRate,
      fftSize: fftSize,
      hopSize: hopSize,
    );
  }

  /// 執行短時距傅立葉變換 (STFT)
  List<List<double>> _performSTFT(List<double> audio, int sampleRate) {
    final window = _hanningWindow(fftSize);
    final fft = FFT(fftSize);
    final result = <List<double>>[];

    // 遍歷音訊,每次移動 hopSize 個樣本
    for (int i = 0; i < audio.length - fftSize; i += hopSize) {
      // 提取當前窗口的樣本
      final frame = audio.sublist(i, i + fftSize);
      
      // 應用 Hanning 窗函數
      final windowedFrame = List<double>.generate(
        fftSize,
        (j) => frame[j] * window[j],
      );

      // 執行 FFT (fftea 使用 List<double> 作為輸入)
      final complexResult = fft.realFft(windowedFrame);

      // 計算功率譜 (幅度)
      final magnitudes = <double>[];
      for (int j = 0; j < fftSize ~/ 2 + 1; j++) {
        final real = complexResult[j].x;
        final imag = complexResult[j].y;
        final magnitude = sqrt(real * real + imag * imag);
        magnitudes.add(magnitude);
      }

      result.add(magnitudes);
    }

    return result;
  }

  /// 生成 Hanning 窗函數
  /// 
  /// Hanning 窗可以減少頻譜洩漏,使頻譜分析更準確
  List<double> _hanningWindow(int size) {
    return List<double>.generate(size, (i) {
      return 0.5 * (1 - cos(2 * pi * i / (size - 1)));
    });
  }

  /// 將 PCM16 數據轉換為 -1.0 到 1.0 的 double 數組
  List<double> _pcm16ToDouble(Uint8List pcmData) {
    final samples = <double>[];
    
    // PCM16 是 16-bit signed integer, 每個樣本 2 bytes
    for (int i = 0; i < pcmData.length - 1; i += 2) {
      // Little-endian: 低位在前
      final int16Value = pcmData[i] | (pcmData[i + 1] << 8);
      
      // 轉換為有符號整數
      final signedValue = int16Value > 32767 
          ? int16Value - 65536 
          : int16Value;
      
      // 正規化到 -1.0 到 1.0
      final normalized = signedValue / 32768.0;
      samples.add(normalized);
    }
    
    return samples;
  }

  /// 解析 WAV 文件格式
  _WavData _parseWavFile(Uint8List bytes) {
    // 基本的 WAV 文件格式驗證
    if (bytes.length < 44) {
      throw Exception('WAV 文件格式錯誤: 文件太小');
    }

    // 檢查 "RIFF" 標記
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    if (riff != 'RIFF') {
      throw Exception('WAV 文件格式錯誤: 缺少 RIFF 標記');
    }

    // 檢查 "WAVE" 標記
    final wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (wave != 'WAVE') {
      throw Exception('WAV 文件格式錯誤: 缺少 WAVE 標記');
    }

    // 讀取採樣率 (位置 24-27, little-endian)
    final sampleRate = bytes[24] | 
                      (bytes[25] << 8) | 
                      (bytes[26] << 16) | 
                      (bytes[27] << 24);

    // 讀取聲道數 (位置 22-23)
    final numChannels = bytes[22] | (bytes[23] << 8);

    // 讀取位深度 (位置 34-35)
    final bitsPerSample = bytes[34] | (bytes[35] << 8);

    // 驗證格式
    if (numChannels != 1) {
      throw Exception('僅支持單聲道 WAV 文件 (當前: $numChannels 聲道)');
    }

    if (bitsPerSample != 16) {
      throw Exception('僅支持 16-bit WAV 文件 (當前: $bitsPerSample-bit)');
    }

    // 尋找 "data" 區塊
    int dataOffset = 12;
    while (dataOffset < bytes.length - 8) {
      final chunkId = String.fromCharCodes(bytes.sublist(dataOffset, dataOffset + 4));
      final chunkSize = bytes[dataOffset + 4] | 
                       (bytes[dataOffset + 5] << 8) | 
                       (bytes[dataOffset + 6] << 16) | 
                       (bytes[dataOffset + 7] << 24);

      if (chunkId == 'data') {
        // 找到數據區塊
        final samples = bytes.sublist(dataOffset + 8, dataOffset + 8 + chunkSize);
        return _WavData(
          samples: samples,
          sampleRate: sampleRate,
          numChannels: numChannels,
          bitsPerSample: bitsPerSample,
        );
      }

      dataOffset += 8 + chunkSize;
    }

    throw Exception('WAV 文件格式錯誤: 找不到 data 區塊');
  }
}

/// WAV 數據結構
class _WavData {
  final Uint8List samples;
  final int sampleRate;
  final int numChannels;
  final int bitsPerSample;

  _WavData({
    required this.samples,
    required this.sampleRate,
    required this.numChannels,
    required this.bitsPerSample,
  });
}

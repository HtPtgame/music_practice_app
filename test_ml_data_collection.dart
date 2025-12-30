/// ML 資料收集測試程式
/// 
/// 目標: 產生高品質訓練數據 CSV，用於邏輯回歸模型訓練
/// 策略: 
/// 1. MIDI 檔案: 基於 Ground Truth 時間戳自動標記 (±0.1s)
/// 2. 純雜訊錄音: 全部標記為 0 (教會模型過濾環境音)
/// 3. 真實錄音: 基於 Ground Truth 時間戳自動標記
/// 
/// 資料品質: 垃圾進 → 垃圾出，必須嚴格執行標記策略
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloria/services/audio_analysis/models/spectrogram.dart';
import 'package:veloria/services/audio_analysis/note_detector_service_optimized.dart';
import 'package:veloria/services/audio_analysis/sequence_matcher_service.dart';
import 'package:fftea/fftea.dart';

void main() {
  group('🤖 ML 資料收集器', () {
    
    /// 🎹 小星星 MIDI Ground Truth (手動標記的標準答案)
    /// 來源: ACCURACY_EVALUATION_REPORT.md
    final midiGroundTruth = [
      0.650, 0.743, 1.021, 1.114, 1.393, 1.486, 1.765,  // 第一句
      1.998, 2.090, 2.322, 2.415, 2.601, 2.693, 2.927,  // 第二句
      // ... (可以根據實際需求擴展)
    ];
    
    /// 🎤 小星星錄音 Ground Truth (前 5 秒的標準答案)
    /// 來源: ACCURACY_EVALUATION_REPORT.md
    final recordingGroundTruth = [
      0.75, 1.25, 1.75, 2.25, 2.75, 3.25, 3.75,  // 前 7 個音符
    ];
    
    /// CSV 輸出檔案
    final csvFile = File('ml_training_data.csv');
    
    setUpAll(() {
      // 只在第一次初始化 CSV 標頭（整個測試組只執行一次）
      if (csvFile.existsSync()) {
        csvFile.deleteSync();  // 刪除舊檔案
      }
      csvFile.writeAsStringSync(DetectedNote.csvHeader + '\n');
      print('📝 CSV 檔案已初始化: ${csvFile.path}\n');
    });
    
    // ═══════════════════════════════════════════════════════════════
    // 策略 1: MIDI 檔案 - Positive Samples (真音符)
    // ═══════════════════════════════════════════════════════════════
    
    test('📊 收集 MIDI 訓練數據 (Label=1 為主)', () async {
      print('\n🎹 開始處理 MIDI 檔案...');
      
      final midiFile = File('assets/test_voice/小星星.mid');
      if (!midiFile.existsSync()) {
        print('⚠️ MIDI 檔案不存在，跳過此測試');
        return;
      }
      
      // 載入 MIDI 並轉換為音訊
      final audioData = await _loadMidiAsAudio(midiFile);
      
      // 產生頻譜圖
      final spectrogram = _createSpectrogramFromAudio(audioData);
      
      // 執行檢測 (閾值 0.20 的瘋狂檢察官模式)
      final detector = OptimizedNoteDetectorService();
      detector.mlDataCollectionMode = true;  // 🤖 啟用 ML 數據收集模式
      
      final candidates = await detector.detectAll(spectrogram);
      
      print('🔍 檢測到 ${candidates.length} 個候選音符');
      
      // 自動標記策略
      int positiveCount = 0;
      int negativeCount = 0;
      
      for (final note in candidates) {
        // ⚠️ 略過前 0.5 秒 (MIDI 瞬態雜訊)
        if (note.time < 0.5) {
          continue;
        }
        
        // 檢查是否在任何 Ground Truth 的 ±0.1 秒範圍內
        int label = 0;
        for (final truth in midiGroundTruth) {
          if ((note.time - truth).abs() < 0.1) {
            label = 1;
            positiveCount++;
            break;
          }
        }
        
        if (label == 0) negativeCount++;
        
        // 寫入 CSV
        csvFile.writeAsStringSync(
          note.toCSV(label: label) + '\n',
          mode: FileMode.append,
        );
      }
      
      print('✅ MIDI 數據收集完成:');
      print('   - 真音符 (Label=1): $positiveCount');
      print('   - 雜訊 (Label=0): $negativeCount');
      print('   - 比例: ${(positiveCount / (positiveCount + negativeCount) * 100).toStringAsFixed(1)}% 正樣本');
    });
    
    // ═══════════════════════════════════════════════════════════════
    // 策略 2: 純雜訊錄音 - Negative Samples (教會模型過濾環境音)
    // ═══════════════════════════════════════════════════════════════
    
    test('📊 收集純雜訊訓練數據 #1 (Label=0)', () async {
      print('\n🌬️ 開始處理純雜訊錄音 noise.wav...');
      
      // 檢查是否存在雜訊檔案
      final noiseFile = File('assets/test_voice/noise.wav');
      if (!noiseFile.existsSync()) {
        print('⚠️ 雜訊檔案不存在: ${noiseFile.path}');
        return;
      }
      
      await _collectNoiseData(noiseFile, csvFile);
    });
    
    test('📊 收集純雜訊訓練數據 #2 (Label=0)', () async {
      print('\n🌬️ 開始處理純雜訊錄音 noise2.wav...');
      
      // 檢查是否存在第二個雜訊檔案
      final noiseFile2 = File('assets/test_voice/noise2.wav');
      if (!noiseFile2.existsSync()) {
        print('⚠️ 雜訊檔案不存在: ${noiseFile2.path}');
        return;
      }
      
      await _collectNoiseData(noiseFile2, csvFile);
    });
    
    // ═══════════════════════════════════════════════════════════════
    // 策略 3: 敲擊聲錄音 - Hard Negatives (教會模型區分敲擊與樂音)
    // ═══════════════════════════════════════════════════════════════
    
    test('📊 收集敲擊聲訓練數據 (Label=0, Hard Negatives)', () async {
      print('\n👊 開始處理敲擊聲錄音...');
      
      final percussionFile = File('assets/test_voice/percussion_only.wav');
      if (!percussionFile.existsSync()) {
        print('⚠️ 敲擊聲檔案不存在，請錄製 10 秒「敲琴鍵/敲桌子」的聲音');
        print('   特性: 有 onsetStrength，但無 harmonicRatio');
        return;
      }
      
      // 載入音訊
      final audioData = await _loadWavFile(percussionFile);
      
      // 產生頻譜圖
      final spectrogram = _createSpectrogramFromAudio(audioData);
      
      // 執行檢測
      final detector = OptimizedNoteDetectorService();
      detector.mlDataCollectionMode = true;  // 🤖 啟用 ML 模式
      final candidates = await detector.detectAll(spectrogram);
      
      print('🔍 在敲擊聲中檢測到 ${candidates.length} 個候選音符');
      
      // 全部標記為 0
      int count = 0;
      for (final note in candidates) {
        csvFile.writeAsStringSync(
          note.toCSV(label: 0) + '\n',
          mode: FileMode.append,
        );
        count++;
      }
      
      print('✅ 敲擊聲數據收集完成:');
      print('   - 敲擊聲 (Label=0): $count');
      print('   - 特徵期望: onsetStrength 高, harmonicRatio 低');
    });
    
    // ═══════════════════════════════════════════════════════════════
    // 策略 4: 真實錄音 - Mixed Samples (基於 Ground Truth 標記)
    // ═══════════════════════════════════════════════════════════════
    
    test('📊 收集真實錄音訓練數據 (Label=0/1 混合)', () async {
      print('\n🎤 開始處理真實錄音...');
      
      // 使用現有的電腦環境錄製檔案
      final recordingFile = File('assets/test_voice/小星星(電腦環境錄製).wav');
      if (!recordingFile.existsSync()) {
        print('⚠️ 錄音檔案不存在: ${recordingFile.path}');
        return;
      }
      
      // 載入音訊
      final audioData = await _loadWavFile(recordingFile);
      
      // 產生頻譜圖
      final spectrogram = _createSpectrogramFromAudio(audioData);
      
      // 執行檢測
      final detector = OptimizedNoteDetectorService();
      detector.mlDataCollectionMode = true;  // 🤖 啟用 ML 模式
      final candidates = await detector.detectAll(spectrogram);
      
      print('🔍 檢測到 ${candidates.length} 個候選音符');
      
      // 基於 Ground Truth 自動標記
      int positiveCount = 0;
      int negativeCount = 0;
      
      for (final note in candidates) {
        // 只處理前 5 秒 (Ground Truth 範圍)
        if (note.time > 5.0) {
          break;
        }
        
        // 🔧 擴大時間容差到 ±0.3 秒,捕捉音符首尾片段
        // 原因: 一個音符被切成多個 frames,只用 ±0.1 秒會漏掉邊緣 frames
        int label = 0;
        for (final truth in recordingGroundTruth) {
          if ((note.time - truth).abs() < 0.3) {
            label = 1;
            positiveCount++;
            break;
          }
        }
        
        if (label == 0) negativeCount++;
        
        // 寫入 CSV
        csvFile.writeAsStringSync(
          note.toCSV(label: label) + '\n',
          mode: FileMode.append,
        );
      }
      
      print('✅ 真實錄音數據收集完成:');
      print('   - 真音符 (Label=1): $positiveCount');
      print('   - 雜訊 (Label=0): $negativeCount');
      print('   - 比例: ${(positiveCount / (positiveCount + negativeCount) * 100).toStringAsFixed(1)}% 正樣本');
    });
    
    // ═══════════════════════════════════════════════════════════════
    // 數據品質檢查
    // ═══════════════════════════════════════════════════════════════
    
    test('🔍 檢查數據品質', () {
      print('\n📈 分析收集的訓練數據...');
      
      if (!csvFile.existsSync()) {
        print('⚠️ CSV 檔案不存在，請先執行數據收集測試');
        return;
      }
      
      final lines = csvFile.readAsLinesSync();
      final header = lines.first;
      final data = lines.skip(1).toList();
      
      print('📊 總數據量: ${data.length} 筆');
      
      // 統計標籤分佈
      int label0 = 0;
      int label1 = 0;
      
      // 統計特徵範圍
      double minHarmonicRatio = double.infinity;
      double maxHarmonicRatio = -double.infinity;
      double minSpectralFlatness = double.infinity;
      double maxSpectralFlatness = -double.infinity;
      
      for (final line in data) {
        final parts = line.split(',');
        if (parts.length < 6) continue;
        
        final label = int.parse(parts[0]);
        final harmonicRatio = double.parse(parts[2]);
        final spectralFlatness = double.parse(parts[4]);
        
        if (label == 0) label0++;
        if (label == 1) label1++;
        
        if (harmonicRatio < minHarmonicRatio) minHarmonicRatio = harmonicRatio;
        if (harmonicRatio > maxHarmonicRatio) maxHarmonicRatio = harmonicRatio;
        if (spectralFlatness < minSpectralFlatness) minSpectralFlatness = spectralFlatness;
        if (spectralFlatness > maxSpectralFlatness) maxSpectralFlatness = spectralFlatness;
      }
      
      print('');
      print('🏷️ 標籤分佈:');
      print('   - Label=0 (雜訊): $label0 (${(label0 / data.length * 100).toStringAsFixed(1)}%)');
      print('   - Label=1 (真音符): $label1 (${(label1 / data.length * 100).toStringAsFixed(1)}%)');
      print('   - 類別平衡度: ${(label1 / label0).toStringAsFixed(2)} (理想: 0.3-0.5)');
      
      print('');
      print('📐 特徵範圍:');
      print('   - HarmonicRatio: [$minHarmonicRatio, $maxHarmonicRatio]');
      print('   - SpectralFlatness: [$minSpectralFlatness, $maxSpectralFlatness]');
      
      print('');
      print('✅ 數據品質檢查完成!');
      print('📁 訓練數據已保存至: ${csvFile.path}');
      print('');
      print('🚀 下一步: 使用 Python 訓練邏輯回歸模型');
      print('   python train_classifier.py');
    });
  });
}

// ═══════════════════════════════════════════════════════════════
// 輔助函數
// ═══════════════════════════════════════════════════════════════

/// 收集雜訊數據的通用函數
Future<void> _collectNoiseData(File noiseFile, File csvFile) async {
  // 載入音訊
  final audioData = await _loadWavFile(noiseFile);
  
  // 產生頻譜圖
  final spectrogram = _createSpectrogramFromAudio(audioData);
  
  // 執行檢測
  final detector = OptimizedNoteDetectorService();
  detector.mlDataCollectionMode = true;  // 🤖 啟用 ML 模式
  final candidates = await detector.detectAll(spectrogram);
  
  print('🔍 在雜訊中檢測到 ${candidates.length} 個候選音符 (全部為假陽性)');
  
  // 全部標記為 0 (這些都是模型需要學會拒絕的)
  int count = 0;
  for (final note in candidates) {
    csvFile.writeAsStringSync(
      note.toCSV(label: 0) + '\n',
      mode: FileMode.append,
    );
    count++;
  }
  
  print('✅ 雜訊數據收集完成:');
  print('   - 純雜訊 (Label=0): $count');
  print('   - 特徵期望: spectralFlatness 高, harmonicRatio 低\n');
}

/// 從音訊數據創建頻譜圖
Spectrogram _createSpectrogramFromAudio(Float32List audioData) {
  const int fftSize = 2048;
  const int hopSize = 512;
  const int sampleRate = 44100;
  
  // 使用 FFT 創建頻譜圖
  final window = Window.hanning(fftSize);
  final fft = FFT(fftSize);
  final spectrogramData = <List<double>>[];
  
  // 遍歷音訊,每次移動 hopSize 個樣本
  for (int i = 0; i < audioData.length - fftSize; i += hopSize) {
    // 提取當前窗口的樣本
    final frame = audioData.sublist(i, i + fftSize);
    
    // 應用 Hanning 窗函數
    final windowedFrame = List<double>.generate(
      fftSize,
      (j) => frame[j] * window[j],
    );
    
    // 執行 FFT
    final complexResult = fft.realFft(windowedFrame);
    
    // 計算幅度譜
    final magnitudes = <double>[];
    for (int j = 0; j < fftSize ~/ 2 + 1; j++) {
      final real = complexResult[j].x;
      final imag = complexResult[j].y;
      magnitudes.add(sqrt(real * real + imag * imag));
    }
    
    spectrogramData.add(magnitudes);
  }
  
  return Spectrogram(
    data: spectrogramData,
    timeFrames: spectrogramData.length,
    freqBins: fftSize ~/ 2 + 1,
    sampleRate: sampleRate,
    fftSize: fftSize,
    hopSize: hopSize,
  );
}

/// 載入 MIDI 並轉換為音訊 (模擬函數)
Future<Float32List> _loadMidiAsAudio(File midiFile) async {
  // 使用已經轉換好的 MIDI WAV 檔案
  final wavFile = File(midiFile.path.replaceAll('.mid', '(midi轉檔).wav'));
  if (!wavFile.existsSync()) {
    throw Exception('請先將 MIDI 轉換為 WAV: ${wavFile.path}');
  }
  return _loadWavFile(wavFile);
}

/// 載入 WAV 檔案並轉換為 Float32 音訊數據
Future<Float32List> _loadWavFile(File file) async {
  print('  📂 讀取檔案: ${file.path}');
  
  final bytes = await file.readAsBytes();
  
  // 解析 WAV 標頭
  if (bytes.length < 44) {
    throw Exception('檔案太小，不是有效的 WAV 檔案');
  }
  
  // 檢查 RIFF/WAVE 標頭
  final riff = String.fromCharCodes(bytes.sublist(0, 4));
  final wave = String.fromCharCodes(bytes.sublist(8, 12));
  if (riff != 'RIFF' || wave != 'WAVE') {
    throw Exception('不是有效的 WAV 檔案');
  }
  
  // 讀取格式資訊
  final numChannels = bytes[22] | (bytes[23] << 8);
  final sampleRate = bytes[24] | (bytes[25] << 8) | (bytes[26] << 16) | (bytes[27] << 24);
  final bitsPerSample = bytes[34] | (bytes[35] << 8);
  
  print('  🎵 格式: ${numChannels}聲道, ${sampleRate}Hz, ${bitsPerSample}bit');
  
  // 找到 data chunk (音訊數據起始位置)
  int dataOffset = 12;
  while (dataOffset < bytes.length - 8) {
    final chunkId = String.fromCharCodes(bytes.sublist(dataOffset, dataOffset + 4));
    final chunkSize = bytes[dataOffset + 4] |
        (bytes[dataOffset + 5] << 8) |
        (bytes[dataOffset + 6] << 16) |
        (bytes[dataOffset + 7] << 24);
    
    if (chunkId == 'data') {
      dataOffset += 8;
      break;
    }
    dataOffset += 8 + chunkSize;
  }
  
  if (dataOffset >= bytes.length) {
    throw Exception('找不到音訊數據');
  }
  
  // 讀取音訊數據
  final audioBytes = bytes.sublist(dataOffset);
  final bytesPerSample = bitsPerSample ~/ 8;
  final frameSize = bytesPerSample * numChannels;
  final numFrames = audioBytes.length ~/ frameSize;
  
  print('  📊 幀數: $numFrames (${(numFrames / sampleRate).toStringAsFixed(2)}秒)');
  
  // 轉換為單聲道 Float32 (-1.0 到 1.0)
  final samples = Float32List(numFrames);
  
  if (bitsPerSample == 16) {
    // 16-bit signed PCM
    for (int i = 0; i < numFrames; i++) {
      if (numChannels == 1) {
        // 單聲道
        final offset = i * 2;
        final int16Value = (audioBytes[offset] | (audioBytes[offset + 1] << 8)).toSigned(16);
        samples[i] = int16Value / 32768.0;
      } else if (numChannels == 2) {
        // 立體聲: 平均左右聲道
        final leftOffset = i * 4;
        final rightOffset = leftOffset + 2;
        final left = (audioBytes[leftOffset] | (audioBytes[leftOffset + 1] << 8)).toSigned(16);
        final right = (audioBytes[rightOffset] | (audioBytes[rightOffset + 1] << 8)).toSigned(16);
        samples[i] = ((left + right) / 2) / 32768.0;
      }
    }
  } else if (bitsPerSample == 8) {
    // 8-bit unsigned PCM
    for (int i = 0; i < numFrames; i++) {
      if (numChannels == 1) {
        samples[i] = (audioBytes[i] - 128) / 128.0;
      } else if (numChannels == 2) {
        final left = audioBytes[i * 2];
        final right = audioBytes[i * 2 + 1];
        samples[i] = (((left + right) / 2) - 128) / 128.0;
      }
    }
  } else {
    throw Exception('不支援的位深度: $bitsPerSample');
  }
  
  print('  ✅ 音訊載入完成: ${samples.length} 個樣本\n');
  return samples;
}

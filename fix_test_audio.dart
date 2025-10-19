/// 修正測試音檔格式
/// 將所有測試音檔轉換為: 單聲道, 44100Hz, 16-bit PCM

import 'dart:io';
import 'dart:typed_data';

void main() async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║       🔧 測試音檔格式修正工具                             ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');

  final testFiles = [
    'assets/test_voice/測試音檔(midi轉檔).wav',
    'assets/test_voice/測試音檔(環境).wav',
    'assets/test_voice/小星星(midi轉檔).wav',
    'assets/test_voice/小星星(環境).wav',
    'assets/test_voice/環境背景.wav',
    'assets/test_voice/環境背景2.wav',
    'assets/test_voice/名偵探柯南(midi轉檔).wav',
    'assets/test_voice/名偵探柯南(環境).wav',
  ];

  for (var path in testFiles) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📄 處理: $path');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final file = File(path);
    if (!await file.exists()) {
      print('   ⚠️  檔案不存在,跳過');
      print('');
      continue;
    }

    await processWavFile(path);
    print('');
  }

  print('╔═══════════════════════════════════════════════════════════╗');
  print('║                  ✅ 所有檔案處理完成!                     ║');
  print('╚═══════════════════════════════════════════════════════════╝');
}

Future<void> processWavFile(String inputPath) async {
  // 讀取檔案
  final bytes = await File(inputPath).readAsBytes();
  final data = ByteData.sublistView(Uint8List.fromList(bytes));

  // 解析 WAV 頭
  final channels = data.getInt16(22, Endian.little);
  final sampleRate = data.getInt32(24, Endian.little);
  final bitsPerSample = data.getInt16(34, Endian.little);

  print('   原始格式: $channels 聲道, $sampleRate Hz, $bitsPerSample bits');

  bool needsConversion = false;
  if (channels != 1) {
    print('   🔄 需要轉換: 雙聲道 → 單聲道');
    needsConversion = true;
  }
  if (sampleRate != 44100) {
    print('   🔄 需要重新取樣: $sampleRate Hz → 44100 Hz');
    needsConversion = true;
  }
  if (bitsPerSample != 16) {
    print('   ❌ 錯誤: 僅支援 16-bit PCM');
    return;
  }

  if (!needsConversion) {
    print('   ✅ 格式正確,無需轉換');
    return;
  }

  // 讀取音訊數據
  final dataSize = bytes.length - 44;
  final totalSamples = dataSize ~/ (channels * 2);

  print('   📊 總樣本數: $totalSamples');

  // 步驟 1: 立體聲轉單聲道 (如果需要)
  List<int> monoSamples;
  if (channels == 2) {
    print('   🔄 混音為單聲道...');
    monoSamples = List<int>.filled(totalSamples, 0);
    for (var i = 0; i < totalSamples; i++) {
      final offset = 44 + (i * 4);
      final left = data.getInt16(offset, Endian.little);
      final right = data.getInt16(offset + 2, Endian.little);
      monoSamples[i] = ((left + right) / 2).round();
    }
  } else {
    monoSamples = List<int>.filled(totalSamples, 0);
    for (var i = 0; i < totalSamples; i++) {
      final offset = 44 + (i * 2);
      monoSamples[i] = data.getInt16(offset, Endian.little);
    }
  }

  // 步驟 2: 重新取樣到 44100Hz (如果需要)
  List<int> resampledSamples;
  if (sampleRate != 44100) {
    print('   🔄 重新取樣到 44100Hz...');
    final ratio = sampleRate / 44100.0;
    final newSampleCount = (totalSamples / ratio).round();
    resampledSamples = List<int>.filled(newSampleCount, 0);
    
    for (var i = 0; i < newSampleCount; i++) {
      final srcIndex = (i * ratio);
      final srcIndexInt = srcIndex.floor();
      final frac = srcIndex - srcIndexInt;
      
      if (srcIndexInt + 1 < monoSamples.length) {
        // 線性插值
        final sample1 = monoSamples[srcIndexInt];
        final sample2 = monoSamples[srcIndexInt + 1];
        resampledSamples[i] = (sample1 * (1 - frac) + sample2 * frac).round();
      } else {
        resampledSamples[i] = monoSamples[srcIndexInt];
      }
    }
  } else {
    resampledSamples = monoSamples;
  }

  print('   📊 新樣本數: ${resampledSamples.length}');

  // 創建標準 WAV 文件 (RIFF + fmt + data)
  final newDataSize = resampledSamples.length * 2;
  
  // 建立完整的 WAV 標頭
  final output = ByteData(44 + newDataSize);
  
  // RIFF header
  output.setUint8(0, 0x52); // 'R'
  output.setUint8(1, 0x49); // 'I'
  output.setUint8(2, 0x46); // 'F'
  output.setUint8(3, 0x46); // 'F'
  output.setUint32(4, 36 + newDataSize, Endian.little); // ChunkSize
  output.setUint8(8, 0x57);  // 'W'
  output.setUint8(9, 0x41);  // 'A'
  output.setUint8(10, 0x56); // 'V'
  output.setUint8(11, 0x45); // 'E'
  
  // fmt subchunk
  output.setUint8(12, 0x66); // 'f'
  output.setUint8(13, 0x6d); // 'm'
  output.setUint8(14, 0x74); // 't'
  output.setUint8(15, 0x20); // ' '
  output.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
  output.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
  output.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
  output.setUint32(24, 44100, Endian.little); // SampleRate
  output.setUint32(28, 44100 * 1 * 2, Endian.little); // ByteRate
  output.setUint16(32, 2, Endian.little);  // BlockAlign (1 * 16/8)
  output.setUint16(34, 16, Endian.little); // BitsPerSample
  
  // data subchunk
  output.setUint8(36, 0x64); // 'd'
  output.setUint8(37, 0x61); // 'a'
  output.setUint8(38, 0x74); // 't'
  output.setUint8(39, 0x61); // 'a'
  output.setUint32(40, newDataSize, Endian.little); // Subchunk2Size
  
  // 寫入樣本數據
  for (var i = 0; i < resampledSamples.length; i++) {
    output.setInt16(44 + i * 2, resampledSamples[i].clamp(-32768, 32767), Endian.little);
  }

  // 轉換為 Uint8List
  final outputBytes = output.buffer.asUint8List();

  // 備份原始文件
  final backupPath = inputPath.replaceAll('.wav', '_backup.wav');
  if (!await File(backupPath).exists()) {
    await File(inputPath).copy(backupPath);
    print('   💾 原始檔案備份至: $backupPath');
  }

  // 覆寫原文件
  await File(inputPath).writeAsBytes(outputBytes);
  
  final newSize = (outputBytes.length / 1024 / 1024).toStringAsFixed(2);
  print('   ✅ 轉換完成! (新格式: 1 聲道, 44100 Hz, ${newSize} MB)');
}

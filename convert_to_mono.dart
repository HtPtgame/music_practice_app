/// WAV 立體聲轉單聲道工具
/// 
/// 將雙聲道 WAV 轉換為單聲道,混音方式為平均左右聲道
library;

import 'dart:io';
import 'dart:typed_data';

void main() async {
  // 檔案路徑
  final desktopPath = Platform.environment['USERPROFILE']! + r'\Desktop';
  final inputPath = '$desktopPath\\名偵探柯南 Detective Conan OP.wav';
  final outputPath = '$desktopPath\\名偵探柯南 Detective Conan OP_mono.wav';

  print('\n🔧 WAV 聲道轉換工具');
  print('═' * 70);
  print('輸入: $inputPath');
  print('輸出: $outputPath\n');

  // 檢查輸入檔案
  final inputFile = File(inputPath);
  if (!await inputFile.exists()) {
    print('❌ 錯誤: 找不到輸入檔案!');
    return;
  }

  // 讀取檔案
  print('📂 讀取 WAV 檔案...');
  final bytes = await inputFile.readAsBytes();
  final data = ByteData.sublistView(Uint8List.fromList(bytes));

  // 解析 WAV 頭
  final channels = data.getInt16(22, Endian.little);
  final sampleRate = data.getInt32(24, Endian.little);
  final bitsPerSample = data.getInt16(34, Endian.little);

  print('\n📊 原始格式:');
  print('  聲道數: $channels');
  print('  取樣率: $sampleRate Hz');
  print('  位元深度: $bitsPerSample bits\n');

  if (channels == 1) {
    print('✅ 已經是單聲道,無需轉換!');
    return;
  }

  if (bitsPerSample != 16) {
    print('❌ 錯誤: 目前僅支援 16-bit PCM');
    return;
  }

  print('🔄 開始轉換 (立體聲 → 單聲道)...\n');

  // 計算大小
  final dataSize = bytes.length - 44;
  final samplesPerChannel = dataSize ~/ (channels * 2); // 2 bytes per sample (16-bit)
  final newDataSize = samplesPerChannel * 2;

  // 創建新 WAV 頭 (單聲道)
  final newHeader = Uint8List(44);
  newHeader.setAll(0, bytes.sublist(0, 44));
  
  final headerData = ByteData.sublistView(newHeader);
  headerData.setInt16(22, 1, Endian.little); // 聲道數 = 1
  
  final byteRate = sampleRate * 1 * 2; // sampleRate * channels * bytesPerSample
  headerData.setInt32(28, byteRate, Endian.little); // ByteRate
  
  headerData.setInt16(32, 2, Endian.little); // BlockAlign = 1 * 2
  headerData.setInt32(40, newDataSize, Endian.little); // Subchunk2Size
  headerData.setInt32(4, newDataSize + 36, Endian.little); // ChunkSize

  // 混音: 將雙聲道平均為單聲道
  final newData = Uint8List(newDataSize);
  final newDataView = ByteData.sublistView(newData);

  print('  處理樣本: 0 / $samplesPerChannel (0%)');
  
  for (var i = 0; i < samplesPerChannel; i++) {
    // 顯示進度
    if (i % 50000 == 0 || i == samplesPerChannel - 1) {
      final progress = ((i / samplesPerChannel) * 100).toStringAsFixed(1);
      stdout.write('\r  處理樣本: $i / $samplesPerChannel ($progress%)');
    }

    // 讀取左右聲道
    final srcOffset = 44 + (i * channels * 2);
    final left = data.getInt16(srcOffset, Endian.little);
    final right = data.getInt16(srcOffset + 2, Endian.little);

    // 平均混音
    final mono = ((left + right) / 2).round();

    // 寫入單聲道樣本
    final dstOffset = i * 2;
    newDataView.setInt16(dstOffset, mono, Endian.little);
  }

  print('\n');

  // 寫入輸出檔案
  print('💾 寫入檔案...');
  final output = Uint8List(44 + newDataSize);
  output.setAll(0, newHeader);
  output.setAll(44, newData);

  await File(outputPath).writeAsBytes(output);

  // 顯示結果
  final outputSize = await File(outputPath).length();
  print('\n✅ 轉換完成!');
  print('═' * 70);
  print('輸出檔案: $outputPath');
  print('檔案大小: ${(outputSize / 1024 / 1024).toStringAsFixed(2)} MB');
  print('聲道數: 1 (單聲道)\n');
}

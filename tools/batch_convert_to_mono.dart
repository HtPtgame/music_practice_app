/// 批量 WAV 立體聲轉單聲道工具
/// 
/// 掃描 test_voice 資料夾,將所有雙聲道 WAV 轉換為單聲道 (覆蓋原檔)
/// 混音方式: 平均左右聲道
library;

import 'dart:io';
import 'dart:typed_data';

void main() async {
  print('\n🔧 批量 WAV 聲道轉換工具');
  print('═' * 80);
  
  // 測試音訊資料夾路徑
  final testVoiceDir = Directory(r'D:\Flutter_project\music_practice_app\assets\test_voice');
  
  if (!await testVoiceDir.exists()) {
    print('❌ 錯誤: test_voice 資料夾不存在!');
    print('   路徑: ${testVoiceDir.path}');
    return;
  }

  print('📂 掃描資料夾: ${testVoiceDir.path}\n');

  // 找出所有 WAV 檔案
  final wavFiles = await testVoiceDir
      .list()
      .where((entity) => entity is File && entity.path.toLowerCase().endsWith('.wav'))
      .cast<File>()
      .toList();

  print('找到 ${wavFiles.length} 個 WAV 檔案\n');

  if (wavFiles.isEmpty) {
    print('⚠️ 沒有找到任何 WAV 檔案');
    return;
  }

  // 統計
  int totalFiles = wavFiles.length;
  int monoCount = 0;
  int stereoCount = 0;
  int convertedCount = 0;
  int errorCount = 0;

  // 逐個處理
  for (var i = 0; i < wavFiles.length; i++) {
    final file = wavFiles[i];
    final fileName = file.path.split('\\').last;
    
    print('─' * 80);
    print('[${ i + 1 }/$totalFiles] 處理: $fileName');
    print('─' * 80);

    try {
      // 讀取檔案
      final bytes = await file.readAsBytes();
      final data = ByteData.sublistView(Uint8List.fromList(bytes));

      // 檢查 WAV 格式
      final riff = String.fromCharCodes(bytes.sublist(0, 4));
      final wave = String.fromCharCodes(bytes.sublist(8, 12));
      
      if (riff != 'RIFF' || wave != 'WAVE') {
        print('⚠️ 跳過: 不是有效的 WAV 檔案');
        errorCount++;
        continue;
      }

      // 解析 WAV 頭
      final channels = data.getInt16(22, Endian.little);
      final sampleRate = data.getInt32(24, Endian.little);
      final bitsPerSample = data.getInt16(34, Endian.little);

      print('📊 格式資訊:');
      print('   聲道數: $channels');
      print('   取樣率: $sampleRate Hz');
      print('   位元深度: $bitsPerSample bits');

      // 判斷是否需要轉換
      if (channels == 1) {
        print('✅ 已經是單聲道,跳過');
        monoCount++;
        continue;
      }

      stereoCount++;

      if (bitsPerSample != 16) {
        print('❌ 錯誤: 目前僅支援 16-bit PCM');
        errorCount++;
        continue;
      }

      // 開始轉換
      print('🔄 轉換中 (立體聲 → 單聲道)...');

      // 計算大小
      final dataSize = bytes.length - 44;
      final samplesPerChannel = dataSize ~/ (channels * 2);
      final newDataSize = samplesPerChannel * 2;

      // 創建新 WAV 頭 (單聲道)
      final newHeader = Uint8List(44);
      newHeader.setAll(0, bytes.sublist(0, 44));
      
      final headerData = ByteData.sublistView(newHeader);
      headerData.setInt16(22, 1, Endian.little); // 聲道數 = 1
      
      final byteRate = sampleRate * 1 * 2;
      headerData.setInt32(28, byteRate, Endian.little); // ByteRate
      
      headerData.setInt16(32, 2, Endian.little); // BlockAlign = 1 * 2
      headerData.setInt32(40, newDataSize, Endian.little); // Subchunk2Size
      headerData.setInt32(4, newDataSize + 36, Endian.little); // ChunkSize

      // 混音: 將雙聲道平均為單聲道
      final newData = Uint8List(newDataSize);
      final newDataView = ByteData.sublistView(newData);

      for (var j = 0; j < samplesPerChannel; j++) {
        // 讀取左右聲道
        final srcOffset = 44 + (j * channels * 2);
        final left = data.getInt16(srcOffset, Endian.little);
        final right = data.getInt16(srcOffset + 2, Endian.little);

        // 平均混音
        final mono = ((left + right) / 2).round();

        // 寫入單聲道樣本
        final dstOffset = j * 2;
        newDataView.setInt16(dstOffset, mono, Endian.little);
      }

      // 組合完整檔案
      final output = Uint8List(44 + newDataSize);
      output.setAll(0, newHeader);
      output.setAll(44, newData);

      // 備份原檔案
      final backupPath = file.path + '.stereo_backup';
      await file.copy(backupPath);
      print('💾 已備份原檔: ${backupPath.split('\\').last}');

      // 覆蓋原檔案
      await file.writeAsBytes(output);
      
      final outputSize = await file.length();
      print('✅ 轉換完成! (${(outputSize / 1024 / 1024).toStringAsFixed(2)} MB)');
      
      convertedCount++;

    } catch (e, stackTrace) {
      print('❌ 處理失敗: $e');
      print('堆疊追蹤: $stackTrace');
      errorCount++;
    }

    print('');
  }

  // 總結
  print('═' * 80);
  print('📊 轉換總結');
  print('═' * 80);
  print('總檔案數: $totalFiles');
  print('✅ 原本就是單聲道: $monoCount');
  print('🔄 立體聲 (需轉換): $stereoCount');
  print('✅ 成功轉換: $convertedCount');
  print('❌ 轉換失敗: $errorCount');
  print('');

  if (convertedCount > 0) {
    print('🎉 已將 $convertedCount 個檔案轉換為單聲道!');
    print('💡 原檔案已備份為 .stereo_backup 檔案');
    print('   如需還原,請手動刪除單聲道版本並重新命名備份檔');
  } else if (monoCount == totalFiles) {
    print('✅ 所有檔案都已是單聲道,無需轉換!');
  } else {
    print('⚠️ 沒有成功轉換任何檔案');
  }

  print('');
}

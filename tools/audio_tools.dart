/// 音訊處理工具集
/// 整合音訊格式轉換、修復、批次處理等功能
///
/// 使用方式:
/// ```bash
/// # 單檔轉換為單聲道
/// dart tools/audio_tools.dart convert <輸入檔案> <輸出檔案>
///
/// # 批次轉換目錄中的所有 WAV 檔案
/// dart tools/audio_tools.dart batch <目錄路徑>
///
/// # 修復音訊格式（轉為 16-bit PCM, 44100Hz, 單聲道）
/// dart tools/audio_tools.dart fix <檔案路徑>
///
/// # 分析音訊檔案資訊
/// dart tools/audio_tools.dart analyze <檔案路徑>
/// ```

import 'dart:io';
import 'dart:typed_data';

void main(List<String> args) {
  if (args.isEmpty) {
    printUsage();
    exit(1);
  }

  final command = args[0].toLowerCase();

  try {
    switch (command) {
      case 'convert':
        if (args.length < 3) {
          print('❌ 錯誤: convert 指令需要輸入和輸出檔案路徑');
          print('用法: dart tools/audio_tools.dart convert <輸入檔案> <輸出檔案>');
          exit(1);
        }
        convertToMono(args[1], args[2]);
        break;

      case 'batch':
        if (args.length < 2) {
          print('❌ 錯誤: batch 指令需要目錄路徑');
          print('用法: dart tools/audio_tools.dart batch <目錄路徑>');
          exit(1);
        }
        batchConvertToMono(args[1]);
        break;

      case 'fix':
        if (args.length < 2) {
          print('❌ 錯誤: fix 指令需要檔案路徑');
          print('用法: dart tools/audio_tools.dart fix <檔案路徑>');
          exit(1);
        }
        fixAudioFormat(args[1]);
        break;

      case 'analyze':
        if (args.length < 2) {
          print('❌ 錯誤: analyze 指令需要檔案路徑');
          print('用法: dart tools/audio_tools.dart analyze <檔案路徑>');
          exit(1);
        }
        analyzeAudio(args[1]);
        break;

      default:
        print('❌ 未知指令: $command');
        printUsage();
        exit(1);
    }
  } catch (e) {
    print('❌ 錯誤: $e');
    exit(1);
  }
}

void printUsage() {
  print('''
🎵 音訊處理工具集

使用方式:
  dart tools/audio_tools.dart <指令> [參數]

指令:
  convert <輸入檔案> <輸出檔案>  - 將立體聲轉為單聲道
  batch <目錄路徑>                - 批次轉換目錄中的所有 WAV 檔案
  fix <檔案路徑>                  - 修復音訊格式（16-bit PCM, 44100Hz, 單聲道）
  analyze <檔案路徑>              - 分析音訊檔案資訊

範例:
  dart tools/audio_tools.dart convert input.wav output.wav
  dart tools/audio_tools.dart batch assets/test_voice/
  dart tools/audio_tools.dart fix test.wav
  dart tools/audio_tools.dart analyze test.wav
''');
}

// ============================================================================
// 功能 1: 單檔轉換為單聲道
// ============================================================================

void convertToMono(String inputPath, String outputPath) {
  print('🔄 轉換音檔為單聲道...');
  print('   輸入: $inputPath');
  print('   輸出: $outputPath');

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    throw Exception('輸入檔案不存在: $inputPath');
  }

  final bytes = inputFile.readAsBytesSync();

  // 解析 WAV 標頭
  if (bytes.length < 44) {
    throw Exception('檔案太小，不是有效的 WAV 檔案');
  }

  // 檢查 RIFF 標頭
  final riff = String.fromCharCodes(bytes.sublist(0, 4));
  if (riff != 'RIFF') {
    throw Exception('不是有效的 WAV 檔案（缺少 RIFF 標頭）');
  }

  // 檢查 WAVE 格式
  final wave = String.fromCharCodes(bytes.sublist(8, 12));
  if (wave != 'WAVE') {
    throw Exception('不是有效的 WAV 檔案（缺少 WAVE 標識）');
  }

  // 讀取格式資訊
  final numChannels = bytes[22] | (bytes[23] << 8);
  final sampleRate =
      bytes[24] | (bytes[25] << 8) | (bytes[26] << 16) | (bytes[27] << 24);
  final bitsPerSample = bytes[34] | (bytes[35] << 8);

  print('   聲道數: $numChannels');
  print('   採樣率: $sampleRate Hz');
  print('   位深度: $bitsPerSample bit');

  if (numChannels == 1) {
    print('⏭️  檔案已是單聲道，直接複製');
    File(outputPath).writeAsBytesSync(bytes);
    print('✅ 完成');
    return;
  }

  if (numChannels != 2) {
    throw Exception('不支援的聲道數: $numChannels（僅支援 1 或 2 聲道）');
  }

  // 找到 data chunk
  int dataOffset = 12;
  while (dataOffset < bytes.length - 8) {
    final chunkId =
        String.fromCharCodes(bytes.sublist(dataOffset, dataOffset + 4));
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
    throw Exception('找不到音訊數據（data chunk）');
  }

  // 轉換音訊數據（立體聲 → 單聲道：平均左右聲道）
  final audioData = bytes.sublist(dataOffset);
  final bytesPerSample = bitsPerSample ~/ 8;
  final frameSize = bytesPerSample * numChannels;
  final numFrames = audioData.length ~/ frameSize;

  final monoData = Uint8List(numFrames * bytesPerSample);

  for (int i = 0; i < numFrames; i++) {
    final leftOffset = i * frameSize;
    final rightOffset = leftOffset + bytesPerSample;

    if (bitsPerSample == 16) {
      // 16-bit signed PCM
      final left = (audioData[leftOffset] | (audioData[leftOffset + 1] << 8))
          .toSigned(16);
      final right = (audioData[rightOffset] | (audioData[rightOffset + 1] << 8))
          .toSigned(16);
      final mono = ((left + right) / 2).round();

      monoData[i * 2] = mono & 0xFF;
      monoData[i * 2 + 1] = (mono >> 8) & 0xFF;
    } else if (bitsPerSample == 8) {
      // 8-bit unsigned PCM
      final left = audioData[leftOffset];
      final right = audioData[rightOffset];
      monoData[i] = ((left + right) / 2).round();
    } else {
      throw Exception('不支援的位深度: $bitsPerSample（僅支援 8 或 16 bit）');
    }
  }

  // 建立新的 WAV 標頭（單聲道）
  final newWav = _createWavHeader(
    numChannels: 1,
    sampleRate: sampleRate,
    bitsPerSample: bitsPerSample,
    audioData: monoData,
  );

  File(outputPath).writeAsBytesSync(newWav);
  print('✅ 轉換完成！');
}

// ============================================================================
// 功能 2: 批次轉換
// ============================================================================

void batchConvertToMono(String directoryPath) {
  print('🔍 掃描目錄: $directoryPath');

  final directory = Directory(directoryPath);
  if (!directory.existsSync()) {
    throw Exception('目錄不存在: $directoryPath');
  }

  final wavFiles = directory
      .listSync()
      .where((f) => f.path.toLowerCase().endsWith('.wav'))
      .toList();

  if (wavFiles.isEmpty) {
    print('⚠️  目錄中沒有 WAV 檔案');
    return;
  }

  print('📊 找到 ${wavFiles.length} 個 WAV 檔案\n');

  int converted = 0;
  int skipped = 0;
  int errors = 0;

  for (final file in wavFiles) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    print('處理: $fileName');

    try {
      final bytes = File(file.path).readAsBytesSync();
      final numChannels = bytes[22] | (bytes[23] << 8);

      if (numChannels == 1) {
        print('  ⏭️  已是單聲道，跳過');
        skipped++;
      } else {
        convertToMono(file.path, file.path);
        converted++;
      }
    } catch (e) {
      print('  ❌ 錯誤: $e');
      errors++;
    }
    print('');
  }

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📊 批次處理完成');
  print('   轉換: $converted 個檔案');
  print('   跳過: $skipped 個檔案');
  if (errors > 0) {
    print('   錯誤: $errors 個檔案');
  }
}

// ============================================================================
// 功能 3: 修復音訊格式
// ============================================================================

void fixAudioFormat(String filePath) {
  print('🔧 修復音訊格式: $filePath');

  final file = File(filePath);
  if (!file.existsSync()) {
    throw Exception('檔案不存在: $filePath');
  }

  final bytes = file.readAsBytesSync();

  // 解析當前格式
  final numChannels = bytes[22] | (bytes[23] << 8);
  final sampleRate =
      bytes[24] | (bytes[25] << 8) | (bytes[26] << 16) | (bytes[27] << 24);
  final bitsPerSample = bytes[34] | (bytes[35] << 8);

  print('   當前格式:');
  print('     聲道數: $numChannels');
  print('     採樣率: $sampleRate Hz');
  print('     位深度: $bitsPerSample bit');

  bool needsFix = false;
  final issues = <String>[];

  if (numChannels != 1) {
    issues.add('聲道數不正確（應為 1，實際 $numChannels）');
    needsFix = true;
  }

  if (sampleRate != 44100) {
    issues.add('採樣率不正確（應為 44100Hz，實際 ${sampleRate}Hz）');
    needsFix = true;
  }

  if (bitsPerSample != 16) {
    issues.add('位深度不正確（應為 16-bit，實際 ${bitsPerSample}-bit）');
    needsFix = true;
  }

  if (!needsFix) {
    print('✅ 檔案格式正確，無需修復');
    return;
  }

  print('\n⚠️  發現問題:');
  for (final issue in issues) {
    print('     - $issue');
  }

  print('\n🔄 開始修復...');

  // 備份原檔案
  final backupPath = '${filePath}.backup';
  file.copySync(backupPath);
  print('   ✓ 已建立備份: $backupPath');

  // 先轉換為單聲道（如果需要）
  if (numChannels != 1) {
    convertToMono(filePath, filePath);
    print('   ✓ 已轉換為單聲道');
  }

  // TODO: 採樣率和位深度轉換需要更複雜的 DSP 處理
  // 這裡只示範基本框架，實際專案可使用 FFmpeg

  if (sampleRate != 44100 || bitsPerSample != 16) {
    print('   ⚠️  採樣率或位深度轉換需要 FFmpeg，請手動處理');
    print(
        '   建議指令: ffmpeg -i "$filePath" -ar 44100 -sample_fmt s16 -ac 1 output.wav');
  } else {
    print('✅ 修復完成！');
  }
}

// ============================================================================
// 功能 4: 分析音訊資訊
// ============================================================================

void analyzeAudio(String filePath) {
  print('🔍 分析音訊檔案: $filePath\n');

  final file = File(filePath);
  if (!file.existsSync()) {
    throw Exception('檔案不存在: $filePath');
  }

  final bytes = file.readAsBytesSync();
  final fileSize = bytes.length;

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📁 檔案資訊');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('檔案大小: ${(fileSize / 1024).toStringAsFixed(2)} KB');

  if (bytes.length < 44) {
    print('❌ 檔案太小，不是有效的 WAV 檔案');
    return;
  }

  // 解析標頭
  final riff = String.fromCharCodes(bytes.sublist(0, 4));
  final wave = String.fromCharCodes(bytes.sublist(8, 12));

  if (riff != 'RIFF' || wave != 'WAVE') {
    print('❌ 不是有效的 WAV 檔案');
    return;
  }

  final numChannels = bytes[22] | (bytes[23] << 8);
  final sampleRate =
      bytes[24] | (bytes[25] << 8) | (bytes[26] << 16) | (bytes[27] << 24);
  final byteRate =
      bytes[28] | (bytes[29] << 8) | (bytes[30] << 16) | (bytes[31] << 24);
  final bitsPerSample = bytes[34] | (bytes[35] << 8);

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🎵 格式資訊');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print(
      '聲道數: $numChannels ${numChannels == 1 ? '(單聲道)' : numChannels == 2 ? '(立體聲)' : ''}');
  print('採樣率: $sampleRate Hz');
  print('位深度: $bitsPerSample bit');
  print('位元率: ${(byteRate * 8 / 1000).toStringAsFixed(0)} kbps');

  // 計算時長
  final dataSize = fileSize - 44;
  final bytesPerSample = bitsPerSample ~/ 8;
  final numSamples = dataSize ~/ (numChannels * bytesPerSample);
  final duration = numSamples / sampleRate;

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('⏱️  時長資訊');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print(
      '總樣本數: ${numSamples.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}');
  print('時長: ${duration.toStringAsFixed(2)} 秒');

  // 格式檢查
  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✅ 格式檢查');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  final checks = [
    ('單聲道', numChannels == 1),
    ('44100Hz 採樣率', sampleRate == 44100),
    ('16-bit 位深度', bitsPerSample == 16),
  ];

  for (final check in checks) {
    final status = check.$2 ? '✅' : '❌';
    print('$status ${check.$1}');
  }

  final allPassed = checks.every((c) => c.$2);
  if (allPassed) {
    print('\n🎉 檔案格式完全符合要求！');
  } else {
    print('\n⚠️  建議使用 fix 指令修復格式問題');
  }

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

// ============================================================================
// 輔助函數
// ============================================================================

Uint8List _createWavHeader({
  required int numChannels,
  required int sampleRate,
  required int bitsPerSample,
  required Uint8List audioData,
}) {
  final dataSize = audioData.length;
  final fileSize = 36 + dataSize;
  final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  final blockAlign = numChannels * (bitsPerSample ~/ 8);

  final header = Uint8List(44);

  // RIFF header
  header.setAll(0, 'RIFF'.codeUnits);
  _writeInt32(header, 4, fileSize);
  header.setAll(8, 'WAVE'.codeUnits);

  // fmt chunk
  header.setAll(12, 'fmt '.codeUnits);
  _writeInt32(header, 16, 16); // fmt chunk size
  _writeInt16(header, 20, 1); // PCM format
  _writeInt16(header, 22, numChannels);
  _writeInt32(header, 24, sampleRate);
  _writeInt32(header, 28, byteRate);
  _writeInt16(header, 32, blockAlign);
  _writeInt16(header, 34, bitsPerSample);

  // data chunk
  header.setAll(36, 'data'.codeUnits);
  _writeInt32(header, 40, dataSize);

  return Uint8List.fromList([...header, ...audioData]);
}

void _writeInt16(Uint8List buffer, int offset, int value) {
  buffer[offset] = value & 0xFF;
  buffer[offset + 1] = (value >> 8) & 0xFF;
}

void _writeInt32(Uint8List buffer, int offset, int value) {
  buffer[offset] = value & 0xFF;
  buffer[offset + 1] = (value >> 8) & 0xFF;
  buffer[offset + 2] = (value >> 16) & 0xFF;
  buffer[offset + 3] = (value >> 24) & 0xFF;
}

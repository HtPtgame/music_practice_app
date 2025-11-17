import 'dart:io';
import 'package:music_practice_app/services/audio_analysis/audio_analyzer_service_impl.dart';
import 'package:music_practice_app/services/audio_analysis/note_verification_service_impl.dart';
import 'package:music_practice_app/services/audio_analysis/models/note_event.dart';

/// WAV 音訊分析測試腳本
///
/// 使用方法:
/// 1. 使用 App 錄製一段 WAV 音訊,或準備任何 44100Hz PCM16 單聲道 WAV
/// 2. 修改下面的文件路徑
/// 3. 運行: flutter run -d windows lib/services/audio_analysis/test_wav_analyzer.dart
void main() async {
  print('🎤 WAV 音訊分析測試工具');
  print('═══════════════════════════════════════');

  // ⚠️ 修改為您的 WAV 文件路徑
  const wavPath = 'test_recording.wav'; // 或使用絕對路徑

  final file = File(wavPath);
  if (!await file.exists()) {
    print('❌ 錯誤: 找不到文件 "$wavPath"');
    print('');
    print('💡 請執行以下步驟:');
    print('1. 使用 App 錄製一段音訊 (會存為 WAV 格式)');
    print('2. 找到錄音文件路徑 (通常在 App 數據目錄)');
    print(
        '3. 修改 lib/services/audio_analysis/test_wav_analyzer.dart 中的 wavPath');
    print('4. 重新運行此腳本');
    print('');
    print('📝 或者可以在 practice_page.dart 錄音完成後查看路徑:');
    print('   debugPrint("錄音路徑: \$_audioPath");');
    return;
  }

  print('📂 文件: $wavPath');
  print('📊 大小: ${(await file.length() / 1024 / 1024).toStringAsFixed(2)} MB');
  print('');

  try {
    final analyzer = AudioAnalyzerServiceImpl();

    print('⏳ 開始分析音訊...');
    final stopwatch = Stopwatch()..start();

    final spectrogram = await analyzer.analyze(wavPath);

    stopwatch.stop();
    print('');
    print('✅ 分析完成! (耗時: ${stopwatch.elapsedMilliseconds}ms)');
    print('═══════════════════════════════════════');
    print('📊 頻譜圖資訊:');
    print('   時間幀數: ${spectrogram.timeFrames}');
    print('   頻率bins: ${spectrogram.freqBins}');
    print(
        '   頻率解析度: ${spectrogram.frequencyResolution.toStringAsFixed(2)} Hz/bin');
    print(
        '   時間解析度: ${(spectrogram.timeResolution * 1000).toStringAsFixed(2)} ms/幀');
    print(
        '   總時長: ${(spectrogram.timeFrames * spectrogram.timeResolution).toStringAsFixed(2)} 秒');

    print('');
    print('🎵 測試音符檢測:');
    print('───────────────────────────────────────');

    // 測試幾個常見音符
    final testNotes = [
      {'midi': 60, 'name': 'C4 (Middle C)'},
      {'midi': 69, 'name': 'A4 (440Hz)'},
      {'midi': 64, 'name': 'E4'},
      {'midi': 67, 'name': 'G4'},
      {'midi': 72, 'name': 'C5'},
    ];

    final verifier = NoteVerificationServiceImpl();

    // 在錄音中間位置測試
    final testTime = (spectrogram.timeFrames * spectrogram.timeResolution) / 2;

    print('測試時間點: ${testTime.toStringAsFixed(2)}秒');
    print('');

    for (final noteInfo in testNotes) {
      final midi = noteInfo['midi'] as int;
      final name = noteInfo['name'] as String;

      final detected = await verifier.verifyNote(midi, testTime, spectrogram);
      final icon = detected ? '✅' : '❌';

      // 計算該音符的頻率
      final note = NoteEvent(midiNote: midi, startTime: 0, endTime: 0);
      print('   $icon $name (${note.frequency.toStringAsFixed(2)} Hz)');
    }

    print('');
    print('💡 提示:');
    print('   - ✅ 表示在該時間點檢測到該音符');
    print('   - ❌ 表示未檢測到');
    print('   - 如果所有音符都是 ❌, 可能是:');
    print('     1. 錄音沒有樂器聲音 (只有靜音/噪音)');
    print('     2. 音量太小');
    print('     3. 需要調整檢測閾值');

    print('');
    print('🔍 頻譜能量分析 (前5個時間幀):');
    print('───────────────────────────────────────');

    for (int frame = 0; frame < 5 && frame < spectrogram.timeFrames; frame++) {
      final time = frame * spectrogram.timeResolution;
      final spectrum = spectrogram.data[frame];

      // 找出能量最強的頻率
      double maxEnergy = 0;
      int maxBin = 0;

      for (int bin = 0; bin < spectrum.length; bin++) {
        if (spectrum[bin] > maxEnergy) {
          maxEnergy = spectrum[bin];
          maxBin = bin;
        }
      }

      final peakFreq = maxBin * spectrogram.frequencyResolution;

      print(
          '   時間 ${time.toStringAsFixed(2)}s: 峰值頻率 ${peakFreq.toStringAsFixed(1)} Hz, '
          '能量 ${maxEnergy.toStringAsFixed(4)}');
    }

    print('');
    print('═══════════════════════════════════════');
    print('✅ 測試完成!');
  } catch (e) {
    print('');
    print('❌ 分析失敗: $e');
  }
}

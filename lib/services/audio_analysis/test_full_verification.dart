import 'dart:io';
import 'package:music_practice_app/services/audio_analysis/audio_analyzer_service_impl.dart';
import 'package:music_practice_app/services/audio_analysis/midi_parser_service.dart';
import 'package:music_practice_app/services/audio_analysis/note_verification_service_impl.dart';

/// 完整音符驗證測試 (MIDI + WAV)
///
/// 使用方法:
/// 1. 準備 MIDI 標準答案文件
/// 2. 錄製對應的演奏音訊 (WAV)
/// 3. 修改下面的文件路徑
/// 4. 運行: flutter run -d windows lib/services/audio_analysis/test_full_verification.dart
void main() async {
  print('🎯 完整音符驗證測試');
  print('═══════════════════════════════════════════════════════════');

  // ⚠️ 修改為您的文件路徑
  const midiPath = 'assets/測試.mid'; // MIDI 標準答案
  const wavPath = 'performance.wav'; // 演奏錄音

  // 檢查文件
  final midiFile = File(midiPath);
  final wavFile = File(wavPath);

  if (!await midiFile.exists()) {
    print('❌ 找不到 MIDI 文件: $midiPath');
    return;
  }

  if (!await wavFile.exists()) {
    print('❌ 找不到 WAV 文件: $wavPath');
    return;
  }

  print('📂 MIDI 標準答案: $midiPath');
  print('📂 演奏錄音: $wavPath');
  print('');

  try {
    // 步驟 1: 解析 MIDI
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('步驟 1/3: 解析 MIDI 標準答案');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final midiParser = MidiParserService();
    final timeline = await midiParser.parseFile(midiPath);

    print('✅ MIDI 解析完成');
    print('   音符數: ${timeline.events.length}');
    print('   時長: ${timeline.duration.toStringAsFixed(2)}秒');
    print('');

    // 步驟 2: 分析音訊
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('步驟 2/3: 分析錄音頻譜');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final analyzer = AudioAnalyzerServiceImpl();
    final stopwatch = Stopwatch()..start();

    final spectrogram = await analyzer.analyze(wavPath);

    stopwatch.stop();

    print('✅ 頻譜分析完成 (${stopwatch.elapsedMilliseconds}ms)');
    print('   時間幀數: ${spectrogram.timeFrames}');
    print('   頻率bins: ${spectrogram.freqBins}');
    print(
        '   錄音時長: ${(spectrogram.timeFrames * spectrogram.timeResolution).toStringAsFixed(2)}秒');
    print('');

    // 步驟 3: 驗證音符
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('步驟 3/3: 驗證音符');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final verifier = NoteVerificationServiceImpl();
    final results = await verifier.verifyAll(timeline, spectrogram);

    // 統計結果
    int detected = 0;
    int missed = 0;

    for (final verified in results.values) {
      if (verified) {
        detected++;
      } else {
        missed++;
      }
    }

    final accuracy = detected / timeline.events.length;

    print('');
    print('═══════════════════════════════════════════════════════════');
    print('📊 驗證結果統計');
    print('═══════════════════════════════════════════════════════════');
    print('');
    print('   總音符數: ${timeline.events.length}');
    print('   ✅ 檢測到: $detected');
    print('   ❌ 漏音: $missed');
    print('   📈 準確率: ${(accuracy * 100).toStringAsFixed(1)}%');
    print('');

    // 評級
    String grade;
    String comment;

    if (accuracy >= 0.9) {
      grade = 'A (優秀)';
      comment = '演奏非常準確!';
    } else if (accuracy >= 0.8) {
      grade = 'B (良好)';
      comment = '演奏良好,有少數漏音。';
    } else if (accuracy >= 0.7) {
      grade = 'C (及格)';
      comment = '基本掌握,但仍需練習。';
    } else if (accuracy >= 0.6) {
      grade = 'D (待加強)';
      comment = '有較多漏音,建議放慢速度練習。';
    } else {
      grade = 'F (不及格)';
      comment = '需要重新練習,注意每個音符的清晰度。';
    }

    print('   🏆 評級: $grade');
    print('   💬 評語: $comment');
    print('');

    // 詳細結果 (前20個音符)
    print('───────────────────────────────────────────────────────────');
    print('🎵 詳細結果 (前20個音符)');
    print('───────────────────────────────────────────────────────────');
    print('');

    int count = 0;
    for (final entry in results.entries) {
      if (count >= 20) break;

      final note = entry.key;
      final verified = entry.value;
      final icon = verified ? '✅' : '❌';
      final status = verified ? '檢測到' : '漏音';

      print(
          '   ${(count + 1).toString().padLeft(2)}. $icon ${note.noteName.padRight(4)} '
          '│ ${note.startTime.toStringAsFixed(2)}s '
          '│ $status');

      count++;
    }

    if (timeline.events.length > 20) {
      print('   ... 還有 ${timeline.events.length - 20} 個音符');
    }

    print('');

    // 漏音詳情
    if (missed > 0) {
      print('───────────────────────────────────────────────────────────');
      print('⚠️  漏音詳情 (前10個)');
      print('───────────────────────────────────────────────────────────');
      print('');

      int missedCount = 0;
      for (final entry in results.entries) {
        if (!entry.value && missedCount < 10) {
          final note = entry.key;
          print(
              '   ${(missedCount + 1).toString().padLeft(2)}. ${note.noteName.padRight(4)} '
              '在 ${note.startTime.toStringAsFixed(2)}秒 '
              '(${note.frequency.toStringAsFixed(1)} Hz)');
          missedCount++;
        }
      }

      print('');
      print('💡 漏音可能原因:');
      print('   1. 該音符彈奏時音量太小');
      print('   2. 該音符持續時間太短');
      print('   3. 錄音環境噪音影響');
      print('   4. 可以嘗試調低檢測閾值 (當前: 0.3)');
      print('');
    }

    // 參數調整建議
    if (accuracy < 0.8) {
      print('───────────────────────────────────────────────────────────');
      print('🔧 參數調整建議');
      print('───────────────────────────────────────────────────────────');
      print('');
      print('如果準確率偏低,可以嘗試調整參數:');
      print('');
      print('1. 降低能量閾值 (在 note_verification_service_impl.dart):');
      print('   static const double energyThreshold = 0.3;  // 改為 0.2 或 0.25');
      print('');
      print('2. 調整諧波權重:');
      print('   static const List<double> harmonicWeights = [1.0, 0.5, 0.25];');
      print('   // 增加基頻權重: [1.2, 0.4, 0.2]');
      print('');
      print('3. 確認錄音質量:');
      print('   - 採樣率: 44100 Hz ✅');
      print('   - 格式: PCM16 單聲道 ✅');
      print('   - 音量: 建議適中,不要太小');
      print('');
    }

    print('═══════════════════════════════════════════════════════════');
    print('✅ 測試完成!');
    print('═══════════════════════════════════════════════════════════');
  } catch (e, stackTrace) {
    print('');
    print('❌ 測試失敗: $e');
    print('');
    print('錯誤堆疊:');
    print(stackTrace);
  }
}

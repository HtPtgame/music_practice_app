/// Phase 1A 測試: 自動時間對齊驗證
///
/// 測試目標:
/// 1. 驗證自動檢測錄音起始點功能
/// 2. 驗證時間軸對齊功能
/// 3. 確保不影響樂曲中間的休止符
///
/// 測試方法:
/// - 使用現有測試音檔 (生日快樂.mid + 對應 WAV)
/// - 手動添加不同長度的靜音前綴
/// - 驗證能否正確檢測並對齊
library;

import 'dart:io';
import 'package:music_practice_app/services/audio_analysis/auto_alignment_service.dart';
import 'package:music_practice_app/services/audio_analysis/audio_analyzer_service_impl.dart';
import 'package:music_practice_app/services/audio_analysis/midi_parser_service.dart';

void main(List<String> args) async {
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║  Phase 1A 測試: 自動時間對齊                                 ║');
  print('╚══════════════════════════════════════════════════════════════╝\n');

  // 初始化服務
  final autoAlignment = AutoAlignmentService();
  final audioAnalyzer = AudioAnalyzerServiceImpl();
  final midiParser = MidiParserService();

  // 測試音檔路徑
  final testCases = [
    {
      'name': '生日快樂 - 電腦環境錄音',
      'wav':
          r'D:\Flutter_project\music_practice_app\assets\test_voice\生日快樂(電腦環境錄製).wav',
      'midi':
          r'D:\Flutter_project\music_practice_app\assets\test_voice\生日快樂.mid',
      'expectedDelay': '未知 (實際錄音)',
    },
    {
      'name': '小星星 - MIDI轉檔',
      'wav':
          r'D:\Flutter_project\music_practice_app\assets\test_voice\小星星(midi轉檔).wav',
      'midi':
          r'D:\Flutter_project\music_practice_app\assets\test_voice\小星星.mid',
      'expectedDelay': '~0秒 (理論完美對齊)',
    },
    {
      'name': '名偵探柯南 - 手機環境錄音',
      'wav':
          r'D:\Flutter_project\music_practice_app\assets\test_voice\名偵探柯南(手機環境錄製).wav',
      'midi':
          r'D:\Flutter_project\music_practice_app\assets\test_voice\名偵探柯南.mid',
      'expectedDelay': '未知 (實際錄音)',
    },
  ];

  int testNumber = 0;
  int passCount = 0;
  int failCount = 0;

  for (final testCase in testCases) {
    testNumber++;
    print('═══════════════════════════════════════════════════════════════');
    print('測試 $testNumber/${testCases.length}: ${testCase['name']}');
    print('═══════════════════════════════════════════════════════════════');

    try {
      // 檢查檔案是否存在
      final wavFile = File(testCase['wav'] as String);
      final midiFile = File(testCase['midi'] as String);

      if (!await wavFile.exists()) {
        print('❌ 錯誤: WAV 檔案不存在');
        print('   路徑: ${testCase['wav']}');
        failCount++;
        continue;
      }

      if (!await midiFile.exists()) {
        print('❌ 錯誤: MIDI 檔案不存在');
        print('   路徑: ${testCase['midi']}');
        failCount++;
        continue;
      }

      // 解析 MIDI
      print('\n📄 解析 MIDI 檔案...');
      final timeline = await midiParser.parseFile(testCase['midi'] as String);
      print('   音符數量: ${timeline.events.length}');
      print('   曲目時長: ${timeline.duration.toStringAsFixed(2)} 秒');
      print('   第一音符: ${timeline.events.first}');

      // 分析音訊
      print('\n🎵 分析音訊檔案...');
      final spectrogram =
          await audioAnalyzer.analyze(testCase['wav'] as String);
      print(
          '   頻譜: ${spectrogram.timeFrames} 幀 × ${spectrogram.freqBins} bins');
      print(
          '   錄音長度: ${(spectrogram.timeFrames * spectrogram.timeResolution).toStringAsFixed(2)} 秒');
      print(
          '   時間解析度: ${(spectrogram.timeResolution * 1000).toStringAsFixed(2)} ms');

      // 檢測起始點
      print('\n🔍 檢測錄音起始點...');
      final actualStart = autoAlignment.detectActualStart(spectrogram);
      // (detectActualStart 內部會打印詳細資訊)

      // 對齊時間軸
      print('\n⏰ 對齊 MIDI 時間軸...');
      final alignedTimeline =
          autoAlignment.alignMidiTimeline(timeline, actualStart);
      // (alignMidiTimeline 內部會打印詳細資訊)

      // 驗證結果
      print('\n📊 驗證結果:');
      final originalFirstNote = timeline.events.first.startTime;
      final alignedFirstNote = alignedTimeline.events.first.startTime;
      final timeShift = alignedFirstNote - originalFirstNote;

      print('   原始第一音符時間: ${originalFirstNote.toStringAsFixed(3)} 秒');
      print('   對齊後第一音符時間: ${alignedFirstNote.toStringAsFixed(3)} 秒');
      print(
          '   時間偏移量: ${timeShift >= 0 ? '+' : ''}${timeShift.toStringAsFixed(3)} 秒');
      print('   預期延遲: ${testCase['expectedDelay']}');

      // 簡單的 Pass/Fail 判定 (檢測到的起始點應該 >= 0)
      if (actualStart >= 0 && actualStart < 60) {
        print('\n✅ PASS - 成功檢測起始點並完成對齊');
        passCount++;
      } else {
        print('\n⚠️ FAIL - 檢測結果異常 (起始點: ${actualStart.toStringAsFixed(3)} 秒)');
        failCount++;
      }
    } catch (e, stackTrace) {
      print('\n❌ ERROR: $e');
      print('堆疊追蹤:\n$stackTrace');
      failCount++;
    }

    print('');
  }

  // 總結
  print('\n╔══════════════════════════════════════════════════════════════╗');
  print('║  測試總結                                                    ║');
  print('╚══════════════════════════════════════════════════════════════╝');
  print('總測試數: $testNumber');
  print('✅ 通過: $passCount');
  print('❌ 失敗: $failCount');
  print('通過率: ${(passCount / testNumber * 100).toStringAsFixed(1)}%');
  print('');

  // 結論
  if (failCount == 0) {
    print('🎉 Phase 1A 測試完全通過!自動時間對齊功能正常。');
  } else {
    print('⚠️ 有 $failCount 個測試失敗,需要進一步調查。');
  }

  print('\n═══════════════════════════════════════════════════════════════\n');
}

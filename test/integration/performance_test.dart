// integration/performance_test.dart
// Round 10 動態參數系統 - 整合測試
// 整合自：test_round10_full.dart, test_comprehensive.dart, test_round10_comprehensive.dart

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_practice_app/services/audio_analysis/performance_analyzer.dart';

/// 測試配置
class TestConfig {
  final String name;
  final String midiPath;
  final String audioPath;
  final int noteCount;
  final double duration;
  final String description;

  const TestConfig({
    required this.name,
    required this.midiPath,
    required this.audioPath,
    required this.noteCount,
    required this.duration,
    required this.description,
  });
}

/// Round 11 測試配置（四輪測試）- 使用實際音檔路徑
final List<TestConfig> round10Tests = [
  // 第一輪：生日快樂（簡單基準）
  const TestConfig(
    name: '生日快樂',
    midiPath: 'assets/test_voice/生日快樂.mid',
    audioPath: 'assets/test_voice',
    noteCount: 25,
    duration: 17.0,
    description: '基準測試 - 簡單旋律',
  ),

  // 第二輪：測試音檔（單音無伴奏）
  const TestConfig(
    name: '測試音檔',
    midiPath: 'assets/test_voice/測試音檔.mid',
    audioPath: 'assets/test_voice',
    noteCount: 94,
    duration: 34.0,
    description: '單音無伴奏測試',
  ),

  // 第三輪：小星星（有伴奏）
  const TestConfig(
    name: '小星星',
    midiPath: 'assets/test_voice/小星星.mid',
    audioPath: 'assets/test_voice',
    noteCount: 147,
    duration: 27.0,
    description: '伴奏測試 - 中等複雜度',
  ),

  // 第四輪：名偵探柯南（複雜長曲）
  const TestConfig(
    name: '名偵探柯南',
    midiPath: 'assets/test_voice/名偵探柯南.mid',
    audioPath: 'assets/test_voice',
    noteCount: 1431,
    duration: 164.0,
    description: '複雜測試 - 快速長曲',
  ),
];

/// 測試難度等級
enum DifficultyLevel {
  beginner('初學', 0.39, 200),
  intermediate('中等', 0.35, 150),
  expert('專業', 0.30, 100);

  final String label;
  final double energyThreshold;
  final int timingTolerance;

  const DifficultyLevel(this.label, this.energyThreshold, this.timingTolerance);
}

/// 測試類型
enum TestType {
  correctPerformance('正確演奏'),
  environmentalNoise('環境噪音'),
  wrongPitch('錯誤音高'),
  all('完整測試');

  final String label;
  const TestType(this.label);
}

void main() {
  // 檢查命令列參數，支援單輪執行
  final args = Platform.executableArguments;
  int? targetRound;

  if (args.isNotEmpty && args.last.length == 1) {
    targetRound = int.tryParse(args.last);
    if (targetRound != null && (targetRound < 1 || targetRound > 4)) {
      print('⚠️ 無效的輪次：$targetRound (有效範圍: 1-4)');
      targetRound = null;
    }
  }

  if (targetRound != null) {
    print('🎯 執行第 $targetRound 輪測試：${round10Tests[targetRound - 1].name}');
  } else {
    print('🎯 執行完整測試（4輪共32個案例）');
  }

  TestWidgetsFlutterBinding.ensureInitialized();

  group('Round 10 - 動態參數系統測試', () {
    late PerformanceAnalyzer analyzer;

    setUp(() {
      analyzer = PerformanceAnalyzer();
    });

    // 根據參數決定執行哪些輪次
    final roundsToRun =
        targetRound != null ? [targetRound - 1] : List.generate(4, (i) => i);

    for (final roundIndex in roundsToRun) {
      final config = round10Tests[roundIndex];
      final roundNum = roundIndex + 1;

      group('第 $roundNum 輪：${config.name}', () {
        print('\n${'=' * 60}');
        print('🎯 Round $roundNum: ${config.name}');
        print('   描述: ${config.description}');
        print('   音符數: ${config.noteCount}, 時長: ${config.duration}秒');
        print(
            '   參數: energyThreshold=${DifficultyLevel.beginner.energyThreshold}, tolerance=±${DifficultyLevel.beginner.timingTolerance}ms');
        print('=' * 60);

        // 測試音檔列表 (根據用戶需求)
        final testAudioFiles = [
          // 正確演奏音檔
          ('${config.name}(midi轉檔).wav', TestType.correctPerformance, 'MIDI轉檔'),
          ('${config.name}(手機環境錄製).wav', TestType.correctPerformance, '手機錄製'),
          ('${config.name}(電腦環境錄製).wav', TestType.correctPerformance, '電腦錄製'),
          // 其他曲目測試(錯誤音高)
          ...() {
            final wrongPitchFiles = <(String, TestType, String)>[];
            final allSongs = ['小星星', '名偵探柯南', '測試音檔', '生日快樂'];
            for (final song in allSongs) {
              if (song != config.name) {
                wrongPitchFiles
                    .add(('$song(手機環境錄製).wav', TestType.wrongPitch, song));
              }
            }
            return wrongPitchFiles;
          }(),
          // 環境噪音
          ('環境背景.wav', TestType.environmentalNoise, '環境背景1'),
          ('環境背景2.wav', TestType.environmentalNoise, '環境背景2'),
        ];

        var testNum = 1;
        for (final (fileName, testType, description) in testAudioFiles) {
          test(description, () async {
            final audioFile = '${config.audioPath}/$fileName';
            await _runTest(
              analyzer: analyzer,
              config: config,
              audioFile: audioFile,
              level: DifficultyLevel.beginner, // 使用初學參數作為基準
              testType: testType,
              testNumber: testNum++,
              roundNumber: roundNum,
            );
          });
        }

        print('\n✅ Round $roundNum 完成\n');
      });
    }
  });
}

/// 執行單個測試案例 (簡化輸出)
Future<void> _runTest({
  required PerformanceAnalyzer analyzer,
  required TestConfig config,
  required String audioFile,
  required DifficultyLevel level,
  required TestType testType,
  required int testNumber,
  required int roundNumber,
}) async {
  // 檢查檔案是否存在
  if (!File(audioFile).existsSync()) {
    print('⚠️ 跳過: ${audioFile.split('/').last} (不存在)');
    return;
  }

  try {
    // 執行分析 (靜默模式 - 不顯示過程)
    final result = await analyzer.analyze(
      audioFile,
      config.midiPath,
    );

    // 輸出結果
    _printTestResult(result, testType, config, testNumber, roundNumber);

    // 驗證結果（根據測試類型）
    _validateResult(result, testType);
  } catch (e) {
    print('❌ R$roundNumber-T$testNumber | 錯誤: $e');
    rethrow;
  }
}

/// 輸出測試結果 (簡化版)
void _printTestResult(
  result,
  TestType testType,
  TestConfig config,
  int testNumber,
  int roundNumber,
) {
  final matchedNotes = result.correctNotes;
  final totalNotes = result.totalNotes;
  final recall = result.recall;

  // 判定是否通過
  final passed = _isTestPassed(result, testType);
  final passLabel = passed ? '✅' : '❌';

  // 簡化輸出: 只顯示關鍵資訊
  print(
      '$passLabel R$roundNumber-T$testNumber | Recall: ${(recall * 100).toStringAsFixed(1)}% ($matchedNotes/$totalNotes) | ${testType.label}');
}

/// 判斷測試是否通過
bool _isTestPassed(result, TestType testType) {
  final recall = result.recall;

  switch (testType) {
    case TestType.correctPerformance:
      // 正確演奏：只檢查 recall ≥ 0.9 (不漏音即可,暫不處理多彈)
      return recall >= 0.9;
    case TestType.environmentalNoise:
      // 環境噪音：recall < 0.2 (不應該檢測到音符)
      return recall < 0.2;
    case TestType.wrongPitch:
      // 錯誤音高：recall < 0.5 (不應匹配太多)
      return recall < 0.5;
    default:
      return false;
  }
}

/// 驗證測試結果
void _validateResult(result, TestType testType) {
  final passed = _isTestPassed(result, testType);

  expect(passed, isTrue,
      reason: '測試未通過: ${testType.label}, '
          'recall=${result.recall.toStringAsFixed(3)}, '
          'precision=${result.precision.toStringAsFixed(3)}');
}

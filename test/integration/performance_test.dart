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

/// Round 10 測試配置（四輪測試）
final List<TestConfig> round10Tests = [
  // 第一輪：生日快樂（簡單基準）
  TestConfig(
    name: '生日快樂',
    midiPath: 'assets/test_voice/生日快樂.mid',
    audioPath: 'D:/Flutter_project/music_practice_app/test_recordings/生日快樂',
    noteCount: 25,
    duration: 17.0,
    description: '基準測試 - 簡單旋律',
  ),
  
  // 第二輪：測試音檔（單音無伴奏）
  TestConfig(
    name: '測試音檔',
    midiPath: 'assets/test_voice/測試音檔.mid',
    audioPath: 'D:/Flutter_project/music_practice_app/test_recordings/測試音檔',
    noteCount: 94,
    duration: 34.0,
    description: '單音無伴奏測試',
  ),
  
  // 第三輪：小星星（有伴奏）
  TestConfig(
    name: '小星星',
    midiPath: 'assets/test_voice/小星星.mid',
    audioPath: 'D:/Flutter_project/music_practice_app/test_recordings/小星星',
    noteCount: 147,
    duration: 27.0,
    description: '伴奏測試 - 中等複雜度',
  ),
  
  // 第四輪：名偵探柯南（複雜長曲）
  TestConfig(
    name: '名偵探柯南',
    midiPath: 'assets/test_voice/名偵探柯南.mid',
    audioPath: 'D:/Flutter_project/music_practice_app/test_recordings/名偵探柯南',
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
    final roundsToRun = targetRound != null 
        ? [targetRound - 1]
        : List.generate(4, (i) => i);

    for (final roundIndex in roundsToRun) {
      final config = round10Tests[roundIndex];
      final roundNum = roundIndex + 1;

      group('第 $roundNum 輪：${config.name}', () {
        print('\n' + '=' * 60);
        print('第 $roundNum 輪測試：${config.name}');
        print('描述：${config.description}');
        print('音符數：${config.noteCount}, 時長：${config.duration}秒');
        print('=' * 60);

        // 測試1-4: 正確演奏測試（三種難度）
        for (final level in DifficultyLevel.values) {
          test('${config.name} - 正確演奏 (${level.label})', () async {
            final audioFile = '${config.audioPath}/correct_performance_${level.label}.wav';
            await _runTest(
              analyzer: analyzer,
              config: config,
              audioFile: audioFile,
              level: level,
              testType: TestType.correctPerformance,
              testNumber: level.index + 1,
              roundNumber: roundNum,
            );
          });
        }

        // 測試5-8: 環境噪音測試
        final noiseTests = [
          ('background_noise_初學.wav', DifficultyLevel.beginner),
          ('background_noise_中等.wav', DifficultyLevel.intermediate),
          ('background_noise_專業.wav', DifficultyLevel.expert),
          ('silence_專業.wav', DifficultyLevel.expert),
        ];

        for (var i = 0; i < noiseTests.length; i++) {
          final (fileName, level) = noiseTests[i];
          test('${config.name} - 環境噪音 ${i + 1} (${level.label})', () async {
            final audioFile = '${config.audioPath}/$fileName';
            await _runTest(
              analyzer: analyzer,
              config: config,
              audioFile: audioFile,
              level: level,
              testType: TestType.environmentalNoise,
              testNumber: 5 + i,
              roundNumber: roundNum,
            );
          });
        }
      });
    }
  });
}

/// 執行單個測試案例
Future<void> _runTest({
  required PerformanceAnalyzer analyzer,
  required TestConfig config,
  required String audioFile,
  required DifficultyLevel level,
  required TestType testType,
  required int testNumber,
  required int roundNumber,
}) async {
  print('\n' + '-' * 60);
  print('🎵 測試 #$testNumber: ${config.name} - ${testType.label} (${level.label})');
  print('音檔：${audioFile.split('/').last}');
  print('參數：energyThreshold=${level.energyThreshold}, timingTolerance=±${level.timingTolerance}ms');

  // 檢查檔案是否存在
  if (!File(audioFile).existsSync()) {
    print('⚠️ 音檔不存在: $audioFile');
    print('測試跳過');
    return;
  }

  try {
    // 執行分析 (注意: analyze 方法參數順序是 wavPath, midiPath)
    final result = await analyzer.analyze(
      audioFile,
      config.midiPath,
    );

    // 輸出結果
    _printTestResult(result, testType, config, testNumber, roundNumber);

    // 驗證結果（根據測試類型）
    _validateResult(result, testType);
  } catch (e, stackTrace) {
    print('❌ 測試失敗: $e');
    print('堆疊追蹤: $stackTrace');
    rethrow;
  }
}

/// 輸出測試結果
void _printTestResult(
  result,
  TestType testType,
  TestConfig config,
  int testNumber,
  int roundNumber,
) {
  final score = result.overallScore;
  final matchedNotes = result.correctNotes;
  final totalNotes = result.totalNotes;
  final precision = result.precision;
  final recall = result.recall;
  final f1Score = result.f1Score;

  print('\n📊 測試結果：');
  print('   分數: ${score.toStringAsFixed(1)}');
  print('   匹配音符: $matchedNotes / $totalNotes');
  print('   Precision: ${(precision * 100).toStringAsFixed(1)}%');
  print('   Recall: ${(recall * 100).toStringAsFixed(1)}%');
  print('   F1 Score: ${(f1Score * 100).toStringAsFixed(1)}%');
  print('   評級: ${result.grade}');

  // 判定是否通過
  final passed = _isTestPassed(result, testType);
  final passLabel = passed ? '✅ PASS' : '❌ FAIL';
  print('\n$passLabel (Round $roundNumber, Test #$testNumber)');
  print('-' * 60);
}

/// 判斷測試是否通過
bool _isTestPassed(result, TestType testType) {
  final recall = result.recall;
  final precision = result.precision;

  switch (testType) {
    case TestType.correctPerformance:
      // 正確演奏：recall ≥ 0.8
      return recall >= 0.8;
    case TestType.environmentalNoise:
      // 環境噪音：precision ≥ 0.9 (低誤報)
      return precision >= 0.9;
    case TestType.wrongPitch:
      // 錯誤音高：recall < 0.5 (不應匹配)
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

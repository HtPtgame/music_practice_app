import 'dart:io';
import 'dart:async';
import 'lib/services/audio_analysis/performance_analyzer.dart';

/// 🎯 完整音檔檢測測試系統 (2025/10/25)
/// 
/// 測試範圍：
/// - 正確演奏檢測（應該高召回率）
/// - 錯誤音檔排除（應該低召回率）
/// - 環境噪音排除（應該極低召回率）
void main(List<String> args) async {
  final bool verbose = args.contains('--verbose') || args.contains('-v');
  final bool silentMode = !verbose;
  
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║     🎵 音樂練習檢測系統 - 完整檢測測試 (4輪×8音檔)         ║');
  print('╚══════════════════════════════════════════════════════════════╝');
  if (silentMode) {
    print('💡 使用 --verbose 參數可查看詳細調試信息\n');
  }

  // 測試配置 - 4 輪完整測試
  final testRounds = [
    {
      'name': '第一輪：生日快樂',
      'desc': '單音無伴奏 + 短時長',
      'midi': 'assets/test_voice/生日快樂.mid',
      'tests': [
        // 正確演奏（期望高召回率 ≥85%）
        {'wav': 'assets/test_voice/生日快樂(midi轉檔).wav', 'name': 'MIDI轉檔', 'type': 'correct', 'target': 95.0},
        {'wav': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '手機錄製', 'type': 'correct', 'target': 85.0},
        {'wav': 'assets/test_voice/生日快樂(電腦環境錄製).wav', 'name': '電腦錄製', 'type': 'correct', 'target': 85.0},
        
        // 錯誤音檔（期望低召回率 ≤30%）
        {'wav': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '錯誤:小星星', 'type': 'wrong', 'target': 30.0},
        {'wav': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '錯誤:柯南', 'type': 'wrong', 'target': 30.0},
        {'wav': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '錯誤:測試音檔', 'type': 'wrong', 'target': 30.0},
        
        // 環境噪音（期望極低召回率 ≤5%）
        {'wav': 'assets/test_voice/環境背景.wav', 'name': '噪音:背景1', 'type': 'noise', 'target': 5.0},
        {'wav': 'assets/test_voice/環境背景2.wav', 'name': '噪音:背景2', 'type': 'noise', 'target': 5.0},
      ],
    },
    {
      'name': '第二輪：測試音檔',
      'desc': '單音無伴奏 + 中時長',
      'midi': 'assets/test_voice/測試音檔.mid',
      'tests': [
        // 正確演奏
        {'wav': 'assets/test_voice/測試音檔(midi轉檔).wav', 'name': 'MIDI轉檔', 'type': 'correct', 'target': 95.0},
        {'wav': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '手機錄製', 'type': 'correct', 'target': 85.0},
        {'wav': 'assets/test_voice/測試音檔(電腦環境錄製).wav', 'name': '電腦錄製', 'type': 'correct', 'target': 85.0},
        
        // 錯誤音檔
        {'wav': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '錯誤:小星星', 'type': 'wrong', 'target': 30.0},
        {'wav': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '錯誤:柯南', 'type': 'wrong', 'target': 30.0},
        {'wav': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '錯誤:生日快樂', 'type': 'wrong', 'target': 30.0},
        
        // 環境噪音
        {'wav': 'assets/test_voice/環境背景.wav', 'name': '噪音:背景1', 'type': 'noise', 'target': 5.0},
        {'wav': 'assets/test_voice/環境背景2.wav', 'name': '噪音:背景2', 'type': 'noise', 'target': 5.0},
      ],
    },
    {
      'name': '第三輪：小星星',
      'desc': '有伴奏 + 中時長',
      'midi': 'assets/test_voice/小星星.mid',
      'tests': [
        // 正確演奏
        {'wav': 'assets/test_voice/小星星(midi轉檔).wav', 'name': 'MIDI轉檔', 'type': 'correct', 'target': 90.0},
        {'wav': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '手機錄製', 'type': 'correct', 'target': 80.0},
        {'wav': 'assets/test_voice/小星星(電腦環境錄製).wav', 'name': '電腦錄製', 'type': 'correct', 'target': 80.0},
        
        // 錯誤音檔
        {'wav': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '錯誤:測試音檔', 'type': 'wrong', 'target': 30.0},
        {'wav': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '錯誤:柯南', 'type': 'wrong', 'target': 30.0},
        {'wav': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '錯誤:生日快樂', 'type': 'wrong', 'target': 30.0},
        
        // 環境噪音
        {'wav': 'assets/test_voice/環境背景.wav', 'name': '噪音:背景1', 'type': 'noise', 'target': 5.0},
        {'wav': 'assets/test_voice/環境背景2.wav', 'name': '噪音:背景2', 'type': 'noise', 'target': 5.0},
      ],
    },
    {
      'name': '第四輪：名偵探柯南',
      'desc': '旋律複雜 + 曲速極快 + 長時長',
      'midi': 'assets/test_voice/名偵探柯南.mid',
      'tests': [
        // 正確演奏
        {'wav': 'assets/test_voice/名偵探柯南(midi轉檔).wav', 'name': 'MIDI轉檔', 'type': 'correct', 'target': 85.0},
        {'wav': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '手機錄製', 'type': 'correct', 'target': 75.0},
        {'wav': 'assets/test_voice/名偵探柯南(電腦環境錄製).wav', 'name': '電腦錄製', 'type': 'correct', 'target': 75.0},
        
        // 錯誤音檔
        {'wav': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '錯誤:小星星', 'type': 'wrong', 'target': 30.0},
        {'wav': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '錯誤:測試音檔', 'type': 'wrong', 'target': 30.0},
        {'wav': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '錯誤:生日快樂', 'type': 'wrong', 'target': 30.0},
        
        // 環境噪音
        {'wav': 'assets/test_voice/環境背景.wav', 'name': '噪音:背景1', 'type': 'noise', 'target': 5.0},
        {'wav': 'assets/test_voice/環境背景2.wav', 'name': '噪音:背景2', 'type': 'noise', 'target': 5.0},
      ],
    },
  ];

  // 全域統計
  final allResults = <Map<String, dynamic>>[];
  int totalTests = 0;
  int passedTests = 0;

  // 執行所有測試輪次
  for (int roundIdx = 0; roundIdx < testRounds.length; roundIdx++) {
    final round = testRounds[roundIdx];
    print('\n┌${'─' * 64}┐');
    print('│  ${round['name']}  -  ${round['desc']}');
    print('│  任務音檔: ${(round['midi'] as String).split('/').last}');
    print('└${'─' * 64}┘\n');

    final midiPath = round['midi'] as String;
    final tests = round['tests'] as List<Map<String, dynamic>>;

    // 分類顯示
    final correctTests = tests.where((t) => t['type'] == 'correct').toList();
    final wrongTests = tests.where((t) => t['type'] == 'wrong').toList();
    final noiseTests = tests.where((t) => t['type'] == 'noise').toList();

    // 執行正確演奏測試
    if (correctTests.isNotEmpty) {
      print('  📗 正確演奏測試 (期望召回率 ≥85%):');
      for (var test in correctTests) {
        final result = await _runTest(test, midiPath, silentMode);
        if (result != null) {
          _printResult(result);
          allResults.add(result);
          totalTests++;
          if (result['passed'] as bool) passedTests++;
        }
      }
      print('');
    }

    // 執行錯誤音檔測試
    if (wrongTests.isNotEmpty) {
      print('  📙 錯誤音檔測試 (期望召回率 ≤30%):');
      for (var test in wrongTests) {
        final result = await _runTest(test, midiPath, silentMode);
        if (result != null) {
          _printResult(result);
          allResults.add(result);
          totalTests++;
          if (result['passed'] as bool) passedTests++;
        }
      }
      print('');
    }

    // 執行環境噪音測試
    if (noiseTests.isNotEmpty) {
      print('  📕 環境噪音測試 (期望召回率 ≤5%):');
      for (var test in noiseTests) {
        final result = await _runTest(test, midiPath, silentMode);
        if (result != null) {
          _printResult(result);
          allResults.add(result);
          totalTests++;
          if (result['passed'] as bool) passedTests++;
        }
      }
      print('');
    }
  }

  // 最終總結報告
  _printSummaryReport(allResults, passedTests, totalTests);
}

/// 執行單個測試
Future<Map<String, dynamic>?> _runTest(
  Map<String, dynamic> test,
  String midiPath,
  bool silentMode,
) async {
  final wavPath = test['wav'] as String;
  final testName = test['name'] as String;
  final testType = test['type'] as String;
  final target = test['target'] as double;

  // 檢查檔案
  if (!File(midiPath).existsSync()) {
    print('    ⏭️  $testName - MIDI檔案不存在');
    return null;
  }
  
  if (!File(wavPath).existsSync()) {
    print('    ⏭️  $testName - 音檔不存在');
    return null;
  }

  // 執行分析
  try {
    final analyzer = PerformanceAnalyzer();
    late dynamic report;

    if (silentMode) {
      await runZoned(
        () async {
          report = await analyzer.analyze(wavPath, midiPath);
        },
        zoneSpecification: ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
            // 靜默模式：吸收所有 print 輸出
          },
        ),
      );
    } else {
      report = await analyzer.analyze(wavPath, midiPath);
    }

    final recall = report.recall as double;
    final totalExpected = report.totalNotes as int;
    final correctNotes = report.confusionMatrix?.truePositive ?? 0;

    // 判定通過/失敗
    bool passed = false;
    if (testType == 'correct') {
      passed = recall >= (target / 100); // 正確演奏：召回率要高
    } else {
      passed = recall <= (target / 100); // 錯誤/噪音：召回率要低
    }

    return {
      'name': testName,
      'type': testType,
      'recall': recall,
      'target': target,
      'passed': passed,
      'correct': correctNotes,
      'total': totalExpected,
      'wavPath': wavPath,
    };
  } catch (e) {
    print('    ⚠️  $testName - 錯誤: $e');
    return null;
  }
}

/// 打印單個測試結果
void _printResult(Map<String, dynamic> result) {
  final name = result['name'] as String;
  final type = result['type'] as String;
  final recall = result['recall'] as double;
  final target = result['target'] as double;
  final passed = result['passed'] as bool;
  final correct = result['correct'] as int;
  final total = result['total'] as int;

  final statusIcon = passed ? '✅' : '❌';
  final recallStr = (recall * 100).toStringAsFixed(1).padLeft(5);
  final targetStr = target.toStringAsFixed(0).padLeft(2);
  
  String expectation = '';
  if (type == 'correct') {
    expectation = '≥$targetStr%';
  } else {
    expectation = '≤$targetStr%';
  }

  print('    $statusIcon ${name.padRight(16)} │ 召回率:$recallStr% (目標$expectation) │ $correct/$total');
}

/// 打印總結報告
void _printSummaryReport(List<Map<String, dynamic>> allResults, int passed, int total) {
  print('\n╔══════════════════════════════════════════════════════════════╗');
  print('║                    📊 完整測試總結報告                       ║');
  print('╚══════════════════════════════════════════════════════════════╝\n');

  // 按類型分組統計
  final correctResults = allResults.where((r) => r['type'] == 'correct').toList();
  final wrongResults = allResults.where((r) => r['type'] == 'wrong').toList();
  final noiseResults = allResults.where((r) => r['type'] == 'noise').toList();

  print('📊 總體通過率: $passed/$total (${(passed / total * 100).toStringAsFixed(1)}%)\n');

  // 正確演奏統計
  if (correctResults.isNotEmpty) {
    final correctPassed = correctResults.where((r) => r['passed'] as bool).length;
    final avgRecall = correctResults.map((r) => r['recall'] as double).reduce((a, b) => a + b) / correctResults.length;
    
    print('📗 正確演奏檢測 (${correctResults.length}個測試):');
    print('   通過率: $correctPassed/${correctResults.length} (${(correctPassed / correctResults.length * 100).toStringAsFixed(1)}%)');
    print('   平均召回率: ${(avgRecall * 100).toStringAsFixed(1)}% (目標 ≥85%)');
    
    final failed = correctResults.where((r) => !(r['passed'] as bool)).toList();
    if (failed.isNotEmpty) {
      print('   ❌ 失敗案例:');
      for (var r in failed) {
        final recall = ((r['recall'] as double) * 100).toStringAsFixed(1);
        final target = r['target'];
        print('      • ${r['name']}: $recall% (需≥$target%)');
      }
    }
    print('');
  }

  // 錯誤音檔統計
  if (wrongResults.isNotEmpty) {
    final wrongPassed = wrongResults.where((r) => r['passed'] as bool).length;
    final avgRecall = wrongResults.map((r) => r['recall'] as double).reduce((a, b) => a + b) / wrongResults.length;
    
    print('📙 錯誤音檔排除 (${wrongResults.length}個測試):');
    print('   通過率: $wrongPassed/${wrongResults.length} (${(wrongPassed / wrongResults.length * 100).toStringAsFixed(1)}%)');
    print('   平均召回率: ${(avgRecall * 100).toStringAsFixed(1)}% (目標 ≤30%)');
    
    final failed = wrongResults.where((r) => !(r['passed'] as bool)).toList();
    if (failed.isNotEmpty) {
      print('   ❌ 失敗案例 (誤判為正確):');
      for (var r in failed) {
        final recall = ((r['recall'] as double) * 100).toStringAsFixed(1);
        final target = r['target'];
        print('      • ${r['name']}: $recall% (需≤$target%)');
      }
    }
    print('');
  }

  // 環境噪音統計
  if (noiseResults.isNotEmpty) {
    final noisePassed = noiseResults.where((r) => r['passed'] as bool).length;
    final avgRecall = noiseResults.map((r) => r['recall'] as double).reduce((a, b) => a + b) / noiseResults.length;
    
    print('📕 環境噪音排除 (${noiseResults.length}個測試):');
    print('   通過率: $noisePassed/${noiseResults.length} (${(noisePassed / noiseResults.length * 100).toStringAsFixed(1)}%)');
    print('   平均召回率: ${(avgRecall * 100).toStringAsFixed(1)}% (目標 ≤5%)');
    
    final failed = noiseResults.where((r) => !(r['passed'] as bool)).toList();
    if (failed.isNotEmpty) {
      print('   ❌ 失敗案例 (誤判為音樂):');
      for (var r in failed) {
        final recall = ((r['recall'] as double) * 100).toStringAsFixed(1);
        final target = r['target'];
        print('      • ${r['name']}: $recall% (需≤$target%)');
      }
    }
    print('');
  }

  // 關鍵發現
  print('🔍 關鍵發現:');
  if (correctResults.isNotEmpty) {
    final avgCorrectRecall = correctResults.map((r) => r['recall'] as double).reduce((a, b) => a + b) / correctResults.length;
    if (avgCorrectRecall >= 0.85) {
      print('   ✅ 正確演奏檢測能力良好 (平均召回率 ${(avgCorrectRecall * 100).toStringAsFixed(1)}%)');
    } else {
      print('   ⚠️  正確演奏檢測需要改進 (平均召回率 ${(avgCorrectRecall * 100).toStringAsFixed(1)}%)');
    }
  }
  
  if (wrongResults.isNotEmpty) {
    final avgWrongRecall = wrongResults.map((r) => r['recall'] as double).reduce((a, b) => a + b) / wrongResults.length;
    if (avgWrongRecall <= 0.30) {
      print('   ✅ 錯誤音檔排除能力良好 (平均召回率 ${(avgWrongRecall * 100).toStringAsFixed(1)}%)');
    } else {
      print('   ⚠️  錯誤音檔排除需要改進 (平均召回率 ${(avgWrongRecall * 100).toStringAsFixed(1)}%)');
    }
  }
  
  if (noiseResults.isNotEmpty) {
    final avgNoiseRecall = noiseResults.map((r) => r['recall'] as double).reduce((a, b) => a + b) / noiseResults.length;
    if (avgNoiseRecall <= 0.05) {
      print('   ✅ 環境噪音排除能力優秀 (平均召回率 ${(avgNoiseRecall * 100).toStringAsFixed(1)}%)');
    } else {
      print('   ⚠️  環境噪音排除需要改進 (平均召回率 ${(avgNoiseRecall * 100).toStringAsFixed(1)}%)');
    }
  }

  print('\n═══════════════════════════════════════════════════════════════');
  print('✅ 完整測試結束！\n');
}

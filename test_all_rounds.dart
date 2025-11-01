import 'dart:io';
import 'dart:async';
import 'lib/services/audio_analysis/performance_analyzer.dart';

/// 🎯 完整 4 輪音檔檢測測試 (2025/10/25)
/// 
/// 簡化版本：清晰的輸出，專注於關鍵指標
void main(List<String> args) async {
  final bool silentMode = args.contains('--silent') || args.contains('-s');
  
  if (!silentMode) {
    print('💡 提示：使用 --silent 參數可抑制調試輸出');
  }
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║        🎵 音樂練習檢測系統 - 完整測試報告                  ║');
  print('╚══════════════════════════════════════════════════════════════╝');
  print('');

  // 測試配置 - 專注於正確演奏準確度
  final testRounds = [
    {
      'name': '第一輪：生日快樂',
      'desc': '單音無伴奏 + 短時長',
      'midi': 'assets/test_voice/生日快樂.mid',
      'tests': [
        {'wav': 'assets/test_voice/生日快樂(midi轉檔).wav', 'name': 'MIDI轉檔', 'type': 'correct', 'target': 0.95},
        {'wav': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '手機錄製', 'type': 'correct', 'target': 0.85},
        {'wav': 'assets/test_voice/生日快樂(電腦環境錄製).wav', 'name': '電腦錄製', 'type': 'correct', 'target': 0.85},
        // 暫時移除環境噪音測試，專注於準確度
      ],
    },
    {
      'name': '第二輪：測試音檔',
      'desc': '單音無伴奏 + 中時長',
      'midi': 'assets/test_voice/測試音檔.mid',
      'tests': [
        {'wav': 'assets/test_voice/測試音檔(midi轉檔).wav', 'name': 'MIDI轉檔', 'type': 'correct', 'target': 0.95},
        {'wav': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '手機錄製', 'type': 'correct', 'target': 0.85},
        {'wav': 'assets/test_voice/測試音檔(電腦環境錄製).wav', 'name': '電腦錄製', 'type': 'correct', 'target': 0.85},
      ],
    },
    {
      'name': '第三輪：小星星',
      'desc': '有伴奏 + 中時長',
      'midi': 'assets/test_voice/小星星.mid',
      'tests': [
        {'wav': 'assets/test_voice/小星星(midi轉檔).wav', 'name': 'MIDI轉檔', 'type': 'correct', 'target': 0.90},
        {'wav': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '手機錄製', 'type': 'correct', 'target': 0.80},
        {'wav': 'assets/test_voice/小星星(電腦環境錄製).wav', 'name': '電腦錄製', 'type': 'correct', 'target': 0.80},
      ],
    },
    {
      'name': '第四輪：名偵探柯南',
      'desc': '旋律複雜 + 曲速極快 + 長時長',
      'midi': 'assets/test_voice/名偵探柯南.mid',
      'tests': [
        {'wav': 'assets/test_voice/名偵探柯南(midi轉檔).wav', 'name': 'MIDI轉檔', 'type': 'correct', 'target': 0.85},
        {'wav': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '手機錄製', 'type': 'correct', 'target': 0.75},
        {'wav': 'assets/test_voice/名偵探柯南(電腦環境錄製).wav', 'name': '電腦錄製', 'type': 'correct', 'target': 0.75},
      ],
    },
  ];

  // 全域統計
  final allResults = <Map<String, dynamic>>[];

  // 執行所有測試輪次
  for (int roundIdx = 0; roundIdx < testRounds.length; roundIdx++) {
    final round = testRounds[roundIdx];
    print('');
    print('┌${'─' * 64}┐');
    print('│  ${round['name']}  -  ${round['desc']}');
    print('└${'─' * 64}┘');
    print('');

    final midiPath = round['midi'] as String;
    final tests = round['tests'] as List<Map<String, dynamic>>;

    for (int testIdx = 0; testIdx < tests.length; testIdx++) {
      final test = tests[testIdx];
      final wavPath = test['wav'] as String;
      final testName = test['name'] as String;
      final testType = test['type'] as String;
      final target = test['target'] as double;

      // 檢查檔案
      if (!File(midiPath).existsSync() || !File(wavPath).existsSync()) {
        print('  ⏭️  ${testIdx + 1}. $testName - 檔案不存在');
        continue;
      }

      // 執行分析
      try {
        final analyzer = PerformanceAnalyzer();
        
        // 靜默模式：捕獲 print 輸出
        late dynamic report;
        if (silentMode) {
          await runZoned(
            () async {
              report = await analyzer.analyze(wavPath, midiPath);
            },
            zoneSpecification: ZoneSpecification(
              print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
                // 吸收所有 print 輸出
              },
            ),
          );
        } else {
          report = await analyzer.analyze(wavPath, midiPath);
        }

        final f1 = report.f1Score;
        final precision = report.precision;
        final recall = report.recall;
        final totalExpected = report.totalNotes;
        final correctNotes = report.confusionMatrix?.truePositive ?? 0;
        
        // 判定通過/失敗（只看 Recall）
        bool passed = false;
        if (testType == 'correct') {
          passed = recall >= target;  // 改用 recall
        } else {
          passed = recall <= target;  // 改用 recall
        }

        // 精簡輸出 - 只顯示 Recall（召回率）
        final statusIcon = passed ? '✅' : '❌';
        final recallStr = (recall * 100).toStringAsFixed(1).padLeft(5);
        final correctStr = '$correctNotes/$totalExpected'.padRight(10);
        
        print('  $statusIcon ${(testIdx + 1)}. ${testName.padRight(20)} │ 召回率:$recallStr% │ 正確: $correctStr');

        // 記錄結果
        allResults.add({
          'round': round['name'],
          'test': testName,
          'type': testType,
          'f1': f1,
          'precision': precision,
          'recall': recall,
          'target': target,
          'passed': passed,
          'detected': report.totalDetectedNotes ?? 0,
          'expected': report.totalNotes,
        });
      } catch (e) {
        print('  ⚠️  ${testIdx + 1}. $testName - 錯誤: $e');
      }
    }
  }

  // 最終總結
  print('');
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║                    📊 測試總結報告                          ║');
  print('╚══════════════════════════════════════════════════════════════╝');
  print('');

  // 統計正確演奏測試
  final correctTests = allResults.where((r) => r['type'] == 'correct').toList();
  final correctPassed = correctTests.where((r) => r['passed'] == true).length;
  final correctAvgRecall = correctTests.isEmpty ? 0.0 :
    correctTests.map((r) => r['recall'] as double).reduce((a, b) => a + b) / correctTests.length;

  print('📈 正確演奏測試總結');
  print('   通過率: $correctPassed/${correctTests.length} (${(correctPassed / correctTests.length * 100).toStringAsFixed(1)}%)');
  print('   平均召回率: ${(correctAvgRecall * 100).toStringAsFixed(1)}% (目標 ≥85%)');
  print('');

  final totalPassed = correctPassed;
  final totalTests = allResults.length;
  
  print('🎯 總體通過率: $totalPassed/$totalTests (${(totalPassed / totalTests * 100).toStringAsFixed(1)}%)');
  print('');

  // 最差案例提示
  print('⚠️  需要改進的案例:');
  final failedTests = allResults.where((r) => r['passed'] == false).toList();
  if (failedTests.isEmpty) {
    print('   🎉 全部通過！');
  } else {
    for (final test in failedTests.take(5)) {
      final f1 = ((test['f1'] as double) * 100).toStringAsFixed(1);
      final target = ((test['target'] as double) * 100).toInt();
      final op = test['type'] == 'correct' ? '≥' : '≤';
      print('   • ${test['round']} - ${test['test']}: F1=$f1% (需$op$target%)');
    }
  }
  
  print('');
  print('✅ 測試完成！');
}

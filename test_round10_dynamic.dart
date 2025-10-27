import 'dart:io';
import 'lib/services/audio_analysis/performance_analyzer.dart';

/// Round 10 測試腳本 - 動態參數全面驗證 (2025/10/26)
/// 
/// 測試目的：
/// 1. 驗證動態參數系統在 32 個測試案例的表現
/// 2. 與 Round 8 (2025/10/08) 固定參數 0.38 對比
/// 3. 與 Round 8 末 (2025/10/25) 固定參數 0.38 對比
/// 
/// 測試配置：
/// - 步驟1: 小星星.mid vs 6個音檔
/// - 步驟2: 測試音檔.mid vs 6個音檔  
/// - 步驟3: 名偵探柯南.mid vs 6個音檔
/// - 步驟4: 名偵探柯南.mid vs 4個音檔(柯南專屬)
/// - 步驟5: 生日快樂.mid vs 10個音檔 (全部測試)
/// 總計：32 個測試案例
void main(List<String> args) async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║     🎚️ Round 10 動態參數全面測試 (2025/10/26)           ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');
  print('📊 測試配置: 32 個測試案例');
  print('🎯 測試目標: 驗證動態參數效果並與歷史數據對比');
  print('');

  // 測試步驟定義（與 Round 8 相同）
  final testSteps = [
    {
      'name': '步驟1: 小星星.mid 全面測試',
      'midi': 'assets/test_voice/小星星.mid',
      'wavs': [
        {'path': 'assets/test_voice/小星星(midi轉檔).wav', 'name': '小星星(midi轉檔)', 'type': '和弦+伴奏', 'expect': 'PASS'},
        {'path': 'assets/test_voice/小星星(環境).wav', 'name': '小星星(環境)', 'type': '和弦+伴奏', 'expect': 'PASS'},
        {'path': 'assets/test_voice/測試音檔(midi轉檔).wav', 'name': '測試音檔(midi轉檔)', 'type': '單音', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/測試音檔(環境).wav', 'name': '測試音檔(環境)', 'type': '單音', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'type': '噪音', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'type': '噪音', 'expect': 'FAIL'},
      ],
    },
    {
      'name': '步驟2: 測試音檔.mid 全面測試',
      'midi': 'assets/test_voice/測試音檔.mid',
      'wavs': [
        {'path': 'assets/test_voice/小星星(midi轉檔).wav', 'name': '小星星(midi轉檔)', 'type': '和弦+伴奏', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/小星星(環境).wav', 'name': '小星星(環境)', 'type': '和弦+伴奏', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/測試音檔(midi轉檔).wav', 'name': '測試音檔(midi轉檔)', 'type': '單音', 'expect': 'PASS'},
        {'path': 'assets/test_voice/測試音檔(環境).wav', 'name': '測試音檔(環境)', 'type': '單音', 'expect': 'PASS'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'type': '噪音', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'type': '噪音', 'expect': 'FAIL'},
      ],
    },
    {
      'name': '步驟3: 名偵探柯南.mid 全面測試',
      'midi': 'assets/test_voice/名偵探柯南.mid',
      'wavs': [
        {'path': 'assets/test_voice/小星星(midi轉檔).wav', 'name': '小星星(midi轉檔)', 'type': '和弦+伴奏', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/小星星(環境).wav', 'name': '小星星(環境)', 'type': '和弦+伴奏', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/測試音檔(midi轉檔).wav', 'name': '測試音檔(midi轉檔)', 'type': '單音', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/測試音檔(環境).wav', 'name': '測試音檔(環境)', 'type': '單音', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'type': '噪音', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'type': '噪音', 'expect': 'FAIL'},
      ],
    },
    {
      'name': '步驟4: 名偵探柯南.mid 專屬測試',
      'midi': 'assets/test_voice/名偵探柯南.mid',
      'wavs': [
        {'path': 'assets/test_voice/名偵探柯南(midi轉檔).wav', 'name': '名偵探柯南(midi轉檔)', 'type': '複雜音樂', 'expect': 'PASS'},
        {'path': 'assets/test_voice/名偵探柯南(環境).wav', 'name': '名偵探柯南(環境)', 'type': '複雜音樂', 'expect': 'PASS'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'type': '噪音', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'type': '噪音', 'expect': 'FAIL'},
      ],
    },
    {
      'name': '步驟5: 生日快樂.mid 全面測試',
      'midi': 'assets/test_voice/生日快樂.mid',
      'wavs': [
        {'path': 'assets/test_voice/生日快樂(midi轉檔).wav', 'name': '生日快樂(midi轉檔)', 'type': '簡單曲目', 'expect': 'PASS'},
        {'path': 'assets/test_voice/生日快樂(環境).wav', 'name': '生日快樂(環境)', 'type': '簡單曲目', 'expect': 'PASS'},
        {'path': 'assets/test_voice/小星星(midi轉檔).wav', 'name': '小星星(midi轉檔)', 'type': '和弦+伴奏', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/小星星(環境).wav', 'name': '小星星(環境)', 'type': '和弦+伴奏', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/測試音檔(midi轉檔).wav', 'name': '測試音檔(midi轉檔)', 'type': '單音', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/測試音檔(環境).wav', 'name': '測試音檔(環境)', 'type': '單音', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/名偵探柯南(midi轉檔).wav', 'name': '名偵探柯南(midi轉檔)', 'type': '複雜音樂', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/名偵探柯南(環境).wav', 'name': '名偵探柯南(環境)', 'type': '複雜音樂', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'type': '噪音', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'type': '噪音', 'expect': 'FAIL'},
      ],
    },
  ];

  // 結果收集
  final allResults = <Map<String, dynamic>>[];
  int totalTests = 0;
  int passedTests = 0;
  int failedTests = 0;
  int correctPredictions = 0;
  int totalExpectedPass = 0;
  int totalExpectedFail = 0;
  
  // 分類統計
  final Map<String, int> passCount = {};
  final Map<String, int> failCount = {};

  final analyzer = PerformanceAnalyzer();
  final startTime = DateTime.now();

  // 執行所有測試
  for (int stepIndex = 0; stepIndex < testSteps.length; stepIndex++) {
    final step = testSteps[stepIndex];
    final midiPath = step['midi'] as String;
    final wavList = step['wavs'] as List<Map<String, String>>;

    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📋 ${step['name']}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📄 MIDI: $midiPath');
    print('🎵 測試數: ${wavList.length}');
    print('');

    for (int wavIndex = 0; wavIndex < wavList.length; wavIndex++) {
      final wavInfo = wavList[wavIndex];
      final wavPath = wavInfo['path']!;
      final wavName = wavInfo['name']!;
      final wavType = wavInfo['type']!;
      final expect = wavInfo['expect']!;

      totalTests++;
      if (expect == 'PASS') totalExpectedPass++;
      if (expect == 'FAIL') totalExpectedFail++;

      print('🧪 測試 ${stepIndex + 1}.${wavIndex + 1}: $wavName ($wavType) - 預期: $expect');

      // 檢查檔案
      final midiFile = File(midiPath);
      final wavFile = File(wavPath);

      if (!midiFile.existsSync() || !wavFile.existsSync()) {
        print('   ❌ 檔案不存在');
        allResults.add({
          'step': stepIndex + 1,
          'name': wavName,
          'type': wavType,
          'expect': expect,
          'status': 'ERROR',
          'error': 'File not found',
        });
        continue;
      }

      try {
        // 執行分析
        final report = await analyzer.analyze(wavPath, midiPath);

        final passRate = report.totalNotes > 0 
            ? (report.correctNotes / report.totalNotes * 100) 
            : 0.0;
        final f1Score = report.confusionMatrix?.f1Score ?? 0.0;
        final recall = report.confusionMatrix?.recall ?? 0.0;
        final precision = report.confusionMatrix?.precision ?? 0.0;
        final tp = report.confusionMatrix?.truePositive ?? 0;
        final fp = report.confusionMatrix?.falsePositive ?? 0;
        final fn = report.confusionMatrix?.falseNegative ?? 0;
        final isPassed = passRate >= 60.0;

        // 統計
        if (isPassed) {
          passedTests++;
          passCount[wavType] = (passCount[wavType] ?? 0) + 1;
        } else {
          failedTests++;
          failCount[wavType] = (failCount[wavType] ?? 0) + 1;
        }

        if ((expect == 'PASS' && isPassed) || (expect == 'FAIL' && !isPassed)) {
          correctPredictions++;
        }

        final result = isPassed ? '✅ PASS' : '❌ FAIL';
        final match = (expect == 'PASS' && isPassed) || (expect == 'FAIL' && !isPassed) 
            ? '✓' 
            : '✗ 預測錯誤';

        print('   $result (通過率: ${passRate.toStringAsFixed(1)}%, F1: ${(f1Score * 100).toStringAsFixed(1)}%) $match');
        print('   正確: ${report.correctNotes}/${report.totalNotes}, '
              'Recall: ${(recall * 100).toStringAsFixed(1)}%, '
              'Precision: ${(precision * 100).toStringAsFixed(1)}%');

        allResults.add({
          'step': stepIndex + 1,
          'name': wavName,
          'type': wavType,
          'expect': expect,
          'status': isPassed ? 'PASS' : 'FAIL',
          'passRate': passRate,
          'f1Score': f1Score * 100,
          'recall': recall * 100,
          'precision': precision * 100,
          'correct': report.correctNotes,
          'total': report.totalNotes,
          'tp': tp,
          'fp': fp,
          'fn': fn,
        });

      } catch (e) {
        print('   ❌ 分析錯誤: $e');
        failedTests++;
        allResults.add({
          'step': stepIndex + 1,
          'name': wavName,
          'type': wavType,
          'expect': expect,
          'status': 'ERROR',
          'error': e.toString(),
        });
      }
    }
  }

  final endTime = DateTime.now();
  final duration = endTime.difference(startTime);

  // 生成詳細報告
  print('');
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║              📊 Round 10 測試總結報告                    ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');
  print('【測試概況】');
  print('  總測試數: $totalTests');
  print('  通過: $passedTests (${(passedTests / totalTests * 100).toStringAsFixed(1)}%)');
  print('  失敗: $failedTests (${(failedTests / totalTests * 100).toStringAsFixed(1)}%)');
  print('  預測準確率: ${(correctPredictions / totalTests * 100).toStringAsFixed(1)}% ($correctPredictions/$totalTests)');
  print('  測試時長: ${duration.inSeconds} 秒');
  print('');

  print('【分類統計】');
  final allTypes = {...passCount.keys, ...failCount.keys}.toList()..sort();
  for (final type in allTypes) {
    final pass = passCount[type] ?? 0;
    final fail = failCount[type] ?? 0;
    final total = pass + fail;
    print('  $type: $pass/$total 通過 (${(pass / total * 100).toStringAsFixed(1)}%)');
  }
  print('');

  // 計算正確演奏案例的平均指標
  final correctPerformances = allResults.where((r) => 
    r['expect'] == 'PASS' && r['status'] == 'PASS'
  ).toList();

  if (correctPerformances.isNotEmpty) {
    final avgPassRate = correctPerformances
        .map((r) => r['passRate'] as double)
        .reduce((a, b) => a + b) / correctPerformances.length;
    final avgF1 = correctPerformances
        .map((r) => r['f1Score'] as double)
        .reduce((a, b) => a + b) / correctPerformances.length;
    final avgRecall = correctPerformances
        .map((r) => r['recall'] as double)
        .reduce((a, b) => a + b) / correctPerformances.length;
    final avgPrecision = correctPerformances
        .map((r) => r['precision'] as double)
        .reduce((a, b) => a + b) / correctPerformances.length;

    print('【正確演奏案例平均指標】($totalExpectedPass 個案例)');
    print('  平均通過率: ${avgPassRate.toStringAsFixed(1)}%');
    print('  平均 F1 Score: ${avgF1.toStringAsFixed(1)}%');
    print('  平均 Recall: ${avgRecall.toStringAsFixed(1)}%');
    print('  平均 Precision: ${avgPrecision.toStringAsFixed(1)}%');
    print('');
  }

  // 詳細結果列表
  print('【詳細測試結果】');
  print('');
  for (final result in allResults) {
    final status = result['status'];
    final statusIcon = status == 'PASS' ? '✅' : (status == 'FAIL' ? '❌' : '⚠️');
    final expectMatch = result['expect'] == status ? '✓' : '✗';
    
    print('步驟${result['step']} - ${result['name']} ($expectMatch)');
    print('  狀態: $statusIcon $status (預期: ${result['expect']})');
    
    if (status == 'PASS' || status == 'FAIL') {
      print('  通過率: ${result['passRate'].toStringAsFixed(1)}% | F1: ${result['f1Score'].toStringAsFixed(1)}%');
      print('  Recall: ${result['recall'].toStringAsFixed(1)}% | Precision: ${result['precision'].toStringAsFixed(1)}%');
      print('  混淆矩陣: TP=${result['tp']}, FP=${result['fp']}, FN=${result['fn']}');
    } else if (status == 'ERROR') {
      print('  錯誤: ${result['error']}');
    }
    print('');
  }

  print('╔═══════════════════════════════════════════════════════════╗');
  print('║            🎉 Round 10 測試完成！                         ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');
  print('💾 結果已保存至內存，可用於後續分析');
  print('📊 下一步: 與 Round 8 (1008/1025) 數據對比');
  print('');
}

import 'dart:io';
import 'lib/services/audio_analysis/performance_analyzer.dart';

/// Round 10 快速測試 - 關鍵案例驗證 (2025/10/26)
/// 
/// 測試目的：快速驗證動態參數效果
/// 測試案例：6 個關鍵案例
void main() async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║     🎚️ Round 10 快速測試 (2025/10/26)                   ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');

  // 關鍵測試案例
  final testCases = [
    {
      'name': '生日快樂(midi轉檔)',
      'midi': 'assets/test_voice/生日快樂.mid',
      'wav': 'assets/test_voice/生日快樂(midi轉檔).wav',
      'type': '簡單曲目',
      'expect': 'PASS',
    },
    {
      'name': '小星星(midi轉檔)',
      'midi': 'assets/test_voice/小星星.mid',
      'wav': 'assets/test_voice/小星星(midi轉檔).wav',
      'type': '中級曲目',
      'expect': 'PASS',
    },
    {
      'name': '測試音檔(midi轉檔)',
      'midi': 'assets/test_voice/測試音檔.mid',
      'wav': 'assets/test_voice/測試音檔(midi轉檔).wav',
      'type': '單音曲目',
      'expect': 'PASS',
    },
    {
      'name': '柯南(midi轉檔)',
      'midi': 'assets/test_voice/名偵探柯南.mid',
      'wav': 'assets/test_voice/名偵探柯南(midi轉檔).wav',
      'type': '複雜曲目',
      'expect': 'PASS',
    },
    {
      'name': '柯南(環境)',
      'midi': 'assets/test_voice/名偵探柯南.mid',
      'wav': 'assets/test_voice/名偵探柯南(環境).wav',
      'type': '複雜曲目',
      'expect': 'PASS',
    },
    {
      'name': '環境背景 vs 小星星',
      'midi': 'assets/test_voice/小星星.mid',
      'wav': 'assets/test_voice/環境背景.wav',
      'type': '噪音',
      'expect': 'FAIL',
    },
  ];

  final analyzer = PerformanceAnalyzer();
  final results = <Map<String, dynamic>>[];
  final startTime = DateTime.now();

  print('📊 測試案例數: ${testCases.length}');
  print('');

  for (int i = 0; i < testCases.length; i++) {
    final testCase = testCases[i];
    final name = testCase['name']!;
    final midiPath = testCase['midi']!;
    final wavPath = testCase['wav']!;
    final type = testCase['type']!;
    final expect = testCase['expect']!;

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🧪 測試 ${i + 1}/${testCases.length}: $name ($type)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('預期: $expect');
    print('');

    // 檢查檔案
    if (!File(midiPath).existsSync() || !File(wavPath).existsSync()) {
      print('❌ 檔案不存在');
      results.add({
        'name': name,
        'type': type,
        'expect': expect,
        'status': 'ERROR',
        'error': 'File not found',
      });
      print('');
      continue;
    }

    try {
      final report = await analyzer.analyze(wavPath, midiPath);

      final passRate = report.totalNotes > 0
          ? (report.correctNotes / report.totalNotes * 100)
          : 0.0;
      final f1Score = report.confusionMatrix?.f1Score ?? 0.0;
      final recall = report.confusionMatrix?.recall ?? 0.0;
      final precision = report.confusionMatrix?.precision ?? 0.0;
      final isPassed = passRate >= 60.0;

      final statusIcon = isPassed ? '✅' : '❌';
      final matchIcon = (expect == 'PASS' && isPassed) || (expect == 'FAIL' && !isPassed) ? '✓' : '✗';

      print('');
      print('【結果】$statusIcon ${isPassed ? "PASS" : "FAIL"} $matchIcon');
      print('  通過率: ${passRate.toStringAsFixed(1)}%');
      print('  F1 Score: ${(f1Score * 100).toStringAsFixed(1)}%');
      print('  Recall: ${(recall * 100).toStringAsFixed(1)}%');
      print('  Precision: ${(precision * 100).toStringAsFixed(1)}%');
      print('  正確音符: ${report.correctNotes}/${report.totalNotes}');
      print('');

      results.add({
        'name': name,
        'type': type,
        'expect': expect,
        'status': isPassed ? 'PASS' : 'FAIL',
        'passRate': passRate,
        'f1Score': f1Score * 100,
        'recall': recall * 100,
        'precision': precision * 100,
        'correct': report.correctNotes,
        'total': report.totalNotes,
      });
    } catch (e) {
      print('❌ 錯誤: $e');
      print('');
      results.add({
        'name': name,
        'type': type,
        'expect': expect,
        'status': 'ERROR',
        'error': e.toString(),
      });
    }
  }

  final endTime = DateTime.now();
  final duration = endTime.difference(startTime);

  // 統計
  final passCount = results.where((r) => r['status'] == 'PASS').length;
  final failCount = results.where((r) => r['status'] == 'FAIL').length;
  final errorCount = results.where((r) => r['status'] == 'ERROR').length;
  final correctPredictions = results.where((r) =>
      (r['expect'] == 'PASS' && r['status'] == 'PASS') ||
      (r['expect'] == 'FAIL' && r['status'] == 'FAIL')
  ).length;

  print('╔═══════════════════════════════════════════════════════════╗');
  print('║              📊 Round 10 快速測試總結                    ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');
  print('【測試概況】');
  print('  總測試數: ${testCases.length}');
  print('  通過: $passCount');
  print('  失敗: $failCount');
  print('  錯誤: $errorCount');
  print('  預測準確率: ${(correctPredictions / testCases.length * 100).toStringAsFixed(1)}% ($correctPredictions/${testCases.length})');
  print('  測試時長: ${duration.inSeconds} 秒');
  print('');

  // 正確演奏案例的平均指標
  final correctPerformances = results.where((r) =>
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

    print('【正確演奏案例平均指標】(${correctPerformances.length} 個案例)');
    print('  平均通過率: ${avgPassRate.toStringAsFixed(1)}%');
    print('  平均 F1 Score: ${avgF1.toStringAsFixed(1)}%');
    print('  平均 Recall: ${avgRecall.toStringAsFixed(1)}%');
    print('  平均 Precision: ${avgPrecision.toStringAsFixed(1)}%');
    print('');
  }

  // 詳細結果
  print('【詳細結果】');
  print('');
  for (final result in results) {
    final status = result['status'];
    final statusIcon = status == 'PASS' ? '✅' : (status == 'FAIL' ? '❌' : '⚠️');
    final expectMatch = result['expect'] == status ? '✓' : '✗';

    print('${result['name']} ($expectMatch)');
    print('  狀態: $statusIcon $status (預期: ${result['expect']})');

    if (status == 'PASS' || status == 'FAIL') {
      print('  通過率: ${result['passRate'].toStringAsFixed(1)}% | '
            'F1: ${result['f1Score'].toStringAsFixed(1)}%');
      print('  Recall: ${result['recall'].toStringAsFixed(1)}% | '
            'Precision: ${result['precision'].toStringAsFixed(1)}%');
    }
    print('');
  }

  print('╔═══════════════════════════════════════════════════════════╗');
  print('║            🎉 Round 10 快速測試完成！                     ║');
  print('╚═══════════════════════════════════════════════════════════╝');
}

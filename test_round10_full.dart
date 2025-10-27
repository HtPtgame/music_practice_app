import 'dart:io';
import 'lib/services/audio_analysis/performance_analyzer.dart';

/// Round 10 完整測試 - 分四輪執行 (2025/10/26)
/// 
/// 測試配置：
/// 第一輪：生日快樂.mid (單音無伴奏+短時常) - 8個測試案例
/// 第二輪：測試音檔.mid (單音無伴奏+中時常) - 8個測試案例
/// 第三輪：小星星.mid (有伴奏+中時常) - 8個測試案例
/// 第四輪：名偵探柯南.mid (旋律複雜+曲速極快+長時常) - 8個測試案例
/// 
/// 使用方式：dart test_round10_full.dart [1-4]

void main(List<String> args) async {
  if (args.isEmpty) {
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║     🎚️ Round 10 完整測試 - 分四輪執行 (2025/10/26)        ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');
    print('📋 使用方式: dart test_round10_full.dart [輪次]');
    print('');
    print('【測試輪次】');
    print('  1️⃣  第一輪: 生日快樂.mid (單音無伴奏+短時常) - 8個案例');
    print('  2️⃣  第二輪: 測試音檔.mid (單音無伴奏+中時常) - 8個案例');
    print('  3️⃣  第三輪: 小星星.mid (有伴奏+中時常) - 8個案例');
    print('  4️⃣  第四輪: 名偵探柯南.mid (複雜+極快+長時常) - 8個案例');
    print('');
    print('💡 範例: dart test_round10_full.dart 1');
    print('');
    return;
  }

  final round = int.tryParse(args[0]);
  if (round == null || round < 1 || round > 4) {
    print('❌ 無效的輪次選擇: ${args[0]}');
    print('   請選擇 1-4');
    return;
  }

  // 定義測試輪次
  final testRounds = {
    1: {
      'name': '第一輪: 生日快樂.mid (單音無伴奏+短時常)',
      'midi': 'assets/test_voice/生日快樂.mid',
      'description': '簡單曲目 - 25音符, ~17秒',
      'wavs': [
        {'path': 'assets/test_voice/生日快樂(midi轉檔).wav', 'name': '生日快樂(midi轉檔)', 'expect': 'PASS'},
        {'path': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '生日快樂(手機環境錄製)', 'expect': 'PASS'},
        {'path': 'assets/test_voice/生日快樂(電腦環境錄製).wav', 'name': '生日快樂(電腦環境錄製)', 'expect': 'PASS'},
        {'path': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '小星星(手機環境錄製)', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '名偵探柯南(手機環境錄製)', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '測試音檔(手機環境錄製)', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'expect': 'FAIL'},
      ],
    },
    2: {
      'name': '第二輪: 測試音檔.mid (單音無伴奏+中時常)',
      'midi': 'assets/test_voice/測試音檔.mid',
      'description': '單音曲目 - 94音符, ~34秒',
      'wavs': [
        {'path': 'assets/test_voice/測試音檔(midi轉檔).wav', 'name': '測試音檔(midi轉檔)', 'expect': 'PASS'},
        {'path': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '測試音檔(手機環境錄製)', 'expect': 'PASS'},
        {'path': 'assets/test_voice/測試音檔(電腦環境錄製).wav', 'name': '測試音檔(電腦環境錄製)', 'expect': 'PASS'},
        {'path': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '小星星(手機環境錄製)', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '名偵探柯南(手機環境錄製)', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '生日快樂(手機環境錄製)', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'expect': 'FAIL'},
      ],
    },
    3: {
      'name': '第三輪: 小星星.mid (有伴奏+中時常)',
      'midi': 'assets/test_voice/小星星.mid',
      'description': '中級曲目 - 147音符, ~27秒',
      'wavs': [
        {'path': 'assets/test_voice/小星星(midi轉檔).wav', 'name': '小星星(midi轉檔)', 'expect': 'PASS'},
        {'path': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '小星星(手機環境錄製)', 'expect': 'PASS'},
        {'path': 'assets/test_voice/小星星(電腦環境錄製).wav', 'name': '小星星(電腦環境錄製)', 'expect': 'PASS'},
        {'path': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '測試音檔(手機環境錄製)', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '名偵探柯南(手機環境錄製)', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '生日快樂(手機環境錄製)', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'expect': 'FAIL'},
      ],
    },
    4: {
      'name': '第四輪: 名偵探柯南.mid (旋律複雜+曲速極快+長時常)',
      'midi': 'assets/test_voice/名偵探柯南.mid',
      'description': '專家級曲目 - 1431音符, ~164秒',
      'wavs': [
        {'path': 'assets/test_voice/名偵探柯南(midi轉檔).wav', 'name': '名偵探柯南(midi轉檔)', 'expect': 'PASS'},
        {'path': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '名偵探柯南(手機環境錄製)', 'expect': 'PASS'},
        {'path': 'assets/test_voice/名偵探柯南(電腦環境錄製).wav', 'name': '名偵探柯南(電腦環境錄製)', 'expect': 'PASS'},
        {'path': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '小星星(手機環境錄製)', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '測試音檔(手機環境錄製)', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '生日快樂(手機環境錄製)', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'expect': 'FAIL'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'expect': 'FAIL'},
      ],
    },
  };

  final testConfig = testRounds[round]!;
  final midiPath = testConfig['midi'] as String;
  final description = testConfig['description'] as String;
  final wavList = testConfig['wavs'] as List<Map<String, String>>;

  print('╔══════════════════════════════════════════════════════════════╗');
  print('║     🎚️ ${testConfig['name']}                    ║');
  print('╚══════════════════════════════════════════════════════════════╝');
  print('');
  print('📄 任務音檔: $midiPath');
  print('📊 曲目描述: $description');
  print('🎵 測試音檔數: ${wavList.length}');
  print('');

  // 檢查 MIDI 檔案
  if (!File(midiPath).existsSync()) {
    print('❌ MIDI 檔案不存在: $midiPath');
    return;
  }

  final analyzer = PerformanceAnalyzer();
  final results = <Map<String, dynamic>>[];
  final startTime = DateTime.now();

  int passCount = 0;
  int failCount = 0;
  int errorCount = 0;
  int correctPredictions = 0;

  // 執行測試
  for (int i = 0; i < wavList.length; i++) {
    final wavInfo = wavList[i];
    final wavPath = wavInfo['path']!;
    final wavName = wavInfo['name']!;
    final expect = wavInfo['expect']!;

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🧪 測試 ${i + 1}/${wavList.length}: $wavName');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📦 音檔: $wavPath');
    print('🎯 預期: $expect');
    print('');

    // 檢查 WAV 檔案
    if (!File(wavPath).existsSync()) {
      print('❌ WAV 檔案不存在');
      print('');
      errorCount++;
      results.add({
        'name': wavName,
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
      final isPassed = passRate >= 60.0;

      // 統計
      if (isPassed) {
        passCount++;
      } else {
        failCount++;
      }

      if ((expect == 'PASS' && isPassed) || (expect == 'FAIL' && !isPassed)) {
        correctPredictions++;
      }

      final statusIcon = isPassed ? '✅' : '❌';
      final matchIcon = (expect == 'PASS' && isPassed) || (expect == 'FAIL' && !isPassed) ? '✓' : '✗';

      print('【結果】$statusIcon ${isPassed ? "PASS" : "FAIL"} $matchIcon');
      print('  通過率: ${passRate.toStringAsFixed(1)}%');
      print('  F1 Score: ${(f1Score * 100).toStringAsFixed(1)}%');
      print('  Recall: ${(recall * 100).toStringAsFixed(1)}%');
      print('  Precision: ${(precision * 100).toStringAsFixed(1)}%');
      print('  正確音符: ${report.correctNotes}/${report.totalNotes}');
      print('  處理時間: ${report.processingTime.inMilliseconds}ms');
      print('');

      results.add({
        'name': wavName,
        'expect': expect,
        'status': isPassed ? 'PASS' : 'FAIL',
        'passRate': passRate,
        'f1Score': f1Score * 100,
        'recall': recall * 100,
        'precision': precision * 100,
        'correct': report.correctNotes,
        'total': report.totalNotes,
        'match': (expect == 'PASS' && isPassed) || (expect == 'FAIL' && !isPassed),
      });
    } catch (e) {
      print('❌ 分析錯誤: $e');
      print('');
      errorCount++;
      results.add({
        'name': wavName,
        'expect': expect,
        'status': 'ERROR',
        'error': e.toString(),
        'match': false,
      });
    }
  }

  final endTime = DateTime.now();
  final duration = endTime.difference(startTime);

  // 生成總結報告
  print('');
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║              📊 ${testConfig['name']} - 總結報告              ║');
  print('╚══════════════════════════════════════════════════════════════╝');
  print('');
  print('【測試概況】');
  print('  總測試數: ${wavList.length}');
  print('  通過: $passCount (${(passCount / wavList.length * 100).toStringAsFixed(1)}%)');
  print('  失敗: $failCount (${(failCount / wavList.length * 100).toStringAsFixed(1)}%)');
  print('  錯誤: $errorCount');
  print('  預測準確率: ${(correctPredictions / wavList.length * 100).toStringAsFixed(1)}% ($correctPredictions/${wavList.length})');
  print('  測試時長: ${duration.inSeconds} 秒');
  print('');

  // 計算正確演奏案例的平均指標
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

  // 詳細結果列表
  print('【詳細測試結果】');
  print('');
  for (final result in results) {
    final status = result['status'];
    final statusIcon = status == 'PASS' ? '✅' : (status == 'FAIL' ? '❌' : '⚠️');
    final expectMatch = result['match'] == true ? '✓' : '✗';

    print('${result['name']} ($expectMatch)');
    print('  狀態: $statusIcon $status (預期: ${result['expect']})');

    if (status == 'PASS' || status == 'FAIL') {
      print('  通過率: ${result['passRate'].toStringAsFixed(1)}% | '
            'F1: ${result['f1Score'].toStringAsFixed(1)}%');
      print('  Recall: ${result['recall'].toStringAsFixed(1)}% | '
            'Precision: ${result['precision'].toStringAsFixed(1)}%');
    } else if (status == 'ERROR') {
      print('  錯誤: ${result['error']}');
    }
    print('');
  }

  print('╔══════════════════════════════════════════════════════════════╗');
  print('║            🎉 ${testConfig['name']} 測試完成！                ║');
  print('╚══════════════════════════════════════════════════════════════╝');
  print('');
}

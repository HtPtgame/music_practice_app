import 'dart:io';
import 'dart:async';
import 'lib/services/audio_analysis/performance_analyzer.dart';

/// 分輪執行測試 - 避免長時間運行中斷
/// 每輪測試完立即顯示結果，避免被中斷
void main(List<String> args) async {
  // 可指定只測試某一輪: dart test_by_rounds.dart 1
  final targetRound = args.isNotEmpty ? int.tryParse(args[0]) : null;

  print('╔══════════════════════════════════════════════════════════════╗');
  print('║     🎵 分輪測試 (energyThreshold = 0.38)                    ║');
  print('╚══════════════════════════════════════════════════════════════╝\n');

  if (targetRound != null) {
    print('📍 僅執行第 $targetRound 輪測試\n');
  }

  final rounds = _getRounds();

  for (var i = 0; i < rounds.length; i++) {
    if (targetRound != null && i + 1 != targetRound) continue;

    final round = rounds[i];
    print('┌────────────────────────────────────────────────────────────┐');
    print('│ 第${i + 1}輪：${round['name']} - ${round['desc']}');
    print('└────────────────────────────────────────────────────────────┘');

    await _runRound(round);
    
    print(''); // 輪次間隔
  }

  print('✅ 測試完成！\n');
}

Future<void> _runRound(Map<String, dynamic> round) async {
  final midiPath = round['midi'] as String;
  final tests = round['tests'] as List<Map<String, dynamic>>;

  var passed = 0;
  var total = tests.length;

  for (var test in tests) {
    final wavPath = test['wav'] as String;
    final name = test['name'] as String;
    final type = test['type'] as String;
    final target = test['target'] as int;

    if (!File(wavPath).existsSync()) {
      print('  ⏭️  ${name.padRight(20)} - 檔案不存在');
      total--;
      continue;
    }

    try {
      final analyzer = PerformanceAnalyzer();
      late dynamic report;

      // 靜默執行
      await runZoned(
        () async {
          report = await analyzer.analyze(wavPath, midiPath);
        },
        zoneSpecification: ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String line) {},
        ),
      );

      final recall = (report.recall as double) * 100;
      final correct = report.confusionMatrix?.truePositive ?? 0;
      final totalNotes = report.totalNotes as int;

      bool isPassed = false;
      String emoji = '';
      
      if (type == 'correct') {
        isPassed = recall >= target;
        emoji = '📗';
      } else if (type == 'wrong') {
        isPassed = recall <= target;
        emoji = '📙';
      } else {
        isPassed = recall <= target;
        emoji = '📕';
      }
      
      if (isPassed) passed++;

      final status = isPassed ? '✅' : '❌';
      final op = type == 'correct' ? '≥' : '≤';
      
      print('  $emoji $status ${name.padRight(20)} │ ${recall.toStringAsFixed(1).padLeft(5)}% (目標$op$target%) │ $correct/$totalNotes');
    } catch (e) {
      print('  ❌ ${name.padRight(20)} - 錯誤: $e');
      total--;
    }
  }

  print('\n  通過率: $passed/$total (${(passed / total * 100).toStringAsFixed(1)}%)');
}

List<Map<String, dynamic>> _getRounds() {
  return [
    {
      'name': '生日快樂',
      'desc': '單音無伴奏 + 短時長',
      'midi': 'assets/test_voice/生日快樂.mid',
      'tests': [
        {'wav': 'assets/test_voice/生日快樂(midi轉檔).wav', 'name': 'MIDI轉檔', 'type': 'correct', 'target': 95},
        {'wav': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '手機錄製', 'type': 'correct', 'target': 85},
        {'wav': 'assets/test_voice/生日快樂(電腦環境錄製).wav', 'name': '電腦錄製', 'type': 'correct', 'target': 85},
        {'wav': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '錯誤:小星星', 'type': 'wrong', 'target': 30},
        {'wav': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '錯誤:柯南', 'type': 'wrong', 'target': 30},
        {'wav': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '錯誤:測試音檔', 'type': 'wrong', 'target': 30},
        {'wav': 'assets/test_voice/環境背景.wav', 'name': '噪音:背景1', 'type': 'noise', 'target': 5},
        {'wav': 'assets/test_voice/環境背景2.wav', 'name': '噪音:背景2', 'type': 'noise', 'target': 5},
      ],
    },
    {
      'name': '測試音檔',
      'desc': '單音無伴奏 + 中時長',
      'midi': 'assets/test_voice/測試音檔.mid',
      'tests': [
        {'wav': 'assets/test_voice/測試音檔(midi轉檔).wav', 'name': 'MIDI轉檔', 'type': 'correct', 'target': 95},
        {'wav': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '手機錄製', 'type': 'correct', 'target': 85},
        {'wav': 'assets/test_voice/測試音檔(電腦環境錄製).wav', 'name': '電腦錄製', 'type': 'correct', 'target': 85},
        {'wav': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '錯誤:小星星', 'type': 'wrong', 'target': 30},
        {'wav': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '錯誤:柯南', 'type': 'wrong', 'target': 30},
        {'wav': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '錯誤:生日快樂', 'type': 'wrong', 'target': 30},
        {'wav': 'assets/test_voice/環境背景.wav', 'name': '噪音:背景1', 'type': 'noise', 'target': 5},
        {'wav': 'assets/test_voice/環境背景2.wav', 'name': '噪音:背景2', 'type': 'noise', 'target': 5},
      ],
    },
    {
      'name': '小星星',
      'desc': '有伴奏 + 中時長',
      'midi': 'assets/test_voice/小星星.mid',
      'tests': [
        {'wav': 'assets/test_voice/小星星(midi轉檔).wav', 'name': 'MIDI轉檔', 'type': 'correct', 'target': 90},
        {'wav': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '手機錄製', 'type': 'correct', 'target': 80},
        {'wav': 'assets/test_voice/小星星(電腦環境錄製).wav', 'name': '電腦錄製', 'type': 'correct', 'target': 80},
        {'wav': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '錯誤:測試音檔', 'type': 'wrong', 'target': 30},
        {'wav': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '錯誤:柯南', 'type': 'wrong', 'target': 30},
        {'wav': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '錯誤:生日快樂', 'type': 'wrong', 'target': 30},
        {'wav': 'assets/test_voice/環境背景.wav', 'name': '噪音:背景1', 'type': 'noise', 'target': 5},
        {'wav': 'assets/test_voice/環境背景2.wav', 'name': '噪音:背景2', 'type': 'noise', 'target': 5},
      ],
    },
    {
      'name': '名偵探柯南',
      'desc': '旋律複雜 + 曲速極快 + 長時長',
      'midi': 'assets/test_voice/名偵探柯南.mid',
      'tests': [
        {'wav': 'assets/test_voice/名偵探柯南(midi轉檔).wav', 'name': 'MIDI轉檔', 'type': 'correct', 'target': 85},
        {'wav': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '手機錄製', 'type': 'correct', 'target': 75},
        {'wav': 'assets/test_voice/名偵探柯南(電腦環境錄製).wav', 'name': '電腦錄製', 'type': 'correct', 'target': 75},
        {'wav': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '錯誤:小星星', 'type': 'wrong', 'target': 30},
        {'wav': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '錯誤:測試音檔', 'type': 'wrong', 'target': 30},
        {'wav': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '錯誤:生日快樂', 'type': 'wrong', 'target': 30},
        {'wav': 'assets/test_voice/環境背景.wav', 'name': '噪音:背景1', 'type': 'noise', 'target': 5},
        {'wav': 'assets/test_voice/環境背景2.wav', 'name': '噪音:背景2', 'type': 'noise', 'target': 5},
      ],
    },
  ];
}

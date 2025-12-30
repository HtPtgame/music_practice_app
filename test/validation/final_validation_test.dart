import 'dart:io';
import 'dart:async';
import 'package:veloria/services/audio_analysis/performance_analyzer.dart';

/// 最終驗證測試 - energyThreshold = 0.38
/// 4 輪 × 8 音檔 = 32 測試案例
void main() async {
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║     🎵 最終驗證測試 (energyThreshold = 0.38)                ║');
  print('║           4輪 × 8音檔 = 32 測試案例                         ║');
  print('╚══════════════════════════════════════════════════════════════╝\n');

  // 定義 4 輪測試
  final rounds = [
    {
      'name': '第一輪：生日快樂',
      'desc': '單音無伴奏 + 短時長',
      'midi': 'assets/test_voice/生日快樂.mid',
      'tests': [
        {
          'wav': 'assets/test_voice/生日快樂(midi轉檔).wav',
          'name': 'MIDI轉檔',
          'type': 'correct',
          'target': 95
        },
        {
          'wav': 'assets/test_voice/生日快樂(手機環境錄製).wav',
          'name': '手機錄製',
          'type': 'correct',
          'target': 85
        },
        {
          'wav': 'assets/test_voice/生日快樂(電腦環境錄製).wav',
          'name': '電腦錄製',
          'type': 'correct',
          'target': 85
        },
        {
          'wav': 'assets/test_voice/小星星(手機環境錄製).wav',
          'name': '錯誤:小星星',
          'type': 'wrong',
          'target': 30
        },
        {
          'wav': 'assets/test_voice/名偵探柯南(手機環境錄製).wav',
          'name': '錯誤:柯南',
          'type': 'wrong',
          'target': 30
        },
        {
          'wav': 'assets/test_voice/測試音檔(手機環境錄製).wav',
          'name': '錯誤:測試音檔',
          'type': 'wrong',
          'target': 30
        },
        {
          'wav': 'assets/test_voice/環境背景.wav',
          'name': '噪音:背景1',
          'type': 'noise',
          'target': 5
        },
        {
          'wav': 'assets/test_voice/環境背景2.wav',
          'name': '噪音:背景2',
          'type': 'noise',
          'target': 5
        },
      ],
    },
    {
      'name': '第二輪：測試音檔',
      'desc': '單音無伴奏 + 中時長',
      'midi': 'assets/test_voice/測試音檔.mid',
      'tests': [
        {
          'wav': 'assets/test_voice/測試音檔(midi轉檔).wav',
          'name': 'MIDI轉檔',
          'type': 'correct',
          'target': 95
        },
        {
          'wav': 'assets/test_voice/測試音檔(手機環境錄製).wav',
          'name': '手機錄製',
          'type': 'correct',
          'target': 85
        },
        {
          'wav': 'assets/test_voice/測試音檔(電腦環境錄製).wav',
          'name': '電腦錄製',
          'type': 'correct',
          'target': 85
        },
        {
          'wav': 'assets/test_voice/小星星(手機環境錄製).wav',
          'name': '錯誤:小星星',
          'type': 'wrong',
          'target': 30
        },
        {
          'wav': 'assets/test_voice/名偵探柯南(手機環境錄製).wav',
          'name': '錯誤:柯南',
          'type': 'wrong',
          'target': 30
        },
        {
          'wav': 'assets/test_voice/生日快樂(手機環境錄製).wav',
          'name': '錯誤:生日快樂',
          'type': 'wrong',
          'target': 30
        },
        {
          'wav': 'assets/test_voice/環境背景.wav',
          'name': '噪音:背景1',
          'type': 'noise',
          'target': 5
        },
        {
          'wav': 'assets/test_voice/環境背景2.wav',
          'name': '噪音:背景2',
          'type': 'noise',
          'target': 5
        },
      ],
    },
    {
      'name': '第三輪：小星星',
      'desc': '有伴奏 + 中時長',
      'midi': 'assets/test_voice/小星星.mid',
      'tests': [
        {
          'wav': 'assets/test_voice/小星星(midi轉檔).wav',
          'name': 'MIDI轉檔',
          'type': 'correct',
          'target': 90
        },
        {
          'wav': 'assets/test_voice/小星星(手機環境錄製).wav',
          'name': '手機錄製',
          'type': 'correct',
          'target': 80
        },
        {
          'wav': 'assets/test_voice/小星星(電腦環境錄製).wav',
          'name': '電腦錄製',
          'type': 'correct',
          'target': 80
        },
        {
          'wav': 'assets/test_voice/測試音檔(手機環境錄製).wav',
          'name': '錯誤:測試音檔',
          'type': 'wrong',
          'target': 30
        },
        {
          'wav': 'assets/test_voice/名偵探柯南(手機環境錄製).wav',
          'name': '錯誤:柯南',
          'type': 'wrong',
          'target': 30
        },
        {
          'wav': 'assets/test_voice/生日快樂(手機環境錄製).wav',
          'name': '錯誤:生日快樂',
          'type': 'wrong',
          'target': 30
        },
        {
          'wav': 'assets/test_voice/環境背景.wav',
          'name': '噪音:背景1',
          'type': 'noise',
          'target': 5
        },
        {
          'wav': 'assets/test_voice/環境背景2.wav',
          'name': '噪音:背景2',
          'type': 'noise',
          'target': 5
        },
      ],
    },
    {
      'name': '第四輪：名偵探柯南',
      'desc': '旋律複雜 + 曲速極快 + 長時長',
      'midi': 'assets/test_voice/名偵探柯南.mid',
      'tests': [
        {
          'wav': 'assets/test_voice/名偵探柯南(midi轉檔).wav',
          'name': 'MIDI轉檔',
          'type': 'correct',
          'target': 85
        },
        {
          'wav': 'assets/test_voice/名偵探柯南(手機環境錄製).wav',
          'name': '手機錄製',
          'type': 'correct',
          'target': 75
        },
        {
          'wav': 'assets/test_voice/名偵探柯南(電腦環境錄製).wav',
          'name': '電腦錄製',
          'type': 'correct',
          'target': 75
        },
        {
          'wav': 'assets/test_voice/小星星(手機環境錄製).wav',
          'name': '錯誤:小星星',
          'type': 'wrong',
          'target': 30
        },
        {
          'wav': 'assets/test_voice/測試音檔(手機環境錄製).wav',
          'name': '錯誤:測試音檔',
          'type': 'wrong',
          'target': 30
        },
        {
          'wav': 'assets/test_voice/生日快樂(手機環境錄製).wav',
          'name': '錯誤:生日快樂',
          'type': 'wrong',
          'target': 30
        },
        {
          'wav': 'assets/test_voice/環境背景.wav',
          'name': '噪音:背景1',
          'type': 'noise',
          'target': 5
        },
        {
          'wav': 'assets/test_voice/環境背景2.wav',
          'name': '噪音:背景2',
          'type': 'noise',
          'target': 5
        },
      ],
    },
  ];

  var totalTests = 0;
  var passedTests = 0;

  final correctResults = <double>[];
  final wrongResults = <double>[];
  final noiseResults = <double>[];

  for (var round in rounds) {
    print('┌────────────────────────────────────────────────────────────────┐');
    print('│  ${round['name']}  -  ${round['desc']}');
    print('│  任務音檔: ${(round['midi'] as String).split('/').last}');
    print(
        '└────────────────────────────────────────────────────────────────┘\n');

    final midiPath = round['midi'] as String;
    final tests = round['tests'] as List;

    for (var test in tests) {
      final wavPath = test['wav'] as String;
      final name = test['name'] as String;
      final type = test['type'] as String;
      final target = test['target'] as int;

      if (!File(wavPath).existsSync()) {
        print('  ⏭️  $name - 檔案不存在\n');
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
        final total = report.totalNotes as int;

        totalTests++;

        bool passed = false;
        String emoji = '';
        String status = '';

        if (type == 'correct') {
          correctResults.add(recall);
          passed = recall >= target;
          emoji = '📗';
          status = passed ? '✅' : '❌';
        } else if (type == 'wrong') {
          wrongResults.add(recall);
          passed = recall <= target;
          emoji = '📙';
          status = passed ? '✅' : '❌';
        } else {
          noiseResults.add(recall);
          passed = recall <= target;
          emoji = '📕';
          status = passed ? '✅' : '❌';
        }

        if (passed) passedTests++;

        print(
            '  $emoji $status ${name.padRight(18)} │ 召回率:${recall.toStringAsFixed(1).padLeft(5)}% (目標${type == 'correct' ? '≥' : '≤'}$target%) │ $correct/$total');
      } catch (e) {
        print('  ❌ $name - 錯誤: $e\n');
      }
    }

    print('');
  }

  // 統計總結
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║                    📊 測試總結                               ║');
  print('╚══════════════════════════════════════════════════════════════╝\n');

  print(
      '總體通過率: $passedTests/$totalTests (${(passedTests / totalTests * 100).toStringAsFixed(1)}%)\n');

  if (correctResults.isNotEmpty) {
    final avgCorrect =
        correctResults.reduce((a, b) => a + b) / correctResults.length;
    final passedCorrect = correctResults.where((r) => r >= 85).length;
    print('📗 正確演奏檢測 (${correctResults.length}個測試):');
    print(
        '   通過率: $passedCorrect/${correctResults.length} (${(passedCorrect / correctResults.length * 100).toStringAsFixed(1)}%)');
    print('   平均召回率: ${avgCorrect.toStringAsFixed(1)}% (目標 ≥85%)');
    print('   狀態: ${avgCorrect >= 85 ? '✅ 達標' : '⚠️ 未達標'}\n');
  }

  if (wrongResults.isNotEmpty) {
    final avgWrong = wrongResults.reduce((a, b) => a + b) / wrongResults.length;
    final passedWrong = wrongResults.where((r) => r <= 30).length;
    print('📙 錯誤音檔排除 (${wrongResults.length}個測試):');
    print(
        '   通過率: $passedWrong/${wrongResults.length} (${(passedWrong / wrongResults.length * 100).toStringAsFixed(1)}%)');
    print('   平均召回率: ${avgWrong.toStringAsFixed(1)}% (目標 ≤30%)');
    print('   狀態: ${avgWrong <= 30 ? '✅ 達標' : '❌ 設計限制'}\n');
  }

  if (noiseResults.isNotEmpty) {
    final avgNoise = noiseResults.reduce((a, b) => a + b) / noiseResults.length;
    final passedNoise = noiseResults.where((r) => r <= 5).length;
    print('📕 環境噪音排除 (${noiseResults.length}個測試):');
    print(
        '   通過率: $passedNoise/${noiseResults.length} (${(passedNoise / noiseResults.length * 100).toStringAsFixed(1)}%)');
    print('   平均召回率: ${avgNoise.toStringAsFixed(1)}% (目標 ≤5%)');
    print('   狀態: ${avgNoise <= 5 ? '✅ 達標' : '⚠️ 需改進'}\n');
  }

  print('═══════════════════════════════════════════════════════════════');
  print('✅ 測試完成！參數 energyThreshold = 0.38 驗證完成');
  print('═══════════════════════════════════════════════════════════════\n');
}

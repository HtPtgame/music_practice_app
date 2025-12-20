import 'dart:io';
import 'dart:async';
import 'package:music_practice_app/services/audio_analysis/performance_analyzer.dart';

/// 參數掃描測試 - 找出最佳 energyThreshold
///
/// 測試範圍: 0.30 - 0.50 (步進 0.02)
/// 評估指標: 正確演奏召回率 + 噪音誤判率
void main() async {
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║        🔬 參數掃描測試 - energyThreshold 優化              ║');
  print('╚══════════════════════════════════════════════════════════════╝\n');

  const midiPath = 'assets/test_voice/生日快樂.mid';

  final tests = [
    // 正確演奏 (期望高召回率)
    {
      'wav': 'assets/test_voice/生日快樂(midi轉檔).wav',
      'name': 'MIDI轉檔',
      'type': 'correct',
      'target': 95.0
    },
    {
      'wav': 'assets/test_voice/生日快樂(手機環境錄製).wav',
      'name': '手機錄製',
      'type': 'correct',
      'target': 85.0
    },
    {
      'wav': 'assets/test_voice/生日快樂(電腦環境錄製).wav',
      'name': '電腦錄製',
      'type': 'correct',
      'target': 85.0
    },

    // 環境噪音 (期望極低召回率)
    {
      'wav': 'assets/test_voice/環境背景.wav',
      'name': '噪音:背景1',
      'type': 'noise',
      'target': 5.0
    },
    {
      'wav': 'assets/test_voice/環境背景2.wav',
      'name': '噪音:背景2',
      'type': 'noise',
      'target': 5.0
    },
  ];

  // 測試不同的 energyThreshold 值 (擴大範圍)
  final thresholds = [
    0.25,
    0.30,
    0.33,
    0.35,
    0.38,
    0.40,
    0.45,
    0.50,
    0.55,
    0.60
  ];

  print('測試範圍: ${thresholds.first} - ${thresholds.last}');
  print('測試案例: ${tests.length} 個\n');
  print('┌─────────┬──────────┬──────────┬──────────┬──────────┬──────────┐');
  print('│ 閾值     │ MIDI轉檔 │ 手機錄製 │ 電腦錄製 │ 噪音1    │ 噪音2    │');
  print('├─────────┼──────────┼──────────┼──────────┼──────────┼──────────┤');

  for (var threshold in thresholds) {
    final results = <double>[];

    for (var test in tests) {
      final wavPath = test['wav'] as String;

      if (!File(wavPath).existsSync()) {
        results.add(-1);
        continue;
      }

      try {
        // 修改當前閾值 (臨時修改檔案)
        await _setThreshold(threshold);

        final analyzer = PerformanceAnalyzer();
        late dynamic report;

        await runZoned(
          () async {
            report = await analyzer.analyze(wavPath, midiPath);
          },
          zoneSpecification: ZoneSpecification(
            print: (Zone self, ZoneDelegate parent, Zone zone, String line) {},
          ),
        );

        final recall = (report.recall as double) * 100;
        results.add(recall);

        // 小延遲避免檔案鎖定
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        results.add(-1);
      }
    }

    // 格式化輸出
    final midi =
        results[0] >= 0 ? '${results[0].toStringAsFixed(1)}%' : '  -  ';
    final phone =
        results[1] >= 0 ? '${results[1].toStringAsFixed(1)}%' : '  -  ';
    final pc = results[2] >= 0 ? '${results[2].toStringAsFixed(1)}%' : '  -  ';
    final noise1 =
        results[3] >= 0 ? '${results[3].toStringAsFixed(1)}%' : '  -  ';
    final noise2 =
        results[4] >= 0 ? '${results[4].toStringAsFixed(1)}%' : '  -  ';

    // 計算評分: 正確演奏高 + 噪音低 = 好
    var score = 0.0;
    if (results[0] >= 0) score += (results[0] / 100) * 1.0; // MIDI 權重 1.0
    if (results[1] >= 0) score += (results[1] / 100) * 0.9; // 手機 權重 0.9
    if (results[2] >= 0) score += (results[2] / 100) * 0.8; // 電腦 權重 0.8
    if (results[3] >= 0) score -= (results[3] / 100) * 1.5; // 噪音1 懲罰 1.5
    if (results[4] >= 0) score -= (results[4] / 100) * 1.5; // 噪音2 懲罰 1.5

    final scoreStr = score >= 0 ? score.toStringAsFixed(2) : '0.00';
    final marker = score >= 2.0 ? ' ⭐' : (score >= 1.5 ? ' ✓' : '');

    print(
        '│ ${threshold.toStringAsFixed(2).padRight(7)} │ ${midi.padLeft(8)} │ ${phone.padLeft(8)} │ ${pc.padLeft(8)} │ ${noise1.padLeft(8)} │ ${noise2.padLeft(8)} │ $scoreStr$marker');
  }

  print('└─────────┴──────────┴──────────┴──────────┴──────────┴──────────┘\n');

  print('📊 評分公式: MIDI×1.0 + 手機×0.9 + 電腦×0.8 - 噪音1×1.5 - 噪音2×1.5');
  print('⭐ 評分 ≥2.0 (優秀) | ✓ 評分 ≥1.5 (良好)\n');

  print('✅ 測試完成\n');
  print('💡 建議: 選擇評分最高且正確演奏召回率 ≥85% 的閾值');
}

/// 臨時修改 energyThreshold (修改檔案)
Future<void> _setThreshold(double threshold) async {
  final files = [
    'lib/services/audio_analysis/note_detector_service.dart',
    'lib/services/audio_analysis/note_verification_service_impl.dart',
  ];

  for (var filePath in files) {
    final file = File(filePath);
    if (!file.existsSync()) continue;

    var content = await file.readAsString();

    // 替換 minEnergyThreshold 或 energyThreshold
    content = content.replaceAllMapped(
      RegExp(r'(minEnergyThreshold|energyThreshold)\s*=\s*0\.\d+'),
      (match) => '${match.group(1)} = ${threshold.toStringAsFixed(2)}',
    );

    await file.writeAsString(content);
  }
}

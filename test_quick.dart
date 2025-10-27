import 'dart:io';
import 'dart:async';
import 'lib/services/audio_analysis/performance_analyzer.dart';

/// 快速測試 - 只執行第一輪
void main() async {
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║              🎵 快速測試 - 第一輪：生日快樂                 ║');
  print('╚══════════════════════════════════════════════════════════════╝\n');

  final midiPath = 'assets/test_voice/生日快樂.mid';
  
  final tests = [
    // 正確演奏
    {'wav': 'assets/test_voice/生日快樂(midi轉檔).wav', 'name': 'MIDI轉檔', 'type': 'correct'},
    {'wav': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '手機錄製', 'type': 'correct'},
    
    // 錯誤音檔
    {'wav': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '錯誤:小星星', 'type': 'wrong'},
    
    // 環境噪音
    {'wav': 'assets/test_voice/環境背景.wav', 'name': '噪音:背景1', 'type': 'noise'},
  ];

  print('正在測試...\n');
  
  for (var test in tests) {
    final wavPath = test['wav'] as String;
    final name = test['name'] as String;
    final type = test['type'] as String;
    
    if (!File(wavPath).existsSync()) {
      print('⏭️  $name - 檔案不存在');
      continue;
    }
    
    try {
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
      
      final recall = ((report.recall as double) * 100).toStringAsFixed(1);
      final correct = report.confusionMatrix?.truePositive ?? 0;
      final total = report.totalNotes as int;
      
      String emoji = '';
      if (type == 'correct') {
        emoji = '📗';
      } else if (type == 'wrong') {
        emoji = '📙';
      } else {
        emoji = '📕';
      }
      
      print('$emoji $name: 召回率=$recall%, 檢測=$correct/$total');
    } catch (e) {
      print('❌ $name - 錯誤: $e');
    }
  }
  
  print('\n✅ 測試完成');
}

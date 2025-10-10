/// 快速測試名偵探柯南
import 'dart:io';
import 'lib/services/audio_analysis/performance_analyzer.dart';

void main() async {
  print('🎵 測試: 名偵探柯南(環境)');
  print('');
  
  final analyzer = PerformanceAnalyzer();
  
  try {
    final report = await analyzer.analyze(
      'assets/test_voice/名偵探柯南(環境).wav',
      'assets/test_voice/名偵探柯南.mid',
    );
    
    print('📊 結果:');
    print('   總音符: ${report.totalNotes}');
    print('   檢測到: ${report.correctNotes}');
    print('   漏音: ${report.missedNotes}');
    print('   準確率: ${report.accuracy.toStringAsFixed(1)}%');
    print('   評級: ${report.grade}');
    print('   處理時間: ${report.processingTime}ms');
    print('');
    
  } catch (e) {
    print('❌ 錯誤: $e');
  }
}

import 'dart:io';
import 'lib/services/audio_analysis/performance_analyzer.dart';

/// Week 3 整合測試
void main() async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║       🎼 Week 3: 錯誤分類與整合測試                      ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');
  
  // 配置文件路徑
  const midiPath = 'assets/測試.mid';
  const wavPath = 'performance.wav';
  
  // 檢查文件
  print('📂 檢查文件...');
  final midiFile = File(midiPath);
  final wavFile = File(wavPath);
  
  if (!await midiFile.exists()) {
    print('❌ 找不到 MIDI: $midiPath');
    return;
  }
  print('   ✅ MIDI: $midiPath');
  
  if (!await wavFile.exists()) {
    print('   ⚠️  找不到 WAV: $wavPath');
    print('');
    print('💡 請錄製一個演奏文件 (WAV 格式, 44100Hz)');
    print('   或使用測試音訊生成器 (下一步將實現)');
    return;
  }
  print('   ✅ WAV: $wavPath');
  print('');
  
  try {
    // 創建分析器
    final analyzer = PerformanceAnalyzer();
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🚀 開始分析...');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    
    // 執行分析 (帶進度條)
    final report = await analyzer.analyze(
      wavPath,
      midiPath,
      onProgress: (progress) {
        final percent = (progress * 100).toStringAsFixed(0);
        final bar = '█' * (progress * 30).round();
        final empty = '░' * (30 - (progress * 30).round());
        print('\r   進度: $bar$empty $percent%');
      },
    );
    
    print('');
    print('╔═══════════════════════════════════════════════════════════╗');
    print('║                     📊 分析報告                           ║');
    print('╚═══════════════════════════════════════════════════════════╝');
    print('');
    
    // 基本統計
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📈 基本統計');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    print('   總音符數: ${report.totalNotes}');
    print('   ✅ 正確: ${report.correctNotes}');
    print('   ❌ 漏音: ${report.missedNotes}');
    print('   🔴 錯音: ${report.wrongNotes}');
    print('   ⏪ 搶拍: ${report.earlyNotes}');
    print('   ⏩ 拖拍: ${report.lateNotes}');
    print('');
    print('   準確率: ${(report.accuracy * 100).toStringAsFixed(1)}%');
    print('   節奏分數: ${report.rhythmScore.toStringAsFixed(1)}');
    print('   總分: ${report.overallScore.toStringAsFixed(1)}');
    print('   處理時間: ${report.processingTime.inMilliseconds}ms');
    print('');
    
    // 評級
    final gradeIcon = switch (report.grade) {
      'A' => '🏆',
      'B' => '🥈',
      'C' => '🥉',
      'D' => '📝',
      _ => '💪',
    };
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎯 評級');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    print('   $gradeIcon 評級: ${report.grade}');
    print('');
    
    // 錯誤詳情
    if (report.errors.isNotEmpty) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('⚠️  錯誤詳情 (前 20 個)');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      
      for (int i = 0; i < report.errors.length && i < 20; i++) {
        final error = report.errors[i];
        final icon = switch (error.type.toString().split('.').last) {
          'missedNote' => '❌',
          'wrongNote' => '🔴',
          'earlyTiming' => '⏪',
          'lateTiming' => '⏩',
          _ => '⚠️',
        };
        
        print('   ${(i + 1).toString().padLeft(2)}. $icon ${error.message}');
      }
      
      if (report.errors.length > 20) {
        print('   ... 還有 ${report.errors.length - 20} 個錯誤');
      }
      print('');
    }
    
    // 建議
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('💡 練習建議');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    
    if (report.accuracy >= 0.95) {
      print('   🌟 演奏非常出色!可以嘗試更難的曲目。');
    } else if (report.accuracy >= 0.85) {
      print('   👍 演奏很好!繼續保持,注意錯誤的地方。');
    } else if (report.accuracy >= 0.75) {
      print('   📝 建議重點練習錯誤較多的段落。');
    } else if (report.accuracy >= 0.65) {
      print('   💪 建議放慢速度,確保每個音符都準確。');
    } else {
      print('   🎯 建議分段練習,每次只練習幾小節。');
      print('   🎼 確保每個音符都能清晰彈出再加快速度。');
    }
    
    if (report.missedNotes > 0) {
      print('   ❌ 有 ${report.missedNotes} 個漏音,注意音符的清晰度');
    }
    
    if (report.earlyNotes + report.lateNotes > report.totalNotes * 0.1) {
      print('   🎵 節奏不夠穩定,建議使用節拍器練習');
    }
    print('');
    
    print('╔═══════════════════════════════════════════════════════════╗');
    print('║                  ✅ Week 3 測試完成!                      ║');
    print('╚═══════════════════════════════════════════════════════════╝');
    
  } catch (e, stackTrace) {
    print('');
    print('❌ 測試失敗: $e');
    print('');
    print(stackTrace);
  }
}

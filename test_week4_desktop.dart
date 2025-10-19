/// 階段 2.4 測試腳本 - 使用桌面的 test.wav
/// 
/// 測試完整的分析流程:
/// 1. 解析 MIDI 標準答案 (assets/測試.mid)
/// 2. 分析 WAV 錄音 (Desktop/test.wav)
/// 3. 驗證音符準確性
/// 4. 分類錯誤類型
/// 5. 生成完整報告
library;

import 'dart:io';
import 'package:music_practice_app/services/audio_analysis/performance_analyzer.dart';

void main() async {
  print('\n${'═' * 60}');
  print('階段 2.4 完整分析測試 - 桌面 test.wav');
  print('═' * 60 + '\n');

  // 檔案路徑
  final desktopPath = Platform.environment['USERPROFILE']! + r'\Desktop';
  final wavPath = '$desktopPath\\test.wav';
  const midiPath = 'assets/測試.mid';

  // 檢查檔案
  print('📁 檢查測試檔案...');
  
  final wavFile = File(wavPath);
  if (!await wavFile.exists()) {
    print('❌ 錯誤: 找不到 $wavPath');
    return;
  }
  final wavSize = await wavFile.length();
  print('✅ WAV 檔案: $wavPath');
  print('   大小: ${(wavSize / 1024 / 1024).toStringAsFixed(2)} MB\n');

  final midiFile = File(midiPath);
  if (!await midiFile.exists()) {
    print('❌ 錯誤: 找不到 $midiPath');
    return;
  }
  final midiSize = await midiFile.length();
  print('✅ MIDI 檔案: $midiPath');
  print('   大小: ${(midiSize / 1024).toStringAsFixed(2)} KB\n');

  // 創建分析器
  print('🔧 初始化 PerformanceAnalyzer...\n');
  final analyzer = PerformanceAnalyzer();

  // 進度顯示
  var lastProgress = 0.0;
  void showProgress(double progress) {
    final percent = (progress * 100).toInt();
    if (percent != lastProgress.toInt()) {
      final stage = _getStageDescription(progress);
      print('[${'█' * (percent ~/ 5)}${' ' * (20 - percent ~/ 5)}] $percent% - $stage');
      lastProgress = progress;
    }
  }

  // 執行分析
  print('🎯 開始分析...\n');
  final stopwatch = Stopwatch()..start();

  try {
    final report = await analyzer.analyze(
      wavPath,
      midiPath,
      onProgress: showProgress,
    );

    stopwatch.stop();

    // 顯示結果
    print('\n${'═' * 60}');
    print('分析完成!');
    print('═' * 60 + '\n');

    print('⏱️  處理時間: ${stopwatch.elapsedMilliseconds}ms\n');

    print('📊 統計數據:');
    print('─' * 60);
    print('  總音符數: ${report.totalNotes}');
    print('  ✅ 正確: ${report.correctNotes} (${(report.accuracy * 100).toStringAsFixed(1)}%)');
    print('  ❌ 漏音: ${report.missedNotes}');
    print('  🔴 錯音: ${report.wrongNotes}');
    print('  ⏪ 搶拍: ${report.earlyNotes}');
    print('  ⏩ 拖拍: ${report.lateNotes}');
    print('');

    print('🎯 評分:');
    print('─' * 60);
    print('  準確率: ${(report.accuracy * 100).toStringAsFixed(1)}%');
    print('  節奏分數: ${report.rhythmScore.toStringAsFixed(1)}');
    print('  總評分數: ${report.overallScore.toStringAsFixed(1)} / 100');
    print('  評級: ${report.grade}');
    print('');

    // 顯示錯誤詳情 (前10個)
    if (report.errors.isNotEmpty) {
      print('⚠️  錯誤詳情 (前10個):');
      print('─' * 60);
      final topErrors = report.errors.take(10);
      for (int i = 0; i < topErrors.length; i++) {
        final error = topErrors.elementAt(i);
        print('  ${i + 1}. ${error.toString()}');
      }
      if (report.errors.length > 10) {
        print('  ... 還有 ${report.errors.length - 10} 個錯誤');
      }
      print('');
    }

    // 練習建議
    final suggestions = report.generateSuggestions();
    if (suggestions.isNotEmpty) {
      print('💡 練習建議:');
      print('─' * 60);
      for (final suggestion in suggestions) {
        print('  • $suggestion');
      }
      print('');
    }

    // 評級顏色
    print('🏆 評級說明:');
    print('─' * 60);
    print('  S級 (95-100): 完美演奏! 🌟');
    print('  A級 (90-94):  優秀表現! ⭐');
    print('  B級 (80-89):  良好水準 ✨');
    print('  C級 (70-79):  及格程度 💫');
    print('  D級 (60-69):  需要加強 ⚡');
    print('  F級 (0-59):   需多練習 💪');
    print('');

    print('═' * 60);
    print('測試完成! 🎉');
    print('═' * 60 + '\n');

  } catch (e, stackTrace) {
    stopwatch.stop();
    print('\n❌ 分析失敗!');
    print('錯誤: $e');
    print('\n堆疊追蹤:');
    print(stackTrace);
  }
}

String _getStageDescription(double progress) {
  if (progress < 0.2) {
    return '解析 MIDI 標準答案...';
  } else if (progress < 0.6) {
    return '分析 WAV 頻譜...';
  } else if (progress < 0.8) {
    return '驗證音符準確性...';
  } else if (progress < 1.0) {
    return '分類錯誤類型...';
  } else {
    return '生成報告...';
  }
}

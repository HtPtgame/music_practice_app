import 'performance_error.dart';

/// 分析報告
class AnalysisReport {
  /// 總音符數
  final int totalNotes;
  
  /// 正確音符數
  final int correctNotes;
  
  /// 錯音數
  final int wrongNotes;
  
  /// 漏音數
  final int missedNotes;
  
  /// 搶拍數
  final int earlyNotes;
  
  /// 拖拍數
  final int lateNotes;
  
  /// 所有錯誤詳情
  final List<PerformanceError> errors;
  
  /// 處理時間
  final Duration processingTime;
  
  /// 時間對齊結果
  final double timeOffset;

  AnalysisReport({
    required this.totalNotes,
    required this.correctNotes,
    required this.wrongNotes,
    required this.missedNotes,
    required this.earlyNotes,
    required this.lateNotes,
    required this.errors,
    required this.processingTime,
    this.timeOffset = 0.0,
  });

  /// 音準正確率 (0-1)
  double get accuracy {
    if (totalNotes == 0) return 0;
    return correctNotes / totalNotes;
  }

  /// 節奏分數 (0-100)
  double get rhythmScore {
    if (totalNotes == 0) return 0;
    final timingErrors = earlyNotes + lateNotes;
    final timingAccuracy = 1 - (timingErrors / totalNotes);
    return (timingAccuracy * 100).clamp(0, 100);
  }

  /// 總分 (0-100)
  double get overallScore {
    // 音準權重 70%, 節奏權重 30%
    return (accuracy * 70 + rhythmScore * 0.3).clamp(0, 100);
  }

  /// 評級 (A-F)
  String get grade {
    if (overallScore >= 90) return 'A';
    if (overallScore >= 80) return 'B';
    if (overallScore >= 70) return 'C';
    if (overallScore >= 60) return 'D';
    return 'F';
  }

  /// 錯誤分布 (用於圖表)
  Map<String, int> get errorDistribution => {
    '正確': correctNotes,
    '錯音': wrongNotes,
    '漏音': missedNotes,
    '搶拍': earlyNotes,
    '拖拍': lateNotes,
  };

  /// 生成文字報告
  String generateTextReport() {
    final sb = StringBuffer();
    sb.writeln('═══ 演奏分析報告 ═══');
    sb.writeln();
    sb.writeln('📊 統計數據:');
    sb.writeln('  總音符數: $totalNotes');
    sb.writeln('  正確: $correctNotes (${(accuracy * 100).toStringAsFixed(1)}%)');
    sb.writeln('  錯音: $wrongNotes');
    sb.writeln('  漏音: $missedNotes');
    sb.writeln('  節奏問題: ${earlyNotes + lateNotes} (搶拍:$earlyNotes, 拖拍:$lateNotes)');
    sb.writeln();
    sb.writeln('🎯 評分:');
    sb.writeln('  音準分數: ${(accuracy * 100).toStringAsFixed(1)}');
    sb.writeln('  節奏分數: ${rhythmScore.toStringAsFixed(1)}');
    sb.writeln('  總評分數: ${overallScore.toStringAsFixed(1)} ($grade)');
    sb.writeln();
    
    if (timeOffset.abs() > 0.01) {
      sb.writeln('⏱️  整體時間偏移: ${(timeOffset * 1000).toStringAsFixed(0)}ms');
      sb.writeln();
    }
    
    if (errors.isNotEmpty) {
      sb.writeln('❌ 錯誤詳情 (前10項):');
      final topErrors = errors.take(10);
      for (int i = 0; i < topErrors.length; i++) {
        final error = topErrors.elementAt(i);
        sb.writeln('  ${i + 1}. $error');
      }
      if (errors.length > 10) {
        sb.writeln('  ... 還有 ${errors.length - 10} 個錯誤');
      }
      sb.writeln();
    }
    
    sb.writeln('⚡ 處理時間: ${processingTime.inMilliseconds}ms');
    
    return sb.toString();
  }

  /// 生成建議
  List<String> generateSuggestions() {
    final suggestions = <String>[];
    
    if (accuracy < 0.6) {
      suggestions.add('🎹 音準需要加強練習,建議放慢速度逐個音符確認');
    } else if (accuracy < 0.8) {
      suggestions.add('🎵 音準基本正確,但仍有進步空間');
    } else {
      suggestions.add('⭐ 音準表現優秀!');
    }
    
    if (rhythmScore < 60) {
      suggestions.add('⏱️ 節奏不穩定,建議使用節拍器練習');
    } else if (rhythmScore < 80) {
      suggestions.add('🎼 節奏基本穩定,可以嘗試稍微提高速度');
    } else {
      suggestions.add('✨ 節奏掌握很好!');
    }
    
    if (missedNotes > totalNotes * 0.1) {
      suggestions.add('⚠️ 有較多漏音,請檢查手指是否完全按下琴鍵');
    }
    
    if (wrongNotes > totalNotes * 0.1) {
      suggestions.add('❌ 錯音較多,建議重新熟悉樂譜');
    }
    
    if (earlyNotes > lateNotes * 2) {
      suggestions.add('⏩ 有搶拍傾向,可以放鬆一點,不要太急');
    } else if (lateNotes > earlyNotes * 2) {
      suggestions.add('⏸️ 有拖拍傾向,可能需要加強節奏訓練');
    }
    
    return suggestions;
  }

  @override
  String toString() {
    return 'AnalysisReport($totalNotes notes, ${(accuracy * 100).toStringAsFixed(1)}% accuracy, grade: $grade)';
  }
}

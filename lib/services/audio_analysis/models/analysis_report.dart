import 'performance_error.dart';
import 'confusion_matrix.dart';

/// 分析報告 (已優化 - 2025/10/25)
///
/// 新增功能:
/// - 混淆矩陣 (Confusion Matrix) 評估
/// - F1 分數計算,防止「亂彈高分」問題
/// - 更精確的評分機制
class AnalysisReport {
  /// 總音符數 (期望演奏的音符數)
  final int totalNotes;

  /// 正確音符數 (True Positive)
  final int correctNotes;

  /// 錯音數 (已廢棄,保留向後兼容)
  @Deprecated('使用 confusionMatrix.falsePositive 代替')
  final int wrongNotes;

  /// 漏音數 (False Negative)
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

  /// 混淆矩陣 (新增 - 2025/10/25)
  ///
  /// 提供更全面的評估:
  /// - Precision: 檢出準確度 (防止亂彈高分)
  /// - Recall: 完整度 (防止漏音)
  /// - F1 Score: 綜合評分
  final ConfusionMatrix? confusionMatrix;

  /// 檢測到的總音符數 (包括正確和錯誤)
  ///
  /// 用於計算 False Positive
  /// - 如果檢測到的音符數 >> 期望音符數 → 可能在亂彈
  final int? totalDetectedNotes;

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
    this.confusionMatrix,
    this.totalDetectedNotes,
  });

  /// 音準正確率 (0-1)
  ///
  /// ⚠️ 舊版指標,僅考慮漏音,不考慮誤報
  /// 建議使用 f1Score 作為主要評分
  double get accuracy {
    if (totalNotes == 0) return 0;
    return correctNotes / totalNotes;
  }

  /// Precision (精確率) - 新增 2025/10/25
  ///
  /// 定義: 檢測出的音符中,真正正確的比例
  /// 作用: 防止「亂彈高分」問題
  ///
  /// - 高 Precision: 檢測到的基本都對
  /// - 低 Precision: 很多誤報,可能在亂彈
  double get precision {
    return confusionMatrix?.precision ?? accuracy;
  }

  /// Recall (召回率) - 新增 2025/10/25
  ///
  /// 定義: 期望的音符中,被檢測出的比例
  /// 作用: 衡量完整性
  ///
  /// - 高 Recall: 很少漏音
  /// - 低 Recall: 漏音嚴重
  double get recall {
    return confusionMatrix?.recall ?? accuracy;
  }

  /// F1 Score - 新增 2025/10/25
  ///
  /// 定義: Precision 和 Recall 的調和平均數
  /// 作用: 綜合評估,同時考慮誤報和漏檢
  ///
  /// 這是新的主要評分指標!
  /// - F1 = 1.0: 完美演奏
  /// - F1 < 0.3: 可能在亂彈或嚴重錯誤
  double get f1Score {
    return confusionMatrix?.f1Score ?? accuracy;
  }

  /// False Positive (誤報數) - 新增 2025/10/25
  ///
  /// 定義: 多彈的音符數量
  ///
  /// - FP = 0: 沒有多彈
  /// - FP > 期望音符數: 可能在亂彈
  int get falsePositives {
    return confusionMatrix?.falsePositive ?? wrongNotes;
  }

  /// 誤報率 - 新增 2025/10/25
  ///
  /// 計算: 多彈音符數 / 期望音符數
  ///
  /// - < 0.1: 正常範圍
  /// - > 0.5: 多彈過多,可能亂彈
  double get falsePositiveRate {
    if (totalNotes == 0) return 0;
    return falsePositives / totalNotes;
  }

  /// 節奏分數 (0-100)
  double get rhythmScore {
    if (totalNotes == 0) return 0;
    final timingErrors = earlyNotes + lateNotes;
    final timingAccuracy = 1 - (timingErrors / totalNotes);
    return (timingAccuracy * 100).clamp(0, 100);
  }

  /// 總分 (0-100)
  ///
  /// 優化版評分 (2025/10/27):
  /// - 準確率 (60% 權重): 實際演奏正確的音符比例
  /// - 節奏分數 (40% 權重): 節奏準確性
  ///
  /// 修正原因: F1 Score 在低準確率時仍可能給高分（如51.7%準確率得87分）
  double get overallScore {
    // 使用實際準確率作為主要評分 (0-100)
    final accuracyPercent = accuracy * 100;

    // 準確率權重 60%, 節奏權重 40%
    return (accuracyPercent * 0.6 + rhythmScore * 0.4).clamp(0, 100);
  }

  /// 評級 (S/A/B/C/D/F) - 已優化
  ///
  /// 基於綜合評分（準確率+節奏）
  String get grade {
    final score = overallScore;
    if (score >= 95) return 'S'; // 95%+
    if (score >= 85) return 'A'; // 85-94%
    if (score >= 75) return 'B'; // 75-84%
    if (score >= 65) return 'C'; // 65-74%
    if (score >= 55) return 'D'; // 55-64%
    return 'F'; // <55%
  }

  /// 是否可能在亂彈 - 新增 2025/10/25
  ///
  /// 判斷標準:
  /// - Precision < 0.5: 一半以上是誤報
  /// - 或 誤報率 > 50%
  bool get isProbablyRandomPlaying {
    return precision < 0.5 || falsePositiveRate > 0.5;
  }

  /// 是否為錯誤曲目 - 新增 2025/10/25
  ///
  /// 判斷標準:
  /// - F1 Score < 0.2: 幾乎完全不匹配
  /// - 且 Recall < 0.3: 期望音符大部分未檢出
  bool get isProbablyWrongSong {
    return f1Score < 0.2 && recall < 0.3;
  }

  /// 錯誤分布 (用於圖表)
  Map<String, int> get errorDistribution => {
        '正確': correctNotes,
        '錯音': wrongNotes,
        '漏音': missedNotes,
        '搶拍': earlyNotes,
        '拖拍': lateNotes,
      };

  /// 生成文字報告 (已優化 - 2025/10/25)
  String generateTextReport() {
    final sb = StringBuffer();
    sb.writeln('═══ 演奏分析報告 ═══');
    sb.writeln();

    // 警告訊息 (新增)
    if (isProbablyRandomPlaying) {
      sb.writeln('⚠️  警告: 檢測到疑似亂彈!');
      sb.writeln('   誤報率過高 (${(falsePositiveRate * 100).toStringAsFixed(1)}%)');
      sb.writeln('   請確認是否選擇了正確的 MIDI 檔案');
      sb.writeln();
    } else if (isProbablyWrongSong) {
      sb.writeln('⚠️  警告: 可能演奏了錯誤的曲目!');
      sb.writeln('   匹配度極低 (F1=${(f1Score * 100).toStringAsFixed(1)}%)');
      sb.writeln('   請確認演奏的曲目與 MIDI 是否一致');
      sb.writeln();
    }

    sb.writeln('📊 統計數據:');
    sb.writeln('  總音符數 (期望): $totalNotes');
    if (totalDetectedNotes != null) {
      sb.writeln('  檢測到音符數: $totalDetectedNotes');
    }
    sb.writeln(
        '  正確匹配 (TP): $correctNotes (${(recall * 100).toStringAsFixed(1)}%)');
    sb.writeln('  漏音 (FN): $missedNotes');
    if (confusionMatrix != null) {
      sb.writeln('  誤報/多彈 (FP): $falsePositives');
    }
    sb.writeln(
        '  節奏問題: ${earlyNotes + lateNotes} (搶拍:$earlyNotes, 拖拍:$lateNotes)');
    sb.writeln();

    // 新增混淆矩陣評估
    if (confusionMatrix != null) {
      sb.writeln('🎯 混淆矩陣評估:');
      sb.writeln('  Precision (精確率): ${(precision * 100).toStringAsFixed(1)}%');
      sb.writeln('  Recall (召回率): ${(recall * 100).toStringAsFixed(1)}%');
      sb.writeln('  F1 Score: ${(f1Score * 100).toStringAsFixed(1)}%');
      sb.writeln();
    }

    sb.writeln('🎯 評分:');
    if (confusionMatrix != null) {
      sb.writeln('  音準分數 (F1): ${(f1Score * 100).toStringAsFixed(1)}');
    } else {
      sb.writeln('  音準分數: ${(accuracy * 100).toStringAsFixed(1)}');
    }
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

  /// 生成建議 (已優化 - 2025/10/25)
  List<String> generateSuggestions() {
    final suggestions = <String>[];

    // 新增: 亂彈檢測
    if (isProbablyRandomPlaying) {
      suggestions.add('🚨 系統檢測到疑似亂彈或錯誤曲目,請確認:');
      suggestions.add('   1. 是否選擇了正確的 MIDI 檔案');
      suggestions.add('   2. 是否完整演奏了指定曲目');
      suggestions.add('   3. 是否在安靜環境下錄音');
      return suggestions; // 直接返回,不提供其他建議
    }

    // 新增: 錯誤曲目檢測
    if (isProbablyWrongSong) {
      suggestions.add('❌ 演奏內容與指定曲目嚴重不符!');
      suggestions.add('   請確認是否演奏了正確的曲目');
      return suggestions;
    }

    // 音準建議 (使用 F1 Score 而非 accuracy)
    if (f1Score < 0.6) {
      suggestions.add('🎹 音準需要加強練習,建議放慢速度逐個音符確認');
    } else if (f1Score < 0.8) {
      suggestions.add('🎵 音準基本正確,但仍有進步空間');
    } else if (f1Score >= 0.95) {
      suggestions.add('🌟 音準表現完美!');
    } else {
      suggestions.add('⭐ 音準表現優秀!');
    }

    // Precision 建議 (新增)
    if (precision < 0.7 && falsePositives > 5) {
      suggestions.add('⚠️ 檢測到 $falsePositives 個多餘音符,請注意:');
      suggestions.add('   - 避免誤觸其他琴鍵');
      suggestions.add('   - 確保手指準確按在正確位置');
    }

    // Recall 建議
    if (recall < 0.7) {
      suggestions.add('❌ 漏音較多 ($missedNotes個),建議:');
      suggestions.add('   - 檢查手指是否完全按下琴鍵');
      suggestions.add('   - 在安靜環境下重新錄音');
      suggestions.add('   - 確保麥克風靈敏度足夠');
    } else if (missedNotes > totalNotes * 0.1) {
      suggestions.add('⚠️ 有少量漏音 ($missedNotes個),請檢查按鍵力度');
    }

    // 節奏建議
    if (rhythmScore < 60) {
      suggestions.add('⏱️ 節奏不穩定,建議使用節拍器練習');
    } else if (rhythmScore < 80) {
      suggestions.add('🎼 節奏基本穩定,可以嘗試稍微提高速度');
    } else {
      suggestions.add('✨ 節奏掌握很好!');
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

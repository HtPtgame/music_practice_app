/// 混淆矩陣 - 用於評估演奏檢測準確度
/// 
/// 這是機器學習中的標準評估工具,能夠全面反映系統性能
/// 特別適合處理「亂彈也能高分」的問題
library;

import 'dart:math';

/// 混淆矩陣數據結構
/// 
/// 用於二分類問題:「音符是否正確演奏」
class ConfusionMatrix {
  /// True Positive: 期望的音符被正確檢測到
  final int truePositive;
  
  /// False Positive: 檢測到不該出現的音符 (多彈/錯音)
  final int falsePositive;
  
  /// False Negative: 期望的音符未被檢測到 (漏音)
  final int falseNegative;
  
  /// True Negative: 正確地未檢測到不存在的音符
  /// (在音符檢測場景中較少使用,通常設為 0)
  final int trueNegative;

  ConfusionMatrix({
    required this.truePositive,
    required this.falsePositive,
    required this.falseNegative,
    this.trueNegative = 0,
  });

  /// 精確率 (Precision)
  /// 
  /// 定義: 檢測出的音符中,真正正確的比例
  /// 公式: TP / (TP + FP)
  /// 
  /// 意義: 衡量「誤報率」
  /// - 高 Precision: 很少誤報,檢測到的基本都對
  /// - 低 Precision: 經常誤報,檢測到的很多是錯的
  /// 
  /// 案例:
  /// - Precision = 0.95: 檢測到 100 個音符,其中 95 個是對的
  /// - Precision = 0.30: 檢測到 100 個音符,其中只有 30 個是對的 (亂彈!)
  double get precision {
    final denominator = truePositive + falsePositive;
    if (denominator == 0) return 0.0;
    return truePositive / denominator;
  }

  /// 召回率 (Recall / Sensitivity)
  /// 
  /// 定義: 期望的音符中,被檢測出的比例
  /// 公式: TP / (TP + FN)
  /// 
  /// 意義: 衡量「漏檢率」
  /// - 高 Recall: 很少漏音,該彈的都檢測到了
  /// - 低 Recall: 經常漏音,該彈的很多沒檢測到
  /// 
  /// 案例:
  /// - Recall = 0.95: 期望 100 個音符,檢測到 95 個
  /// - Recall = 0.60: 期望 100 個音符,只檢測到 60 個
  double get recall {
    final denominator = truePositive + falseNegative;
    if (denominator == 0) return 0.0;
    return truePositive / denominator;
  }

  /// F1 分數 (F1 Score)
  /// 
  /// 定義: Precision 和 Recall 的調和平均數
  /// 公式: 2 * (Precision * Recall) / (Precision + Recall)
  /// 
  /// 意義: 綜合評估,同時考慮誤報和漏檢
  /// - F1 = 1.0: 完美檢測 (無誤報,無漏檢)
  /// - F1 = 0.0: 完全失敗
  /// 
  /// 為什麼用調和平均而非算術平均?
  /// - 調和平均對低值敏感,只有兩者都高時 F1 才高
  /// - 例: Precision=1.0, Recall=0.1 → F1=0.18 (而非 0.55)
  /// 
  /// 案例:
  /// - Precision=0.95, Recall=0.95 → F1=0.95 (優秀)
  /// - Precision=0.30, Recall=0.90 → F1=0.45 (亂彈被懲罰)
  /// - Precision=0.95, Recall=0.30 → F1=0.46 (漏音太多)
  double get f1Score {
    final denominator = precision + recall;
    if (denominator == 0) return 0.0;
    return 2 * (precision * recall) / denominator;
  }

  /// 準確率 (Accuracy)
  /// 
  /// 定義: 所有判斷中,正確的比例
  /// 公式: (TP + TN) / (TP + FP + FN + TN)
  /// 
  /// 注意: 在音符檢測中,TN 通常為 0 或很小,
  /// 所以 Accuracy 往往不如 F1 Score 有意義
  double get accuracy {
    final denominator = truePositive + falsePositive + falseNegative + trueNegative;
    if (denominator == 0) return 0.0;
    return (truePositive + trueNegative) / denominator;
  }

  /// 特異度 (Specificity)
  /// 
  /// 定義: 不該檢測的音符中,正確未檢測的比例
  /// 公式: TN / (TN + FP)
  /// 
  /// 意義: 衡量「抗誤報能力」
  /// 在雜訊測試中有用 (環境背景不應檢測到音符)
  double get specificity {
    final denominator = trueNegative + falsePositive;
    if (denominator == 0) return 0.0;
    return trueNegative / denominator;
  }

  /// 假陽性率 (False Positive Rate)
  /// 
  /// 定義: 不該檢測的音符中,被誤報的比例
  /// 公式: FP / (FP + TN) = 1 - Specificity
  /// 
  /// 意義: 雜訊誤報率
  double get falsePositiveRate {
    return 1.0 - specificity;
  }

  /// Matthews 相關係數 (MCC)
  /// 
  /// 定義: 考慮所有四個值的平衡指標
  /// 公式: (TP*TN - FP*FN) / sqrt((TP+FP)(TP+FN)(TN+FP)(TN+FN))
  /// 
  /// 範圍: -1 (完全錯誤) 到 +1 (完全正確)
  /// 
  /// 優點: 即使類別不平衡也能可靠評估
  double get matthewsCorrelation {
    final numerator = (truePositive * trueNegative) - (falsePositive * falseNegative);
    final denominator = sqrt(
      (truePositive + falsePositive) *
      (truePositive + falseNegative) *
      (trueNegative + falsePositive) *
      (trueNegative + falseNegative)
    );
    
    if (denominator == 0) return 0.0;
    return numerator / denominator;
  }

  /// 根據 F1 分數給出評級
  /// 
  /// - S: 0.95+ (近乎完美)
  /// - A: 0.90-0.95 (優秀)
  /// - B: 0.80-0.90 (良好)
  /// - C: 0.70-0.80 (及格)
  /// - D: 0.60-0.70 (不及格)
  /// - F: <0.60 (失敗)
  String get gradeByF1 {
    if (f1Score >= 0.95) return 'S';
    if (f1Score >= 0.90) return 'A';
    if (f1Score >= 0.80) return 'B';
    if (f1Score >= 0.70) return 'C';
    if (f1Score >= 0.60) return 'D';
    return 'F';
  }

  /// 生成詳細報告字符串
  String toDetailedReport() {
    final buffer = StringBuffer();
    buffer.writeln('╔═══════════════════════════════════════╗');
    buffer.writeln('║       混淆矩陣評估報告                ║');
    buffer.writeln('╚═══════════════════════════════════════╝');
    buffer.writeln();
    
    buffer.writeln('📊 混淆矩陣:');
    buffer.writeln('                  實際: 正確   實際: 錯誤');
    buffer.writeln('   預測: 正確      $truePositive (TP)     $falsePositive (FP)');
    buffer.writeln('   預測: 錯誤      $falseNegative (FN)     $trueNegative (TN)');
    buffer.writeln();
    
    buffer.writeln('📈 評估指標:');
    buffer.writeln('   Precision (精確率): ${(precision * 100).toStringAsFixed(1)}%');
    buffer.writeln('   Recall (召回率):    ${(recall * 100).toStringAsFixed(1)}%');
    buffer.writeln('   F1 Score:           ${(f1Score * 100).toStringAsFixed(1)}%');
    buffer.writeln('   Accuracy (準確率):  ${(accuracy * 100).toStringAsFixed(1)}%');
    buffer.writeln();
    
    buffer.writeln('🎯 評級: $gradeByF1');
    buffer.writeln();
    
    buffer.writeln('💡 解讀:');
    if (precision < 0.5) {
      buffer.writeln('   ⚠️  Precision 過低! 誤報率高,可能在亂彈');
    } else if (precision < 0.8) {
      buffer.writeln('   ⚠️  Precision 偏低,有一定誤報');
    } else {
      buffer.writeln('   ✅ Precision 良好,誤報率低');
    }
    
    if (recall < 0.5) {
      buffer.writeln('   ⚠️  Recall 過低! 漏音嚴重');
    } else if (recall < 0.8) {
      buffer.writeln('   ⚠️  Recall 偏低,有一定漏音');
    } else {
      buffer.writeln('   ✅ Recall 良好,漏音少');
    }
    
    if (f1Score >= 0.90) {
      buffer.writeln('   🎉 整體表現優秀!');
    } else if (f1Score >= 0.70) {
      buffer.writeln('   👍 整體表現良好');
    } else if (f1Score >= 0.50) {
      buffer.writeln('   🤔 整體表現一般,需要改進');
    } else {
      buffer.writeln('   ❌ 整體表現較差,建議重新練習');
    }
    
    return buffer.toString();
  }

  @override
  String toString() {
    return 'ConfusionMatrix(TP=$truePositive, FP=$falsePositive, '
           'FN=$falseNegative, TN=$trueNegative, '
           'P=${(precision * 100).toStringAsFixed(1)}%, '
           'R=${(recall * 100).toStringAsFixed(1)}%, '
           'F1=${(f1Score * 100).toStringAsFixed(1)}%)';
  }

  /// 從檢測結果構建混淆矩陣
  /// 
  /// [expectedNotes] 期望的音符列表 (來自 MIDI)
  /// [detectedNotes] 實際檢測到的音符列表 (來自錄音分析)
  /// [matchedPairs] 成功匹配的音符對 [(expected, detected), ...]
  factory ConfusionMatrix.fromDetectionResults({
    required int totalExpectedNotes,
    required int totalDetectedNotes,
    required int correctlyMatched,
  }) {
    // TP: 正確匹配的音符
    final tp = correctlyMatched;
    
    // FN: 期望但未檢測到 (漏音)
    final fn = totalExpectedNotes - correctlyMatched;
    
    // FP: 檢測到但不該出現 (多彈/錯音)
    final fp = totalDetectedNotes - correctlyMatched;
    
    // TN: 在音符檢測場景中通常為 0
    // (因為我們不會去統計「正確地沒有檢測到不存在的音符」這個數量)
    final tn = 0;
    
    return ConfusionMatrix(
      truePositive: tp,
      falsePositive: fp,
      falseNegative: fn,
      trueNegative: tn,
    );
  }
}

/// 測試案例類型
enum TestCaseType {
  /// 正確演奏 (應該高分)
  correctPerformance,
  
  /// 錯誤曲目 (應該低分)
  wrongSong,
  
  /// 純雜訊 (應該接近 0 分)
  noise,
  
  /// 亂彈 (應該低分,測試 Precision)
  randomPlay,
}

/// 擴展: 測試案例期望值
extension TestCaseExpectation on TestCaseType {
  /// 期望的 F1 分數範圍
  (double min, double max) get expectedF1Range {
    switch (this) {
      case TestCaseType.correctPerformance:
        return (0.85, 1.0); // 85%+ 為合格
      case TestCaseType.wrongSong:
        return (0.0, 0.20); // <20% 為正常
      case TestCaseType.noise:
        return (0.0, 0.10); // <10% 為正常
      case TestCaseType.randomPlay:
        return (0.0, 0.30); // <30% 為正常
    }
  }
  
  /// 檢查實際 F1 分數是否符合期望
  bool isF1InExpectedRange(double actualF1) {
    final (min, max) = expectedF1Range;
    return actualF1 >= min && actualF1 <= max;
  }
  
  /// 獲取測試案例類型的描述
  String get description {
    switch (this) {
      case TestCaseType.correctPerformance:
        return '正確演奏測試 (期望高分)';
      case TestCaseType.wrongSong:
        return '錯誤曲目測試 (期望低分)';
      case TestCaseType.noise:
        return '雜訊測試 (期望接近0分)';
      case TestCaseType.randomPlay:
        return '亂彈測試 (期望低分)';
    }
  }
}

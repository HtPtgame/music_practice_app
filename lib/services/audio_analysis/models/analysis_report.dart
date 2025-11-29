import 'dart:math' show max;
import 'performance_error.dart';
import 'confusion_matrix.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../timeline_analysis_service.dart';

/// 分析報告 (已優化 - v3.4-v3.6 功能恢復 2025/11/27)
///
/// 新增功能:
/// - 混淆矩陣 (Confusion Matrix) 評估
/// - F1 分數計算,防止「亂彈高分」問題
/// - 時間軸分析結果整合
/// - 短錄音偵測與懲罰 (durationPenalty)
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

  /// 時間軸分析結果 (v3.4 新增 - 2025/11/27)
  ///
  /// 包含:
  /// - 演奏時長與預期時長的比較
  /// - 延遲開始、中斷、跳過段落等資訊
  final TimelineAnalysisResult? timelineAnalysis;

  /// 短錄音懲罰係數 (v3.7 優化 - 2025/11/29)
  ///
  /// 當錄音時長明顯短於 MIDI 預期時長時的懲罰係數
  /// - 1.0: 無懲罰 (>=90% 正常長度)
  /// - 0.5-1.0: 輕微懲罰 (50-90%)
  /// - 0.0-0.5: 嚴重懲罰 (<50% 非常短)
  ///
  /// v3.7 優化: 加強短錄音懲罰力度，解汻30秒錄音得98.7分的問題
  double get durationPenalty {
    if (timelineAnalysis == null) return 1.0;
    final ratio = timelineAnalysis!.durationRatio;
    
    // v3.7: 更嚴格的懲罰曲線
    if (ratio >= 0.9) return 1.0; // 90%以上無懲罰
    if (ratio >= 0.7) return 0.6 + (ratio - 0.7) * 2.0; // 70-90%: 0.6-1.0
    if (ratio >= 0.5) return 0.3 + (ratio - 0.5) * 1.5; // 50-70%: 0.3-0.6
    if (ratio >= 0.3) return 0.1 + (ratio - 0.3) * 1.0; // 30-50%: 0.1-0.3
    return 0.05; // <30%: 極低分 (30秒/164秒=18.3% -> 0.05倍)
  }

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
    this.timelineAnalysis,
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

  /// 節奏分數 (0-100) - v3.7 優化 2025/11/29
  ///
  /// v3.7 優化: 解決環境音節奏分數過高問題
  /// 原因: 環境音可能有很少的誤報音符，但節奏錯誤極低，導致99.3%高分
  /// 解決方案: 結合準確率調整節奏分數，低準確率時降低節奏分數
  double get rhythmScore {
    if (totalNotes == 0) return 0;
    
    // 基礎節奏分數: 根據節奏錯誤計算
    final timingErrors = earlyNotes + lateNotes;
    final baseRhythmScore = correctNotes > 0 
        ? (1 - (timingErrors / correctNotes)).clamp(0.0, 1.0)
        : 0.0;
    
    // v3.7: 根據準確率調整節奏分數
    // 準確率很低時，節奏分數也應該降低
    final accuracyFactor = accuracy.clamp(0.3, 1.0); // 最低30%的影響
    final adjustedRhythmScore = baseRhythmScore * accuracyFactor;
    
    return (adjustedRhythmScore * 100).clamp(0, 100);
  }

  /// 總分 (0-100) - v3.7 全面優化 2025/11/29
  ///
  /// v3.7 優化:
  /// 1. 修正38.7%準確率卻得0分的異常問題
  /// 2. 平衡環境音和實際演奏的分數
  /// 3. 加強短錄音懲罰（30秒錄音不應該得98.7分）
  ///
  /// 評分策略:
  /// - F1 Score (50% 權重): 綜合考慮準確率和完整性
  /// - 節奏分數 (50% 權重): 節奏準確性（已結合準確率調整）
  /// - 短錄音懲罰: 時長不足時降低分數
  double get overallScore {
    // 使用 F1 Score 作為主要評分 (0-100)
    // F1 Score 會同時考慮 Precision 和 Recall，避免亂彈高分
    final f1Percent = f1Score * 100;
    
    // 節奏分數已經結合準確率調整，可以直接使用
    final rhythm = rhythmScore;
    
    // v3.7: 調整權重為 50%:50%，更平衡
    final baseScore = (f1Percent * 0.5 + rhythm * 0.5);
    
    // 應用短錄音懲罰 (v3.7 加強)
    final finalScore = baseScore * durationPenalty;
    
    // 確保最低分：即使有一些正確音符，也應該給予基礎分
    // 解決38.7%準確率卻0分的問題
    if (finalScore < 1.0 && accuracy > 0.1) {
      // 最低保證分 = 準確率 * 20
      final minScore = accuracy * 20;
      return max(finalScore, minScore).clamp(0, 100);
    }
    
    return finalScore.clamp(0, 100);
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

  /// 是否可能在亂彈 - 優化 2025/11/27
  ///
  /// 判斷標準（更嚴格，避免誤判）:
  /// - Precision < 0.3: 大部分檢測為誤報
  /// - 且 False Positive Rate > 0.7: 超過70%的檢測是錯的
  /// - 且 F1 Score < 0.3: 綜合評分極低
  bool get isProbablyRandomPlaying {
    return precision < 0.3 && falsePositiveRate > 0.7 && f1Score < 0.3;
  }

  /// 是否為錯誤曲目 - 優化 2025/11/27
  ///
  /// 判斷標準（更嚴格，避免誤判）:
  /// - F1 Score < 0.15: 幾乎完全不匹配（從0.2降至0.15）
  /// - 且 Recall < 0.2: 期望音符幾乎全部未檢出（從0.3降至0.2）
  /// - 且 Accuracy < 0.3: 準確率極低
  bool get isProbablyWrongSong {
    return f1Score < 0.15 && recall < 0.2 && accuracy < 0.3;
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
  List<String> generateSuggestions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final suggestions = <String>[];

    // 新增: 亂彈檢測
    if (isProbablyRandomPlaying) {
      suggestions.add(l10n?.suggestionRandomPlaying ?? '🚨 系統檢測到疑似亂彈或錯誤曲目,請確認:');
      suggestions.add(l10n?.suggestionCheckCorrectFile ?? '   1. 是否選擇了正確的 MIDI 檔案');
      suggestions.add(l10n?.suggestionCheckCompleteSong ?? '   2. 是否完整演奏了指定曲目');
      suggestions.add(l10n?.suggestionCheckQuietEnvironment ?? '   3. 是否在安靜環境下錄音');
      return suggestions; // 直接返回,不提供其他建議
    }

    // 新增: 錯誤曲目檢測
    if (isProbablyWrongSong) {
      suggestions.add(l10n?.suggestionWrongSong ?? '❌ 演奏內容與指定曲目嚴重不符!');
      suggestions.add(l10n?.suggestionConfirmCorrectSong ?? '   請確認是否演奏了正確的曲目');
      return suggestions;
    }

    // 音準建議 (使用 F1 Score 而非 accuracy)
    if (f1Score < 0.6) {
      suggestions.add(l10n?.suggestionPitchNeedsPractice ?? '🎹 音準需要加強練習,建議放慢速度逐個音符確認');
    } else if (f1Score < 0.8) {
      suggestions.add(l10n?.suggestionPitchBasic ?? '🎵 音準基本正確,但仍有進步空間');
    } else if (f1Score >= 0.95) {
      suggestions.add(l10n?.suggestionPitchPerfect ?? '🌟 音準表現完美!');
    } else {
      suggestions.add(l10n?.suggestionPitchExcellent ?? '⭐ 音準表現優秀!');
    }

    // Precision 建議 (新增)
    if (precision < 0.7 && falsePositives > 5) {
      suggestions.add(l10n?.suggestionExtraNotes(falsePositives) ?? '⚠️ 檢測到 $falsePositives 個多餘音符,請注意:');
      suggestions.add(l10n?.suggestionAvoidWrongKeys ?? '   - 避免誤觸其他琴鍵');
      suggestions.add(l10n?.suggestionEnsureAccuracy ?? '   - 確保手指準確按在正確位置');
    }

    // Recall 建議
    if (recall < 0.7) {
      suggestions.add(l10n?.suggestionManyMissed(missedNotes) ?? '❌ 漏音較多 ($missedNotes個),建議:');
      suggestions.add(l10n?.suggestionCheckKeyPress ?? '   - 檢查手指是否完全按下琴鍵');
      suggestions.add(l10n?.suggestionRetryQuietEnvironment ?? '   - 在安靜環境下重新錄音');
      suggestions.add(l10n?.suggestionCheckMicSensitivity ?? '   - 確保麥克風靈敏度足夠');
    } else if (missedNotes > totalNotes * 0.1) {
      suggestions.add(l10n?.suggestionSomeMissed(missedNotes) ?? '⚠️ 有少量漏音 ($missedNotes個),請檢查按鍵力度');
    }

    // 節奏建議
    if (rhythmScore < 60) {
      suggestions.add(l10n?.suggestionRhythmUnstable ?? '⏱️ 節奏不穩定,建議使用節拍器練習');
    } else if (rhythmScore < 80) {
      suggestions.add(l10n?.suggestionRhythmBasic ?? '🎼 節奏基本穩定,可以嘗試稍微提高速度');
    } else {
      suggestions.add(l10n?.suggestionRhythmGood ?? '✨ 節奏掌握很好!');
    }

    if (earlyNotes > lateNotes * 2) {
      suggestions.add(l10n?.suggestionTendencyRushing ?? '⏩ 有搶拍傾向,可以放鬆一點,不要太急');
    } else if (lateNotes > earlyNotes * 2) {
      suggestions.add(l10n?.suggestionTendencyDragging ?? '⏸️ 有拖拍傾向,可能需要加強節奏訓練');
    }

    return suggestions;
  }

  @override
  String toString() {
    return 'AnalysisReport($totalNotes notes, ${(accuracy * 100).toStringAsFixed(1)}% accuracy, grade: $grade)';
  }
}

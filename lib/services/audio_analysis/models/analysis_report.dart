import 'dart:math' show max;
import 'performance_error.dart';
import 'confusion_matrix.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../timeline_analysis_service.dart';

/// 分析報告 (v4.0 全面優化 - 2025/11/29)
///
/// v4.0 優化重點:
/// - 修正環境音節奏分數過高問題（99.3% → 合理值）
/// - 修正短錄音分數過高問題（98.7% → 合理懲罰）
/// - 提升正式演奏的分數表現
/// - 新增覆蓋率因子：正確音符太少時節奏分數無意義
///
/// 功能特性:
/// - 混淆矩陣 (Confusion Matrix) 評估
/// - F1 分數計算,防止「亂彈高分」問題
/// - 時間軸分析結果整合
/// - 短錄音偵測與懲罰 (durationPenalty)
/// - 覆蓋率調整的節奏分數 (rhythmScore)
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

  /// 短錄音懲罰係數 (v4.0 大幅優化 - 2025/11/29)
  ///
  /// 問題：30秒錄音/164秒曲目 = 18.3%，卻得到 98.7 分
  /// 原因：durationPenalty 計算不夠嚴格
  ///
  /// v4.0 優化：使用更嚴格的懲罰曲線
  /// - 1.0: 無懲罰 (>=90% 完整演奏)
  /// - 0.5-1.0: 輕微懲罰 (70-90%)
  /// - 0.2-0.5: 中度懲罰 (50-70%)
  /// - 0.05-0.2: 嚴重懲罰 (30-50%)
  /// - <0.05: 極度懲罰 (<30% - 如30秒/164秒=18.3%)
  double get durationPenalty {
    if (timelineAnalysis == null) return 1.0;
    final ratio = timelineAnalysis!.durationRatio;
    
    // v4.0: 更嚴格且平滑的懲罰曲線
    if (ratio >= 0.9) {
      return 1.0; // 90%以上無懲罰
    }
    if (ratio >= 0.7) {
      // 70-90%: 0.5-1.0 (線性插值)
      return 0.5 + (ratio - 0.7) * 2.5;
    }
    if (ratio >= 0.5) {
      // 50-70%: 0.2-0.5 (線性插值)
      return 0.2 + (ratio - 0.5) * 1.5;
    }
    if (ratio >= 0.3) {
      // 30-50%: 0.05-0.2 (線性插值)
      return 0.05 + (ratio - 0.3) * 0.75;
    }
    // <30%: 極低分 (如 18.3% -> ~0.02)
    return max(0.01, ratio * 0.1);
  }

  /// 覆蓋率 (v4.0 新增)
  ///
  /// 正確音符數 / 期望總音符數
  /// 用於調整節奏分數：如果只檢出很少的正確音符，節奏分數應該無意義
  double get coverageRate {
    if (totalNotes == 0) return 0;
    return correctNotes / totalNotes;
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

  /// 節奏分數 (0-100) - v4.7 加強環境噪音懲罰 2025/11/29
  ///
  /// 目標：
  /// 1. 正式演奏時節奏分數應達到 95%+
  /// 2. 環境噪音節奏分數應低於 30%
  ///
  /// v4.7 調整：
  /// - 加強低覆蓋率的節奏分數懲罰
  /// - 覆蓋率 < 50% 時使用更嚴格的覆蓋率因子
  double get rhythmScore {
    if (totalNotes == 0) return 0;
    if (correctNotes == 0) return 0;
    
    // v4.6: 加權節奏分數計算
    final timingCorrectNotes = correctNotes - earlyNotes - lateNotes;
    final timingErrorNotes = earlyNotes + lateNotes;
    
    // 加權計算：搶拍/拖拍給予 0.8 權重
    final weightedScore = (timingCorrectNotes * 1.0 + timingErrorNotes * 0.8) / correctNotes;
    double baseRhythmScore = weightedScore.clamp(0.0, 1.0);
    
    // 對高覆蓋率演奏給予額外獎勵
    if (coverageRate >= 0.95) {
      baseRhythmScore = (baseRhythmScore * 1.03).clamp(0.0, 1.0);
    } else if (coverageRate >= 0.9) {
      baseRhythmScore = (baseRhythmScore * 1.02).clamp(0.0, 1.0);
    }
    
    // v4.7: 加強低覆蓋率的節奏分數懲罰
    // 環境噪音覆蓋率約 38%，應該大幅降低節奏分數
    double coverageFactor = 1.0;
    if (coverageRate < 0.6) {
      // 使用二次曲線懲罰，覆蓋率越低懲罰越重
      // coverageRate = 0.6 → factor = 1.0
      // coverageRate = 0.5 → factor ≈ 0.69
      // coverageRate = 0.4 → factor ≈ 0.44
      // coverageRate = 0.3 → factor ≈ 0.25
      // coverageRate = 0.2 → factor ≈ 0.11
      final ratio = coverageRate / 0.6;
      coverageFactor = ratio * ratio;
      coverageFactor = coverageFactor.clamp(0.05, 1.0);
    }
    
    // 最低音符門檻
    if (correctNotes < 10) {
      coverageFactor = coverageFactor * 0.5;
    }
    
    // 最終節奏分數
    final adjustedRhythmScore = baseRhythmScore * coverageFactor;
    
    return (adjustedRhythmScore * 100).clamp(0, 100);
  }

  /// 總分 (0-100) - v4.3 環境噪音處理加強 2025/11/29
  ///
  /// 設計目標：
  /// 1. 正式演奏（高覆蓋率）應得到合理高分 (80-95%)
  /// 2. 環境噪音（低覆蓋率）應得到低分 (<15%)
  /// 3. 短錄音應受到嚴重懲罰
  /// 4. 錯誤曲目（時長不匹配）應得到低分
  ///
  /// v4.3 調整：
  /// - 提高環境噪音懲罰閾值：coverageRate < 0.6 時開始懲罰
  /// - 使用三次曲線使懲罰更嚴格
  double get overallScore {
    // v4.1: 使用準確率（Recall）作為主要指標
    final accuracyPercent = accuracy * 100;
    
    // 節奏分數（已結合覆蓋率調整）
    final rhythm = rhythmScore;
    
    // v4.1: 調整權重為 70%:30%
    final baseScore = (accuracyPercent * 0.7 + rhythm * 0.3);
    
    // 應用短錄音懲罰 (v4.0)
    var finalScore = baseScore * durationPenalty;
    
    // v4.3: 環境噪音懲罰（更嚴格）
    // 覆蓋率 < 60% 時開始應用懲罰
    // 這處理「環境背景音偶然命中一些音符」的情況
    if (coverageRate < 0.6) {
      // 使用三次曲線使懲罰更嚴格
      // coverageRate = 0.6 → penalty = 1.0 (無懲罰)
      // coverageRate = 0.4 → penalty ≈ 0.30
      // coverageRate = 0.3 → penalty ≈ 0.125
      // coverageRate = 0.2 → penalty ≈ 0.037
      final ratio = coverageRate / 0.6;
      final noisePenalty = ratio * ratio * ratio; // 三次方
      finalScore = finalScore * noisePenalty.clamp(0.01, 1.0);
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

  /// 是否為亂彈 - v5.0 優化判定邏輯 2025/12/10
  ///
  /// 判斷標準（多層級檢測，更精確）:
  /// 1. 極端亂彈: Precision < 0.2 && FP Rate > 1.0 && F1 < 0.25
  /// 2. 嚴重亂彈: Precision < 0.3 && FP Rate > 0.7 && F1 < 0.3
  /// 3. 中度亂彈: Precision < 0.4 && FP Rate > 0.5 && F1 < 0.4 && 覆蓋率 < 0.4
  bool get isProbablyRandomPlaying {
    // 極端亂彈：檢測音符比期望多，且準確率極低
    if (precision < 0.2 && falsePositiveRate > 1.0 && f1Score < 0.25) {
      return true;
    }
    
    // 嚴重亂彈：大量誤報
    if (precision < 0.3 && falsePositiveRate > 0.7 && f1Score < 0.3) {
      return true;
    }
    
    // 中度亂彈：結合覆蓋率判斷（可能是環境噪音）
    if (precision < 0.4 && falsePositiveRate > 0.5 && 
        f1Score < 0.4 && coverageRate < 0.4) {
      return true;
    }
    
    return false;
  }

  /// 是否為錯誤曲目 - v5.0 優化判定邏輯 2025/12/10
  ///
  /// 判斷標準（避免與短錄音混淆）:
  /// 1. 時長匹配但內容錯誤: F1 < 0.15 && Recall < 0.2 && 時長比 > 0.7
  /// 2. 時長和內容都不匹配: F1 < 0.2 && Recall < 0.25 && 時長比 < 0.5
  bool get isProbablyWrongSong {
    final durationOk = timelineAnalysis != null && 
                       timelineAnalysis!.durationRatio > 0.7;
    
    // 時長匹配但內容完全不對 → 錯誤曲目
    if (f1Score < 0.15 && recall < 0.2 && durationOk) {
      return true;
    }
    
    // 時長和內容都不對，且不是單純的短錄音
    if (f1Score < 0.2 && recall < 0.25 && 
        timelineAnalysis != null && 
        timelineAnalysis!.durationRatio < 0.5 &&
        accuracy < 0.3) {
      return true;
    }
    
    return false;
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

  /// 生成建議 - v5.0 全面優化 2025/12/10
  ///
  /// 優化重點:
  /// 1. 分層次判定：極端問題 → 嚴重問題 → 一般問題 → 優點
  /// 2. 避免重複提示：高分時只顯示正面評價
  /// 3. 具體化建議：根據錯誤類型給出針對性建議
  /// 4. 智能門檻：根據總分動態調整提示門檻
  List<String> generateSuggestions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final suggestions = <String>[];

    // === 第一層：致命問題檢測 ===
    
    // 1. 亂彈檢測（最高優先級）
    if (isProbablyRandomPlaying) {
      suggestions.add(l10n?.suggestionRandomPlaying ?? '🚨 系統檢測到疑似亂彈或錯誤曲目,請確認:');
      suggestions.add(l10n?.suggestionCheckCorrectFile ?? '   1. 是否選擇了正確的 MIDI 檔案');
      suggestions.add(l10n?.suggestionCheckCompleteSong ?? '   2. 是否完整演奏了指定曲目');
      suggestions.add(l10n?.suggestionCheckQuietEnvironment ?? '   3. 是否在安靜環境下錄音');
      return suggestions; // 直接返回,不提供其他建議
    }

    // 2. 錯誤曲目檢測
    if (isProbablyWrongSong) {
      suggestions.add(l10n?.suggestionWrongSong ?? '❌ 演奏內容與指定曲目嚴重不符!');
      suggestions.add(l10n?.suggestionConfirmCorrectSong ?? '   請確認是否演奏了正確的曲目');
      return suggestions;
    }

    // 3. 錄音過短檢測（新增）
    if (timelineAnalysis != null && timelineAnalysis!.durationRatio < 0.3) {
      suggestions.add('⏱️ 錄音時長過短 (僅 ${(timelineAnalysis!.durationRatio * 100).toStringAsFixed(0)}%)');
      suggestions.add('   建議完整演奏整首曲目後再進行分析');
      if (overallScore < 60) {
        return suggestions; // 短錄音且分數低，不提供其他建議
      }
    }

    // === 第二層：高分表揚（90分以上） ===
    
    if (overallScore >= 90) {
      // 完美演奏
      if (f1Score >= 0.95 && rhythmScore >= 95) {
        suggestions.add(l10n?.suggestionPitchPerfect ?? '🌟 音準表現完美!');
        suggestions.add(l10n?.suggestionRhythmGood ?? '✨ 節奏掌握很好!');
        suggestions.add('🎉 這是一次出色的演奏，繼續保持！');
      }
      // 優秀演奏
      else if (f1Score >= 0.9 && rhythmScore >= 90) {
        suggestions.add(l10n?.suggestionPitchExcellent ?? '⭐ 音準表現優秀!');
        suggestions.add(l10n?.suggestionRhythmGood ?? '✨ 節奏掌握很好!');
      }
      // 良好演奏（給出小建議）
      else {
        if (f1Score >= 0.85) {
          suggestions.add(l10n?.suggestionPitchExcellent ?? '⭐ 音準表現優秀!');
        }
        if (rhythmScore >= 85) {
          suggestions.add(l10n?.suggestionRhythmGood ?? '✨ 節奏掌握很好!');
        }
        // 給出細微改進建議
        if (earlyNotes > totalNotes * 0.05) {
          suggestions.add('💡 小提示：有輕微搶拍傾向，可以再放鬆一點');
        } else if (lateNotes > totalNotes * 0.05) {
          suggestions.add('💡 小提示：節奏可以再緊湊一些');
        }
      }
      return suggestions;
    }

    // === 第三層：中等分數建議（75-89分） ===
    
    if (overallScore >= 75) {
      suggestions.add('👍 整體表現良好，以下是改進建議：');
      
      // 音準建議
      if (f1Score < 0.8) {
        suggestions.add(l10n?.suggestionPitchBasic ?? '🎵 音準基本正確,但仍有進步空間');
        if (missedNotes > totalNotes * 0.1) {
          suggestions.add('   - 有 $missedNotes 個漏音，注意手指按鍵力度');
        }
        if (falsePositives > totalNotes * 0.1) {
          suggestions.add('   - 有 $falsePositives 個多餘音符，注意手指位置');
        }
      } else {
        suggestions.add(l10n?.suggestionPitchExcellent ?? '⭐ 音準表現優秀!');
      }
      
      // 節奏建議
      if (rhythmScore < 80) {
        suggestions.add(l10n?.suggestionRhythmBasic ?? '🎼 節奏基本穩定,可以嘗試稍微提高速度');
        if (earlyNotes > lateNotes * 1.5) {
          suggestions.add('   - 注意不要太急，保持穩定的節奏');
        } else if (lateNotes > earlyNotes * 1.5) {
          suggestions.add('   - 節奏可以再積極一些，避免拖拍');
        }
      }
      
      return suggestions;
    }

    // === 第四層：需要改進（60-74分） ===
    
    if (overallScore >= 60) {
      suggestions.add('📝 發現一些需要改進的地方：');
      
      // 音準問題分析
      if (f1Score < 0.6) {
        suggestions.add(l10n?.suggestionPitchNeedsPractice ?? '🎹 音準需要加強練習,建議放慢速度逐個音符確認');
      } else if (f1Score < 0.75) {
        suggestions.add(l10n?.suggestionPitchBasic ?? '🎵 音準基本正確,但仍有進步空間');
      }
      
      // 具體錯誤分析
      if (missedNotes > totalNotes * 0.15) {
        suggestions.add(l10n?.suggestionSomeMissed(missedNotes) ?? '⚠️ 有少量漏音 ($missedNotes個),請檢查按鍵力度');
        suggestions.add('   - 確保每個音符都完全按下');
        suggestions.add('   - 可以嘗試在安靜環境下重新錄音');
      }
      
      if (falsePositives > totalNotes * 0.15) {
        suggestions.add('⚠️ 檢測到 $falsePositives 個多餘音符');
        suggestions.add('   - 注意手指不要誤觸其他琴鍵');
        suggestions.add('   - 確保手指準確按在正確位置');
      }
      
      // 節奏問題分析
      if (rhythmScore < 70) {
        suggestions.add(l10n?.suggestionRhythmUnstable ?? '⏱️ 節奏不穩定,建議使用節拍器練習');
        if (earlyNotes + lateNotes > totalNotes * 0.2) {
          suggestions.add('   - 時間偏差較大的音符有 ${earlyNotes + lateNotes} 個');
        }
      }
      
      return suggestions;
    }

    // === 第五層：嚴重問題（< 60分） ===
    
    suggestions.add('⚠️ 演奏需要較多改進，以下是重點建議：');
    
    // 覆蓋率問題
    if (coverageRate < 0.5) {
      suggestions.add('📊 音符覆蓋率較低 (${(coverageRate * 100).toStringAsFixed(0)}%)');
      suggestions.add('   建議：');
      suggestions.add('   1. 確保完整演奏整首曲目');
      suggestions.add('   2. 檢查是否選擇了正確的 MIDI 檔案');
      suggestions.add('   3. 在安靜環境下錄音，避免環境噪音干擾');
    }
    
    // 嚴重的音準問題
    if (f1Score < 0.5) {
      suggestions.add(l10n?.suggestionPitchNeedsPractice ?? '🎹 音準需要加強練習,建議放慢速度逐個音符確認');
      
      // 詳細分析
      if (recall < 0.5) {
        suggestions.add(l10n?.suggestionManyMissed(missedNotes) ?? '❌ 漏音較多 ($missedNotes個),建議:');
        suggestions.add(l10n?.suggestionCheckKeyPress ?? '   - 檢查手指是否完全按下琴鍵');
        suggestions.add(l10n?.suggestionRetryQuietEnvironment ?? '   - 在安靜環境下重新錄音');
        suggestions.add(l10n?.suggestionCheckMicSensitivity ?? '   - 確保麥克風靈敏度足夠');
      }
      
      if (precision < 0.5 && falsePositives > 10) {
        suggestions.add(l10n?.suggestionExtraNotes(falsePositives) ?? '⚠️ 檢測到 $falsePositives 個多餘音符,請注意:');
        suggestions.add(l10n?.suggestionAvoidWrongKeys ?? '   - 避免誤觸其他琴鍵');
        suggestions.add(l10n?.suggestionEnsureAccuracy ?? '   - 確保手指準確按在正確位置');
      }
    }
    
    // 嚴重的節奏問題
    if (rhythmScore < 50) {
      suggestions.add(l10n?.suggestionRhythmUnstable ?? '⏱️ 節奏不穩定,建議使用節拍器練習');
      suggestions.add('   - 從慢速開始練習，逐步提高速度');
      suggestions.add('   - 每次只練習一小段，確保穩定後再連貫');
      
      if (earlyNotes > lateNotes * 2) {
        suggestions.add(l10n?.suggestionTendencyRushing ?? '⏩ 有搶拍傾向,可以放鬆一點,不要太急');
      } else if (lateNotes > earlyNotes * 2) {
        suggestions.add(l10n?.suggestionTendencyDragging ?? '⏸️ 有拖拍傾向,可能需要加強節奏訓練');
      }
    }

    return suggestions;
  }

  @override
  String toString() {
    return 'AnalysisReport($totalNotes notes, ${(accuracy * 100).toStringAsFixed(1)}% accuracy, grade: $grade)';
  }
}

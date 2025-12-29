/// 序列匹配服務 (V3 最終修復版)
///
/// 使用動態時間規整 (DTW) 或貪心算法進行序列對齊
/// 確保演奏的音符序列與標準答案匹配
library;

import 'dart:math';
import 'package:veloria/services/audio_analysis/models/note_event.dart';
// ✅ 1. 引入正宮 (外部定義的 DetectedNote)
import 'package:veloria/services/detected_note.dart';

/// 序列匹配結果 (V3 - 包含詳細統計)
class SequenceMatchResult {
  /// 匹配的音符對 (MIDI事件索引 -> 檢測到的時間)
  final Map<int, double?> matches;

  /// 整體匹配分數 (0-100)
  final double score;

  /// 序列相似度
  final double sequenceSimilarity;

  /// 時間對齊偏移 (秒)
  final double timeOffset;

  // ✅ 2. 新增統計欄位 (為了給 PerformanceAnalyzer 用)
  final int perfectMatches; // TP
  final int wrongNotes;     // 錯音 (Pitch mismatch)
  final int missedNotes;    // FN
  final int extraNotes;     // FP

  SequenceMatchResult({
    required this.matches,
    required this.score,
    required this.sequenceSimilarity,
    required this.timeOffset,
    required this.perfectMatches,
    required this.wrongNotes,
    required this.missedNotes,
    required this.extraNotes,
  });
}

// ❌ 原本這裡的 class DetectedNote 被刪除了，因為我們用了 import

abstract class ISequenceMatcher {
  Future<SequenceMatchResult> match(
    MidiTimeline expectedTimeline,
    List<DetectedNote> detectedNotes, // 介面微調：不需要 Spectrogram 了
  );
}

/// 序列匹配服務實現
class SequenceMatcherService implements ISequenceMatcher {
  // 匹配參數
  static const double maxTimeDifference = 0.5; // 縮小時間窗，提高精確度 (原本 2.0 太寬)
  static const double pitchMatchWeight = 0.6;  // 提高音高權重
  static const double timingMatchWeight = 0.4;

  @override
  Future<SequenceMatchResult> match(
    MidiTimeline expectedTimeline,
    List<DetectedNote> detectedNotes,
  ) async {
    final expectedNotes = expectedTimeline.events;

    if (expectedNotes.isEmpty) {
      return SequenceMatchResult(
        matches: {},
        score: 0.0,
        sequenceSimilarity: 0.0,
        timeOffset: 0.0,
        perfectMatches: 0,
        wrongNotes: 0,
        missedNotes: 0,
        extraNotes: detectedNotes.length,
      );
    }

    // 1. 計算時間偏移 (全局對齊)
    final timeOffset = _estimateTimeOffset(expectedNotes, detectedNotes);

    // 2. 貪心序列對齊
    final alignmentResult = _alignSequences(
      expectedNotes,
      detectedNotes,
      timeOffset,
    );

    // 3. 計算統計數據 (TP, FN, FP)
    int perfectCount = 0;
    int missedCount = 0;
    
    // 計算完美匹配和漏音
    for (int i = 0; i < expectedNotes.length; i++) {
      if (alignmentResult[i] != null) {
        perfectCount++;
      } else {
        missedCount++;
      }
    }

    // 計算多餘音符 (FP)
    // 簡單算法：總檢測數 - 成功匹配數
    // (進階版可以用 Set 記錄哪些檢測音符被用過了)
    final matchedDetectedCount = alignmentResult.values.where((v) => v != null).length;
    final extraCount = max(0, detectedNotes.length - matchedDetectedCount);

    // 4. 計算分數 (F1 Score 近似值)
    final precision = matchedDetectedCount / (matchedDetectedCount + extraCount + 0.001);
    final recall = perfectCount / (expectedNotes.length + 0.001);
    final f1Score = 2 * (precision * recall) / (precision + recall + 0.001);

    return SequenceMatchResult(
      matches: alignmentResult,
      score: f1Score * 100, // 轉成 0-100 分
      sequenceSimilarity: recall,
      timeOffset: timeOffset,
      perfectMatches: perfectCount,
      wrongNotes: 0, // 目前簡易版不區分錯音與漏音，統一算在 missed/extra
      missedNotes: missedCount,
      extraNotes: extraCount,
    );
  }

  /// 估算時間偏移
  double _estimateTimeOffset(
    List<NoteEvent> expectedNotes,
    List<DetectedNote> detectedNotes,
  ) {
    if (expectedNotes.isEmpty || detectedNotes.isEmpty) return 0.0;

    // 取前 5 個音符來對齊
    final sampleSize = min(5, min(expectedNotes.length, detectedNotes.length));
    double totalOffset = 0.0;
    int validSamples = 0;

    for (int i = 0; i < sampleSize; i++) {
      final expected = expectedNotes[i];
      
      // 在檢測音符中找同音高的
      for (final detected in detectedNotes) {
        if (detected.midiNote == expected.midiNote) {
          // 如果時間差在合理範圍內
          if ((detected.time - expected.startTime).abs() < 2.0) {
            totalOffset += (detected.time - expected.startTime);
            validSamples++;
            break; // 找到一個就停
          }
        }
      }
    }

    return validSamples > 0 ? totalOffset / validSamples : 0.0;
  }

  /// 序列對齊核心邏輯
  Map<int, double?> _alignSequences(
    List<NoteEvent> expectedNotes,
    List<DetectedNote> detectedNotes,
    double timeOffset,
  ) {
    final matches = <int, double?>{};
    final usedDetections = <int>{}; // 避免重複使用同一個檢測音符

    for (int i = 0; i < expectedNotes.length; i++) {
      final expected = expectedNotes[i];
      final adjustedExpectedTime = expected.startTime + timeOffset;

      double bestScore = -1.0;
      int? bestMatchIndex;

      for (int j = 0; j < detectedNotes.length; j++) {
        if (usedDetections.contains(j)) continue;

        final detected = detectedNotes[j];
        
        // 必須音高相同才考慮匹配 (這是嚴格模式，錯音就算 Miss)
        if (detected.midiNote != expected.midiNote) continue;

        final timeDiff = (detected.time - adjustedExpectedTime).abs();
        
        // 超出時間窗就不匹配
        if (timeDiff > maxTimeDifference) continue;

        // 分數越高越好 (時間越近分數越高)
        final score = 1.0 - (timeDiff / maxTimeDifference);

        if (score > bestScore) {
          bestScore = score;
          bestMatchIndex = j;
        }
      }

      if (bestMatchIndex != null) {
        matches[i] = detectedNotes[bestMatchIndex].time;
        usedDetections.add(bestMatchIndex);
      } else {
        matches[i] = null; // Missed
      }
    }

    return matches;
  }
}
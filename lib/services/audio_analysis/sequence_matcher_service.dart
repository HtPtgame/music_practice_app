/// 序列匹配服務
///
/// 使用動態時間規整 (Dynamic Time Warping, DTW) 或序列對齊算法
/// 確保演奏的音符序列與標準答案匹配,而不僅僅是音高匹配
library;

import 'dart:math';
import 'models/note_event.dart';
import 'models/spectrogram.dart';

/// 序列匹配結果
class SequenceMatchResult {
  /// 匹配的音符對 (MIDI事件索引 -> 檢測到的時間)
  final Map<int, double?> matches;

  /// 整體匹配分數 (0-1, 越高越好)
  final double overallScore;

  /// 序列相似度 (考慮順序)
  final double sequenceSimilarity;

  /// 時間對齊偏移 (秒)
  final double timeOffset;

  SequenceMatchResult({
    required this.matches,
    required this.overallScore,
    required this.sequenceSimilarity,
    required this.timeOffset,
  });
}

/// 檢測到的音符
class DetectedNote {
  final int midiNote;
  final double time;
  final double confidence;

  DetectedNote({
    required this.midiNote,
    required this.time,
    required this.confidence,
  });
}

abstract class ISequenceMatcher {
  /// 執行序列匹配
  ///
  /// [expectedTimeline] 期望的 MIDI 時間軸
  /// [spectrogram] 頻譜圖
  /// [detectedNotes] 檢測到的音符列表
  Future<SequenceMatchResult> match(
    MidiTimeline expectedTimeline,
    Spectrogram spectrogram,
    List<DetectedNote> detectedNotes,
  );
}

/// 序列匹配服務實現
///
/// 使用改進的動態規劃算法進行序列對齊
class SequenceMatcherService implements ISequenceMatcher {
  // 匹配參數
  static const double maxTimeDifference = 2.0; // 最大時間差 (秒)
  static const double pitchMatchWeight = 0.4; // 音高匹配權重
  static const double timingMatchWeight = 0.3; // 時間匹配權重
  static const double sequenceOrderWeight = 0.3; // 序列順序權重

  @override
  Future<SequenceMatchResult> match(
    MidiTimeline expectedTimeline,
    Spectrogram spectrogram,
    List<DetectedNote> detectedNotes,
  ) async {
    final expectedNotes = expectedTimeline.events;

    if (expectedNotes.isEmpty) {
      return SequenceMatchResult(
        matches: {},
        overallScore: 0.0,
        sequenceSimilarity: 0.0,
        timeOffset: 0.0,
      );
    }

    // 1. 計算時間偏移 (全局對齊)
    final timeOffset = _estimateTimeOffset(expectedNotes, detectedNotes);

    // 2. 使用動態規劃進行序列對齊
    final alignmentResult = _alignSequences(
      expectedNotes,
      detectedNotes,
      timeOffset,
    );

    // 3. 計算序列相似度
    final sequenceSimilarity = _calculateSequenceSimilarity(
      expectedNotes,
      detectedNotes,
      alignmentResult,
    );

    // 4. 計算整體分數
    final overallScore = _calculateOverallScore(
      alignmentResult,
      sequenceSimilarity,
    );

    return SequenceMatchResult(
      matches: alignmentResult,
      overallScore: overallScore,
      sequenceSimilarity: sequenceSimilarity,
      timeOffset: timeOffset,
    );
  }

  /// 估算時間偏移
  ///
  /// 找出最佳的全局時間偏移,使得期望音符和檢測音符最匹配
  double _estimateTimeOffset(
    List<NoteEvent> expectedNotes,
    List<DetectedNote> detectedNotes,
  ) {
    if (expectedNotes.isEmpty || detectedNotes.isEmpty) {
      return 0.0;
    }

    // 使用前幾個音符估算偏移
    final sampleSize = min(5, min(expectedNotes.length, detectedNotes.length));
    double totalOffset = 0.0;
    int validSamples = 0;

    for (int i = 0; i < sampleSize; i++) {
      final expected = expectedNotes[i];

      // 找出與期望音高最接近的檢測音符
      DetectedNote? bestMatch;
      double bestDistance = double.infinity;

      for (final detected in detectedNotes) {
        if (detected.midiNote == expected.midiNote) {
          final timeDiff = (detected.time - expected.startTime).abs();
          if (timeDiff < bestDistance) {
            bestDistance = timeDiff;
            bestMatch = detected;
          }
        }
      }

      if (bestMatch != null) {
        totalOffset += bestMatch.time - expected.startTime;
        validSamples++;
      }
    }

    return validSamples > 0 ? totalOffset / validSamples : 0.0;
  }

  /// 序列對齊 (動態規劃)
  ///
  /// 返回每個期望音符的最佳匹配 (索引 -> 檢測時間)
  Map<int, double?> _alignSequences(
    List<NoteEvent> expectedNotes,
    List<DetectedNote> detectedNotes,
    double timeOffset,
  ) {
    final matches = <int, double?>{};
    final usedDetections = <int>{}; // 記錄已使用的檢測音符

    // 貪心匹配: 按順序為每個期望音符找最佳匹配
    for (int i = 0; i < expectedNotes.length; i++) {
      final expected = expectedNotes[i];
      final expectedTime = expected.startTime + timeOffset;

      DetectedNote? bestMatch;
      int? bestMatchIndex;
      double bestScore = -1.0;

      // 在檢測音符中尋找最佳匹配
      for (int j = 0; j < detectedNotes.length; j++) {
        // 跳過已使用的音符
        if (usedDetections.contains(j)) continue;

        final detected = detectedNotes[j];
        final score = _calculateMatchScore(
          expected,
          detected,
          expectedTime,
          i,
          j,
          expectedNotes.length,
          detectedNotes.length,
        );

        if (score > bestScore) {
          bestScore = score;
          bestMatch = detected;
          bestMatchIndex = j;
        }
      }

      // 只接受分數足夠高的匹配
      if (bestMatch != null && bestScore > 0.3) {
        matches[i] = bestMatch.time;
        usedDetections.add(bestMatchIndex!);
      } else {
        matches[i] = null; // 未找到匹配
      }
    }

    return matches;
  }

  /// 計算單個音符的匹配分數
  double _calculateMatchScore(
    NoteEvent expected,
    DetectedNote detected,
    double expectedTime,
    int expectedIndex,
    int detectedIndex,
    int totalExpected,
    int totalDetected,
  ) {
    double score = 0.0;

    // 1. 音高匹配 (40%)
    if (detected.midiNote == expected.midiNote) {
      score += pitchMatchWeight;
    } else {
      // 音高不匹配,直接返回0
      return 0.0;
    }

    // 2. 時間匹配 (30%)
    final timeDiff = (detected.time - expectedTime).abs();
    if (timeDiff <= maxTimeDifference) {
      final timingScore = 1.0 - (timeDiff / maxTimeDifference);
      score += timingMatchWeight * timingScore;
    }

    // 3. 序列順序匹配 (30%)
    // 期望索引應該與檢測索引大致對應
    final expectedPosition = expectedIndex / totalExpected;
    final detectedPosition =
        totalDetected > 0 ? detectedIndex / totalDetected : 0.0;
    final positionDiff = (expectedPosition - detectedPosition).abs();
    final orderScore = 1.0 - positionDiff;
    score += sequenceOrderWeight * orderScore;

    return score.clamp(0.0, 1.0);
  }

  /// 計算序列相似度
  ///
  /// 檢查整體序列結構是否相似
  double _calculateSequenceSimilarity(
    List<NoteEvent> expectedNotes,
    List<DetectedNote> detectedNotes,
    Map<int, double?> alignmentResult,
  ) {
    if (expectedNotes.isEmpty) return 0.0;

    // 統計連續匹配的音符對
    int consecutiveMatches = 0;
    int maxConsecutive = 0;

    for (int i = 0; i < expectedNotes.length; i++) {
      if (alignmentResult[i] != null) {
        consecutiveMatches++;
        maxConsecutive = max(maxConsecutive, consecutiveMatches);
      } else {
        consecutiveMatches = 0;
      }
    }

    // 計算匹配率
    final matchRate = alignmentResult.values.where((v) => v != null).length /
        expectedNotes.length;

    // 計算連續性分數
    final consecutivenessScore = maxConsecutive / expectedNotes.length;

    // 綜合分數
    return (matchRate * 0.7 + consecutivenessScore * 0.3).clamp(0.0, 1.0);
  }

  /// 計算整體分數
  double _calculateOverallScore(
    Map<int, double?> alignmentResult,
    double sequenceSimilarity,
  ) {
    if (alignmentResult.isEmpty) return 0.0;

    // 匹配率
    final matchRate = alignmentResult.values.where((v) => v != null).length /
        alignmentResult.length;

    // 綜合評分: 70% 匹配率 + 30% 序列相似度
    return (matchRate * 0.7 + sequenceSimilarity * 0.3).clamp(0.0, 1.0);
  }
}

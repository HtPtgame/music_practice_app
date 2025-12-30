import 'dart:math';
import 'package:veloria/services/audio_analysis/sequence_matcher_service.dart';
import 'package:veloria/services/detected_note.dart';

/// Phase 1C: Dynamic Time Warping (DTW) 動態時間對齊
///
/// 用於處理演奏中的中斷、暫停、重新開始等情況。
/// DTW 可以找到兩個時間序列之間的最佳對齊路徑，
/// 即使它們在時間上有延遲、速度變化或中斷。
class DynamicTimeWarping {
  /// 使用 DTW 對齊檢測到的音符和期望的音符
  ///
  /// [detectedNotes] - 從錄音中檢測到的音符序列
  /// [expectedNotes] - MIDI 檔案中期望的音符序列
  ///
  /// 返回對齊結果，包含匹配對和時間偏移資訊
  AlignmentResult align(
    List<DetectedNote> detectedNotes,
    List<DetectedNote> expectedNotes,
  ) {
    if (detectedNotes.isEmpty || expectedNotes.isEmpty) {
      return AlignmentResult(
        matches: [],
        totalCost: double.infinity,
        timeOffset: 0.0,
        isAligned: false,
      );
    }

    final n = detectedNotes.length;
    final m = expectedNotes.length;

    // DTW 動態規劃矩陣
    // dtw[i][j] 表示對齊 detectedNotes[0..i] 和 expectedNotes[0..j] 的最小成本
    final dtw = List.generate(
      n + 1,
      (_) => List<double>.filled(m + 1, double.infinity),
    );

    dtw[0][0] = 0.0;

    // 填充 DTW 矩陣
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final cost = _calculateNoteCost(
          detectedNotes[i - 1],
          expectedNotes[j - 1],
        );

        dtw[i][j] = cost +
            min(
              min(
                dtw[i - 1][j], // 插入 (detected 多了一個音符)
                dtw[i][j - 1], // 刪除 (expected 多了一個音符)
              ),
              dtw[i - 1][j - 1], // 匹配
            );
      }
    }

    // 回溯找到最佳對齊路徑
    final matches = _backtrack(dtw, detectedNotes, expectedNotes);

    // 計算平均時間偏移
    final timeOffset = _calculateTimeOffset(matches);

    return AlignmentResult(
      matches: matches,
      totalCost: dtw[n][m],
      timeOffset: timeOffset,
      isAligned: dtw[n][m] < double.infinity,
    );
  }

  /// 計算兩個音符之間的成本 (距離)
  ///
  /// 成本越低表示兩個音符越相似
  /// - 音高相同: 成本 = 0
  /// - 音高差異: 成本 = |pitch1 - pitch2| / 12 (半音距離正規化)
  /// - 時間差異: 額外加成本
  double _calculateNoteCost(DetectedNote detected, DetectedNote expected) {
    // 基礎成本：音高差異
    final pitchDiff = (detected.midiNote - expected.midiNote).abs();
    double cost = pitchDiff / 12.0; // 正規化到 [0, 1] 範圍

    // 如果音高完全相同，檢查時間差異
    if (pitchDiff == 0) {
      final timeDiff = (detected.time - expected.time).abs();

      // 時間差異在合理範圍內 (±2秒)，成本很低
      if (timeDiff < 2.0) {
        cost = timeDiff * 0.1; // 時間匹配獎勵
      } else {
        cost = 1.0 + (timeDiff - 2.0) * 0.5; // 時間差異懲罰
      }
    } else {
      // 音高不同，基本成本較高
      cost = 1.0 + pitchDiff / 6.0;
    }

    return cost;
  }

  /// 回溯 DTW 矩陣，找到最佳對齊路徑
  List<NoteMatch> _backtrack(
    List<List<double>> dtw,
    List<DetectedNote> detectedNotes,
    List<DetectedNote> expectedNotes,
  ) {
    final matches = <NoteMatch>[];
    int i = detectedNotes.length;
    int j = expectedNotes.length;

    while (i > 0 && j > 0) {
      final diag = dtw[i - 1][j - 1];
      final left = dtw[i][j - 1];
      final up = dtw[i - 1][j];

      // 找到最小成本的前一步
      if (diag <= left && diag <= up) {
        // 匹配 (對角線)
        matches.add(NoteMatch(
          detectedNote: detectedNotes[i - 1],
          expectedNote: expectedNotes[j - 1],
          cost: _calculateNoteCost(detectedNotes[i - 1], expectedNotes[j - 1]),
          type: MatchType.match,
        ));
        i--;
        j--;
      } else if (left <= up) {
        // 刪除 (向左) - expected 多了一個音符 (漏音)
        matches.add(NoteMatch(
          detectedNote: null,
          expectedNote: expectedNotes[j - 1],
          cost: dtw[i][j] - left,
          type: MatchType.deletion,
        ));
        j--;
      } else {
        // 插入 (向上) - detected 多了一個音符 (錯音)
        matches.add(NoteMatch(
          detectedNote: detectedNotes[i - 1],
          expectedNote: null,
          cost: dtw[i][j] - up,
          type: MatchType.insertion,
        ));
        i--;
      }
    }

    // 處理剩餘的音符
    while (i > 0) {
      matches.add(NoteMatch(
        detectedNote: detectedNotes[i - 1],
        expectedNote: null,
        cost: 1.0,
        type: MatchType.insertion,
      ));
      i--;
    }

    while (j > 0) {
      matches.add(NoteMatch(
        detectedNote: null,
        expectedNote: expectedNotes[j - 1],
        cost: 1.0,
        type: MatchType.deletion,
      ));
      j--;
    }

    return matches.reversed.toList(); // 反轉以獲得正序
  }

  /// 計算平均時間偏移
  ///
  /// 找出 detected 和 expected 音符的平均時間差異
  double _calculateTimeOffset(List<NoteMatch> matches) {
    if (matches.isEmpty) return 0.0;

    final offsets = <double>[];

    for (final match in matches) {
      if (match.type == MatchType.match &&
          match.detectedNote != null &&
          match.expectedNote != null) {
        final offset = match.detectedNote!.time - match.expectedNote!.time;
        offsets.add(offset);
      }
    }

    if (offsets.isEmpty) return 0.0;

    // 使用中位數而非平均值，更能抵抗離群值
    offsets.sort();
    if (offsets.length.isOdd) {
      return offsets[offsets.length ~/ 2];
    } else {
      final mid = offsets.length ~/ 2;
      return (offsets[mid - 1] + offsets[mid]) / 2.0;
    }
  }

  /// 檢測演奏中的中斷點
  ///
  /// 識別出用戶可能暫停、重新開始的位置
  List<InterruptionPoint> detectInterruptions(
    List<DetectedNote> detectedNotes, {
    double minGapSeconds = 3.0, // 最小間隔被視為中斷
  }) {
    final interruptions = <InterruptionPoint>[];

    if (detectedNotes.length < 2) return interruptions;

    for (int i = 0; i < detectedNotes.length - 1; i++) {
      final currentNote = detectedNotes[i];
      final nextNote = detectedNotes[i + 1];

      // DetectedNote 沒有 duration 屬性，假設每個音符持續 0.5 秒
      const double estimatedNoteDuration = 0.5;
      final gap = nextNote.time - (currentNote.time + estimatedNoteDuration);

      if (gap >= minGapSeconds) {
        interruptions.add(InterruptionPoint(
          indexBefore: i,
          indexAfter: i + 1,
          gapDuration: gap,
          timeBefore: currentNote.time + estimatedNoteDuration,
          timeAfter: nextNote.time,
        ));
      }
    }

    return interruptions;
  }

  /// 分段對齊：處理有中斷的演奏
  ///
  /// 將演奏分成多個連續段落，分別進行 DTW 對齊
  SegmentedAlignmentResult alignWithInterruptions(
    List<DetectedNote> detectedNotes,
    List<DetectedNote> expectedNotes,
  ) {
    // 檢測中斷點
    final interruptions = detectInterruptions(detectedNotes);

    if (interruptions.isEmpty) {
      // 沒有中斷，直接整體對齊
      final result = align(detectedNotes, expectedNotes);
      return SegmentedAlignmentResult(
        segments: [
          AlignmentSegment(
            detectedStart: 0,
            detectedEnd: detectedNotes.length,
            expectedStart: 0,
            expectedEnd: expectedNotes.length,
            alignment: result,
          )
        ],
        interruptions: [],
      );
    }

    // 有中斷，分段對齊
    final segments = <AlignmentSegment>[];
    int detectedStart = 0;
    int expectedStart = 0;

    for (int i = 0; i <= interruptions.length; i++) {
      final detectedEnd = i < interruptions.length
          ? interruptions[i].indexAfter
          : detectedNotes.length;

      if (detectedEnd > detectedStart) {
        // 提取當前段落
        final detectedSegment =
            detectedNotes.sublist(detectedStart, detectedEnd);

        // 在 expected 中尋找最佳匹配段落
        AlignmentResult? bestAlignment;
        int bestExpectedEnd = expectedStart;
        double bestCost = double.infinity;

        for (int expEnd = expectedStart + 1;
            expEnd <= expectedNotes.length;
            expEnd++) {
          final expectedSegment = expectedNotes.sublist(expectedStart, expEnd);
          final alignment = align(detectedSegment, expectedSegment);

          if (alignment.totalCost < bestCost) {
            bestCost = alignment.totalCost;
            bestAlignment = alignment;
            bestExpectedEnd = expEnd;
          }

          // 如果成本已經很低，可以提前停止搜索
          if (bestCost < detectedSegment.length * 0.2) break;
        }

        if (bestAlignment != null) {
          segments.add(AlignmentSegment(
            detectedStart: detectedStart,
            detectedEnd: detectedEnd,
            expectedStart: expectedStart,
            expectedEnd: bestExpectedEnd,
            alignment: bestAlignment,
          ));

          expectedStart = bestExpectedEnd;
        }
      }

      detectedStart = detectedEnd;
    }

    return SegmentedAlignmentResult(
      segments: segments,
      interruptions: interruptions,
    );
  }
}

/// DTW 對齊結果
class AlignmentResult {
  final List<NoteMatch> matches;
  final double totalCost;
  final double timeOffset; // 平均時間偏移 (秒)
  final bool isAligned;

  AlignmentResult({
    required this.matches,
    required this.totalCost,
    required this.timeOffset,
    required this.isAligned,
  });

  /// 計算對齊品質分數 (0-1, 越高越好)
  double get qualityScore {
    if (matches.isEmpty) return 0.0;

    final matchCount = matches.where((m) => m.type == MatchType.match).length;
    final totalNotes = matches.length;

    return matchCount / totalNotes;
  }
}

/// 音符匹配
class NoteMatch {
  final DetectedNote? detectedNote; // null 表示漏音
  final DetectedNote? expectedNote; // null 表示錯音
  final double cost;
  final MatchType type;

  NoteMatch({
    required this.detectedNote,
    required this.expectedNote,
    required this.cost,
    required this.type,
  });

  bool get isPerfectMatch =>
      type == MatchType.match &&
      detectedNote != null &&
      expectedNote != null &&
      detectedNote!.midiNote == expectedNote!.midiNote &&
      cost < 0.3;
}

/// 匹配類型
enum MatchType {
  match, // 匹配
  insertion, // 插入 (錯音)
  deletion, // 刪除 (漏音)
}

/// 中斷點
class InterruptionPoint {
  final int indexBefore; // 中斷前的音符索引
  final int indexAfter; // 中斷後的音符索引
  final double gapDuration; // 間隔時長 (秒)
  final double timeBefore; // 中斷前的時間點
  final double timeAfter; // 中斷後的時間點

  InterruptionPoint({
    required this.indexBefore,
    required this.indexAfter,
    required this.gapDuration,
    required this.timeBefore,
    required this.timeAfter,
  });
}

/// 分段對齊結果
class SegmentedAlignmentResult {
  final List<AlignmentSegment> segments;
  final List<InterruptionPoint> interruptions;

  SegmentedAlignmentResult({
    required this.segments,
    required this.interruptions,
  });

  /// 總體品質分數
  double get overallQuality {
    if (segments.isEmpty) return 0.0;

    final totalQuality =
        segments.map((s) => s.alignment.qualityScore).reduce((a, b) => a + b);

    return totalQuality / segments.length;
  }

  /// 合併所有段落的匹配
  List<NoteMatch> get allMatches {
    return segments.expand((s) => s.alignment.matches).toList();
  }
}

/// 對齊段落
class AlignmentSegment {
  final int detectedStart;
  final int detectedEnd;
  final int expectedStart;
  final int expectedEnd;
  final AlignmentResult alignment;

  AlignmentSegment({
    required this.detectedStart,
    required this.detectedEnd,
    required this.expectedStart,
    required this.expectedEnd,
    required this.alignment,
  });
}

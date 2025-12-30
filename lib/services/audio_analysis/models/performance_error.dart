// 📂 檔名: lib/services/audio_analysis/models/performance_error.dart

/// 演奏錯誤類型
enum ErrorType {
  /// ✅ 正確
  correct,

  /// ❌ 錯音 - 彈了不該彈的音符
  wrongNote,

  /// ⚠️ 漏音 - 該彈的音符沒彈
  missedNote,

  /// ⏩ 搶拍 - 提前彈奏 (>100ms)
  earlyTiming,

  /// ⏸️ 拖拍 - 延遲彈奏 (>100ms)
  lateTiming,
  
  /// 👻 多餘音 - 額外的雜訊 (V20 新增相容)
  extraNote,
}

/// 演奏錯誤詳情
class PerformanceError {
  /// 錯誤發生時間點 (統一欄位，對應 V20 的 time 參數)
  final double time;

  /// 錯誤類型
  final ErrorType type;

  /// 預期的 MIDI 音符 (如果有)
  final int? expectedNote;

  /// 實際彈奏的 MIDI 音符 (如果有)
  final int? actualNote;

  /// 實際彈奏時間 (秒,如果有)
  final double? actualTime;

  /// 時間偏移 (秒, 正數=遲到, 負數=提前)
  final double? timingOffset;

  /// 錯誤描述信息
  final String message;

  /// 置信度 (0-1)
  final double confidence;

  PerformanceError({
    required this.time, // ✅ 改用 time 以匹配 V20 分析器
    required this.type,
    required this.message,
    this.expectedNote,
    this.actualNote,
    this.actualTime,
    this.timingOffset,
    this.confidence = 1.0,
  });

  /// 為了相容舊 UI 的 getter
  /// 如果你的 UI 原本是用 .expectedTime，這個 getter 會讓它繼續運作
  double get expectedTime => time;

  /// 是否為節奏問題
  bool get isTimingError =>
      type == ErrorType.earlyTiming || type == ErrorType.lateTiming;

  /// 是否為音高問題
  bool get isPitchError =>
      type == ErrorType.wrongNote || type == ErrorType.missedNote || type == ErrorType.extraNote;

  /// 計算錯誤嚴重程度 (0-1)
  /// 用於熱力圖顏色深淺
  double get severity {
    switch (type) {
      case ErrorType.correct:
        return 0.0;
      case ErrorType.wrongNote:
        return 1.0; // 紅色最深
      case ErrorType.missedNote:
        return 0.9; // 黃色/橘色
      case ErrorType.extraNote:
        return 0.5; // 雜訊輕微
      case ErrorType.lateTiming:
        return 0.3 + (timingOffset?.abs() ?? 0) * 2; // 最多0.6
      case ErrorType.earlyTiming:
        return 0.3 + (timingOffset?.abs() ?? 0) * 2;
    }
  }

  /// 獲取錯誤圖標 (UI 直接顯示這個)
  String get icon {
    switch (type) {
      case ErrorType.correct:
        return '✅';
      case ErrorType.wrongNote:
        return '❌';
      case ErrorType.missedNote:
        return '⚠️';
      case ErrorType.earlyTiming:
        return '⏩';
      case ErrorType.lateTiming:
        return '⏸️';
      case ErrorType.extraNote:
        return '👻';
    }
  }

  @override
  String toString() {
    return '$icon $message (at ${time.toStringAsFixed(2)}s) [Exp:$expectedNote, Act:$actualNote]';
  }
}

/// 對齊結果 (保留原本邏輯)
class AlignmentResult {
  /// 時間偏移量 (秒)
  final double timeOffset;

  /// 對齊誤差 (秒)
  final double alignmentError;

  /// 對齊置信度 (0-1)
  final double confidence;

  AlignmentResult({
    required this.timeOffset,
    required this.alignmentError,
    this.confidence = 1.0,
  });

  @override
  String toString() {
    return 'AlignmentResult(offset: ${(timeOffset * 1000).toStringAsFixed(0)}ms, '
        'error: ${(alignmentError * 1000).toStringAsFixed(0)}ms)';
  }
}
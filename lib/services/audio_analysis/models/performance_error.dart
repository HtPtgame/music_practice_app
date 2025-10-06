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
}

/// 演奏錯誤詳情
class PerformanceError {
  /// 錯誤類型
  final ErrorType type;
  
  /// 預期的 MIDI 音符 (如果有)
  final int? expectedNote;
  
  /// 實際彈奏的 MIDI 音符 (如果有)
  final int? actualNote;
  
  /// 預期時間 (秒)
  final double expectedTime;
  
  /// 實際時間 (秒,如果有)
  final double? actualTime;
  
  /// 時間偏移 (秒, 正數=遲到, 負數=提前)
  final double? timingOffset;
  
  /// 錯誤描述信息
  final String message;
  
  /// 置信度 (0-1)
  final double confidence;

  PerformanceError({
    required this.type,
    this.expectedNote,
    this.actualNote,
    required this.expectedTime,
    this.actualTime,
    this.timingOffset,
    required this.message,
    this.confidence = 1.0,
  });

  /// 是否為節奏問題
  bool get isTimingError => type == ErrorType.earlyTiming || type == ErrorType.lateTiming;

  /// 是否為音高問題
  bool get isPitchError => type == ErrorType.wrongNote || type == ErrorType.missedNote;

  /// 錯誤嚴重程度 (0-1, 1最嚴重)
  double get severity {
    switch (type) {
      case ErrorType.correct:
        return 0.0;
      case ErrorType.wrongNote:
        return 1.0;
      case ErrorType.missedNote:
        return 0.9;
      case ErrorType.lateTiming:
        return 0.3 + (timingOffset?.abs() ?? 0) * 2; // 最多0.6
      case ErrorType.earlyTiming:
        return 0.3 + (timingOffset?.abs() ?? 0) * 2;
    }
  }

  /// 獲取錯誤圖標
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
    }
  }

  @override
  String toString() {
    return '$icon $message (${expectedTime.toStringAsFixed(2)}s)';
  }
}

/// 對齊結果
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

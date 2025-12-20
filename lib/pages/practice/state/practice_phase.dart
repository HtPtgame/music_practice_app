/// 練習頁面的階段狀態
/// 
/// Phase 3 重構: 集中管理練習頁面的所有狀態階段
enum PracticePhase {
  /// 閒置狀態 - 初始狀態,可以開始錄音或上傳
  idle,
  
  /// 準備錄音 - 倒數計時中
  preparing,
  
  /// 錄音中 - 正在進行錄音
  recording,
  
  /// 播放中 - 正在播放錄音或 MIDI
  playing,
  
  /// 已暫停 - 播放暫停中
  paused,
  
  /// 分析中 - 正在分析演奏
  analyzing,
  
  /// 上傳中 - 正在上傳檔案
  uploading,
}

/// 錄音模式
enum RecordingMode {
  /// 錄音模式 - 使用麥克風錄音
  record,
  
  /// 上傳模式 - 從檔案系統上傳
  upload,
}

/// PracticePhase 擴展方法
extension PracticePhaseExtension on PracticePhase {
  /// 是否正在執行操作（不能同時執行其他操作）
  bool get isBusy {
    return this == PracticePhase.recording ||
        this == PracticePhase.playing ||
        this == PracticePhase.analyzing ||
        this == PracticePhase.uploading ||
        this == PracticePhase.preparing;
  }
  
  /// 是否可以開始錄音
  bool get canStartRecording {
    return this == PracticePhase.idle;
  }
  
  /// 是否可以播放
  bool get canPlay {
    return this == PracticePhase.idle;
  }
  
  /// 是否可以分析
  bool get canAnalyze {
    return this == PracticePhase.idle;
  }
  
  /// 顯示文字
  String get displayText {
    switch (this) {
      case PracticePhase.idle:
        return '就緒';
      case PracticePhase.preparing:
        return '準備中';
      case PracticePhase.recording:
        return '錄音中';
      case PracticePhase.playing:
        return '播放中';
      case PracticePhase.paused:
        return '已暫停';
      case PracticePhase.analyzing:
        return '分析中';
      case PracticePhase.uploading:
        return '上傳中';
    }
  }
}

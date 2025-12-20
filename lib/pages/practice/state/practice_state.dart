import 'package:flutter/foundation.dart';
import 'practice_phase.dart';

/// 練習頁面的狀態管理
/// 
/// Phase 3 重構: 使用 ChangeNotifier 集中管理所有練習相關狀態
class PracticeState extends ChangeNotifier {
  // ===== 階段狀態 =====
  PracticePhase _phase = PracticePhase.idle;
  PracticePhase get phase => _phase;
  
  // ===== 錄音模式 =====
  RecordingMode _mode = RecordingMode.record;
  RecordingMode get mode => _mode;
  
  // ===== 音訊路徑 =====
  String? _audioPath;
  String? get audioPath => _audioPath;
  
  // ===== 錄音時長 (秒) =====
  int _recordingDuration = 0;
  int get recordingDuration => _recordingDuration;
  
  // ===== 播放進度 =====
  double _playbackPosition = 0.0;
  double _playbackDuration = 0.0;
  double get playbackPosition => _playbackPosition;
  double get playbackDuration => _playbackDuration;
  
  // ===== 分析進度 =====
  double _analysisProgress = 0.0;
  String _analysisPhase = '';
  double get analysisProgress => _analysisProgress;
  String get analysisPhase => _analysisPhase;
  
  // ===== 設定 =====
  bool _enableCountdown = true;
  bool get enableCountdown => _enableCountdown;
  
  // ===== 錯誤訊息 =====
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  // ========== 狀態更新方法 ==========
  
  /// 設定階段
  void setPhase(PracticePhase newPhase) {
    if (_phase != newPhase) {
      _phase = newPhase;
      notifyListeners();
    }
  }
  
  /// 設定錄音模式
  void setMode(RecordingMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
    }
  }
  
  /// 設定音訊路徑
  void setAudioPath(String? path) {
    _audioPath = path;
    notifyListeners();
  }
  
  /// 更新錄音時長
  void updateRecordingDuration(int seconds) {
    _recordingDuration = seconds;
    notifyListeners();
  }
  
  /// 更新播放進度
  void updatePlaybackProgress(double position, double duration) {
    _playbackPosition = position;
    _playbackDuration = duration;
    notifyListeners();
  }
  
  /// 更新分析進度
  void updateAnalysisProgress(double progress, String phase) {
    _analysisProgress = progress;
    _analysisPhase = phase;
    notifyListeners();
  }
  
  /// 設定倒數計時開關
  void setEnableCountdown(bool enabled) {
    if (_enableCountdown != enabled) {
      _enableCountdown = enabled;
      notifyListeners();
    }
  }
  
  /// 設定錯誤訊息
  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  /// 清除錯誤
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
  
  /// 重置狀態
  void reset() {
    _phase = PracticePhase.idle;
    _recordingDuration = 0;
    _playbackPosition = 0.0;
    _playbackDuration = 0.0;
    _analysisProgress = 0.0;
    _analysisPhase = '';
    _errorMessage = null;
    notifyListeners();
  }
  
  /// 重置播放狀態
  void resetPlayback() {
    _playbackPosition = 0.0;
    _playbackDuration = 0.0;
    if (_phase == PracticePhase.playing || _phase == PracticePhase.paused) {
      _phase = PracticePhase.idle;
    }
    notifyListeners();
  }
  
  /// 重置錄音狀態
  void resetRecording() {
    _recordingDuration = 0;
    if (_phase == PracticePhase.recording || _phase == PracticePhase.preparing) {
      _phase = PracticePhase.idle;
    }
    notifyListeners();
  }
  
  // ========== 便捷方法 ==========
  
  /// 是否有可用的音訊檔案
  bool get hasAudioFile => _audioPath != null && _audioPath!.isNotEmpty;
  
  /// 是否正在錄音
  bool get isRecording => _phase == PracticePhase.recording;
  
  /// 是否正在播放
  bool get isPlaying => _phase == PracticePhase.playing;
  
  /// 是否已暫停
  bool get isPaused => _phase == PracticePhase.paused;
  
  /// 是否正在分析
  bool get isAnalyzing => _phase == PracticePhase.analyzing;
  
  /// 是否處於錄音模式
  bool get isRecordMode => _mode == RecordingMode.record;
  
  /// 是否處於上傳模式
  bool get isUploadMode => _mode == RecordingMode.upload;
  
  /// 格式化錄音時長
  String get formattedRecordingDuration {
    final minutes = _recordingDuration ~/ 60;
    final seconds = _recordingDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  /// 格式化播放進度
  String get formattedPlaybackProgress {
    final posMin = _playbackPosition ~/ 60;
    final posSec = (_playbackPosition % 60).toInt();
    final durMin = _playbackDuration ~/ 60;
    final durSec = (_playbackDuration % 60).toInt();
    return '${posMin.toString().padLeft(2, '0')}:${posSec.toString().padLeft(2, '0')} / '
        '${durMin.toString().padLeft(2, '0')}:${durSec.toString().padLeft(2, '0')}';
  }
  
  /// 播放進度百分比
  double get playbackProgressPercent {
    if (_playbackDuration <= 0) return 0.0;
    return (_playbackPosition / _playbackDuration).clamp(0.0, 1.0);
  }
}

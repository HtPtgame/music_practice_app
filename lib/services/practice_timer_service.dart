// lib/services/practice_timer_service.dart
import 'package:flutter/foundation.dart';

/// 全局練習計時器狀態服務
/// 用於跨頁面檢測計時器運行狀態，在頁面切換時提供警告
class PracticeTimerService extends ChangeNotifier {
  static final PracticeTimerService _instance =
      PracticeTimerService._internal();
  factory PracticeTimerService() => _instance;
  PracticeTimerService._internal();

  bool _isTimerRunning = false;
  bool _shouldPauseAndSave = false; // 新增：標記是否需要暫停並保存

  /// 計時器是否正在運行
  bool get isTimerRunning => _isTimerRunning;

  /// 是否需要暫停並保存（用於頁面切換時）
  bool get shouldPauseAndSave => _shouldPauseAndSave;

  /// 設置計時器運行狀態
  void setTimerRunning(bool isRunning) {
    if (_isTimerRunning != isRunning) {
      _isTimerRunning = isRunning;
      notifyListeners();
      debugPrint('計時器狀態變更: ${isRunning ? "運行中" : "已停止"}');
    }
  }

  /// 請求暫停並保存（由導航邏輯調用）
  void requestPauseAndSave() {
    _shouldPauseAndSave = true;
    notifyListeners();
    debugPrint('請求暫停並保存計時器數據');
  }

  /// 確認已處理暫停和保存（由計時器組件調用）
  void confirmPauseAndSaveHandled() {
    _shouldPauseAndSave = false;
    debugPrint('已確認處理暫停和保存');
  }

  /// 重置狀態（用於測試或特殊情況）
  void reset() {
    _isTimerRunning = false;
    _shouldPauseAndSave = false;
    notifyListeners();
  }
}

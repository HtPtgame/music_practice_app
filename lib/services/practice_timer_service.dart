// lib/services/practice_timer_service.dart
import 'package:flutter/foundation.dart';

/// 全局練習計時器狀態服務
/// 用於跨頁面檢測計時器運行狀態，在頁面切換時提供警告
class PracticeTimerService extends ChangeNotifier {
  static final PracticeTimerService _instance = PracticeTimerService._internal();
  factory PracticeTimerService() => _instance;
  PracticeTimerService._internal();

  bool _isTimerRunning = false;
  
  /// 計時器是否正在運行
  bool get isTimerRunning => _isTimerRunning;

  /// 設置計時器運行狀態
  void setTimerRunning(bool isRunning) {
    if (_isTimerRunning != isRunning) {
      _isTimerRunning = isRunning;
      notifyListeners();
      debugPrint('計時器狀態變更: ${isRunning ? "運行中" : "已停止"}');
    }
  }

  /// 重置狀態（用於測試或特殊情況）
  void reset() {
    _isTimerRunning = false;
    notifyListeners();
  }
}

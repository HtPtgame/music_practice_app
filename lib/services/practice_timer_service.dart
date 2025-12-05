// lib/services/practice_timer_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 全局練習計時器服務
/// 支援跨頁面計時、背景運行、自動暫停
class PracticeTimerService extends ChangeNotifier with WidgetsBindingObserver {
  static final PracticeTimerService _instance = PracticeTimerService._internal();
  factory PracticeTimerService() => _instance;
  
  PracticeTimerService._internal();

  bool _initialized = false;

  // 計時狀態
  bool _isRunning = false;
  DateTime? _startTime;
  int _accumulatedSeconds = 0; // 累計已暫停前的秒數
  
  // 背景處理
  DateTime? _backgroundTime;
  static const int _defaultPauseThresholdSeconds = 120; // 預設 2 分鐘
  int _pauseThresholdSeconds = _defaultPauseThresholdSeconds;
  
  // 顯示設定
  bool _showFloatingTimer = true;
  bool _showNotification = true; // 預設開啟通知
  
  // 當日累計（從 SharedPreferences 載入）
  int _todayTotalSeconds = 0;
  String _lastDate = '';
  
  // 停止請求標誌（用於通知 PracticeTimerCard 停止）
  bool _stopRequested = false;
  
  // 今日已累計的秒數（包含之前的練習）
  int _todayPreviousSeconds = 0;
  
  // 通知相關
  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  Timer? _notificationUpdateTimer;
  static const int _notificationId = 1001;
  
  // 自己的計時 Timer（確保跨頁面繼續計時）
  Timer? _countingTimer;

  // Getters
  bool get isRunning => _isRunning;
  bool get showFloatingTimer => _showFloatingTimer;
  bool get showNotification => _showNotification;
  int get pauseThresholdSeconds => _pauseThresholdSeconds;
  int get todayTotalSeconds => _todayTotalSeconds;
  bool get stopRequested => _stopRequested;
  
  // 通知語言設定
  String _currentLanguage = 'zh_TW';
  
  /// 設定當前語言
  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
  }
  
  /// 獲取本地化通知文字
  String _getNotificationTitle(String type) {
    final isEnglish = _currentLanguage.startsWith('en');
    switch (type) {
      case 'practicing':
        return isEnglish ? '🎵 Practicing' : '🎵 練習中';
      case 'paused':
        return isEnglish ? '⏸️ Practice Paused' : '⏸️ 練習暫停';
      case 'completed':
        return isEnglish ? '✅ Practice Complete' : '✅ 練習完成';
      default:
        return '';
    }
  }
  
  String _getNotificationBody(String type, String timeString) {
    final isEnglish = _currentLanguage.startsWith('en');
    switch (type) {
      case 'practicing':
      case 'paused':
        return isEnglish ? 'Today\'s practice: $timeString' : '今日練習: $timeString';
      case 'completed':
        return isEnglish ? 'This session: $timeString' : '本次練習: $timeString';
      default:
        return '';
    }
  }
  
  String _getChannelName() {
    final isEnglish = _currentLanguage.startsWith('en');
    return isEnglish ? 'Practice Timer' : '練習計時器';
  }
  
  String _getChannelDescription() {
    final isEnglish = _currentLanguage.startsWith('en');
    return isEnglish ? 'Shows practice timer progress' : '顯示練習計時進度';
  }
  
  /// 清除停止請求標誌
  void clearStopRequest() {
    _stopRequested = false;
  }
  
  // 兼容舊代碼
  bool get isTimerRunning => _isRunning;
  bool get shouldPauseAndSave => false;
  
  /// 獲取當前計時秒數（即時計算）
  int getElapsedSeconds() {
    if (!_isRunning || _startTime == null) {
      return _accumulatedSeconds;
    }
    final now = DateTime.now();
    return _accumulatedSeconds + now.difference(_startTime!).inSeconds;
  }
  
  /// 設定今日已累計的秒數（在計時開始時由 PracticeTimerCard 調用）
  void setTodayPreviousSeconds(int seconds) {
    _todayPreviousSeconds = seconds;
  }
  
  /// 獲取今日之前累計的秒數
  int get todayPreviousSeconds => _todayPreviousSeconds;
  
  /// 是否有累計時間（用於判斷是否在暫停狀態）
  bool get hasAccumulatedTime => _accumulatedSeconds > 0;
  
  /// 是否在暫停狀態（有累計時間但未運行）
  bool get isPaused => !_isRunning && _accumulatedSeconds > 0;

  /// 獲取當日總練習時長（含當前計時）
  int getTodayTotalWithCurrent() {
    return _todayPreviousSeconds + getElapsedSeconds();
  }
  
  /// 格式化今日總練習時長
  String formatTodayTotal() {
    final seconds = getTodayTotalWithCurrent();
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// 初始化服務
  Future<void> initialize() async {
    if (_initialized) return;
    
    WidgetsBinding.instance.addObserver(this);
    await _loadSettings();
    await _loadTodayData();
    await _initializeNotifications();
    
    // 確保通知功能開啟（首次使用或舊版升級）
    if (!_showNotification) {
      _showNotification = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('timer_show_notification', true);
      debugPrint('🔔 已自動啟用通知功能');
    }
    
    _initialized = true;
    debugPrint('⏱️ PracticeTimerService 初始化完成');
  }
  
  // 通知操作 ID
  static const String _actionPause = 'pause_timer';
  static const String _actionResume = 'resume_timer';
  static const String _actionStop = 'stop_timer';
  
  /// 初始化通知系統
  Future<void> _initializeNotifications() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notificationsPlugin?.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    
    // Android 13+ 請求通知權限
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin?.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      debugPrint('🔔 通知權限: ${granted == true ? "已授權" : "未授權"}');
    }
    
    debugPrint('🔔 通知系統初始化完成');
  }

  /// 載入設定
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showFloatingTimer = prefs.getBool('timer_show_floating') ?? true;
      _showNotification = prefs.getBool('timer_show_notification') ?? true; // 預設開啟通知
      _pauseThresholdSeconds = prefs.getInt('timer_pause_threshold') ?? _defaultPauseThresholdSeconds;
    } catch (e) {
      debugPrint('載入計時器設定失敗: $e');
    }
  }

  /// 載入當日數據
  Future<void> _loadTodayData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayString();
      
      // 檢查是否跨日
      _lastDate = prefs.getString('timer_last_date') ?? '';
      if (_lastDate != today) {
        _todayTotalSeconds = 0;
        _lastDate = today;
        await prefs.setString('timer_last_date', today);
      } else {
        // 從 practice_data 讀取當日數據
        final dataJson = prefs.getString('practice_data');
        if (dataJson != null) {
          final data = Map<String, dynamic>.from(jsonDecode(dataJson) as Map);
          _todayTotalSeconds = (data[today] as int?) ?? 0;
        }
      }
    } catch (e) {
      debugPrint('載入當日數據失敗: $e');
    }
  }

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 安全地調用 notifyListeners，避免在 widget tree 被鎖定時調用
  void _safeNotifyListeners() {
    // 使用 Future.microtask 確保在下一個微任務中執行
    // 這樣可以避免在 build 過程中調用 notifyListeners
    Future.microtask(() {
      notifyListeners();
    });
  }

  /// 開始計時
  void start() {
    if (_isRunning) return;
    
    _startTime = DateTime.now();
    _accumulatedSeconds = 0;
    _isRunning = true;
    
    // 開始自己的計時 Timer
    _startCountingTimer();
    
    // 開始顯示通知
    if (_showNotification) {
      _startNotificationUpdates();
    }
    
    debugPrint('⏱️ 計時開始');
    _safeNotifyListeners();
  }
  
  /// 開始計時 Timer
  void _startCountingTimer() {
    _countingTimer?.cancel();
    _countingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // 每秒更新一次，通知所有監聽者
      _safeNotifyListeners();
    });
  }
  
  /// 停止計時 Timer
  void _stopCountingTimer() {
    _countingTimer?.cancel();
    _countingTimer = null;
  }

  /// 暫停計時
  void pause() {
    if (!_isRunning) return;
    
    _accumulatedSeconds = getElapsedSeconds();
    _startTime = null;
    _isRunning = false;
    
    // 停止計時 Timer
    _stopCountingTimer();
    
    // 暫停時取消計時通知，顯示暫停通知
    _stopNotificationUpdates();
    _showPausedNotification();
    
    debugPrint('⏸️ 計時暫停，累計: $_accumulatedSeconds 秒');
    _safeNotifyListeners();
  }

  /// 繼續計時
  void resume() {
    if (_isRunning) return;
    if (_accumulatedSeconds == 0) {
      // 如果沒有累計時間，視為新開始
      start();
      return;
    }
    
    _startTime = DateTime.now();
    _isRunning = true;
    
    // 重新開始計時 Timer
    _startCountingTimer();
    
    // 恢復通知
    if (_showNotification) {
      _startNotificationUpdates();
    }
    
    debugPrint('▶️ 計時繼續');
    _safeNotifyListeners();
  }

  /// 停止並保存計時（由浮動視窗調用時，設置請求標誌）
  Future<void> stop() async {
    final elapsed = getElapsedSeconds();
    
    // 停止計時 Timer
    _stopCountingTimer();
    
    // 取消計時通知
    _stopNotificationUpdates();
    
    // 設置停止請求標誌，讓 PracticeTimerCard 處理實際的停止和保存
    _stopRequested = true;
    _safeNotifyListeners();
    
    // 等待一小段時間讓 PracticeTimerCard 處理
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 如果仍在運行（PracticeTimerCard 沒有處理），則直接停止
    if (_isRunning) {
      _isRunning = false;
      _startTime = null;
      _accumulatedSeconds = 0;
      
      if (elapsed > 0) {
        await _savePracticeTime(elapsed);
        _todayTotalSeconds += elapsed;
        debugPrint('⏹️ 計時停止，本次: $elapsed 秒，當日累計: $_todayTotalSeconds 秒');
      }
      
      _safeNotifyListeners();
    }
    
    // 顯示停止通知
    await _showStoppedNotification(elapsed);
  }

  /// 保存練習時間到 SharedPreferences
  Future<void> _savePracticeTime(int seconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayString();
      
      // 讀取現有數據
      final dataJson = prefs.getString('practice_data') ?? '{}';
      final data = Map<String, dynamic>.from(jsonDecode(dataJson) as Map);
      
      // 更新當日數據
      final currentSeconds = (data[today] as int?) ?? 0;
      data[today] = currentSeconds + seconds;
      
      // 保存
      await prefs.setString('practice_data', jsonEncode(data));
      debugPrint('💾 已保存練習時間: ${data[today]} 秒');
    } catch (e) {
      debugPrint('保存練習時間失敗: $e');
    }
  }

  /// 更新顯示設定
  Future<void> updateSettings({
    bool? showFloatingTimer,
    bool? showNotification,
    int? pauseThresholdSeconds,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (showFloatingTimer != null) {
        _showFloatingTimer = showFloatingTimer;
        await prefs.setBool('timer_show_floating', showFloatingTimer);
      }
      if (showNotification != null) {
        _showNotification = showNotification;
        await prefs.setBool('timer_show_notification', showNotification);
      }
      if (pauseThresholdSeconds != null) {
        _pauseThresholdSeconds = pauseThresholdSeconds;
        await prefs.setInt('timer_pause_threshold', pauseThresholdSeconds);
      }
      
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('更新計時器設定失敗: $e');
    }
  }

  /// 設定是否顯示浮動計時器
  Future<void> setShowFloatingTimer(bool value) async {
    await updateSettings(showFloatingTimer: value);
  }

  /// 設定是否顯示通知
  Future<void> setShowNotification(bool value) async {
    await updateSettings(showNotification: value);
  }

  /// 設定背景暫停閾值
  Future<void> setPauseThreshold(int seconds) async {
    await updateSettings(pauseThresholdSeconds: seconds);
  }

  /// App 生命週期回調
  /// 注意：只有 paused 狀態才代表真正進入背景
  /// inactive 狀態會在很多短暫操作時觸發（如截圖、下拉通知列、接電話等）
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 只有 paused 狀態才代表真正進入背景（App 完全不可見）
    // inactive 狀態只是暫時失去焦點（如下拉通知列、截圖、系統對話框等）
    if (state == AppLifecycleState.paused) {
      // App 真正進入背景
      if (_isRunning && _backgroundTime == null) {
        _backgroundTime = DateTime.now();
        debugPrint('📱 App 進入背景 (paused)，記錄時間: $_backgroundTime');
        // 通知已經在運行中，不需要額外操作
      }
    } else if (state == AppLifecycleState.resumed) {
      // App 恢復前台
      if (_isRunning && _backgroundTime != null) {
        final now = DateTime.now();
        final backgroundDuration = now.difference(_backgroundTime!).inSeconds;
        
        // -1 表示不暫停
        if (_pauseThresholdSeconds > 0 && backgroundDuration > _pauseThresholdSeconds) {
          // 超過閾值，扣除背景時間
          debugPrint('⚠️ 背景時間 $backgroundDuration 秒超過閾值 $_pauseThresholdSeconds 秒，扣除該段時間');
          // 重新設定開始時間，使背景時間不被計入
          _startTime = now;
        } else {
          debugPrint('✅ 背景時間 $backgroundDuration 秒未超過閾值，繼續計時');
        }
        _backgroundTime = null;
      }
    }
    // 忽略 inactive 和 detached 狀態，不做任何處理
  }
  
  /// 處理通知按鈕點擊
  void _onNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    debugPrint('🔔 通知操作: $actionId');
    
    switch (actionId) {
      case _actionPause:
        pause();
        break;
      case _actionResume:
        resume();
        break;
      case _actionStop:
        stop();
        break;
    }
  }
  
  /// 獲取通知操作按鈕
  List<AndroidNotificationAction> _getNotificationActions() {
    final isEnglish = _currentLanguage.startsWith('en');
    
    if (_isRunning) {
      return [
        AndroidNotificationAction(
          _actionPause,
          isEnglish ? '⏸ Pause' : '⏸ 暫停',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          _actionStop,
          isEnglish ? '⏹ Stop' : '⏹ 停止',
          showsUserInterface: true,
        ),
      ];
    } else {
      return [
        AndroidNotificationAction(
          _actionResume,
          isEnglish ? '▶ Resume' : '▶ 繼續',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          _actionStop,
          isEnglish ? '⏹ Stop' : '⏹ 停止',
          showsUserInterface: true,
        ),
      ];
    }
  }

  /// 開始定期更新通知
  void _startNotificationUpdates() {
    _showTimerNotification();
    _notificationUpdateTimer?.cancel();
    _notificationUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isRunning && _showNotification) {
        _showTimerNotification();
      } else {
        _stopNotificationUpdates();
      }
    });
    debugPrint('🔔 開始通知更新');
  }
  
  /// 停止通知更新
  void _stopNotificationUpdates() {
    _notificationUpdateTimer?.cancel();
    _notificationUpdateTimer = null;
  }
  
  /// 顯示計時通知
  Future<void> _showTimerNotification() async {
    if (_notificationsPlugin == null) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    
    final androidDetails = AndroidNotificationDetails(
      'timer_channel',
      _getChannelName(),
      channelDescription: _getChannelDescription(),
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      category: AndroidNotificationCategory.progress,
      actions: _getNotificationActions(),
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    final timeString = formatTodayTotal();
    
    await _notificationsPlugin?.show(
      _notificationId,
      _getNotificationTitle('practicing'),
      _getNotificationBody('practicing', timeString),
      details,
    );
  }
  
  /// 取消通知
  Future<void> _cancelNotification() async {
    await _notificationsPlugin?.cancel(_notificationId);
    debugPrint('🔕 已取消通知');
  }
  
  /// 顯示暫停通知
  Future<void> _showPausedNotification() async {
    if (_notificationsPlugin == null) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (!_showNotification) return;
    
    final androidDetails = AndroidNotificationDetails(
      'timer_channel',
      _getChannelName(),
      channelDescription: _getChannelDescription(),
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: true,  // 保持通知常駐，讓用戶可以繼續操作
      autoCancel: false,
      showWhen: true,
      playSound: false,
      enableVibration: false,
      actions: _getNotificationActions(),  // 添加操作按鈕
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    final timeString = formatTodayTotal();
    
    await _notificationsPlugin?.show(
      _notificationId,
      _getNotificationTitle('paused'),
      _getNotificationBody('paused', timeString),
      details,
    );
    debugPrint('🔔 顯示暫停通知');
  }
  
  /// 顯示停止通知
  Future<void> _showStoppedNotification(int sessionSeconds) async {
    if (_notificationsPlugin == null) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (!_showNotification) return;
    
    final androidDetails = AndroidNotificationDetails(
      'timer_channel',
      _getChannelName(),
      channelDescription: _getChannelDescription(),
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: false,
      autoCancel: true,
      showWhen: true,
      playSound: false,
      enableVibration: false,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // 格式化本次練習時間
    final isEnglish = _currentLanguage.startsWith('en');
    final hours = sessionSeconds ~/ 3600;
    final minutes = (sessionSeconds % 3600) ~/ 60;
    final secs = sessionSeconds % 60;
    String sessionTime;
    if (isEnglish) {
      if (hours > 0) {
        sessionTime = '${hours}h ${minutes}m ${secs}s';
      } else if (minutes > 0) {
        sessionTime = '${minutes}m ${secs}s';
      } else {
        sessionTime = '${secs}s';
      }
    } else {
      if (hours > 0) {
        sessionTime = '${hours}小時${minutes}分${secs}秒';
      } else if (minutes > 0) {
        sessionTime = '${minutes}分${secs}秒';
      } else {
        sessionTime = '${secs}秒';
      }
    }
    
    await _notificationsPlugin?.show(
      _notificationId,
      _getNotificationTitle('completed'),
      _getNotificationBody('completed', sessionTime),
      details,
    );
    debugPrint('🔔 顯示停止通知: $sessionTime');
  }

  /// 格式化顯示時間
  String formatElapsedTime() {
    final seconds = getElapsedSeconds();
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  // 兼容舊代碼的方法
  void setTimerRunning(bool isRunning) {
    if (isRunning && !_isRunning) {
      start();
    } else if (!isRunning && _isRunning) {
      pause();
    }
  }
  
  void requestPauseAndSave() {
    // 舊邏輯兼容 - 現在直接暫停
    pause();
  }
  
  void confirmPauseAndSaveHandled() {
    // 舊邏輯兼容 - 不再需要
  }
  
  void reset() {
    _stopCountingTimer();
    _stopNotificationUpdates();
    _cancelNotification();
    _isRunning = false;
    _startTime = null;
    _accumulatedSeconds = 0;
    _backgroundTime = null;
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _stopCountingTimer();
    _stopNotificationUpdates();
    _cancelNotification();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

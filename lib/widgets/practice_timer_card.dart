// lib/widgets/practice_timer_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_practice_app/core/services/auth_service_config.dart';
import 'package:music_practice_app/services/user_data_sync_service.dart';
import 'package:music_practice_app/services/practice_timer_service.dart';
import 'package:music_practice_app/l10n/app_localizations.dart';
import 'dart:async';
import 'dart:convert';

class PracticeTimerCard extends StatefulWidget {
  const PracticeTimerCard({super.key});

  @override
  State<PracticeTimerCard> createState() => _PracticeTimerCardState();
}

class _PracticeTimerCardState extends State<PracticeTimerCard>
    with WidgetsBindingObserver {
  final UserDataSyncService _syncService = UserDataSyncService();
  final PracticeTimerService _timerService = PracticeTimerService();

  // 計時器狀態
  bool _isRunning = false;
  int _elapsedSeconds = 0; // 當日累計練習時長（秒）
  int _sessionStartSeconds = 0; // 本次計時開始時的秒數
  Timer? _timer;
  String _lastDate = ''; // 記錄上次使用的日期，用於檢測日期變化

  // 本週練習數據 (格式: {日期: 秒數})
  Map<String, int> _weeklyPracticeData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 添加生命週期觀察者
    _loadPracticeData();

    // 監聽認證狀態變化,登入後刷新數據
    authService.addListener(_onAuthStateChanged);

    // 監聽計時器服務的暫停請求
    _timerService.addListener(_onTimerServiceChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 移除生命週期觀察者
    _timer?.cancel();
    // 不要在 dispose 時停止全局計時器狀態
    // 這樣切換頁面時計時器可以繼續運行
    // 只有用戶主動點擊停止按鈕時才會停止
    authService.removeListener(_onAuthStateChanged);
    _timerService.removeListener(_onTimerServiceChanged);
    super.dispose();
  }

  /// 監聯 App 生命週期變化
  /// 注意：只有 paused 狀態才代表真正進入背景（App 完全不可見）
  /// inactive 狀態只是暫時失去焦點（如下拉通知列、截圖、系統對話框等），不應暫停計時
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 只有當 App 真正進入背景（paused）時才暫停計時
    // inactive 狀態（下拉通知列、截圖等）不暫停
    if (state == AppLifecycleState.paused) {
      if (_isRunning) {
        debugPrint('App 真正切換到後台 (paused)，自動暫停計時並保存數據');
        _pauseTimer();
      }
    }
  }

  /// 認證狀態變化時的回調
  void _onAuthStateChanged() {
    // 當認證狀態改變時,重新載入數據
    // (登入後會從雲端同步到本地,然後這裡載入最新數據)
    if (mounted) {
      _loadPracticeData();
    }
  }

  /// 計時器服務狀態變化時的回調
  void _onTimerServiceChanged() {
    // 檢查是否需要停止計時（從浮動視窗觸發）
    if (_timerService.stopRequested && _isRunning) {
      debugPrint('收到停止請求，執行停止操作');
      _timerService.clearStopRequest();
      _stopAndSaveTimer(); // 使用停止方法而非暫停
      return;
    }

    // 同步計時器服務的狀態
    if (mounted) {
      final serviceRunning = _timerService.isRunning;

      // 如果服務在運行但本地沒有運行，說明是從其他地方恢復的（如浮動視窗按繼續）
      if (serviceRunning && !_isRunning) {
        debugPrint('服務正在運行，恢復本地計時狀態');
        // 恢復本地狀態
        final sessionSeconds = _timerService.getElapsedSeconds();
        setState(() {
          _isRunning = true;
          // 恢復計時
          _elapsedSeconds = _sessionStartSeconds + sessionSeconds;
        });

        // 啟動本地 UI 更新 Timer
        _startUIUpdateTimer();
      }

      // 如果服務已暫停但本地仍在運行，同步暫停本地狀態
      // （例如從浮動視窗按暫停）
      if (!serviceRunning && _timerService.isPaused && _isRunning) {
        debugPrint('服務已暫停，同步本地狀態並保存數據');
        _timer?.cancel();
        final sessionSeconds = _timerService.getElapsedSeconds();
        setState(() {
          _isRunning = false;
          _elapsedSeconds = _sessionStartSeconds + sessionSeconds;
        });
        // 保存練習數據（從浮動視窗暫停時也需要保存）
        if (sessionSeconds > 0) {
          final today = _getTodayString();
          _weeklyPracticeData[today] = _elapsedSeconds;
          _savePracticeData();
          debugPrint('從浮動視窗暫停，已保存練習數據: $sessionSeconds 秒');
        }
        // 不顯示 SnackBar，因為這是從浮動視窗觸發的暫停
      }

      // 同步服務的計時到本地顯示
      if (serviceRunning && _isRunning) {
        final sessionSeconds = _timerService.getElapsedSeconds();
        setState(() {
          _elapsedSeconds = _sessionStartSeconds + sessionSeconds;
        });
      }
    }
  }

  // 載入練習數據
  Future<void> _loadPracticeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ 優先從本地 SharedPreferences 載入最新數據
      final prefs = await SharedPreferences.getInstance();
      final dataJson = prefs.getString('practice_data');

      if (dataJson != null && dataJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(dataJson);
        _weeklyPracticeData =
            data.map((key, value) => MapEntry(key, value as int));
      }

      final today = _getTodayString();
      final todaySavedSeconds = _weeklyPracticeData[today] ?? 0;

      // 檢查計時器服務是否正在運行或暫停
      if (_timerService.isRunning || _timerService.isPaused) {
        // 計時器正在運行/暫停，恢復狀態
        final sessionSeconds = _timerService.getElapsedSeconds();
        final previousSeconds = _timerService.todayPreviousSeconds;

        setState(() {
          _sessionStartSeconds = previousSeconds;
          _elapsedSeconds = previousSeconds + sessionSeconds;
          _isRunning = _timerService.isRunning;
          _lastDate = today;
          _isLoading = false;
        });

        // 如果正在運行，啟動 UI 更新 Timer
        if (_timerService.isRunning) {
          _startUIUpdateTimer();
        }

        debugPrint(
            '恢復計時狀態: 本次計時=$sessionSeconds秒, 之前累計=$previousSeconds秒, 總計=$_elapsedSeconds秒');
      } else {
        // 計時器未運行，使用已存的數據
        setState(() {
          _elapsedSeconds = todaySavedSeconds;
          _sessionStartSeconds = todaySavedSeconds;
          _lastDate = today;
          _isRunning = false;
          _isLoading = false;
        });
      }

      // 執行每日清理檢查（不阻塞載入）
      _cleanOldPracticeDataIfNeeded();

      debugPrint('PracticeTimerCard: ✅ 練習數據已從本地載入 (最新數據)');
      debugPrint('今日累計練習時長: $_elapsedSeconds 秒');
    } catch (e) {
      debugPrint('載入練習數據失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 保存練習數據
  Future<void> _savePracticeData() async {
    // 保存到本地 SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final dataJson = jsonEncode(_weeklyPracticeData);
    await prefs.setString('practice_data', dataJson);

    // 如果已登入，同步到雲端
    final user = authService.currentUser;
    if (user != null) {
      try {
        // 直接儲存秒數到雲端（完全精確，不轉換）
        await _syncService.syncPracticeTime(_weeklyPracticeData);
        debugPrint('練習時間已同步到雲端');
      } catch (e) {
        debugPrint('同步練習時間到雲端失敗: $e');
        // 即使同步失敗,本地數據已保存
      }
    }
  }

  // 清理 90 天前的舊數據（每日檢查一次）
  Future<void> _cleanOldPracticeDataIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCleanDate = prefs.getString('last_practice_clean_date');
    final today = _getTodayString();

    // 如果今天已經清理過，跳過
    if (lastCleanDate == today) {
      return;
    }

    final now = DateTime.now();
    final cutoffDate = now.subtract(const Duration(days: 90));

    bool hasRemoved = false;
    _weeklyPracticeData.removeWhere((key, value) {
      try {
        final parts = key.split('-');
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        if (date.isBefore(cutoffDate)) {
          hasRemoved = true;
          return true;
        }
        return false;
      } catch (e) {
        return false; // 保留無法解析的數據
      }
    });

    // 記錄清理日期
    await prefs.setString('last_practice_clean_date', today);

    if (hasRemoved) {
      debugPrint('已清理 90 天前的練習數據');
      await _savePracticeData();
    }
  }

  // 獲取今天的日期字符串
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // 開始計時
  void _startTimer() {
    _startTimerInternal();
  }

  // 啟動 UI 更新 Timer
  void _startUIUpdateTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_timerService.isRunning) {
        timer.cancel();
        return;
      }
      final sessionSeconds = _timerService.getElapsedSeconds();
      if (mounted) {
        setState(() {
          _elapsedSeconds = _sessionStartSeconds + sessionSeconds;
        });
      }
    });
  }

  // 內部開始計時邏輯
  void _startTimerInternal() {
    // 檢查日期是否變化（跨日檢測）
    final today = _getTodayString();
    if (today != _lastDate) {
      // 日期變化，重置為新一天
      setState(() {
        _elapsedSeconds = _weeklyPracticeData[today] ?? 0;
        _lastDate = today;
      });
      debugPrint('日期變化：已重置為今日累計時長 $_elapsedSeconds 秒');
    }

    // 記錄本次計時開始時的秒數
    _sessionStartSeconds = _elapsedSeconds;

    setState(() {
      _isRunning = true;
    });

    // 使用全局計時器服務開始計時
    _timerService.start();

    // 設定今日已累計的秒數
    _timerService.setTodayPreviousSeconds(_sessionStartSeconds);

    debugPrint('開始計時，今日之前累計: $_elapsedSeconds 秒');

    // 本地 Timer 只用於更新本地 UI（從服務獲取計時秒數）
    _startUIUpdateTimer();
  }

  // 暫停計時並自動保存
  Future<void> _pauseTimer() async {
    final l10n = AppLocalizations.of(context);
    _timer?.cancel();

    final sessionSeconds = _elapsedSeconds - _sessionStartSeconds;

    setState(() {
      _isRunning = false;
    });

    // 完全停止計時器（調用 reset 而不是 pause，確保浮動視窗和通知都消失）
    _timerService.reset();

    // 如果本次練習有時長，則保存數據
    if (sessionSeconds > 0) {
      final today = _getTodayString();

      setState(() {
        _weeklyPracticeData[today] = _elapsedSeconds; // 保存當日累計時長
      });

      await _savePracticeData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.timerRecordedMessage
                    .replaceAll('{session}', _formatTime(sessionSeconds))
                    .replaceAll('{total}', _formatTime(_elapsedSeconds)) ??
                '已記錄本次練習 ${_formatTime(sessionSeconds)}，今日累計 ${_formatTime(_elapsedSeconds)}'),
            backgroundColor: AppColors.dynamicPrimary,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      debugPrint('本次練習: $sessionSeconds 秒, 今日累計: $_elapsedSeconds 秒');
    }

    // 重置本次開始秒數為當前累計（下次開始是新的 session）
    _sessionStartSeconds = _elapsedSeconds;
  }

  // 停止計時並保存（完全結束計時，重置狀態）
  Future<void> _stopAndSaveTimer() async {
    final l10n = AppLocalizations.of(context);
    _timer?.cancel();

    final sessionSeconds = _elapsedSeconds - _sessionStartSeconds;

    setState(() {
      _isRunning = false;
    });

    // 使用全局計時器服務重置（完全停止，不保留暫停狀態）
    _timerService.reset();

    // 如果本次練習有時長，則保存數據
    if (sessionSeconds > 0) {
      final today = _getTodayString();

      setState(() {
        _weeklyPracticeData[today] = _elapsedSeconds; // 保存當日累計時長
      });

      await _savePracticeData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.timerRecordedMessage
                    .replaceAll('{session}', _formatTime(sessionSeconds))
                    .replaceAll('{total}', _formatTime(_elapsedSeconds)) ??
                '已記錄本次練習 ${_formatTime(sessionSeconds)}，今日累計 ${_formatTime(_elapsedSeconds)}'),
            backgroundColor: AppColors.dynamicPrimary,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      debugPrint('停止計時 - 本次練習: $sessionSeconds 秒, 今日累計: $_elapsedSeconds 秒');
    }

    // 重置本次開始秒數為當前累計（下次開始是新的 session）
    _sessionStartSeconds = _elapsedSeconds;
  }

  // 格式化時間 (秒 -> HH:MM:SS)
  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  // 獲取本週日期列表 (週一到週日)
  List<DateTime> _getWeekDates() {
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    final monday = now.subtract(Duration(days: weekday - 1));

    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  // 獲取日期的練習時長（分鐘）
  int _getPracticeMinutes(DateTime date) {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final seconds = _weeklyPracticeData[dateString] ?? 0;
    return seconds ~/ 60;
  }

  // 獲取本週最大練習時長（用於計算比例）
  int _getMaxMinutes() {
    final weekDates = _getWeekDates();
    int maxMinutes = 0;

    for (final date in weekDates) {
      final minutes = _getPracticeMinutes(date);
      if (minutes > maxMinutes) {
        maxMinutes = minutes;
      }
    }

    return maxMinutes > 0 ? maxMinutes : 60; // 最小刻度 60 分鐘
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      color: AppColors.dynamicCard,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(
                    color: AppColors.dynamicPrimary,
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 標題
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n?.timerCardTitle ?? '練習計時',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dynamicTextDark,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n?.timerCardSubtitle ?? '今日累計時長（隔日自動重置）',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.dynamicTextLight,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 計時器顯示和按鈕合併在一行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 計時器顯示
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatTime(_elapsedSeconds),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dynamicPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          // 顯示練習中標籤
                          if (_isRunning)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.dynamicAccent.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fitness_center,
                                    size: 12,
                                    color: AppColors.dynamicTextLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n?.timerDailyPractice ?? '日常練習',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.dynamicTextLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // 控制按鈕 - 單一開始/暫停按鈕
                      IconButton(
                        onPressed: _isRunning ? _pauseTimer : _startTimer,
                        icon: Icon(
                          _isRunning
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          size: 56,
                        ),
                        color: _isRunning
                            ? Colors.orange
                            : AppColors.dynamicPrimary,
                        tooltip: _isRunning
                            ? (l10n?.timerPauseAndSave ?? '暫停並保存')
                            : (l10n?.timerStartTimer ?? '開始計時'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 分隔線
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.dynamicTextLight.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 本週統計標題和數據
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          l10n?.timerWeeklyPractice ?? '本週練習時長',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dynamicTextDark,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatWeekTotal(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dynamicPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 統計摘要行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(l10n?.timerTrendingUp ?? '本週平均',
                          _getWeekAverage(), Icons.trending_up),
                      Container(
                          width: 1,
                          height: 16,
                          color: AppColors.dynamicTextLight.withOpacity(0.3)),
                      _buildStatItem(l10n?.timerCalendarMonth ?? '本月累計',
                          _getMonthTotal(), Icons.calendar_month),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 長條圖
                  _buildWeeklyChart(),

                  const SizedBox(height: 12),

                  // 查看詳細報表按鈕
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        context.push('/practice-stats');
                      },
                      icon: Icon(
                        Icons.analytics_outlined,
                        size: 16,
                        color: AppColors.dynamicPrimary,
                      ),
                      label: Text(
                        l10n?.timerViewStats ?? '查看詳細報表',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.dynamicPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // 構建統計項目
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.dynamicTextLight,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.dynamicTextLight,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dynamicTextDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 格式化本週總時長
  String _formatWeekTotal() {
    final l10n = AppLocalizations.of(context);
    final weekDates = _getWeekDates();
    int totalSeconds = 0;

    // 累加本週所有天數的秒數
    for (final date in weekDates) {
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      totalSeconds += _weeklyPracticeData[dateString] ?? 0;
    }

    // 轉換為小時和分鐘
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    final hourUnit = l10n?.timerHourUnit ?? 'h';
    final minuteUnit = l10n?.timerMinuteUnit ?? 'min';
    final totalText = l10n?.timerWeekTotal ?? '共';

    if (hours > 0) {
      return '$totalText $hours$hourUnit $minutes$minuteUnit';
    } else {
      return '$totalText $minutes$minuteUnit';
    }
  }

  // 計算本週平均每日練習時長
  String _getWeekAverage() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // 只保留日期部分
    final weekDates = _getWeekDates();
    int totalSeconds = 0;
    int daysInWeekSoFar = 0; // 本週已經過去的天數（包含今天）

    // 累加本週所有天數的秒數，只計算已經過去的天數
    for (final date in weekDates) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      // 如果日期在今天之後，跳過（未來的日期）
      if (dateOnly.isAfter(today)) {
        continue;
      }

      daysInWeekSoFar++;
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      totalSeconds += _weeklyPracticeData[dateString] ?? 0;
    }

    // 如果本週還沒有任何天數（理論上不可能），返回0
    final l10n = AppLocalizations.of(context);
    final dayUnit = l10n?.timerDayUnit ?? '/天';

    if (daysInWeekSoFar == 0) return '0min$dayUnit';

    // 計算平均秒數（除以本週已過天數）
    final avgSeconds = totalSeconds / daysInWeekSoFar;

    // 轉換為分鐘（保留1位小數）
    final avgMinutes = avgSeconds / 60;

    if (avgMinutes >= 60) {
      // 超過60分鐘，顯示小時
      final hours = avgMinutes / 60;
      return '${hours.toStringAsFixed(1)}h$dayUnit';
    } else {
      return '${avgMinutes.toStringAsFixed(1)}min$dayUnit';
    }
  }

  // 計算本月總練習時長
  String _getMonthTotal() {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    int totalSeconds = 0; // ← 改為累加秒數

    for (var day = firstDayOfMonth;
        day.isBefore(lastDayOfMonth.add(const Duration(days: 1)));
        day = day.add(const Duration(days: 1))) {
      final dateString =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      totalSeconds += _weeklyPracticeData[dateString] ?? 0; // ← 直接累加秒數
    }

    // ← 最後統一轉換為小時和分鐘
    final totalMinutes = totalSeconds ~/ 60;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    final hourUnit = l10n?.timerHourUnit ?? 'h';
    final minuteUnit = l10n?.timerMinuteUnit ?? 'min';

    if (hours > 0) {
      return '$hours$hourUnit $minutes$minuteUnit';
    } else {
      return '$minutes$minuteUnit';
    }
  }

  // 構建本週長條圖
  Widget _buildWeeklyChart() {
    final weekDates = _getWeekDates();
    final maxMinutes = _getMaxMinutes();
    final today = DateTime.now();

    return SizedBox(
      height: 160, // 降低高度從 180 到 160
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final date = weekDates[index];
          final minutes = _getPracticeMinutes(date);
          final heightRatio = minutes / maxMinutes;
          final barHeight = heightRatio * 100; // 降低最大高度從 120 到 100
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          final isFuture = date.isAfter(today);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3), // 減少橫向間距
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 時長文字（限制高度）
                  SizedBox(
                    height: 14, // 減少高度
                    child: minutes > 0
                        ? Text(
                            minutes >= 60
                                ? '${(minutes / 60).toStringAsFixed(1)}h'
                                : '${minutes}m',
                            style: TextStyle(
                              fontSize: 8, // 減小字體
                              color: AppColors.dynamicTextLight,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 3), // 減少間距

                  // 長條
                  Container(
                    width: double.infinity,
                    height: barHeight.clamp(isFuture ? 0 : 8, 100), // 調整高度範圍
                    decoration: BoxDecoration(
                      gradient: isFuture
                          ? null
                          : LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: minutes == 0
                                  ? [
                                      AppColors.dynamicTextLight
                                          .withOpacity(0.2),
                                      AppColors.dynamicTextLight
                                          .withOpacity(0.1),
                                    ]
                                  : [
                                      AppColors.dynamicPrimary,
                                      AppColors.dynamicPrimary.withOpacity(0.6),
                                    ],
                            ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6), // 減小圓角
                      ),
                      border: minutes == 0 && !isFuture
                          ? Border.all(
                              color:
                                  AppColors.dynamicTextLight.withOpacity(0.3),
                              width: 1,
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 4), // 減少間距

                  // 星期幾
                  Text(
                    _getWeekdayAbbr(date.weekday),
                    style: TextStyle(
                      fontSize: 8, // 減小字體
                      color: AppColors.dynamicTextLight,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // 日期文字（實際日期）
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 3, vertical: 1), // 減小內邊距
                    decoration: isToday
                        ? BoxDecoration(
                            color: AppColors.dynamicPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          )
                        : null,
                    child: Text(
                      '${date.month}/${date.day}',
                      style: TextStyle(
                        fontSize: 9, // 減小字體
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday
                            ? AppColors.dynamicPrimary
                            : isFuture
                                ? AppColors.dynamicTextLight.withOpacity(0.5)
                                : AppColors.dynamicTextDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // 獲取星期幾的縮寫
  String _getWeekdayAbbr(int weekday) {
    final l10n = AppLocalizations.of(context);
    final weekdays = l10n?.statsWeekdays ?? ['一', '二', '三', '四', '五', '六', '日'];
    return weekdays[weekday - 1];
  }
}

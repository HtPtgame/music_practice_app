// lib/widgets/practice_timer_card.dart
import 'package:flutter/material.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_practice_app/services/auth_service_config.dart';
import 'package:music_practice_app/services/user_data_sync_service.dart';
import 'package:music_practice_app/services/practice_timer_service.dart';
import 'dart:async';
import 'dart:convert';

class PracticeTimerCard extends StatefulWidget {
  const PracticeTimerCard({super.key});

  @override
  State<PracticeTimerCard> createState() => _PracticeTimerCardState();
}

class _PracticeTimerCardState extends State<PracticeTimerCard> {
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
    _loadPracticeData();
    
    // 監聽認證狀態變化,登入後刷新數據
    authService.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    // 如果計時器正在運行，離開頁面時重置全局狀態
    if (_isRunning) {
      _timerService.setTimerRunning(false);
    }
    authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  /// 認證狀態變化時的回調
  void _onAuthStateChanged() {
    // 當認證狀態改變時,重新載入數據
    // (登入後會從雲端同步到本地,然後這裡載入最新數據)
    if (mounted) {
      _loadPracticeData();
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
        setState(() {
          _weeklyPracticeData = data.map((key, value) => MapEntry(key, value as int));
          
          // 初始化當日累計時長
          final today = _getTodayString();
          _elapsedSeconds = _weeklyPracticeData[today] ?? 0;
          _lastDate = today;
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _elapsedSeconds = 0;
          _lastDate = _getTodayString();
          _isLoading = false;
        });
      }
      
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
    // 清理 90 天前的舊數據
    _cleanOldPracticeData();
    
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

  // 清理 90 天前的舊數據
  void _cleanOldPracticeData() {
    final now = DateTime.now();
    final cutoffDate = now.subtract(const Duration(days: 90));
    
    _weeklyPracticeData.removeWhere((key, value) {
      try {
        final parts = key.split('-');
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        return date.isBefore(cutoffDate);
      } catch (e) {
        return false; // 保留無法解析的數據
      }
    });
  }

  // 獲取今天的日期字符串
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // 開始計時
  void _startTimer() {
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
    
    // 更新全局計時器狀態
    _timerService.setTimerRunning(true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  // 暫停計時並自動保存
  Future<void> _pauseTimer() async {
    _timer?.cancel();
    
    final sessionSeconds = _elapsedSeconds - _sessionStartSeconds;
    
    setState(() {
      _isRunning = false;
    });
    
    // 更新全局計時器狀態
    _timerService.setTimerRunning(false);
    
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
            content: Text('已記錄本次練習 ${_formatTime(sessionSeconds)}，今日累計 ${_formatTime(_elapsedSeconds)}'),
            backgroundColor: AppColors.dynamicPrimary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      debugPrint('本次練習: $sessionSeconds 秒, 今日累計: $_elapsedSeconds 秒');
    }
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
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
                      Text(
                        '練習計時',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dynamicTextDark,
                        ),
                      ),
                      Text(
                        '今日累計時長（隔日自動重置）',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.dynamicTextLight,
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
                      Text(
                        _formatTime(_elapsedSeconds),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dynamicPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      
                      // 控制按鈕 - 合併為單一按鈕
                      // 控制按鈕 - 單一開始/暫停按鈕
                      IconButton(
                        onPressed: _isRunning ? _pauseTimer : _startTimer,
                        icon: Icon(
                          _isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          size: 56,
                        ),
                        color: _isRunning ? Colors.orange : AppColors.dynamicPrimary,
                        tooltip: _isRunning ? '暫停並保存' : '開始計時',
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
                      Text(
                        '本週練習時長',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dynamicTextDark,
                        ),
                      ),
                      Text(
                        _formatWeekTotal(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dynamicPrimary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 統計摘要行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem('本週平均', _getWeekAverage(), Icons.trending_up),
                      Container(width: 1, height: 16, color: AppColors.dynamicTextLight.withOpacity(0.3)),
                      _buildStatItem('本月累計', _getMonthTotal(), Icons.calendar_month),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 長條圖
                  _buildWeeklyChart(),
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
    final weekDates = _getWeekDates();
    int totalMinutes = 0;
    
    for (final date in weekDates) {
      totalMinutes += _getPracticeMinutes(date);
    }
    
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    
    if (hours > 0) {
      return '共 ${hours}h ${minutes}min';
    } else {
      return '共 ${minutes}min';
    }
  }

  // 計算本週平均每日練習時長
  String _getWeekAverage() {
    final weekDates = _getWeekDates();
    int totalMinutes = 0;
    int practiceDays = 0;
    
    for (final date in weekDates) {
      final minutes = _getPracticeMinutes(date);
      totalMinutes += minutes;
      if (minutes > 0) {
        practiceDays++;
      }
    }
    
    if (practiceDays == 0) return '0min/天';
    
    final avgMinutes = totalMinutes ~/ practiceDays;
    return '${avgMinutes}min/天';
  }

  // 計算本月總練習時長
  String _getMonthTotal() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    
    int totalMinutes = 0;
    
    for (var day = firstDayOfMonth; 
         day.isBefore(lastDayOfMonth.add(const Duration(days: 1))); 
         day = day.add(const Duration(days: 1))) {
      final dateString = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final seconds = _weeklyPracticeData[dateString] ?? 0;
      totalMinutes += seconds ~/ 60;
    }
    
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
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
                                      AppColors.dynamicTextLight.withOpacity(0.2),
                                      AppColors.dynamicTextLight.withOpacity(0.1),
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
                              color: AppColors.dynamicTextLight.withOpacity(0.3),
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
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1), // 減小內邊距
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
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
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
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return weekdays[weekday - 1];
  }
}

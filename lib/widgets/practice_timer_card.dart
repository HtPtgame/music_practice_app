// lib/widgets/practice_timer_card.dart
import 'package:flutter/material.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

class PracticeTimerCard extends StatefulWidget {
  const PracticeTimerCard({super.key});

  @override
  State<PracticeTimerCard> createState() => _PracticeTimerCardState();
}

class _PracticeTimerCardState extends State<PracticeTimerCard> {
  // 計時器狀態
  bool _isRunning = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  
  // 本週練習數據 (格式: {日期: 秒數})
  Map<String, int> _weeklyPracticeData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPracticeData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 載入練習數據
  Future<void> _loadPracticeData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString('practice_data');
    
    if (dataJson != null && dataJson.isNotEmpty) {
      final Map<String, dynamic> data = jsonDecode(dataJson);
      setState(() {
        _weeklyPracticeData = data.map((key, value) => MapEntry(key, value as int));
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 保存練習數據
  Future<void> _savePracticeData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = jsonEncode(_weeklyPracticeData);
    await prefs.setString('practice_data', dataJson);
  }

  // 獲取今天的日期字符串
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // 開始計時
  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  // 暫停計時
  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
  }

  // 結束計時並保存
  Future<void> _stopTimer() async {
    _timer?.cancel();
    
    if (_elapsedSeconds > 0) {
      final today = _getTodayString();
      final currentSeconds = _weeklyPracticeData[today] ?? 0;
      
      setState(() {
        _weeklyPracticeData[today] = currentSeconds + _elapsedSeconds;
        _elapsedSeconds = 0;
        _isRunning = false;
      });
      
      await _savePracticeData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已記錄本次練習時長！'),
            backgroundColor: AppColors.dynamicPrimary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
                  Text(
                    '練習計時',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dynamicTextDark,
                    ),
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
                      
                      // 控制按鈕
                      Row(
                        children: [
                          if (!_isRunning) ...[
                            // 開始按鈕
                            IconButton(
                              onPressed: _startTimer,
                              icon: const Icon(Icons.play_circle_filled, size: 48),
                              color: AppColors.dynamicPrimary,
                              tooltip: '開始',
                            ),
                            if (_elapsedSeconds > 0)
                              IconButton(
                                onPressed: _stopTimer,
                                icon: const Icon(Icons.stop_circle, size: 48),
                                color: Colors.red,
                                tooltip: '結束',
                              ),
                          ] else ...[
                            // 暫停按鈕
                            IconButton(
                              onPressed: _pauseTimer,
                              icon: const Icon(Icons.pause_circle_filled, size: 48),
                              color: Colors.orange,
                              tooltip: '暫停',
                            ),
                            IconButton(
                              onPressed: _stopTimer,
                              icon: const Icon(Icons.stop_circle, size: 48),
                              color: Colors.red,
                              tooltip: '結束',
                            ),
                          ],
                        ],
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
                  
                  // 本週統計標題
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
                  
                  const SizedBox(height: 16),
                  
                  // 長條圖
                  _buildWeeklyChart(),
                ],
              ),
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
      return '共 ${hours}小時${minutes}分鐘';
    } else {
      return '共 ${minutes}分鐘';
    }
  }

  // 構建本週長條圖
  Widget _buildWeeklyChart() {
    final weekDates = _getWeekDates();
    final maxMinutes = _getMaxMinutes();
    final today = DateTime.now();
    
    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final date = weekDates[index];
          final minutes = _getPracticeMinutes(date);
          final heightRatio = minutes / maxMinutes;
          final barHeight = heightRatio * 150; // 最大高度 150
          final isToday = date.year == today.year && 
                         date.month == today.month && 
                         date.day == today.day;
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 時長文字
                  if (minutes > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${minutes}分',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.dynamicTextLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 14),
                  
                  // 長條
                  Container(
                    width: double.infinity,
                    height: barHeight.clamp(0, 150),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.dynamicPrimary,
                          AppColors.dynamicPrimary.withOpacity(0.6),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 日期文字（實際日期）
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isToday 
                          ? AppColors.dynamicPrimary 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday 
                            ? Colors.white 
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
}

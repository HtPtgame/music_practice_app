// lib/pages/practice_stats_page.dart
import 'package:flutter/material.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:music_practice_app/services/practice_session_service.dart';
import 'package:music_practice_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 練習統計報表頁面
class PracticeStatsPage extends StatefulWidget {
  const PracticeStatsPage({super.key});

  @override
  State<PracticeStatsPage> createState() => _PracticeStatsPageState();
}

class _PracticeStatsPageState extends State<PracticeStatsPage> {
  final PracticeSessionService _sessionService = PracticeSessionService();

  // 報表模式：週 (true) 或 月 (false)
  bool _isWeekly = true;
  // 日期偏移 (0 = 本週/本月, -1 = 上週/上月)
  int _dateOffset = 0;
  
  // 練習數據
  Map<String, int> _practiceData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    await _sessionService.loadSessions();
    await _loadPracticeData();
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadPracticeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = prefs.getString('practice_data');
      
      if (dataJson != null && dataJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(dataJson);
        _practiceData = data.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      debugPrint('載入練習數據失敗: $e');
    }
  }

  // 獲取當前顯示的週一日期
  DateTime _getWeekStart() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1));
    return monday.add(Duration(days: _dateOffset * 7));
  }

  // 獲取當前顯示的月份
  DateTime _getMonthStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _dateOffset, 1);
  }

  // 格式化日期範圍字串
  String _getDateRangeText() {
    if (_isWeekly) {
      final monday = _getWeekStart();
      final sunday = monday.add(const Duration(days: 6));
      return '${monday.month}/${monday.day} - ${sunday.month}/${sunday.day}';
    } else {
      final monthStart = _getMonthStart();
      final locale = Localizations.localeOf(context);
      if (locale.languageCode == 'en') {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[monthStart.month - 1]} ${monthStart.year}';
      }
      return '${monthStart.year}年 ${monthStart.month}月';
    }
  }

  // 獲取偏移量描述
  String _getOffsetText(AppLocalizations? l10n) {
    if (_dateOffset == 0) {
      return _isWeekly 
          ? (l10n?.statsThisWeek ?? '本週') 
          : (l10n?.statsThisMonth ?? '本月');
    } else if (_dateOffset == -1) {
      return _isWeekly 
          ? (l10n?.statsLastWeek ?? '上週') 
          : (l10n?.statsLastMonth ?? '上月');
    } else {
      return l10n?.statsHistory ?? '歷史紀錄';
    }
  }

  // 獲取週數據
  List<int> _getWeeklyMinutes() {
    final monday = _getWeekStart();
    final result = <int>[];
    
    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final seconds = _practiceData[dateStr] ?? 0;
      result.add(seconds ~/ 60); // 轉換為分鐘
    }
    
    return result;
  }

  // 計算週總時長
  int _getWeekTotalSeconds() {
    final monday = _getWeekStart();
    int total = 0;
    
    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      total += _practiceData[dateStr] ?? 0;
    }
    
    return total;
  }

  // 計算月總時長
  int _getMonthTotalSeconds() {
    final monthStart = _getMonthStart();
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    int total = 0;
    
    for (int i = 0; i < daysInMonth; i++) {
      final date = monthStart.add(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      total += _practiceData[dateStr] ?? 0;
    }
    
    return total;
  }

  // 獲取月數據 (按 ISO 8601 週分組，週一為始，週日為終)
  List<int> _getMonthlyMinutes() {
    final monthStart = _getMonthStart();
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    
    // 使用 ISO 8601 週計算：找出這個月的所有 ISO 週
    final isoWeeks = _getISOWeeksInMonth(monthStart, daysInMonth);
    final result = List<int>.filled(isoWeeks.length, 0);
    
    for (int i = 0; i < daysInMonth; i++) {
      final date = monthStart.add(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final seconds = _practiceData[dateStr] ?? 0;
      
      // 找出這一天屬於哪個 ISO 週
      final isoWeekNum = _getISOWeekNumber(date);
      final weekIndex = isoWeeks.indexWhere((w) => w['weekNum'] == isoWeekNum);
      if (weekIndex >= 0 && weekIndex < result.length) {
        result[weekIndex] += seconds ~/ 60; // 轉換為分鐘
      }
    }
    
    return result;
  }

  // 獲取指定月份包含的 ISO 週列表
  List<Map<String, dynamic>> _getISOWeeksInMonth(DateTime monthStart, int daysInMonth) {
    final weeks = <Map<String, dynamic>>[];
    final seenWeeks = <int>{};
    
    for (int i = 0; i < daysInMonth; i++) {
      final date = monthStart.add(Duration(days: i));
      final isoWeekNum = _getISOWeekNumber(date);
      
      if (!seenWeeks.contains(isoWeekNum)) {
        seenWeeks.add(isoWeekNum);
        
        // 計算該 ISO 週的週一和週日
        final weekday = date.weekday;
        final monday = date.subtract(Duration(days: weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        
        weeks.add({
          'weekNum': isoWeekNum,
          'monday': monday,
          'sunday': sunday,
        });
      }
    }
    
    return weeks;
  }

  // 計算 ISO 8601 週數
  int _getISOWeekNumber(DateTime date) {
    // ISO 8601: 週一為一週開始，第一週是包含該年第一個週四的那一週
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final weekday = date.weekday;
    final weekNum = ((dayOfYear - weekday + 10) / 7).floor();
    
    if (weekNum < 1) {
      // 屬於上一年的最後一週
      return _getISOWeekNumber(DateTime(date.year - 1, 12, 31));
    } else if (weekNum > 52) {
      // 檢查是否屬於下一年的第一週
      final dec31 = DateTime(date.year, 12, 31);
      if (dec31.weekday < 4) {
        return 1;
      }
    }
    return weekNum;
  }

  // 獲取月練習天數
  int _getMonthPracticeDays() {
    final monthStart = _getMonthStart();
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    int days = 0;
    
    for (int i = 0; i < daysInMonth; i++) {
      final date = monthStart.add(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if ((_practiceData[dateStr] ?? 0) > 0) {
        days++;
      }
    }
    
    return days;
  }

  // 計算與上月比較的百分比變化
  String _getMonthComparisonText() {
    final currentMonthSeconds = _getMonthTotalSeconds();
    
    // 計算上月數據
    final now = DateTime.now();
    final lastMonthStart = DateTime(now.year, now.month + _dateOffset - 1, 1);
    final daysInLastMonth = DateTime(lastMonthStart.year, lastMonthStart.month + 1, 0).day;
    
    int lastMonthSeconds = 0;
    for (int i = 0; i < daysInLastMonth; i++) {
      final date = lastMonthStart.add(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      lastMonthSeconds += _practiceData[dateStr] ?? 0;
    }
    
    if (lastMonthSeconds == 0) {
      return currentMonthSeconds > 0 ? '+∞' : '—';
    }
    
    final change = ((currentMonthSeconds - lastMonthSeconds) / lastMonthSeconds * 100).round();
    return change >= 0 ? '+$change%' : '$change%';
  }

  // 計算與上週比較的百分比變化
  String _getWeekComparisonText() {
    final currentWeekSeconds = _getWeekTotalSeconds();
    
    // 計算上週數據
    final lastWeekOffset = _dateOffset - 1;
    final now = DateTime.now();
    final weekday = now.weekday;
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1))
        .add(Duration(days: lastWeekOffset * 7));
    
    int lastWeekSeconds = 0;
    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      lastWeekSeconds += _practiceData[dateStr] ?? 0;
    }
    
    if (lastWeekSeconds == 0) {
      return currentWeekSeconds > 0 ? '+∞' : '—';
    }
    
    final percentChange = ((currentWeekSeconds - lastWeekSeconds) / lastWeekSeconds * 100).round();
    if (percentChange > 0) {
      return '+$percentChange%';
    } else if (percentChange < 0) {
      return '$percentChange%';
    } else {
      return '持平';
    }
  }

  // 獲取練習天數
  int _getPracticeDays() {
    final monday = _getWeekStart();
    int days = 0;
    
    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if ((_practiceData[dateStr] ?? 0) > 0) {
        days++;
      }
    }
    
    return days;
  }

  // 格式化時長
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.dynamicTextDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n?.statsTitle ?? '練習偵探報表',
          style: TextStyle(
            color: AppColors.dynamicTextDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.dynamicPrimary),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 日期導航與切換器
                    _buildDateNavigator(l10n),
                    const SizedBox(height: 24),

                    // 2. 核心數據概覽
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons.timer,
                            value: _formatDuration(_isWeekly ? _getWeekTotalSeconds() : _getMonthTotalSeconds()),
                            label: _isWeekly 
                                ? (l10n?.statsWeeklyPractice ?? '本週練習')
                                : (l10n?.statsMonthlyPractice ?? '本月練習'),
                            trend: _isWeekly ? _getWeekComparisonText() : _getMonthComparisonText(),
                            isPositive: (_isWeekly ? _getWeekComparisonText() : _getMonthComparisonText()).startsWith('+'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons.calendar_today,
                            value: _isWeekly 
                                ? '${_getPracticeDays()}/7' 
                                : '${_getMonthPracticeDays()}/${DateTime(_getMonthStart().year, _getMonthStart().month + 1, 0).day}',
                            label: l10n?.statsPracticeDays ?? '練習天數',
                            trend: _isWeekly 
                                ? (_getPracticeDays() >= 5 ? (l10n?.statsExcellent ?? '優秀') : (l10n?.statsKeepGoing ?? '加油'))
                                : (_getMonthPracticeDays() >= 20 ? (l10n?.statsExcellent ?? '優秀') : (l10n?.statsKeepGoing ?? '加油')),
                            isPositive: _isWeekly 
                                ? _getPracticeDays() >= 5 
                                : _getMonthPracticeDays() >= 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 3. 練習趨勢圖表
                    Text(
                      l10n?.statsTrend ?? '練習趨勢',
                      style: TextStyle(
                        color: AppColors.dynamicTextDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildChartCard(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // 日期導航器
  Widget _buildDateNavigator(AppLocalizations? l10n) {
    return Column(
      children: [
        // 週/月 切換
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.dynamicCard.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildSegmentTab(
                l10n?.statsWeekReport ?? '週報表',
                _isWeekly,
                () => setState(() {
                  _isWeekly = true;
                  _dateOffset = 0;
                }),
              ),
              _buildSegmentTab(
                l10n?.statsMonthReport ?? '月報表',
                !_isWeekly,
                () => setState(() {
                  _isWeekly = false;
                  _dateOffset = 0;
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 日期選擇
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => setState(() => _dateOffset--),
              icon: Icon(Icons.chevron_left, color: AppColors.dynamicTextLight),
              style: IconButton.styleFrom(backgroundColor: AppColors.dynamicCard),
            ),
            Column(
              children: [
                Text(
                  _getDateRangeText(),
                  style: TextStyle(
                    color: AppColors.dynamicTextDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _getOffsetText(l10n),
                  style: TextStyle(
                    color: AppColors.dynamicTextLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: _dateOffset >= 0 ? null : () => setState(() => _dateOffset++),
              icon: Icon(
                Icons.chevron_right,
                color: _dateOffset >= 0
                    ? AppColors.dynamicTextLight.withOpacity(0.3)
                    : AppColors.dynamicTextLight,
              ),
              style: IconButton.styleFrom(backgroundColor: AppColors.dynamicCard),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSegmentTab(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.dynamicPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.dynamicTextLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // 概覽卡片
  Widget _buildSummaryCard({
    required IconData icon,
    required String value,
    required String label,
    required String trend,
    required bool isPositive,
  }) {
    return Card(
      color: AppColors.dynamicCard,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: AppColors.dynamicPrimary, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: AppColors.dynamicTextDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: AppColors.dynamicTextLight, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // 長條圖卡片
  Widget _buildChartCard() {
    final l10n = AppLocalizations.of(context);

    if (_isWeekly) {
      // 週報表：每天一個條形
      final weeklyMinutes = _getWeeklyMinutes();
      final maxVal = weeklyMinutes.reduce((a, b) => a > b ? a : b);
      final effectiveMax = maxVal > 0 ? maxVal.toDouble() : 60.0;

      return Card(
        color: AppColors.dynamicCard,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.statsDailyDuration ?? '每日練習時長 (分鐘)',
                    style: TextStyle(color: AppColors.dynamicTextLight, fontSize: 12),
                  ),
                  Icon(Icons.bar_chart, color: AppColors.dynamicTextLight, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < 7; i++)
                      _buildWeeklyBar(weeklyMinutes[i].toDouble(), effectiveMax, i),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // 月報表：每週一個條形
      final monthlyMinutes = _getMonthlyMinutes();
      final maxVal = monthlyMinutes.isNotEmpty ? monthlyMinutes.reduce((a, b) => a > b ? a : b) : 0;
      final effectiveMax = maxVal > 0 ? maxVal.toDouble() : 60.0;

      return Card(
        color: AppColors.dynamicCard,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.statsWeeklyDuration ?? '每週練習時長 (分鐘)',
                    style: TextStyle(color: AppColors.dynamicTextLight, fontSize: 12),
                  ),
                  Icon(Icons.bar_chart, color: AppColors.dynamicTextLight, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < monthlyMinutes.length; i++)
                      _buildMonthlyBar(monthlyMinutes[i].toDouble(), effectiveMax, i, monthlyMinutes.length),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // 週報表條形 (每日)
  Widget _buildWeeklyBar(double value, double max, int index) {
    final l10n = AppLocalizations.of(context);
    final weekDays = l10n?.statsWeekdays ?? ['一', '二', '三', '四', '五', '六', '日'];
    final heightFactor = max > 0 ? value / max : 0.0;
    
    final monday = _getWeekStart();
    final date = monday.add(Duration(days: index));
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isFuture = date.isAfter(now);

    // 計算條形高度 (最大 90，為標籤留空間)
    final barHeight = isFuture ? 0.0 : (90.0 * heightFactor).clamp(value > 0 ? 6.0 : 3.0, 90.0);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 數值標籤 (固定高度區域)
            SizedBox(
              height: 14,
              child: value > 0
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value >= 60 ? '${(value / 60).toStringAsFixed(1)}h' : '${value.toInt()}m',
                        style: TextStyle(
                          color: isToday ? AppColors.dynamicPrimary : AppColors.dynamicTextLight,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 2),
            // 條形 (使用 Flexible 避免 overflow)
            Flexible(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: barHeight),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuart,
                builder: (context, val, _) {
                  return Container(
                    width: double.infinity,
                    height: val,
                    decoration: BoxDecoration(
                      color: isFuture
                          ? Colors.transparent
                          : (value > 0
                              ? (isToday
                                  ? AppColors.dynamicPrimary
                                  : AppColors.dynamicPrimary.withValues(alpha: 0.4))
                              : AppColors.dynamicTextLight.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            // 星期
            Text(
              weekDays[index],
              style: TextStyle(
                color: isToday ? AppColors.dynamicPrimary : AppColors.dynamicTextLight,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                fontSize: 10,
              ),
            ),
            // 日期
            Text(
              '${date.month}/${date.day}',
              style: TextStyle(
                color: isFuture
                    ? AppColors.dynamicTextLight.withValues(alpha: 0.3)
                    : (isToday ? AppColors.dynamicPrimary : AppColors.dynamicTextDark),
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 月報表條形 (每週，ISO 8601 標準)
  Widget _buildMonthlyBar(double value, double max, int weekIndex, int totalWeeks) {
    final heightFactor = max > 0 ? value / max : 0.0;
    final monthStart = _getMonthStart();
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    
    // 獲取 ISO 週資訊
    final isoWeeks = _getISOWeeksInMonth(monthStart, daysInMonth);
    if (weekIndex >= isoWeeks.length) {
      return const SizedBox.shrink();
    }
    
    final weekInfo = isoWeeks[weekIndex];
    final monday = weekInfo['monday'] as DateTime;
    final sunday = weekInfo['sunday'] as DateTime;
    
    // 計算在當月範圍內的日期顯示
    final displayStartDay = monday.month == monthStart.month ? monday.day : 1;
    final displayEndDay = sunday.month == monthStart.month ? sunday.day : daysInMonth;
    
    // 判斷是否為當前週
    final now = DateTime.now();
    final isCurrentWeek = now.isAfter(monday.subtract(const Duration(days: 1))) && 
                          now.isBefore(sunday.add(const Duration(days: 1)));
    final isFutureWeek = monday.isAfter(now);

    // 計算條形高度
    final barHeight = isFutureWeek ? 0.0 : (90.0 * heightFactor).clamp(value > 0 ? 6.0 : 3.0, 90.0);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 數值標籤
            SizedBox(
              height: 14,
              child: value > 0
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value >= 60 ? '${(value / 60).toStringAsFixed(1)}h' : '${value.toInt()}m',
                        style: TextStyle(
                          color: isCurrentWeek ? AppColors.dynamicPrimary : AppColors.dynamicTextLight,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 2),
            // 條形
            Flexible(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: barHeight),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuart,
                builder: (context, val, _) {
                  return Container(
                    width: double.infinity,
                    height: val,
                    decoration: BoxDecoration(
                      color: isFutureWeek
                          ? Colors.transparent
                          : (value > 0
                              ? (isCurrentWeek
                                  ? AppColors.dynamicPrimary
                                  : AppColors.dynamicPrimary.withValues(alpha: 0.4))
                              : AppColors.dynamicTextLight.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            // 週數 (中文格式: 第一週, 第二週...)
            Text(
              _getChineseWeekLabel(weekIndex + 1),
              style: TextStyle(
                color: isCurrentWeek ? AppColors.dynamicPrimary : AppColors.dynamicTextLight,
                fontWeight: isCurrentWeek ? FontWeight.bold : FontWeight.normal,
                fontSize: 9,
              ),
            ),
            // 日期範圍 (格式: 12/2-8)
            Text(
              '${monthStart.month}/$displayStartDay-$displayEndDay',
              style: TextStyle(
                color: isFutureWeek
                    ? AppColors.dynamicTextLight.withValues(alpha: 0.3)
                    : (isCurrentWeek ? AppColors.dynamicPrimary : AppColors.dynamicTextDark),
                fontWeight: isCurrentWeek ? FontWeight.bold : FontWeight.normal,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 獲取中文週次標籤
  String _getChineseWeekLabel(int weekNum) {
    final l10n = AppLocalizations.of(context);
    final weekLabels = l10n?.statsWeekLabels ?? ['', '第一週', '第二週', '第三週', '第四週', '第五週', '第六週'];
    if (weekNum > 0 && weekNum < weekLabels.length) {
      return weekLabels[weekNum];
    }
    return l10n?.statsWeekLabel(weekNum) ?? '第$weekNum週';
  }
}

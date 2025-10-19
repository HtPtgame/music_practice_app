// lib/widgets/check_in_card.dart
import 'package:flutter/material.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckInCard extends StatefulWidget {
  const CheckInCard({super.key});

  @override
  State<CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends State<CheckInCard> {
  int _consecutiveDays = 0;
  Set<String> _checkedDates = {}; // 格式: 'yyyy-MM-dd'
  bool _hasCheckedToday = false;
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = true; // 添加加載狀態

  @override
  void initState() {
    super.initState();
    _loadCheckInData();
  }

  Future<void> _loadCheckInData() async {
    final prefs = await SharedPreferences.getInstance();
    final checkedDatesJson = prefs.getStringList('checked_dates') ?? [];
    final consecutiveDays = prefs.getInt('consecutive_days') ?? 0;

    setState(() {
      _checkedDates = checkedDatesJson.toSet();
      _consecutiveDays = consecutiveDays;
      _hasCheckedToday = _checkedDates.contains(_getTodayString());
      _updateConsecutiveDays();
      _isLoading = false; // 載入完成
    });
  }

  Future<void> _saveCheckInData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('checked_dates', _checkedDates.toList());
    await prefs.setInt('consecutive_days', _consecutiveDays);
  }

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _updateConsecutiveDays() {
    // 計算連續打卡天數
    final today = DateTime.now();
    int consecutive = 0;
    
    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      if (_checkedDates.contains(dateString)) {
        consecutive++;
      } else {
        break;
      }
    }
    
    _consecutiveDays = consecutive;
  }

  Future<void> _checkIn() async {
    if (_hasCheckedToday) return;

    setState(() {
      _checkedDates.add(_getTodayString());
      _hasCheckedToday = true;
      _updateConsecutiveDays();
    });

    await _saveCheckInData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('打卡成功！連續打卡 $_consecutiveDays 天 🎉'),
          backgroundColor: AppColors.dynamicPrimary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    
    List<DateTime> days = [];
    for (int i = 0; i < lastDay.day; i++) {
      days.add(firstDay.add(Duration(days: i)));
    }
    
    return days;
  }

  bool _isCheckedDate(DateTime date) {
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _checkedDates.contains(dateString);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    });
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
            : _buildCardContent(),
      ),
    );
  }

  Widget _buildCardContent() {
    final daysInMonth = _getDaysInMonth(_selectedMonth);
    final firstDayWeekday = daysInMonth.first.weekday; // 1 = Monday, 7 = Sunday

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            // 標題和連續天數
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '練習打卡',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dynamicTextDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '連續 $_consecutiveDays 天',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dynamicPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // 打卡按鈕
                ElevatedButton(
                  onPressed: _hasCheckedToday ? null : _checkIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasCheckedToday 
                        ? Colors.grey 
                        : AppColors.dynamicPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    _hasCheckedToday ? '已打卡' : '打卡',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
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
            
            // 月份切換
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: AppColors.dynamicTextDark),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${_selectedMonth.year}年 ${_selectedMonth.month}月',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dynamicTextDark,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: AppColors.dynamicTextDark),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 星期標題
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['日', '一', '二', '三', '四', '五', '六'].map((day) {
                return SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dynamicTextLight,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 8),
            
            // 日曆網格
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: (firstDayWeekday % 7) + daysInMonth.length,
              itemBuilder: (context, index) {
                final offset = firstDayWeekday % 7;
                
                // 空白日期
                if (index < offset) {
                  return const SizedBox();
                }
                
                final date = daysInMonth[index - offset];
                final isChecked = _isCheckedDate(date);
                final isToday = _isToday(date);
                
                return Container(
                  decoration: BoxDecoration(
                    // 已打卡：填滿主題色背景
                    color: isChecked 
                        ? AppColors.dynamicPrimary
                        : Colors.transparent,
                    // 今天：添加邊框
                    border: isToday 
                        ? Border.all(color: AppColors.dynamicPrimary, width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        // 已打卡：白色文字；未打卡：深色文字
                        color: isChecked 
                            ? Colors.white
                            : AppColors.dynamicTextDark,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      }
    }

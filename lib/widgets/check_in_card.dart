// lib/widgets/check_in_card.dart
import 'package:flutter/material.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_practice_app/services/auth_service_config.dart';
import 'package:music_practice_app/services/user_data_sync_service.dart';

class CheckInCard extends StatefulWidget {
  const CheckInCard({super.key});

  @override
  State<CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends State<CheckInCard> {
  final UserDataSyncService _syncService = UserDataSyncService();
  
  int _consecutiveDays = 0;
  int _totalCheckInDays = 0; // 新增：累計打卡天數
  Set<String> _checkedDates = {}; // 格式: 'yyyy-MM-dd'
  bool _hasCheckedToday = false;
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = true; // 添加加載狀態

  @override
  void initState() {
    super.initState();
    _loadCheckInData();
    
    // 監聽認證狀態變化,登入後刷新數據
    authService.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  /// 認證狀態變化時的回調
  void _onAuthStateChanged() {
    // 當認證狀態改變時,重新載入數據
    // (登入後會從雲端同步到本地,然後這裡載入最新數據)
    if (mounted) {
      _loadCheckInData();
    }
  }

  Future<void> _loadCheckInData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ 優先從本地 SharedPreferences 載入最新數據
      final prefs = await SharedPreferences.getInstance();
      final checkedDatesJson = prefs.getStringList('checked_dates') ?? [];
      final consecutiveDays = prefs.getInt('consecutive_days') ?? 0;

      setState(() {
        _checkedDates = checkedDatesJson.toSet();
        _consecutiveDays = consecutiveDays;
        _totalCheckInDays = _checkedDates.length; // 累計打卡天數就是打卡記錄總數
        _hasCheckedToday = _checkedDates.contains(_getTodayString());
        _updateConsecutiveDays();
        _isLoading = false;
      });
      
      debugPrint('CheckInCard: ✅ 打卡數據已從本地載入 (最新數據)');
    } catch (e) {
      debugPrint('載入打卡數據失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCheckInData() async {
    // 保存到本地 SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('checked_dates', _checkedDates.toList());
    await prefs.setInt('consecutive_days', _consecutiveDays);

    // 如果已登入，同步到雲端
    final user = authService.currentUser;
    if (user != null) {
      try {
        final dateList = _checkedDates.map((dateStr) {
          final parts = dateStr.split('-');
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }).toList();
        
        await _syncService.syncCheckInDates(dateList);
        debugPrint('打卡記錄已同步到雲端');
      } catch (e) {
        debugPrint('同步打卡記錄到雲端失敗: $e');
        // 即使同步失敗,本地數據已保存
      }
    }
  }

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _updateConsecutiveDays() {
    // 計算連續打卡天數（優化版：正確處理跨月份）
    final today = DateTime.now();
    final todayString = _getTodayString();
    int consecutive = 0;
    
    // 從今天開始往回檢查
    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateString = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      
      if (_checkedDates.contains(dateString)) {
        consecutive++;
      } else {
        // 如果今天還沒打卡，允許昨天開始計算
        if (i == 0 && !_checkedDates.contains(todayString)) {
          continue; // 跳過今天，從昨天開始計算
        }
        break; // 遇到未打卡的日子就停止
      }
    }
    
    _consecutiveDays = consecutive;
  }

  Future<void> _checkIn() async {
    if (_hasCheckedToday) return;

    setState(() {
      _checkedDates.add(_getTodayString());
      _hasCheckedToday = true;
      _totalCheckInDays = _checkedDates.length; // 更新累計天數
      _updateConsecutiveDays();
    });

    await _saveCheckInData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('打卡成功！連續 $_consecutiveDays 天，累計 $_totalCheckInDays 天 🎉'),
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
                    const SizedBox(height: 6),
                    // 連續打卡天數
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
                    const SizedBox(height: 4),
                    // 累計打卡天數（移到下方）
                    Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '累計 $_totalCheckInDays 天',
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

// lib/widgets/check_in_card.dart
import 'package:flutter/material.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_practice_app/core/services/auth_service_config.dart';
import 'package:music_practice_app/services/user_data_sync_service.dart';
import 'package:music_practice_app/l10n/app_localizations.dart';
import 'package:music_practice_app/models/animal_collection.dart';
import 'package:music_practice_app/widgets/unlock_animation_dialog.dart';
import 'dart:convert';

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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayString = _getTodayString();
    final hasCheckedToday = _checkedDates.contains(todayString);
    int consecutive = 0;

    // 從昨天或今天開始往回檢查
    final startDay = hasCheckedToday ? 0 : 1;

    for (int i = startDay; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateString =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

      if (_checkedDates.contains(dateString)) {
        consecutive++;
      } else {
        break; // 遇到未打卡的日子就停止
      }
    }

    _consecutiveDays = consecutive;
  }

  Future<void> _checkIn() async {
    if (_hasCheckedToday) return;

    final l10n = AppLocalizations.of(context);

    // 備份當前狀態（用於錯誤回滾）
    final backupCheckedDates = Set<String>.from(_checkedDates);
    final backupConsecutiveDays = _consecutiveDays;
    final backupTotalDays = _totalCheckInDays;
    final backupHasChecked = _hasCheckedToday;

    try {
      setState(() {
        _checkedDates.add(_getTodayString());
        _hasCheckedToday = true;
        _totalCheckInDays = _checkedDates.length; // 更新累計天數
        _updateConsecutiveDays();
      });

      await _saveCheckInData();

      // 檢查是否解鎖新動物
      await _checkAndShowUnlockedAnimals();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(l10n?.checkInSuccessMessage.replaceAll('{consecutive}', '$_consecutiveDays').replaceAll('{total}', '$_totalCheckInDays') ?? '打卡成功！連續 $_consecutiveDays 天，累計 $_totalCheckInDays 天 🎉'),
            backgroundColor: AppColors.dynamicPrimary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // 同步失敗時回滾本地狀態
      debugPrint('打卡同步失敗，回滾本地數據: $e');
      setState(() {
        _checkedDates = backupCheckedDates;
        _consecutiveDays = backupConsecutiveDays;
        _totalCheckInDays = backupTotalDays;
        _hasCheckedToday = backupHasChecked;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.checkInFailure ?? '打卡失敗，請檢查網路連線'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 檢查並顯示新解鎖的動物動畫
  Future<void> _checkAndShowUnlockedAnimals() async {
    try {
      debugPrint('🔍 開始檢查解鎖動物...');
      final prefs = await SharedPreferences.getInstance();
      
      // 載入已解鎖的動物
      final unlockedJson = prefs.getString('unlocked_animals');
      Map<String, String> unlockedAnimals = {};
      if (unlockedJson != null) {
        try {
          final decoded = Map<String, dynamic>.from(jsonDecode(unlockedJson));
          unlockedAnimals = decoded.map((key, value) => MapEntry(key, value as String));
        } catch (e) {
          debugPrint('解析已解鎖動物數據失敗: $e');
        }
      }

      // 創建服務實例來獲取所有動物
      final collectionService = AnimalCollectionService();
      final allAnimals = collectionService.allAnimals;
      final totalDays = _totalCheckInDays;
      
      debugPrint('📊 累計打卡天數: $totalDays');
      debugPrint('📝 已解鎖動物數量: ${unlockedAnimals.length}');
      debugPrint('📋 總動物數量: ${allAnimals.length}');
      
      List<AnimalCollection> shouldShowAnimals = [];
      
      for (var animal in allAnimals) {
        debugPrint('🐾 檢查 ${animal.name} (需要${animal.requiredCheckInDays}天)');
        
        // 檢查是否達到解鎖條件
        if (totalDays >= animal.requiredCheckInDays) {
          final now = DateTime.now();
          final dateOnly = DateTime(now.year, now.month, now.day);
          
          // 檢查是否今天才解鎖（或之前沒解鎖過）
          bool isNewlyUnlocked = false;
          
          if (!unlockedAnimals.containsKey(animal.id)) {
            // 之前沒解鎖過，現在新解鎖
            debugPrint('  🎉 首次解鎖！');
            isNewlyUnlocked = true;
            unlockedAnimals[animal.id] = dateOnly.toIso8601String();
          } else {
            // 已經解鎖過，檢查是否今天解鎖的
            final unlockedDateStr = unlockedAnimals[animal.id]!;
            final unlockedDate = DateTime.parse(unlockedDateStr);
            final unlockedDateOnly = DateTime(unlockedDate.year, unlockedDate.month, unlockedDate.day);
            
            if (unlockedDateOnly.isAtSameMomentAs(dateOnly)) {
              debugPrint('  🎊 今天解鎖的，顯示動畫！');
              isNewlyUnlocked = true;
            } else {
              debugPrint('  ✅ 之前解鎖過');
            }
          }
          
          if (isNewlyUnlocked) {
            final unlockedAnimal = animal.copyWith(unlockedAt: dateOnly);
            shouldShowAnimals.add(unlockedAnimal);
          }
        } else {
          debugPrint('  ⏳ 還差 ${animal.requiredCheckInDays - totalDays} 天');
        }
      }

      debugPrint('🆕 需要顯示動畫的動物數量: ${shouldShowAnimals.length}');

      // 顯示所有應該顯示動畫的動物
      for (var animal in shouldShowAnimals) {
        // 延遲一點顯示動畫（等 SnackBar 顯示後）
        await Future.delayed(const Duration(milliseconds: 500));
        
        debugPrint('🎊 顯示解鎖動畫: ${animal.name}');
        
        // 顯示慶祝動畫
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => UnlockAnimationDialog(animal: animal),
          );
        }
      }

      // 保存更新後的解鎖數據
      if (unlockedAnimals.isNotEmpty) {
        await prefs.setString('unlocked_animals', jsonEncode(unlockedAnimals));
        debugPrint('💾 已保存解鎖數據到本地');
        
        // 同步到雲端
        final user = authService.currentUser;
        if (user != null) {
          try {
            await _syncService.syncUnlockedAnimals(unlockedAnimals);
            debugPrint('☁️ 已同步到雲端');
          } catch (e) {
            debugPrint('同步解鎖動物數據失敗: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ 檢查解鎖動物失敗: $e');
      debugPrint('錯誤堆疊: ${StackTrace.current}');
    }
  }

  /// 測試解鎖動畫（長按已打卡按鈕觸發）
  Future<void> _testUnlockAnimation() async {
    debugPrint('🧪 測試解鎖動畫');
    
    // 獲取第一個已解鎖的動物來測試
    final collectionService = AnimalCollectionService();
    final allAnimals = collectionService.allAnimals;
    
    // 找到第一個符合條件的動物
    final testAnimal = allAnimals.firstWhere(
      (animal) => _totalCheckInDays >= animal.requiredCheckInDays,
      orElse: () => allAnimals.first,
    );
    
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    final unlockedAnimal = testAnimal.copyWith(unlockedAt: dateOnly);
    
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UnlockAnimationDialog(animal: unlockedAnimal),
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
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _checkedDates.contains(dateString);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
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
    final l10n = AppLocalizations.of(context);
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n?.checkInTitle ?? '練習打卡',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dynamicTextDark,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // 連續打卡天數
                Row(
                  children: [
                    Icon(Icons.local_fire_department,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${l10n?.checkInConsecutive ?? '連續'} $_consecutiveDays ${l10n?.checkInDaysUnit ?? '天'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dynamicPrimary,
                        ),
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
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${l10n?.checkInAccumulated ?? '累計'} $_totalCheckInDays ${l10n?.checkInDaysUnit ?? '天'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dynamicPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // 打卡按鈕（長按測試動畫）
            GestureDetector(
              onLongPress: _hasCheckedToday ? _testUnlockAnimation : null,
              child: ElevatedButton(
                onPressed: _hasCheckedToday ? null : _checkIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _hasCheckedToday ? Colors.grey : AppColors.dynamicPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _hasCheckedToday ? (l10n?.checkInChecked ?? '已打卡') : (l10n?.checkInButton ?? '打卡'),
                    style:
                        const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
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
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${_selectedMonth.year}${l10n?.checkInYear ?? '年'} ${_selectedMonth.month}${l10n?.checkInMonth ?? '月'}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dynamicTextDark,
                ),
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
          children: (l10n?.checkInWeekdays ?? ['日', '一', '二', '三', '四', '五', '六']).map((day) {
            return SizedBox(
              width: 32,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dynamicTextLight,
                    ),
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
                color:
                    isChecked ? AppColors.dynamicPrimary : Colors.transparent,
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
                    color: isChecked ? Colors.white : AppColors.dynamicTextDark,
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

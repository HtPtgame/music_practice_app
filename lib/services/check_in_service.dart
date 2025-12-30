import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 打卡記錄服務
class CheckInService extends ChangeNotifier {
  static const String _checkInDatesKey = 'check_in_dates';
  static const String _totalCheckInDaysKey = 'total_check_in_days';

  List<DateTime> _checkInDates = [];
  int _totalCheckInDays = 0;

  List<DateTime> get checkInDates => _checkInDates;
  int get totalCheckInDays => _totalCheckInDays;

  /// 取得當前連續打卡天數
  int get currentStreak {
    if (_checkInDates.isEmpty) return 0;

    int streak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 從最近的日期開始往回數
    var checkDate = today;
    for (var i = _checkInDates.length - 1; i >= 0; i--) {
      final date = _checkInDates[i];
      final normalizedDate = DateTime(date.year, date.month, date.day);

      if (normalizedDate == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (normalizedDate.isBefore(checkDate)) {
        // 中斷了
        break;
      }
    }

    return streak;
  }

  /// 今天是否已打卡
  bool get hasCheckedInToday {
    if (_checkInDates.isEmpty) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCheckIn = _checkInDates.last;
    final lastCheckInDate = DateTime(
      lastCheckIn.year,
      lastCheckIn.month,
      lastCheckIn.day,
    );

    return lastCheckInDate == today;
  }

  /// 執行打卡
  Future<bool> checkIn() async {
    if (hasCheckedInToday) {
      return false; // 今天已經打卡過了
    }

    // ✅ 使用當天午夜（只保留日期部分）
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    _checkInDates.add(dateOnly);
    _totalCheckInDays++;

    await _saveCheckInData();
    notifyListeners();

    return true;
  }

  /// 載入打卡記錄
  Future<void> loadCheckInData() async {
    final prefs = await SharedPreferences.getInstance();

    // 載入打卡日期
    final datesJson = prefs.getString(_checkInDatesKey);
    if (datesJson != null) {
      final List<dynamic> datesList = jsonDecode(datesJson);
      _checkInDates = datesList
          .map((dateStr) => DateTime.parse(dateStr as String))
          .toList();
    }

    // 載入總打卡天數
    _totalCheckInDays = prefs.getInt(_totalCheckInDaysKey) ?? 0;

    notifyListeners();
  }

  /// 儲存打卡記錄
  Future<void> _saveCheckInData() async {
    final prefs = await SharedPreferences.getInstance();

    // 儲存打卡日期
    final datesJson = jsonEncode(
      _checkInDates.map((date) => date.toIso8601String()).toList(),
    );
    await prefs.setString(_checkInDatesKey, datesJson);

    // 儲存總打卡天數
    await prefs.setInt(_totalCheckInDaysKey, _totalCheckInDays);
  }

  /// 清除所有打卡記錄 (僅用於測試)
  Future<void> clearAllCheckIns() async {
    _checkInDates.clear();
    _totalCheckInDays = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_checkInDatesKey);
    await prefs.remove(_totalCheckInDaysKey);

    notifyListeners();
  }
}

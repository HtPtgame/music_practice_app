// lib/services/practice_session_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloria/services/user_data_sync_service.dart';

/// 練習會話記錄
class PracticeSession {
  final String id;
  final String date; // 格式: yyyy-MM-dd
  final String? pieceName; // 曲目名稱 (null = 日常練習)
  final int durationSeconds;
  final DateTime startTime;
  final DateTime endTime;

  PracticeSession({
    String? id,
    required this.date,
    this.pieceName,
    required this.durationSeconds,
    required this.startTime,
    required this.endTime,
  }) : id = id ?? '${DateTime.now().millisecondsSinceEpoch}_$durationSeconds';

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'pieceName': pieceName,
        'durationSeconds': durationSeconds,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      };

  factory PracticeSession.fromJson(Map<String, dynamic> json) => PracticeSession(
        id: json['id'] as String,
        date: json['date'] as String,
        pieceName: json['pieceName'] as String?,
        durationSeconds: json['durationSeconds'] as int,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
      );

  @override
  String toString() =>
      'PracticeSession(id: $id, date: $date, piece: $pieceName, duration: ${durationSeconds}s)';
}

/// 曲目統計數據
class PieceStatistics {
  final String pieceName;
  final int totalSeconds;
  final int sessionCount;
  final DateTime lastPracticed;

  PieceStatistics({
    required this.pieceName,
    required this.totalSeconds,
    required this.sessionCount,
    required this.lastPracticed,
  });

  /// 格式化總時長
  String get formattedTime {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// 計算佔比 (相對於最高練習時長)
  double percentOf(int maxSeconds) {
    if (maxSeconds <= 0) return 0;
    return (totalSeconds / maxSeconds).clamp(0.0, 1.0);
  }
}

/// 練習會話服務 - 單例模式
class PracticeSessionService extends ChangeNotifier {
  static final PracticeSessionService _instance = PracticeSessionService._internal();
  factory PracticeSessionService() => _instance;
  PracticeSessionService._internal();

  static const String _storageKey = 'practice_sessions';
  static const int _maxRetentionDays = 180; // 保留 180 天的數據

  final UserDataSyncService _syncService = UserDataSyncService();
  List<PracticeSession> _sessions = [];
  bool _isLoaded = false;

  /// 所有練習會話
  List<PracticeSession> get sessions => List.unmodifiable(_sessions);

  /// 是否已載入
  bool get isLoaded => _isLoaded;

  /// 載入所有練習會話
  Future<void> loadSessions() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? json = prefs.getString(_storageKey);

      if (json != null && json.isNotEmpty) {
        final List<dynamic> list = jsonDecode(json);
        _sessions = list.map((e) => PracticeSession.fromJson(e as Map<String, dynamic>)).toList();
        debugPrint('PracticeSessionService: ✅ 載入 ${_sessions.length} 條練習記錄');
      }

      _isLoaded = true;

      // 清理舊數據
      await _cleanOldSessions();
    } catch (e) {
      debugPrint('PracticeSessionService: ❌ 載入失敗: $e');
      _sessions = [];
      _isLoaded = true;
    }
  }

  /// 保存練習會話
  Future<void> saveSession(PracticeSession session) async {
    _sessions.add(session);
    await _persistSessions();
    await _syncToCloud();
    notifyListeners();

    debugPrint('PracticeSessionService: ✅ 已保存練習會話 - ${session.pieceName ?? "日常練習"} (${session.durationSeconds}s)');
  }

  /// 持久化到本地存儲
  Future<void> _persistSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String json = jsonEncode(_sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, json);
    } catch (e) {
      debugPrint('PracticeSessionService: ❌ 保存失敗: $e');
    }
  }

  /// 同步練習會話到雲端
  Future<void> _syncToCloud() async {
    try {
      final sessionsData = _sessions.map((s) => s.toJson()).toList();
      await _syncService.syncPracticeSessions(sessionsData);
    } catch (e) {
      debugPrint('PracticeSessionService: ⚠️ 雲端同步失敗: $e');
      // 不拋出錯誤，讓本地數據仍然能正常工作
    }
  }

  /// 清理超過保留期限的舊數據
  Future<void> _cleanOldSessions() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: _maxRetentionDays));
    final originalCount = _sessions.length;

    _sessions.removeWhere((session) {
      try {
        final parts = session.date.split('-');
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        return date.isBefore(cutoffDate);
      } catch (e) {
        return false;
      }
    });

    if (_sessions.length < originalCount) {
      debugPrint('PracticeSessionService: 🧹 清理了 ${originalCount - _sessions.length} 條舊記錄');
      await _persistSessions();
    }
  }

  /// 獲取指定日期範圍內的練習會話
  List<PracticeSession> getSessionsInRange(DateTime startDate, DateTime endDate) {
    return _sessions.where((session) {
      try {
        final parts = session.date.split('-');
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        return !date.isBefore(startDate) && !date.isAfter(endDate);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// 獲取曲目排行榜
  List<PieceStatistics> getPieceRanking({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 5,
    bool includeDailyPractice = false,
  }) {
    // 過濾日期範圍
    var filtered = _sessions.where((s) {
      // 過濾日常練習 (pieceName == null)
      if (!includeDailyPractice && s.pieceName == null) return false;

      if (startDate != null || endDate != null) {
        try {
          final parts = s.date.split('-');
          final date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          if (startDate != null && date.isBefore(startDate)) return false;
          if (endDate != null && date.isAfter(endDate)) return false;
        } catch (e) {
          return false;
        }
      }
      return true;
    }).toList();

    // 按曲目分組統計
    final Map<String, Map<String, dynamic>> pieceStats = {};

    for (var session in filtered) {
      final name = session.pieceName ?? '日常練習';

      if (!pieceStats.containsKey(name)) {
        pieceStats[name] = {
          'pieceName': name,
          'totalSeconds': 0,
          'sessionCount': 0,
          'lastPracticed': session.endTime,
        };
      }

      pieceStats[name]!['totalSeconds'] =
          (pieceStats[name]!['totalSeconds'] as int) + session.durationSeconds;
      pieceStats[name]!['sessionCount'] =
          (pieceStats[name]!['sessionCount'] as int) + 1;

      final lastPracticed = pieceStats[name]!['lastPracticed'] as DateTime;
      if (session.endTime.isAfter(lastPracticed)) {
        pieceStats[name]!['lastPracticed'] = session.endTime;
      }
    }

    // 轉換為 PieceStatistics 並排序
    final ranking = pieceStats.values
        .map((stats) => PieceStatistics(
              pieceName: stats['pieceName'] as String,
              totalSeconds: stats['totalSeconds'] as int,
              sessionCount: stats['sessionCount'] as int,
              lastPracticed: stats['lastPracticed'] as DateTime,
            ))
        .toList()
      ..sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds));

    return ranking.take(limit).toList();
  }

  /// 獲取指定週的每日練習數據
  Map<String, int> getWeeklyData(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final Map<String, int> dailyData = {};

    for (var session in _sessions) {
      try {
        final parts = session.date.split('-');
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );

        if (!date.isBefore(weekStart) && !date.isAfter(weekEnd)) {
          dailyData[session.date] =
              (dailyData[session.date] ?? 0) + session.durationSeconds;
        }
      } catch (e) {
        continue;
      }
    }

    return dailyData;
  }

  /// 獲取指定月的練習數據
  Map<String, int> getMonthlyData(int year, int month) {
    final Map<String, int> dailyData = {};

    for (var session in _sessions) {
      try {
        final parts = session.date.split('-');
        final sessionYear = int.parse(parts[0]);
        final sessionMonth = int.parse(parts[1]);

        if (sessionYear == year && sessionMonth == month) {
          dailyData[session.date] =
              (dailyData[session.date] ?? 0) + session.durationSeconds;
        }
      } catch (e) {
        continue;
      }
    }

    return dailyData;
  }

  /// 獲取指定曲目的練習歷史
  List<PracticeSession> getPieceHistory(String pieceName) {
    return _sessions
        .where((s) => s.pieceName == pieceName)
        .toList()
      ..sort((a, b) => b.endTime.compareTo(a.endTime));
  }

  /// 清除所有數據 (用於登出時)
  Future<void> clearAll() async {
    _sessions.clear();
    _isLoaded = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);

    notifyListeners();
    debugPrint('PracticeSessionService: 🗑️ 已清除所有練習會話');
  }

  /// 從雲端數據恢復 (用於登入同步)
  Future<void> restoreFromCloud(List<Map<String, dynamic>> cloudData) async {
    try {
      _sessions = cloudData.map((e) => PracticeSession.fromJson(e)).toList();
      await _persistSessions();
      notifyListeners();
      debugPrint('PracticeSessionService: ☁️ 已從雲端恢復 ${_sessions.length} 條記錄');
    } catch (e) {
      debugPrint('PracticeSessionService: ❌ 雲端恢復失敗: $e');
    }
  }

  /// 導出數據 (用於雲端同步)
  List<Map<String, dynamic>> exportToCloud() {
    return _sessions.map((s) => s.toJson()).toList();
  }
}

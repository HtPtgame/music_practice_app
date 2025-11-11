import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:music_practice_app/models/user.dart';
import 'package:music_practice_app/services/firebase_auth_service.dart';

/// 使用者數據同步服務 - 負責將本地數據同步到 Firestore
class UserDataSyncService extends ChangeNotifier {
  static final UserDataSyncService _instance = UserDataSyncService._internal();
  factory UserDataSyncService() => _instance;
  UserDataSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuthService _authService = FirebaseAuthService();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// 同步打卡記錄
  Future<void> syncCheckInDates(List<DateTime> checkInDates) async {
    final user = _authService.currentUser;
    if (user == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(user.id).update({
        'checkInDates': checkInDates.map((e) => e.toIso8601String()).toList(),
      });
    } catch (e) {
      debugPrint('同步打卡記錄失敗: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 同步練習時間記錄
  Future<void> syncPracticeTime(Map<String, int> practiceTime) async {
    final user = _authService.currentUser;
    if (user == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(user.id).update({
        'practiceTime': practiceTime,
      });
    } catch (e) {
      debugPrint('同步練習時間失敗: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 同步個人化設定
  Future<void> syncSettings(Map<String, dynamic> settings) async {
    final user = _authService.currentUser;
    if (user == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(user.id).update({
        'settings': settings,
      });
    } catch (e) {
      debugPrint('同步設定失敗: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 同步文字筆記
  Future<void> syncMusicNotes(List<MusicNote> musicNotes) async {
    final user = _authService.currentUser;
    if (user == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(user.id).update({
        'musicNotes': musicNotes.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('同步筆記失敗: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 新增單筆打卡記錄
  Future<void> addCheckIn(DateTime date) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final dateOnly = DateTime(date.year, date.month, date.day);
    final checkInDates = List<DateTime>.from(user.checkInDates);

    if (!checkInDates.any((d) =>
        d.year == dateOnly.year &&
        d.month == dateOnly.month &&
        d.day == dateOnly.day)) {
      checkInDates.add(dateOnly);
      await syncCheckInDates(checkInDates);
    }
  }

  /// 新增練習時間
  Future<void> addPracticeTime(DateTime date, int minutes) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final practiceTime = Map<String, int>.from(user.practiceTime);
    practiceTime[dateKey] = (practiceTime[dateKey] ?? 0) + minutes;

    await syncPracticeTime(practiceTime);
  }

  /// 更新設定項目
  Future<void> updateSetting(String key, dynamic value) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final settings = Map<String, dynamic>.from(user.settings);
    settings[key] = value;

    await syncSettings(settings);
  }

  /// 新增或更新筆記
  Future<void> saveNote(MusicNote note) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final musicNotes = List<MusicNote>.from(user.musicNotes);
    final index = musicNotes.indexWhere((n) => n.id == note.id);

    if (index >= 0) {
      musicNotes[index] = note;
    } else {
      musicNotes.add(note);
    }

    await syncMusicNotes(musicNotes);
  }

  /// 刪除筆記
  Future<void> deleteNote(String noteId) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final musicNotes = List<MusicNote>.from(user.musicNotes);
    musicNotes.removeWhere((n) => n.id == noteId);

    await syncMusicNotes(musicNotes);
  }

  /// 從 Firestore 載入使用者數據
  Future<User?> loadUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return User.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('載入使用者數據失敗: $e');
      return null;
    }
  }

  /// 批量同步所有數據
  Future<void> syncAllData({
    List<DateTime>? checkInDates,
    Map<String, int>? practiceTime,
    Map<String, dynamic>? settings,
    List<MusicNote>? musicNotes,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};

      if (checkInDates != null) {
        updates['checkInDates'] =
            checkInDates.map((e) => e.toIso8601String()).toList();
      }
      if (practiceTime != null) {
        updates['practiceTime'] = practiceTime;
      }
      if (settings != null) {
        updates['settings'] = settings;
      }
      if (musicNotes != null) {
        updates['musicNotes'] = musicNotes.map((e) => e.toJson()).toList();
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.id).update(updates);
      }
    } catch (e) {
      debugPrint('批量同步失敗: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}

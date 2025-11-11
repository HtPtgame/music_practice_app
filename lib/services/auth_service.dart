import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_practice_app/models/user.dart';

/// 認證服務 - 管理使用者登入、註冊、登出等功能
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;

  /// 初始化服務，檢查是否有已登入的使用者
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userMap);
        
        // 更新最後登入時間
        _currentUser = _currentUser!.copyWith(lastLoginAt: DateTime.now());
        await _saveCurrentUser();
      } catch (e) {
        debugPrint('載入使用者資料失敗: $e');
        await prefs.remove('current_user');
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// 註冊新使用者
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? displayName,
  }) async {
    try {
      // 檢查使用者名稱是否已存在
      if (await _usernameExists(username)) {
        throw Exception('使用者名稱已被使用');
      }

      // 檢查 Email 是否已存在
      if (await _emailExists(email)) {
        throw Exception('Email 已被註冊');
      }

      // 建立新使用者
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        username: username,
        displayName: displayName,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // 儲存使用者資料和密碼
      await _saveUser(user, password);
      
      // 設為當前使用者
      _currentUser = user;
      await _saveCurrentUser();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('註冊失敗: $e');
      rethrow;
    }
  }

  /// 使用者登入
  Future<bool> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '{}';
      final users = jsonDecode(usersJson) as Map<String, dynamic>;

      // 尋找匹配的使用者
      String? userId;
      for (final entry in users.entries) {
        final userData = entry.value as Map<String, dynamic>;
        if (userData['username'] == usernameOrEmail || 
            userData['email'] == usernameOrEmail) {
          // 驗證密碼
          if (userData['password'] == _hashPassword(password)) {
            userId = entry.key;
            break;
          } else {
            throw Exception('密碼錯誤');
          }
        }
      }

      if (userId == null) {
        throw Exception('找不到此使用者');
      }

      // 載入使用者資料
      final userData = users[userId] as Map<String, dynamic>;
      userData.remove('password'); // 移除密碼欄位
      
      _currentUser = User.fromJson(userData);
      _currentUser = _currentUser!.copyWith(lastLoginAt: DateTime.now());
      
      await _saveCurrentUser();
      
      // 更新使用者的最後登入時間
      users[userId] = _currentUser!.toJson();
      users[userId]['password'] = userData['password'] ?? _hashPassword(password);
      await prefs.setString('users', jsonEncode(users));
      
      // 登入成功後,從帳號數據載入到本地 SharedPreferences
      await _syncUserDataToLocal(_currentUser!);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('登入失敗: $e');
      rethrow;
    }
  }

  /// 將帳號數據同步到本地 SharedPreferences
  Future<void> _syncUserDataToLocal(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // ✅ 同步打卡記錄 (包含空列表,確保新用戶也有初始化)
      final checkInDatesStr = user.checkInDates.map((date) =>
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
      ).toList();
      await prefs.setStringList('checked_dates', checkInDatesStr);
      
      // 計算連續打卡天數
      int consecutiveDays = 0;
      if (checkInDatesStr.isNotEmpty) {
        final today = DateTime.now();
        for (int i = 0; i < 365; i++) {
          final date = today.subtract(Duration(days: i));
          final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          if (checkInDatesStr.contains(dateStr)) {
            consecutiveDays++;
          } else {
            break;
          }
        }
      }
      await prefs.setInt('consecutive_days', consecutiveDays);
      debugPrint('已同步打卡記錄: ${checkInDatesStr.length} 天');
      
      // ✅ 同步練習時間 (包含空 Map,確保新用戶也有初始化)
      // 雲端與本地統一格式: 秒數 (完全精確)
      final practiceDataJson = jsonEncode(user.practiceTime);
      await prefs.setString('practice_data', practiceDataJson);
      debugPrint('已同步練習時間: ${user.practiceTime.length} 筆記錄');
      
      // 同步個人化設定
      if (user.settings.isNotEmpty) {
        final settings = user.settings;
        await prefs.setDouble('master_volume', (settings['masterVolume'] as num?)?.toDouble() ?? 0.8);
        await prefs.setDouble('midi_volume', (settings['midiVolume'] as num?)?.toDouble() ?? 0.7);
        await prefs.setDouble('recording_volume', (settings['recordingVolume'] as num?)?.toDouble() ?? 0.9);
        await prefs.setDouble('metronome_volume', (settings['metronomeVolume'] as num?)?.toDouble() ?? 0.6);
        await prefs.setBool('sound_enabled', settings['soundEnabled'] as bool? ?? true);
        await prefs.setBool('vibration_enabled', settings['vibrationEnabled'] as bool? ?? true);
        await prefs.setString('selected_language', settings['selectedLanguage'] as String? ?? 'zh_TW');
        debugPrint('已同步個人化設定');
      }
      
      debugPrint('帳號數據已完整同步到本地');
    } catch (e) {
      debugPrint('同步帳號數據到本地失敗: $e');
    }
  }

  /// 登出
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    _currentUser = null;
    notifyListeners();
  }

  /// 更新使用者資料
  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(
      displayName: displayName ?? _currentUser!.displayName,
      avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
    );

    await _saveCurrentUser();
    
    // 同時更新 users 中的資料
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '{}';
    final users = jsonDecode(usersJson) as Map<String, dynamic>;
    
    if (users.containsKey(_currentUser!.id)) {
      final userData = users[_currentUser!.id] as Map<String, dynamic>;
      final password = userData['password'];
      
      users[_currentUser!.id] = _currentUser!.toJson();
      users[_currentUser!.id]['password'] = password;
      
      await prefs.setString('users', jsonEncode(users));
    }
    
    notifyListeners();
  }

  /// 變更密碼
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) throw Exception('未登入');

    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '{}';
    final users = jsonDecode(usersJson) as Map<String, dynamic>;

    if (!users.containsKey(_currentUser!.id)) {
      throw Exception('找不到使用者資料');
    }

    final userData = users[_currentUser!.id] as Map<String, dynamic>;
    
    // 驗證舊密碼
    if (userData['password'] != _hashPassword(oldPassword)) {
      throw Exception('舊密碼錯誤');
    }

    // 更新密碼
    userData['password'] = _hashPassword(newPassword);
    users[_currentUser!.id] = userData;
    await prefs.setString('users', jsonEncode(users));
  }

  /// 刪除帳號
  Future<void> deleteAccount(String password) async {
    if (_currentUser == null) throw Exception('未登入');

    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '{}';
    final users = jsonDecode(usersJson) as Map<String, dynamic>;

    if (!users.containsKey(_currentUser!.id)) {
      throw Exception('找不到使用者資料');
    }

    final userData = users[_currentUser!.id] as Map<String, dynamic>;
    
    // 驗證密碼
    if (userData['password'] != _hashPassword(password)) {
      throw Exception('密碼錯誤');
    }

    // 刪除使用者資料
    users.remove(_currentUser!.id);
    await prefs.setString('users', jsonEncode(users));
    
    // 登出
    await logout();
  }

  // ==================== 私有方法 ====================

  /// 儲存當前使用者
  Future<void> _saveCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser != null) {
      await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
    }
  }

  /// 儲存使用者資料
  Future<void> _saveUser(User user, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '{}';
    final users = jsonDecode(usersJson) as Map<String, dynamic>;

    final userData = user.toJson();
    userData['password'] = _hashPassword(password);
    
    users[user.id] = userData;
    await prefs.setString('users', jsonEncode(users));
  }

  /// 檢查使用者名稱是否已存在
  Future<bool> _usernameExists(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '{}';
    final users = jsonDecode(usersJson) as Map<String, dynamic>;

    return users.values.any((userData) => 
      (userData as Map<String, dynamic>)['username'] == username
    );
  }

  /// 檢查 Email 是否已存在
  Future<bool> _emailExists(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '{}';
    final users = jsonDecode(usersJson) as Map<String, dynamic>;

    return users.values.any((userData) => 
      (userData as Map<String, dynamic>)['email'] == email
    );
  }

  /// 簡單的密碼雜湊（實際應用應使用更安全的方法）
  String _hashPassword(String password) {
    // 這裡使用簡單的方法，實際應用建議使用 crypto 套件
    return password.hashCode.toString();
  }
}

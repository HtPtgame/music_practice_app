import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:veloria/models/user.dart' as app_user;

/// Firebase 認證服務 - 整合 Firebase Authentication 和 Firestore
class FirebaseAuthService extends ChangeNotifier {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  app_user.User? _currentUser;
  bool _isInitialized = false;
  bool _hasLoadedData = false; // 標記是否已經載入過雲端數據

  app_user.User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  firebase_auth.User? get firebaseUser => _auth.currentUser;

  /// 初始化服務，監聽認證狀態變化
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 先檢查當前登入狀態並同步數據
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      // 首次載入時同步雲端數據到本地
      await _loadUserData(firebaseUser.uid, syncToLocal: true);
    }

    // 監聽 Firebase Auth 狀態變化 (後續的登入/登出)
    _auth.authStateChanges().listen((firebase_auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        // 使用者已登入,只更新 _currentUser,不同步到本地 (避免覆蓋)
        // 登入時的同步由 login()/register()/signInWithGoogle() 處理
        if (!_hasLoadedData) {
          await _loadUserData(firebaseUser.uid, syncToLocal: true);
        } else {
          await _loadUserData(firebaseUser.uid, syncToLocal: false);
        }
      } else {
        // 使用者已登出
        _currentUser = null;
        _hasLoadedData = false; // 重置標記
      }
      notifyListeners();
    });

    _isInitialized = true;
    notifyListeners();
  }

  /// 使用 Email 和密碼註冊
  /// [importLocalData] 是否導入訪客模式的本地數據（打卡記錄、練習時間）
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? displayName,
    bool importLocalData = false,
  }) async {
    try {
      // 檢查 Email 是否已被使用 (包含 Google 登入的帳號)
      if (await _emailExists(email)) {
        throw Exception('此 Email 已被使用,可能已用 Google 帳號註冊');
      }

      // 檢查使用者名稱是否已存在
      if (await _usernameExists(username)) {
        throw Exception('使用者名稱已被使用');
      }

      // 建立 Firebase 帳號
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('註冊失敗，請稍後再試');
      }

      // 更新 Firebase 使用者顯示名稱
      if (displayName != null) {
        await firebaseUser.updateDisplayName(displayName);
      }

      // 讀取本地數據（如果需要導入）
      final localData = importLocalData ? await _loadLocalGuestData() : null;

      // 建立 Firestore 使用者文件
      final user = app_user.User(
        id: firebaseUser.uid,
        email: email,
        username: username,
        displayName: displayName,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        // 根據 importLocalData 決定初始數據
        checkInDates: importLocalData && localData != null
            ? (localData['checkInDates'] as List<DateTime>)
            : [], // 打卡 0 天
        practiceTime: importLocalData && localData != null
            ? (localData['practiceTime'] as Map<String, int>)
            : {}, // 練習時間 0 秒
        unlockedAnimals: importLocalData && localData != null
            ? (localData['unlockedAnimals'] as Map<String, String>)
            : {}, // 動物解鎖 0 隻
        practiceSessions: importLocalData && localData != null
            ? (localData['practiceSessions'] as List<Map<String, dynamic>>)
            : [], // 練習會話記錄 0 筆
        settings: {
          // 音量設定預設值
          'masterVolume': 0.8, // 主音量 80%
          'midiVolume': 0.7, // MIDI 音量 70%
          'recordingVolume': 0.9, // 錄音音量 90%
          'metronomeVolume': 0.6, // 節拍器音量 60%
          'soundEnabled': true, // 音效開啟
          'vibrationEnabled': true, // 震動開啟
          'selectedLanguage': 'zh_TW', // 預設繁體中文
        },
        musicNotes: [], // 文字筆記 0 筆
      );

      await _saveUserToFirestore(user);
      _currentUser = user;

      // ✅ 同步預設數據到本地 SharedPreferences
      await _syncCloudDataToLocal(user);
      _hasLoadedData = true;

      // 發送驗證郵件
      await firebaseUser.sendEmailVerification();

      notifyListeners();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      debugPrint('註冊失敗: $e');
      rethrow;
    }
  }

  /// 使用 Email 和密碼登入
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('登入失敗，請稍後再試');
      }

      // 載入使用者資料並更新最後登入時間
      // 登入時同步雲端數據到本地
      await _loadUserData(firebaseUser.uid, syncToLocal: true);

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(lastLoginAt: DateTime.now());
        await _saveUserToFirestore(_currentUser!);
      }

      notifyListeners();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      debugPrint('登入失敗: $e');
      rethrow;
    }
  }

  /// Google 登入
  /// 使用 Google 帳號登入
  /// [importLocalData] 僅在新用戶註冊時有效，是否導入訪客模式的本地數據
  Future<bool> signInWithGoogle({bool importLocalData = false}) async {
    try {
      // 先登出 Google,確保每次都顯示帳號選擇器
      await _googleSignIn.signOut();

      // 觸發 Google 登入流程
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 使用者取消登入
        debugPrint('Google 登入已取消');
        return false;
      }

      // 取得認證詳情
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 建立 Firebase 憑證
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 使用 Google 憑證登入 Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Google 登入失敗，請稍後再試');
      }

      // 檢查是否為新使用者
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // 讀取本地數據（如果需要導入）
        final localData = importLocalData ? await _loadLocalGuestData() : null;

        // 新使用者，建立 Firestore 文件
        final username = _generateUsernameFromEmail(firebaseUser.email ?? '');
        final user = app_user.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          username: username,
          displayName: firebaseUser.displayName,
          avatarUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          // 根據 importLocalData 決定初始數據
          checkInDates: importLocalData && localData != null
              ? (localData['checkInDates'] as List<DateTime>)
              : [], // 打卡 0 天
          practiceTime: importLocalData && localData != null
              ? (localData['practiceTime'] as Map<String, int>)
              : {}, // 練習時間 0 秒
          unlockedAnimals: importLocalData && localData != null
              ? (localData['unlockedAnimals'] as Map<String, String>)
              : {}, // 動物解鎖 0 隻
          practiceSessions: importLocalData && localData != null
              ? (localData['practiceSessions'] as List<Map<String, dynamic>>)
              : [], // 練習會話記錄 0 筆
          settings: {
            // 音量設定預設值
            'masterVolume': 0.8, // 主音量 80%
            'midiVolume': 0.7, // MIDI 音量 70%
            'recordingVolume': 0.9, // 錄音音量 90%
            'metronomeVolume': 0.6, // 節拍器音量 60%
            'soundEnabled': true, // 音效開啟
            'vibrationEnabled': true, // 震動開啟
            'selectedLanguage': 'zh_TW', // 預設繁體中文
          },
          musicNotes: [], // 文字筆記 0 筆
        );
        await _saveUserToFirestore(user);
        _currentUser = user;

        // ✅ 同步預設數據到本地 SharedPreferences
        await _syncCloudDataToLocal(user);
        _hasLoadedData = true;
      } else {
        // 現有使用者，載入資料並同步到本地
        await _loadUserData(firebaseUser.uid, syncToLocal: true);

        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(lastLoginAt: DateTime.now());
          await _saveUserToFirestore(_currentUser!);
        }
      }

      notifyListeners();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Google 登入 Firebase 錯誤: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      debugPrint('Google 登入失敗: $e');
      // 如果不是用戶取消,則拋出錯誤
      if (e.toString().contains('sign_in_canceled') ||
          e.toString().contains('popup_closed_by_user')) {
        return false;
      }
      rethrow;
    }
  }

  /// 登出
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _currentUser = null;
    _hasLoadedData = false; // 重置標記

    // 清除本地 SharedPreferences 中的所有用戶數據（恢復到初始狀態）
    try {
      final prefs = await SharedPreferences.getInstance();
      // 清除打卡記錄
      await prefs.remove('checked_dates');
      await prefs.remove('consecutive_days');

      // 清除練習數據
      await prefs.remove('practice_data');
      await prefs.remove('last_practice_clean_date');

      // 清除動物解鎖數據
      await prefs.remove('unlocked_animals');

      // 清除個人化設定（恢復到預設值）
      await prefs.remove('master_volume');
      await prefs.remove('midi_volume');
      await prefs.remove('recording_volume');
      await prefs.remove('metronome_volume');
      await prefs.remove('sound_enabled');
      await prefs.remove('vibration_enabled');
      await prefs.remove('selected_language');

      debugPrint('已清除所有本地用戶數據，恢復到初始狀態');
    } catch (e) {
      debugPrint('清除本地數據失敗: $e');
    }

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

    // 更新 Firebase Auth 使用者
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      if (displayName != null) {
        await firebaseUser.updateDisplayName(displayName);
      }
      if (avatarUrl != null) {
        await firebaseUser.updatePhotoURL(avatarUrl);
      }
    }

    // 更新 Firestore
    await _saveUserToFirestore(_currentUser!);
    notifyListeners();
  }

  /// 內部方法：更新當前使用者數據（用於雲端同步）
  void updateCurrentUser(app_user.User user) {
    _currentUser = user;
    notifyListeners();
    debugPrint('✅ 已更新當前使用者數據');
  }

  /// 變更密碼
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null || firebaseUser.email == null) {
      throw Exception('未登入');
    }

    // 重新認證
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: firebaseUser.email!,
      password: oldPassword,
    );

    try {
      await firebaseUser.reauthenticateWithCredential(credential);
      await firebaseUser.updatePassword(newPassword);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('舊密碼錯誤');
      }
      throw _handleFirebaseAuthException(e);
    }
  }

  /// 刪除帳號
  /// password: Email/密碼登入時需要提供密碼,Google 登入時傳 null
  Future<void> deleteAccount([String? password]) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('未登入');
    }

    try {
      // 檢查用戶的登入方式
      final providerData = firebaseUser.providerData;
      bool isGoogleUser =
          providerData.any((info) => info.providerId == 'google.com');

      if (isGoogleUser) {
        // Google 登入用戶:需要重新進行 Google 認證
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('需要重新登入 Google 帳號才能刪除');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await firebaseUser.reauthenticateWithCredential(credential);
      } else {
        // Email/密碼登入用戶:使用密碼認證
        if (password == null || password.isEmpty) {
          throw Exception('請輸入密碼');
        }

        if (firebaseUser.email == null) {
          throw Exception('無法取得帳號郵件');
        }

        final credential = firebase_auth.EmailAuthProvider.credential(
          email: firebaseUser.email!,
          password: password,
        );

        await firebaseUser.reauthenticateWithCredential(credential);
      }

      // 刪除 Firestore 資料
      await _firestore.collection('users').doc(firebaseUser.uid).delete();

      // 刪除 Firebase Auth 帳號
      await firebaseUser.delete();

      _currentUser = null;
      _hasLoadedData = false;
      notifyListeners();
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('密碼錯誤');
      }
      throw _handleFirebaseAuthException(e);
    }
  }

  /// 檢查當前用戶是否使用 Google 登入
  bool isGoogleSignIn() {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return false;

    return firebaseUser.providerData
        .any((info) => info.providerId == 'google.com');
  }

  /// 發送密碼重置郵件
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  /// 重新發送驗證郵件
  Future<void> resendEmailVerification() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('未登入');
    }

    if (firebaseUser.emailVerified) {
      throw Exception('Email 已驗證');
    }

    await firebaseUser.sendEmailVerification();
  }

  /// 重新載入使用者資料
  Future<void> reloadUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    await firebaseUser.reload();
    await _loadUserData(firebaseUser.uid);
    notifyListeners();
  }

  // ==================== 私有方法 ====================

  /// 從 Firestore 載入使用者資料
  /// syncToLocal: 是否同步雲端數據到本地 SharedPreferences (只在登入時執行一次)
  Future<void> _loadUserData(String uid, {bool syncToLocal = false}) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        
        // ✅ 檢查並補全缺失的資料欄位
        final isUpdated = await _ensureDataIntegrity(uid, data);
        
        // 如果有更新，重新讀取最新數據
        if (isUpdated) {
          final updatedDoc = await _firestore.collection('users').doc(uid).get();
          _currentUser = app_user.User.fromJson(updatedDoc.data()!);
        } else {
          _currentUser = app_user.User.fromJson(data);
        }

        // 只在登入時同步雲端數據到本地 SharedPreferences（直接覆蓋）
        if (syncToLocal) {
          await _syncCloudDataToLocal(_currentUser!);
          _hasLoadedData = true; // 標記已同步
          debugPrint('✅ 雲端數據已同步到本地,_hasLoadedData = true');
        }
      }
    } catch (e) {
      debugPrint('載入使用者資料失敗: $e');
    }
  }

  /// 檢查並補全雲端資料的完整性
  /// 返回 true 表示有更新資料
  Future<bool> _ensureDataIntegrity(String uid, Map<String, dynamic> data) async {
    final Map<String, dynamic> updates = {};
    bool needsUpdate = false;

    // 檢查 checkInDates（打卡記錄）
    if (!data.containsKey('checkInDates')) {
      updates['checkInDates'] = [];
      needsUpdate = true;
      debugPrint('⚠️ 補全缺失欄位: checkInDates');
    }

    // 檢查 practiceTime（練習時間）
    if (!data.containsKey('practiceTime')) {
      updates['practiceTime'] = {};
      needsUpdate = true;
      debugPrint('⚠️ 補全缺失欄位: practiceTime');
    }

    // 檢查 unlockedAnimals（動物解鎖記錄）
    if (!data.containsKey('unlockedAnimals')) {
      updates['unlockedAnimals'] = {};
      needsUpdate = true;
      debugPrint('⚠️ 補全缺失欄位: unlockedAnimals');
    }

    // 檢查 settings（個人化設定）
    if (!data.containsKey('settings')) {
      updates['settings'] = {
        'masterVolume': 0.8,
        'midiVolume': 0.7,
        'recordingVolume': 0.9,
        'metronomeVolume': 0.6,
        'soundEnabled': true,
        'vibrationEnabled': true,
        'selectedLanguage': 'zh_TW',
      };
      needsUpdate = true;
      debugPrint('⚠️ 補全缺失欄位: settings (使用預設值)');
    } else {
      // 檢查 settings 內部的子欄位
      final settings = data['settings'] as Map<String, dynamic>;
      final settingsUpdates = <String, dynamic>{};
      
      if (!settings.containsKey('masterVolume')) settingsUpdates['masterVolume'] = 0.8;
      if (!settings.containsKey('midiVolume')) settingsUpdates['midiVolume'] = 0.7;
      if (!settings.containsKey('recordingVolume')) settingsUpdates['recordingVolume'] = 0.9;
      if (!settings.containsKey('metronomeVolume')) settingsUpdates['metronomeVolume'] = 0.6;
      if (!settings.containsKey('soundEnabled')) settingsUpdates['soundEnabled'] = true;
      if (!settings.containsKey('vibrationEnabled')) settingsUpdates['vibrationEnabled'] = true;
      if (!settings.containsKey('selectedLanguage')) settingsUpdates['selectedLanguage'] = 'zh_TW';
      
      if (settingsUpdates.isNotEmpty) {
        final updatedSettings = Map<String, dynamic>.from(settings)..addAll(settingsUpdates);
        updates['settings'] = updatedSettings;
        needsUpdate = true;
        debugPrint('⚠️ 補全 settings 缺失的子欄位: ${settingsUpdates.keys.join(", ")}');
      }
    }

    // 檢查 musicNotes（文字筆記）
    if (!data.containsKey('musicNotes')) {
      updates['musicNotes'] = [];
      needsUpdate = true;
      debugPrint('⚠️ 補全缺失欄位: musicNotes');
    }

    // 檢查 practiceSessions（練習會話記錄）
    if (!data.containsKey('practiceSessions')) {
      updates['practiceSessions'] = [];
      needsUpdate = true;
      debugPrint('⚠️ 補全缺失欄位: practiceSessions');
    }

    // 如果有缺失欄位，更新到 Firestore
    if (needsUpdate) {
      try {
        await _firestore.collection('users').doc(uid).update(updates);
        debugPrint('✅ 已補全雲端資料的缺失欄位: ${updates.keys.join(", ")}');
        return true;
      } catch (e) {
        debugPrint('❌ 補全資料欄位失敗: $e');
        return false;
      }
    }

    debugPrint('✅ 雲端資料完整，無需補全');
    return false;
  }

  /// 將雲端數據同步到本地 SharedPreferences（直接覆蓋，訪客模式數據會遺失）
  Future<void> _syncCloudDataToLocal(app_user.User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ 同步打卡記錄（直接覆蓋本地數據）
      final checkInDatesStr = user.checkInDates
          .map((date) =>
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}')
          .toList();
      await prefs.setStringList('checked_dates', checkInDatesStr);

      // 計算連續打卡天數
      int consecutiveDays = 0;
      if (checkInDatesStr.isNotEmpty) {
        final today = DateTime.now();
        final todayStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final hasCheckedToday = checkInDatesStr.contains(todayStr);

        // 根據今天是否打卡決定起始日
        final startDay = hasCheckedToday ? 0 : 1;

        for (int i = startDay; i < 365; i++) {
          final date = today.subtract(Duration(days: i));
          final dateStr =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          if (checkInDatesStr.contains(dateStr)) {
            consecutiveDays++;
          } else {
            break;
          }
        }
      }
      await prefs.setInt('consecutive_days', consecutiveDays);
      debugPrint('已同步打卡記錄到本地: ${checkInDatesStr.length} 天');

      // ✅ 同步練習時間（直接覆蓋本地數據）
      final practiceDataJson = jsonEncode(user.practiceTime);
      await prefs.setString('practice_data', practiceDataJson);
      debugPrint('已同步練習時間到本地: ${user.practiceTime.length} 筆記錄');

      // ✅ 同步動物解鎖數據（直接覆蓋本地數據）
      // 修復：即使雲端為空，也要清除本地舊數據
      if (user.unlockedAnimals.isNotEmpty) {
        final unlockedJson = jsonEncode(user.unlockedAnimals);
        await prefs.setString('unlocked_animals', unlockedJson);
        debugPrint('已同步動物解鎖數據到本地: ${user.unlockedAnimals.length} 隻');
      } else {
        // 雲端沒有解鎖動物，清除本地舊數據
        await prefs.remove('unlocked_animals');
        debugPrint('雲端無解鎖動物，已清除本地舊數據');
      }

      // 同步個人化設定
      if (user.settings.isNotEmpty) {
        // 雲端有設定，使用雲端設定（不使用預設值作為備用）
        final settings = user.settings;
        
        // 只在雲端確實有該設定值時才寫入本地
        if (settings.containsKey('masterVolume')) {
          await prefs.setDouble('master_volume',
              (settings['masterVolume'] as num).toDouble());
        }
        if (settings.containsKey('midiVolume')) {
          await prefs.setDouble(
              'midi_volume', (settings['midiVolume'] as num).toDouble());
        }
        if (settings.containsKey('recordingVolume')) {
          await prefs.setDouble('recording_volume',
              (settings['recordingVolume'] as num).toDouble());
        }
        if (settings.containsKey('metronomeVolume')) {
          await prefs.setDouble('metronome_volume',
              (settings['metronomeVolume'] as num).toDouble());
        }
        if (settings.containsKey('soundEnabled')) {
          await prefs.setBool(
              'sound_enabled', settings['soundEnabled'] as bool);
        }
        if (settings.containsKey('vibrationEnabled')) {
          await prefs.setBool(
              'vibration_enabled', settings['vibrationEnabled'] as bool);
        }
        if (settings.containsKey('selectedLanguage')) {
          await prefs.setString('selected_language',
              settings['selectedLanguage'] as String);
        }
        debugPrint('已同步個人化設定到本地（從雲端，僅同步有值的欄位）');
      } else {
        // 雲端沒有設定，讀取本地設定（如果有）或使用預設值
        // 然後將本地設定同步到雲端
        final localSettings = {
          'masterVolume': prefs.getDouble('master_volume') ?? 0.8,
          'midiVolume': prefs.getDouble('midi_volume') ?? 0.7,
          'recordingVolume': prefs.getDouble('recording_volume') ?? 0.9,
          'metronomeVolume': prefs.getDouble('metronome_volume') ?? 0.6,
          'soundEnabled': prefs.getBool('sound_enabled') ?? true,
          'vibrationEnabled': prefs.getBool('vibration_enabled') ?? true,
          'selectedLanguage': prefs.getString('selected_language') ?? 'zh_TW',
        };
        
        // 同步本地設定到雲端
        try {
          await _firestore.collection('users').doc(user.id).update({
            'settings': localSettings,
          });
          debugPrint('已將本地設定同步到雲端（雲端原本沒有設定）');
        } catch (e) {
          debugPrint('同步本地設定到雲端失敗: $e');
        }
      }

      // ✅ 同步練習會話記錄（直接覆蓋本地數據）
      if (user.practiceSessions.isNotEmpty) {
        final sessionsJson = jsonEncode(user.practiceSessions);
        await prefs.setString('practice_sessions', sessionsJson);
        debugPrint('已同步練習會話記錄到本地: ${user.practiceSessions.length} 條記錄');
      } else {
        // 雲端沒有練習會話記錄，清除本地舊數據
        await prefs.remove('practice_sessions');
        debugPrint('雲端無練習會話記錄，已清除本地舊數據');
      }

      debugPrint('雲端數據已完整同步到本地');
    } catch (e) {
      debugPrint('同步雲端數據到本地失敗: $e');
    }
  }

  /// 儲存使用者資料到 Firestore
  /// 讀取本地訪客模式的數據（用於註冊時導入）
  Future<Map<String, dynamic>> _loadLocalGuestData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 讀取打卡記錄
      final localCheckInDates = prefs.getStringList('checked_dates') ?? [];
      final checkInDates = localCheckInDates.map((dateStr) {
        final parts = dateStr.split('-');
        return DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }).toList();

      // 讀取練習時間
      final localPracticeDataJson = prefs.getString('practice_data');
      Map<String, int> practiceTime = {};
      if (localPracticeDataJson != null && localPracticeDataJson.isNotEmpty) {
        try {
          practiceTime =
              Map<String, int>.from(jsonDecode(localPracticeDataJson));
        } catch (e) {
          debugPrint('解析本地練習數據失敗: $e');
        }
      }

      // 讀取動物解鎖數據
      final localUnlockedJson = prefs.getString('unlocked_animals');
      Map<String, String> unlockedAnimals = {};
      if (localUnlockedJson != null && localUnlockedJson.isNotEmpty) {
        try {
          final decoded =
              Map<String, dynamic>.from(jsonDecode(localUnlockedJson));
          unlockedAnimals =
              decoded.map((key, value) => MapEntry(key, value as String));
        } catch (e) {
          debugPrint('解析本地動物解鎖數據失敗: $e');
        }
      }

      // 讀取練習會話記錄
      final localSessionsJson = prefs.getString('practice_sessions');
      List<Map<String, dynamic>> practiceSessions = [];
      if (localSessionsJson != null && localSessionsJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(localSessionsJson);
          practiceSessions = decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        } catch (e) {
          debugPrint('解析本地練習會話記錄失敗: $e');
        }
      }

      return {
        'checkInDates': checkInDates,
        'practiceTime': practiceTime,
        'unlockedAnimals': unlockedAnimals,
        'practiceSessions': practiceSessions,
        'hasData': checkInDates.isNotEmpty ||
            practiceTime.isNotEmpty ||
            unlockedAnimals.isNotEmpty ||
            practiceSessions.isNotEmpty,
      };
    } catch (e) {
      debugPrint('讀取本地數據失敗: $e');
      return {
        'checkInDates': <DateTime>[],
        'practiceTime': <String, int>{},
        'unlockedAnimals': <String, String>{},
        'practiceSessions': <Map<String, dynamic>>[],
        'hasData': false,
      };
    }
  }

  Future<void> _saveUserToFirestore(app_user.User user) async {
    await _firestore.collection('users').doc(user.id).set(
          user.toJson(),
          SetOptions(merge: true),
        );
  }

  /// 檢查使用者名稱是否已存在
  Future<bool> _usernameExists(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// 檢查 Email 是否已被使用 (包含 Google 登入的帳號)
  Future<bool> _emailExists(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// 從 Email 生成使用者名稱
  String _generateUsernameFromEmail(String email) {
    final username = email.split('@')[0];
    return username.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  /// 處理 Firebase Auth 異常
  Exception _handleFirebaseAuthException(
      firebase_auth.FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'email-already-in-use':
        message = '此 Email 已被註冊，請使用其他 Email 或直接登入';
        break;
      case 'invalid-email':
        message = 'Email 格式不正確，請重新輸入';
        break;
      case 'operation-not-allowed':
        message = '此操作未被允許，請聯繫客服';
        break;
      case 'weak-password':
        message = '密碼強度不足，請使用至少 6 個字元的密碼';
        break;
      case 'user-disabled':
        message = '此帳號已被停用，請聯繫客服';
        break;
      case 'user-not-found':
        message = '找不到此使用者，請檢查 Email 是否正確';
        break;
      case 'wrong-password':
        message = '密碼錯誤，請重新輸入';
        break;
      case 'invalid-credential':
        message = 'Email 或密碼錯誤，請重新輸入';
        break;
      case 'too-many-requests':
        message = '登入嘗試次數過多，請稍後再試';
        break;
      case 'network-request-failed':
        message = '網路連線失敗，請檢查網路連線';
        break;
      case 'account-exists-with-different-credential':
        message = '此 Email 已使用其他方式註冊，請使用原本的登入方式';
        break;
      case 'invalid-verification-code':
        message = '驗證碼錯誤，請重新輸入';
        break;
      case 'invalid-verification-id':
        message = '驗證失敗，請重新嘗試';
        break;
      default:
        // 移除技術性的前綴，只保留錯誤訊息
        message = e.message?.replaceAll(RegExp(r'^\[.*?\]\s*'), '') ??
            '登入時發生錯誤，請稍後再試';
        break;
    }
    return Exception(message);
  }
}

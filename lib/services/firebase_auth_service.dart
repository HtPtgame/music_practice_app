import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:music_practice_app/models/user.dart' as app_user;

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
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? displayName,
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

      // 建立 Firestore 使用者文件
      final user = app_user.User(
        id: firebaseUser.uid,
        email: email,
        username: username,
        displayName: displayName,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        // 初始化預設數據
        checkInDates: [], // 打卡 0 天
        practiceTime: {}, // 練習時間 0 秒
        settings: {
          // 音量設定預設值
          'masterVolume': 0.8,      // 主音量 80%
          'midiVolume': 0.7,        // MIDI 音量 70%
          'recordingVolume': 0.9,   // 錄音音量 90%
          'metronomeVolume': 0.6,   // 節拍器音量 60%
          'soundEnabled': true,     // 音效開啟
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
  Future<bool> signInWithGoogle() async {
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
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

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
          // 初始化預設數據
          checkInDates: [], // 打卡 0 天
          practiceTime: {}, // 練習時間 0 秒
          settings: {
            // 音量設定預設值
            'masterVolume': 0.8,      // 主音量 80%
            'midiVolume': 0.7,        // MIDI 音量 70%
            'recordingVolume': 0.9,   // 錄音音量 90%
            'metronomeVolume': 0.6,   // 節拍器音量 60%
            'soundEnabled': true,     // 音效開啟
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
      bool isGoogleUser = providerData.any((info) => info.providerId == 'google.com');
      
      if (isGoogleUser) {
        // Google 登入用戶:需要重新進行 Google 認證
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('需要重新登入 Google 帳號才能刪除');
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
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
    
    return firebaseUser.providerData.any((info) => info.providerId == 'google.com');
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
        _currentUser = app_user.User.fromJson(data);
        
        // 只在登入時同步雲端數據到本地 SharedPreferences
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

  /// 將雲端數據同步到本地 SharedPreferences
  Future<void> _syncCloudDataToLocal(app_user.User user) async {
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
      debugPrint('已同步打卡記錄到本地: ${checkInDatesStr.length} 天');
      
      // ✅ 同步練習時間 (包含空 Map,確保新用戶也有初始化)
      // 雲端與本地統一格式: 秒數 (完全精確)
      final practiceDataJson = jsonEncode(user.practiceTime);
      await prefs.setString('practice_data', practiceDataJson);
      debugPrint('已同步練習時間到本地: ${user.practiceTime.length} 筆記錄');
      
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
        debugPrint('已同步個人化設定到本地');
      }
      
      debugPrint('雲端數據已完整同步到本地');
    } catch (e) {
      debugPrint('同步雲端數據到本地失敗: $e');
    }
  }

  /// 儲存使用者資料到 Firestore
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
  Exception _handleFirebaseAuthException(firebase_auth.FirebaseAuthException e) {
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
        message = e.message?.replaceAll(RegExp(r'^\[.*?\]\s*'), '') ?? '登入時發生錯誤，請稍後再試';
        break;
    }
    return Exception(message);
  }
}

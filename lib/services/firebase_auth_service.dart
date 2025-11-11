import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  app_user.User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  firebase_auth.User? get firebaseUser => _auth.currentUser;

  /// 初始化服務，監聽認證狀態變化
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 監聽 Firebase Auth 狀態變化
    _auth.authStateChanges().listen((firebase_auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        // 使用者已登入，載入使用者資料
        await _loadUserData(firebaseUser.uid);
      } else {
        // 使用者已登出
        _currentUser = null;
      }
      notifyListeners();
    });

    // 檢查當前登入狀態
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _loadUserData(firebaseUser.uid);
    }

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
      );

      await _saveUserToFirestore(user);
      _currentUser = user;

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
      await _loadUserData(firebaseUser.uid);
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
      // 觸發 Google 登入流程
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 使用者取消登入
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
        throw Exception('Google 登入失敗');
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
        );
        await _saveUserToFirestore(user);
        _currentUser = user;
      } else {
        // 現有使用者，載入資料
        await _loadUserData(firebaseUser.uid);
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(lastLoginAt: DateTime.now());
          await _saveUserToFirestore(_currentUser!);
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Google 登入失敗: $e');
      rethrow;
    }
  }

  /// 登出
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
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
  Future<void> deleteAccount(String password) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null || firebaseUser.email == null) {
      throw Exception('未登入');
    }

    // 重新認證
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: firebaseUser.email!,
      password: password,
    );

    try {
      await firebaseUser.reauthenticateWithCredential(credential);

      // 刪除 Firestore 資料
      await _firestore.collection('users').doc(firebaseUser.uid).delete();

      // 刪除 Firebase Auth 帳號
      await firebaseUser.delete();

      _currentUser = null;
      notifyListeners();
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('密碼錯誤');
      }
      throw _handleFirebaseAuthException(e);
    }
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
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _currentUser = app_user.User.fromJson(data);
      }
    } catch (e) {
      debugPrint('載入使用者資料失敗: $e');
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

  /// 從 Email 生成使用者名稱
  String _generateUsernameFromEmail(String email) {
    final username = email.split('@')[0];
    return username.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  /// 處理 Firebase Auth 異常
  Exception _handleFirebaseAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return Exception('此 Email 已被註冊');
      case 'invalid-email':
        return Exception('Email 格式不正確');
      case 'operation-not-allowed':
        return Exception('此操作未被允許');
      case 'weak-password':
        return Exception('密碼強度不足');
      case 'user-disabled':
        return Exception('此帳號已被停用');
      case 'user-not-found':
        return Exception('找不到此使用者');
      case 'wrong-password':
        return Exception('密碼錯誤');
      case 'too-many-requests':
        return Exception('請求次數過多，請稍後再試');
      case 'network-request-failed':
        return Exception('網路連線失敗');
      default:
        return Exception('認證失敗: ${e.message}');
    }
  }
}

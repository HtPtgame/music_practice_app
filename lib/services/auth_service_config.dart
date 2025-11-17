/// 認證服務配置
///
/// 這個檔案用於切換不同的認證服務實作：
/// - 本地認證（LocalAuthService）：使用 SharedPreferences 儲存
/// - Firebase 認證（FirebaseAuthService）：使用 Firebase Authentication 和 Firestore
///
/// 使用方式：
/// 1. 修改 USE_FIREBASE_AUTH 來切換認證服務
/// 2. 在其他檔案中使用 getAuthService() 取得當前服務
/// 3. 或直接 import 'auth_service_config.dart' 並使用 authService

import 'package:music_practice_app/services/auth_service.dart';
import 'package:music_practice_app/services/firebase_auth_service.dart';

/// 設定是否使用 Firebase 認證
///
/// true: 使用 Firebase Authentication（需先完成 Firebase 設定）
/// false: 使用本地 SharedPreferences 儲存（開發測試用）
const bool USE_FIREBASE_AUTH = true;

/// 取得當前配置的認證服務
///
/// 根據 USE_FIREBASE_AUTH 設定回傳對應的認證服務實例
dynamic getAuthService() {
  if (USE_FIREBASE_AUTH) {
    return FirebaseAuthService();
  } else {
    return AuthService();
  }
}

/// 全域認證服務實例
///
/// 可直接使用此變數存取認證服務，無需每次呼叫 getAuthService()
///
/// 使用範例：
/// ```dart
/// import 'package:music_practice_app/services/auth_service_config.dart';
///
/// // 檢查登入狀態
/// if (authService.isAuthenticated) {
///   print('已登入: ${authService.currentUser?.username}');
/// }
///
/// // 執行登入
/// await authService.login(...);
/// ```
final authService = getAuthService();

/// 認證服務類型說明
///
/// 本地認證服務（AuthService）：
/// - 優點：快速開發、無需網路、測試方便
/// - 缺點：資料僅存本地、無法跨裝置同步、安全性較低
/// - 適用：開發階段、原型測試、離線應用
///
/// Firebase 認證服務（FirebaseAuthService）：
/// - 優點：雲端同步、跨裝置登入、高安全性、支援第三方登入
/// - 缺點：需要網路連線、需要 Firebase 設定
/// - 適用：正式上線、生產環境、需要雲端功能
///
/// 功能比較表：
///
/// | 功能 | 本地認證 | Firebase 認證 |
/// |------|---------|--------------|
/// | Email/密碼登入 | ✅ | ✅ |
/// | 註冊新帳號 | ✅ | ✅ |
/// | Google 登入 | ❌ | ✅ |
/// | Apple 登入 | ❌ | ✅ |
/// | 密碼重置 | ❌ | ✅ |
/// | Email 驗證 | ❌ | ✅ |
/// | 跨裝置同步 | ❌ | ✅ |
/// | 離線使用 | ✅ | 部分支援 |
/// | 安全性 | 低 | 高 |
/// | 設定難度 | 簡單 | 中等 |
///
/// 切換步驟：
///
/// 1. 本地認證 → Firebase 認證
///    - 設定 USE_FIREBASE_AUTH = true
///    - 完成 Firebase 設定（參考 FIREBASE_SETUP_GUIDE.md）
///    - 執行 flutter pub get
///    - 重新啟動應用程式
///
/// 2. Firebase 認證 → 本地認證
///    - 設定 USE_FIREBASE_AUTH = false
///    - 重新啟動應用程式
///    - （選用）移除 Firebase 相關套件

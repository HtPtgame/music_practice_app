import 'package:music_practice_app/services/auth_service.dart';
import 'package:music_practice_app/services/firebase_auth_service.dart';

/// 認證服務配置
///
/// 使用方式：
/// 1. 修改 [USE_FIREBASE_AUTH] 切換認證服務
/// 2. import 這個檔案並使用 [authService]
/// 3. 或呼叫 [getAuthService] 取得當前服務
const bool USE_FIREBASE_AUTH = true;

/// 根據 [USE_FIREBASE_AUTH] 回傳對應的認證服務實例
dynamic getAuthService() {
  if (USE_FIREBASE_AUTH) {
    return FirebaseAuthService();
  } else {
    return AuthService();
  }
}

/// 全域認證服務實例，方便直接引用
final authService = getAuthService();

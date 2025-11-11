# 使用者帳號系統使用說明

## 功能概覽

本應用程式現已支援完整的使用者帳號管理系統，包含：

### 1. 使用者註冊
- Email 驗證
- 使用者名稱（3-20個字元，英文、數字、底線）
- 密碼設定（至少6個字元）
- 可選的顯示名稱
- 頭像支援

### 2. 使用者登入
- 支援使用者名稱或 Email 登入
- 密碼驗證
- 記住登入狀態（使用 SharedPreferences）
- 自動登入功能

### 3. 個人資料管理
- 查看個人資料
- 編輯顯示名稱
- 變更密碼
- 刪除帳號（需要密碼確認）

### 4. 登出功能
- 一鍵登出
- 清除登入狀態

## 頁面導覽

### 首頁
- **未登入狀態**：右上角顯示「登入」按鈕
- **已登入狀態**：右上角顯示使用者頭像，點擊進入個人資料頁面

### 登入頁面 (`/login`)
- 輸入使用者名稱或 Email
- 輸入密碼
- 點擊「登入」按鈕
- 若無帳號，可點擊「立即註冊」前往註冊頁面

### 註冊頁面 (`/register`)
- 輸入 Email（需符合格式）
- 輸入使用者名稱（3-20字元，僅限英文、數字、底線）
- 輸入顯示名稱（可選）
- 輸入密碼（至少6個字元）
- 確認密碼
- 點擊「註冊」按鈕

### 個人資料頁面 (`/profile`)
- 顯示使用者頭像
- 顯示使用者名稱、Email
- 顯示註冊日期、上次登入時間
- **編輯資料**：點擊右上角編輯按鈕
- **變更密碼**：需輸入舊密碼和新密碼
- **刪除帳號**：需輸入密碼確認
- **登出**：點擊底部登出按鈕

## 技術實作

### 資料儲存
使用 `shared_preferences` 套件進行本地資料儲存：
- 使用者資料存放在 `users` key
- 當前登入使用者存放在 `current_user` key
- 密碼使用簡單雜湊（實際應用建議使用更安全的加密方法）

### 服務架構
- **User Model** (`lib/models/user.dart`)：定義使用者資料結構
- **AuthService** (`lib/services/auth_service.dart`)：管理認證邏輯，使用 ChangeNotifier 實現狀態管理
- **頁面**：
  - `LoginPage`：登入頁面
  - `RegisterPage`：註冊頁面
  - `ProfilePage`：個人資料頁面

### 狀態管理
使用 `ListenableBuilder` 監聽 `AuthService` 的變化，實現即時 UI 更新。

## 使用範例

### 在其他頁面中檢查登入狀態

```dart
import 'package:music_practice_app/services/auth_service.dart';

// 取得當前使用者
final user = AuthService().currentUser;

// 檢查是否已登入
if (AuthService().isAuthenticated) {
  // 已登入的邏輯
  print('歡迎回來，${user?.username}');
} else {
  // 未登入的邏輯
  print('請先登入');
}
```

### 監聽登入狀態變化

```dart
ListenableBuilder(
  listenable: AuthService(),
  builder: (context, _) {
    final isLoggedIn = AuthService().isAuthenticated;
    return isLoggedIn 
      ? Text('已登入') 
      : Text('未登入');
  },
)
```

### 執行登入/登出操作

```dart
// 登入
try {
  await AuthService().login(
    usernameOrEmail: 'username',
    password: 'password',
  );
  print('登入成功');
} catch (e) {
  print('登入失敗: $e');
}

// 登出
await AuthService().logout();
```

## 未來改進建議

1. **後端整合**：目前使用本地儲存，建議整合 Firebase Auth 或自建後端 API
2. **密碼加密**：使用 crypto 套件實作更安全的密碼雜湊
3. **第三方登入**：支援 Google、Apple、Facebook 等第三方登入
4. **Email 驗證**：新增 Email 驗證流程
5. **忘記密碼**：實作密碼重置功能
6. **使用者設定同步**：將使用者的練習記錄、設定等資料與帳號綁定

## 注意事項

⚠️ **安全性警告**：
- 目前的密碼儲存方式僅用於開發測試
- 生產環境中應使用：
  - HTTPS 連線
  - 安全的密碼雜湊演算法（bcrypt、scrypt 等）
  - 後端 API 進行認證
  - Token-based 認證（JWT）
  - 定期更新安全性套件

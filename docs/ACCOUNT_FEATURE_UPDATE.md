# 使用者帳號系統 - 功能更新

## 📅 更新日期：2025年11月11日

## ✨ 新增功能

### 1. 使用者帳號系統
完整的本地使用者帳號管理系統，包含以下功能：

#### 🔐 註冊與登入
- **註冊新帳號**
  - Email 驗證（格式檢查）
  - 使用者名稱驗證（3-20字元，英文、數字、底線）
  - 密碼強度要求（至少6個字元）
  - 可選的顯示名稱
  - 防止重複註冊（Email 和使用者名稱唯一性檢查）

- **使用者登入**
  - 支援使用者名稱或 Email 登入
  - 密碼驗證
  - 自動記住登入狀態
  - 自動更新最後登入時間

#### 👤 個人資料管理
- 查看個人資料（使用者名稱、Email、註冊日期、最後登入時間）
- 編輯顯示名稱
- 變更密碼（需驗證舊密碼）
- 刪除帳號（需密碼確認，不可復原）
- 使用者頭像顯示（支援自訂圖片或首字母頭像）

#### 🔓 登出功能
- 一鍵登出
- 自動清除登入狀態

### 2. UI/UX 更新

#### 首頁整合
- **未登入狀態**：右上角顯示登入圖示按鈕
- **已登入狀態**：右上角顯示使用者頭像，點擊進入個人資料頁面

#### 設定頁面整合
- 新增「帳號設定」區塊在設定頁面頂部
- **未登入狀態**：顯示「登入 / 註冊」提示
- **已登入狀態**：顯示使用者資訊，點擊進入個人資料頁面

### 3. 新增頁面

| 頁面 | 路由 | 功能 |
|------|------|------|
| 登入頁面 | `/login` | 使用者名稱/Email + 密碼登入 |
| 註冊頁面 | `/register` | 建立新帳號 |
| 個人資料頁面 | `/profile` | 查看和管理個人資料 |

## 🏗️ 技術架構

### 資料模型
- **User Model** (`lib/models/user.dart`)
  - 使用者 ID、Email、使用者名稱
  - 顯示名稱、頭像 URL
  - 註冊日期、最後登入時間
  - JSON 序列化/反序列化

### 服務層
- **AuthService** (`lib/services/auth_service.dart`)
  - 單例模式設計
  - 使用 `ChangeNotifier` 實現狀態管理
  - 本地資料儲存（SharedPreferences）
  - 密碼雜湊（簡易版，建議生產環境使用更安全的方法）

### 資料儲存
- 使用 `shared_preferences` 套件
- 儲存結構：
  - `users`: 所有使用者資料（JSON 格式）
  - `current_user`: 當前登入使用者（JSON 格式）

### 狀態管理
- 使用 `ListenableBuilder` 監聽 `AuthService` 變化
- 自動更新 UI 以反映登入狀態

## 📝 使用範例

### 檢查登入狀態
```dart
import 'package:music_practice_app/services/auth_service.dart';

final user = AuthService().currentUser;
if (AuthService().isAuthenticated) {
  print('已登入: ${user?.username}');
} else {
  print('未登入');
}
```

### 監聽狀態變化
```dart
ListenableBuilder(
  listenable: AuthService(),
  builder: (context, _) {
    final isLoggedIn = AuthService().isAuthenticated;
    return Text(isLoggedIn ? '已登入' : '未登入');
  },
)
```

### 執行登入
```dart
try {
  await AuthService().login(
    usernameOrEmail: 'username',
    password: 'password',
  );
  // 登入成功
} catch (e) {
  // 處理錯誤
}
```

## 🧪 測試

新增完整的單元測試：`test/services/auth_service_test.dart`

測試涵蓋：
- ✅ 初始化狀態
- ✅ 使用者註冊
- ✅ 重複註冊防止
- ✅ 登入功能（使用者名稱和 Email）
- ✅ 密碼驗證
- ✅ 個人資料更新
- ✅ 密碼變更
- ✅ 帳號刪除
- ✅ 登出功能

執行測試：
```bash
flutter test test/services/auth_service_test.dart
```

## 📚 相關文件

- [使用者帳號使用指南](docs/USER_ACCOUNT_GUIDE.md) - 完整使用說明

## ⚠️ 注意事項

### 安全性
目前的實作適用於**開發和測試環境**，生產環境建議：

1. **後端整合**
   - 使用 Firebase Authentication 或自建後端 API
   - Token-based 認證（JWT）
   - HTTPS 加密通訊

2. **密碼安全**
   - 使用 `crypto` 套件或 bcrypt
   - 加鹽雜湊（Salted Hash）
   - 防止暴力破解（Rate Limiting）

3. **資料保護**
   - 敏感資料加密儲存
   - 定期更新安全性套件
   - 實作 Email 驗證

4. **額外功能**
   - 忘記密碼/重置密碼
   - 雙因素認證（2FA）
   - 第三方登入（Google、Apple、Facebook）

## 🚀 未來規劃

- [ ] 整合 Firebase Authentication
- [ ] 雲端資料同步
- [ ] 練習記錄與帳號綁定
- [ ] 成就系統與排行榜
- [ ] 社交功能（好友、分享）
- [ ] Email 驗證
- [ ] 密碼重置功能
- [ ] 第三方登入整合

## 📦 新增檔案清單

### 核心功能
- `lib/models/user.dart` - 使用者資料模型
- `lib/services/auth_service.dart` - 認證服務

### UI 頁面
- `lib/pages/login_page.dart` - 登入頁面
- `lib/pages/register_page.dart` - 註冊頁面
- `lib/pages/profile_page.dart` - 個人資料頁面

### 測試
- `test/services/auth_service_test.dart` - 認證服務單元測試

### 文件
- `docs/USER_ACCOUNT_GUIDE.md` - 使用者帳號使用指南
- `docs/ACCOUNT_FEATURE_UPDATE.md` - 本文件

### 更新檔案
- `lib/main.dart` - 新增 AuthService 初始化
- `lib/router/app_router.dart` - 新增登入/註冊/個人資料路由
- `lib/pages/home_page.dart` - 整合使用者頭像/登入按鈕
- `lib/pages/settings_page.dart` - 新增帳號設定區塊
- `README.md` - 更新專案說明

---

**開發日期**: 2025年11月11日  
**版本**: 1.0.0

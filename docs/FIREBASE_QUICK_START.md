# Firebase Authentication 快速開始

## 🚀 兩種認證方式

本應用程式支援兩種認證服務：

### 1️⃣ 本地認證（預設）
- ✅ 無需額外設定，開箱即用
- ✅ 適合開發測試
- ⚠️ 資料僅存本地，無法跨裝置同步

### 2️⃣ Firebase 認證
- ✅ 雲端同步，跨裝置登入
- ✅ 支援 Google 登入
- ✅ 企業級安全性
- ⚠️ 需要 Firebase 專案設定

## 📌 快速切換

### 方法一：修改配置檔（推薦）

編輯 `lib/services/auth_service_config.dart`：

```dart
// 改為 true 啟用 Firebase
const bool USE_FIREBASE_AUTH = true;
```

### 方法二：環境變數（進階）

可以根據不同環境自動切換：

```dart
const bool USE_FIREBASE_AUTH = bool.fromEnvironment(
  'USE_FIREBASE',
  defaultValue: false,
);
```

然後使用：
```bash
# 使用本地認證
flutter run

# 使用 Firebase
flutter run --dart-define=USE_FIREBASE=true
```

## 🔥 Firebase 設定步驟

### 第一步：安裝 FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 第二步：配置 Firebase

```bash
# 登入 Firebase
firebase login

# 配置專案（自動產生配置檔）
flutterfire configure
```

這會自動：
- 建立/選擇 Firebase 專案
- 產生 Android/iOS/Web 配置檔
- 建立 `lib/firebase_options.dart`

### 第三步：啟用 Authentication

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 選擇你的專案
3. 進入「Authentication」→「Sign-in method」
4. 啟用：
   - ✅ Email/密碼
   - ✅ Google

### 第四步：建立 Firestore 資料庫

1. 進入「Firestore Database」
2. 點擊「建立資料庫」
3. 選擇「測試模式」開始（之後可更改規則）
4. 選擇資料庫位置（建議：asia-east1）

### 第五步：更新應用程式

編輯 `lib/main.dart`，取消註解 Firebase 初始化：

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Firebase
  if (USE_FIREBASE_AUTH) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  // ... 其他初始化
}
```

### 第六步：執行應用程式

```bash
flutter pub get
flutter run
```

## ✅ 驗證設定

### 測試本地認證

1. 保持 `USE_FIREBASE_AUTH = false`
2. 執行應用程式
3. 註冊新帳號
4. 確認可以登入/登出

### 測試 Firebase 認證

1. 設定 `USE_FIREBASE_AUTH = true`
2. 確保已完成 Firebase 設定
3. 執行應用程式
4. 註冊新帳號
5. 檢查 Firebase Console 是否有新使用者

## 🎯 功能比較

| 功能 | 本地認證 | Firebase 認證 |
|------|----------|---------------|
| Email/密碼登入 | ✅ | ✅ |
| Google 登入 | ❌ | ✅ |
| 密碼重置 | ❌ | ✅ |
| Email 驗證 | ❌ | ✅ |
| 跨裝置同步 | ❌ | ✅ |
| 離線使用 | ✅ | 部分 |
| 設定時間 | 0 分鐘 | ~15 分鐘 |

## 📖 詳細文件

- 🔥 [Firebase 完整設定指南](FIREBASE_SETUP_GUIDE.md)
- 👤 [使用者帳號使用說明](USER_ACCOUNT_GUIDE.md)
- 📋 [功能更新說明](ACCOUNT_FEATURE_UPDATE.md)

## 💡 建議

### 開發階段
使用**本地認證**，快速開發原型：
```dart
const bool USE_FIREBASE_AUTH = false;
```

### 測試階段
切換到 **Firebase 認證**，測試雲端功能：
```dart
const bool USE_FIREBASE_AUTH = true;
```

### 生產環境
使用 **Firebase 認證**並設定適當的安全規則。

## 🆘 常見問題

**Q: 切換認證方式後，原有帳號會消失嗎？**
A: 會的。本地認證和 Firebase 認證使用不同的儲存方式，資料不互通。

**Q: 可以將本地帳號遷移到 Firebase 嗎？**
A: 目前不支援自動遷移，但可以手動重新註冊。

**Q: Firebase 免費方案夠用嗎？**
A: 對於中小型應用完全夠用。免費方案包含：
- 10,000 次電話號碼驗證/月
- 無限制 Email/密碼認證
- 無限制第三方登入

**Q: 需要信用卡嗎？**
A: Firebase 免費方案不需要信用卡。

## 🎓 下一步

1. ✅ 選擇認證方式
2. ✅ 完成相應設定
3. ✅ 測試功能
4. 🚀 開始開發你的音樂練習 App！

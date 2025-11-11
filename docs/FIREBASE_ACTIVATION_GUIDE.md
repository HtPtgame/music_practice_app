# 🔥 Firebase 已全面啟用！

## ✅ 已完成的設定

1. ✅ Firebase 認證已設為啟用 (`USE_FIREBASE_AUTH = true`)
2. ✅ main.dart 已更新，包含 Firebase 初始化
3. ✅ 所有認證頁面已切換至使用 Firebase 服務
4. ✅ Firebase 套件已安裝

## 🚀 快速開始（3 步驟）

### 步驟 1:安裝必要工具

#### 1.1 安裝 Node.js (如果尚未安裝)

前往 https://nodejs.org/ 下載並安裝 Node.js LTS 版本

#### 1.2 安裝 Firebase CLI

```powershell
npm install -g firebase-tools
```

安裝完成後,登入 Firebase:

```powershell
firebase login
```

這會開啟瀏覽器,請使用您的 Google 帳號登入。

#### 1.3 安裝 FlutterFire CLI

```powershell
dart pub global activate flutterfire_cli
```

#### 1.4 執行 Firebase 配置

```powershell
# 使用完整路徑執行 (避免 PATH 問題)
C:\Users\1206207\AppData\Local\Pub\Cache\bin\flutterfire.bat configure

# 或者,如果已將 Pub\Cache\bin 加入 PATH:
flutterfire configure
```

配置過程中:
1. 選擇或建立 Firebase 專案
2. 選擇要支援的平台 (Android, iOS, Web)
3. 等待自動生成配置檔

這會自動:
- 生成 `lib/firebase_options.dart` 配置檔
- 產生 Android `google-services.json`
- 產生 iOS `GoogleService-Info.plist`
- 更新 Web 配置

### 步驟 2：在 Firebase Console 啟用服務

前往 https://console.firebase.google.com/

#### 2.1 啟用 Authentication

1. 左側選單 → **Authentication**
2. 點擊「**開始使用**」
3. 在「**Sign-in method**」標籤：
   - ✅ 啟用「**電子郵件/密碼**」
   - ✅ 啟用「**Google**」

#### 2.2 建立 Firestore Database

1. 左側選單 → **Firestore Database**
2. 點擊「**建立資料庫**」
3. 選擇「**以測試模式啟動**」
4. 選擇位置：**asia-east1 (台灣)**
5. 點擊「**啟用**」

#### 2.3 設定 Firestore 安全規則（重要）

在 Firestore → **規則** 標籤，貼上以下規則：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 使用者資料
    match /users/{userId} {
      // 只允許使用者讀寫自己的資料
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // 允許已認證使用者讀取其他使用者的公開資料
      allow read: if request.auth != null;
    }
    
    // 練習記錄（未來擴充）
    match /practice_records/{recordId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == resource.data.userId;
    }
  }
}
```

點擊「**發布**」

### 步驟 3：執行應用程式

```bash
flutter pub get
flutter run
```

## 🎯 測試 Firebase 功能

### 測試註冊功能

1. 開啟應用程式
2. 點擊「註冊」
3. 輸入 Email、使用者名稱、密碼
4. 點擊註冊
5. 前往 Firebase Console → Authentication，應該會看到新使用者

### 測試登入功能

1. 登出（如果已登入）
2. 使用剛才註冊的帳號登入
3. 確認可以成功登入

### 測試 Google 登入

1. 點擊「使用 Google 登入」按鈕（需要在 UI 中新增）
2. 選擇 Google 帳號
3. 確認登入成功

### 驗證 Firestore 資料

1. 前往 Firebase Console → Firestore Database
2. 應該會看到 `users` 集合
3. 展開查看使用者資料

## 📱 各平台額外設定

### Android

已透過 `flutterfire configure` 自動完成：
- ✅ `android/app/google-services.json`
- ✅ `android/build.gradle.kts`
- ✅ `android/app/build.gradle.kts`

如需 Google 登入，需取得 SHA-1：

```bash
cd android
.\gradlew signingReport
```

將 SHA-1 加入 Firebase Console → 專案設定 → 您的應用程式

### iOS

已透過 `flutterfire configure` 自動完成：
- ✅ `ios/Runner/GoogleService-Info.plist`

### Web

已透過 `flutterfire configure` 自動完成。

## 🔍 驗證檢查清單

- [ ] Firebase 專案已建立
- [ ] FlutterFire CLI 已安裝
- [ ] `flutterfire configure` 已執行
- [ ] `lib/firebase_options.dart` 已生成
- [ ] Authentication 已啟用（Email/密碼、Google）
- [ ] Firestore Database 已建立
- [ ] Firestore 安全規則已設定
- [ ] `flutter pub get` 已執行
- [ ] 應用程式可以啟動
- [ ] 可以註冊新使用者
- [ ] 可以登入/登出
- [ ] Firebase Console 顯示新使用者
- [ ] Firestore 顯示使用者資料

## ⚠️ 常見問題

### 錯誤：`DefaultFirebaseOptions` 未定義

**原因**：尚未執行 `flutterfire configure`

**解決方案**：
```bash
flutterfire configure
```

### 錯誤：`[core/no-app]` No Firebase App

**原因**：Firebase 初始化失敗

**解決方案**：
1. 確認 `firebase_options.dart` 存在
2. 確認 `USE_FIREBASE_AUTH = true`
3. 重新啟動應用程式

### Google 登入無法使用

**Android 解決方案**：
1. 取得 SHA-1 憑證
2. 在 Firebase Console 加入 SHA-1
3. 重新下載 `google-services.json`
4. 重新建置應用程式

**iOS 解決方案**：
1. 確認 `GoogleService-Info.plist` 在專案中
2. 確認 Bundle ID 正確

## 🎉 完成！

你現在擁有：
- ✅ Firebase Authentication（Email/密碼、Google 登入）
- ✅ Firestore 資料庫（使用者資料雲端儲存）
- ✅ 跨裝置同步
- ✅ 企業級安全性

## 📚 相關文件

- [Firebase 完整設定指南](FIREBASE_SETUP_GUIDE.md)
- [使用者帳號使用說明](USER_ACCOUNT_GUIDE.md)
- [Firebase 快速開始](FIREBASE_QUICK_START.md)

## 🔄 如何切換回本地認證

如果需要暫時切換回本地認證：

1. 編輯 `lib/services/auth_service_config.dart`
2. 將 `USE_FIREBASE_AUTH` 改為 `false`
3. 重新啟動應用程式

---

**開始享受雲端同步的音樂練習體驗吧！** 🎵

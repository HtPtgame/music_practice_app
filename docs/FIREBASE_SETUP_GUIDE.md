# Firebase 整合設定指南

## 📋 前置準備

### 1. 建立 Firebase 專案

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 點擊「新增專案」
3. 輸入專案名稱（例如：music-practice-app）
4. 選擇是否啟用 Google Analytics（建議啟用）
5. 點擊「建立專案」

### 2. 啟用 Firebase Authentication

1. 在 Firebase Console 左側選單選擇「Authentication」
2. 點擊「開始使用」
3. 在「Sign-in method」標籤頁啟用以下登入方式：
   - ✅ Email/密碼
   - ✅ Google
   
### 3. 建立 Firestore 資料庫

1. 在 Firebase Console 左側選單選擇「Firestore Database」
2. 點擊「建立資料庫」
3. 選擇「以測試模式啟動」（或自訂安全規則）
4. 選擇資料庫位置（建議：asia-east1 台灣）

## 🔧 Android 設定

### 1. 下載 google-services.json

1. 在 Firebase Console 選擇專案
2. 點擊 Android 圖示新增 Android 應用程式
3. 輸入 Android 套件名稱：`com.example.music_practice_app`
4. 下載 `google-services.json`
5. 將檔案放到：`android/app/google-services.json`

### 2. 修改 android/build.gradle.kts

在檔案開頭加入：

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

### 3. 修改 android/app/build.gradle.kts

在檔案底部加入：

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // 加入這一行
}
```

並在 `android` 區塊中設定 minSdkVersion：

```kotlin
android {
    defaultConfig {
        minSdk = 21  // Firebase 需要至少 API 21
    }
}
```

## 🍎 iOS 設定

### 1. 下載 GoogleService-Info.plist

1. 在 Firebase Console 點擊 iOS 圖示新增 iOS 應用程式
2. 輸入 iOS Bundle ID：`com.example.musicPracticeApp`
3. 下載 `GoogleService-Info.plist`
4. 使用 Xcode 打開 `ios/Runner.xcworkspace`
5. 將 `GoogleService-Info.plist` 拖曳到 Runner 資料夾中

### 2. 修改 ios/Podfile

確保最低版本為 iOS 13：

```ruby
platform :ios, '13.0'
```

## 🌐 Web 設定

### 1. 註冊 Web 應用程式

1. 在 Firebase Console 點擊 Web 圖示
2. 註冊應用程式
3. 複製 Firebase 配置

### 2. 修改 web/index.html

在 `<body>` 標籤前加入：

```html
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-auth-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-firestore-compat.js"></script>

<script>
  const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT_ID.appspot.com",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID"
  };
  firebase.initializeApp(firebaseConfig);
</script>
```

## 📱 初始化 Firebase

### 修改 lib/main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:music_practice_app/services/firebase_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Firebase
  await Firebase.initializeApp();
  
  // 初始化設定服務
  await SettingsService().initialize();
  
  // 初始化 Firebase 認證服務
  await FirebaseAuthService().initialize();
  
  // 鎖定螢幕方向為直立模式，防止旋轉破圖
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}
```

## 🔒 Firestore 安全規則

在 Firebase Console 的 Firestore → 規則中設定：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 使用者資料規則
    match /users/{userId} {
      // 只允許使用者讀取和更新自己的資料
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // 允許已認證使用者讀取其他使用者的公開資料
      allow read: if request.auth != null;
    }
    
    // 練習記錄規則（未來擴充）
    match /practice_records/{recordId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == resource.data.userId;
    }
  }
}
```

## 🧪 測試 Firebase 連線

### 1. 安裝套件

```bash
flutter pub get
```

### 2. 執行應用程式

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

### 3. 測試功能

1. ✅ 註冊新帳號
2. ✅ 登入/登出
3. ✅ Google 登入
4. ✅ 更新個人資料
5. ✅ 變更密碼
6. ✅ 發送密碼重置郵件

## 📊 Firebase Console 監控

可以在 Firebase Console 中查看：

1. **Authentication** → 查看已註冊使用者
2. **Firestore Database** → 查看使用者資料
3. **Usage** → 查看使用量統計

## 🔐 Google 登入額外設定

### Android

1. 取得 SHA-1 憑證指紋：

```bash
cd android
./gradlew signingReport
```

2. 將 SHA-1 加入 Firebase Console：
   - 專案設定 → 您的應用程式 → SHA 憑證指紋

### iOS

在 Firebase Console 的 iOS 設定中：
- 確保已正確設定 URL Schemes
- 在 `Info.plist` 中加入必要的設定

## ⚠️ 常見問題

### 問題 1：找不到 google-services.json

**解決方案**：確保檔案放在正確位置 `android/app/google-services.json`

### 問題 2：Firebase 初始化失敗

**解決方案**：
1. 檢查網路連線
2. 確認已正確設定所有配置檔案
3. 執行 `flutter clean` 後重新建置

### 問題 3：Google 登入失敗

**解決方案**：
1. 確認已在 Firebase Console 啟用 Google 登入
2. 檢查 SHA-1 憑證是否正確
3. 確認 `google-services.json` 是最新版本

## 📝 下一步

設定完成後，你可以：

1. 使用 `FirebaseAuthService` 取代 `AuthService`
2. 所有使用者資料自動同步到 Firebase
3. 支援跨裝置登入
4. 享受 Firebase 的安全性和可靠性

## 🔗 相關資源

- [Firebase 官方文件](https://firebase.google.com/docs)
- [FlutterFire 文件](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)

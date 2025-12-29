# Google Sign-In 設定指南

## 問題說明
如果您在使用 Google 登入時看到以下錯誤：
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.Api10: , null, null)
```

這通常是因為 **SHA-1 fingerprint** 未在 Firebase Console 中正確配置。

## 解決步驟

### 步驟 1: 獲取 SHA-1 Fingerprint

#### 方法 A: 使用 PowerShell 腳本（推薦）

在專案根目錄執行：
```powershell
# Debug SHA-1
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# 如果需要 Release SHA-1（發布版本）
keytool -list -v -keystore "你的keystore路徑" -alias "你的別名"
```

#### 方法 B: 使用 Gradle（如果 Java 已安裝）

```bash
cd android
./gradlew signingReport
```

#### 方法 C: 透過 Android Studio

1. 打開 Android Studio
2. 打開 **Terminal** 視窗
3. 執行：
   ```bash
   cd android
   ./gradlew signingReport
   ```
4. 在輸出中找到：
   ```
   SHA1: 6F:0E:81:1F:29:44:63:49:59:33:37:02:7C:71:38:B7:F8:FA:8A:CB
   ```

### 步驟 2: 添加 SHA-1 到 Firebase

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 選擇你的專案：**sound-spirit-detective**
3. 點擊左側的 ⚙️ **Project Settings**（專案設定）
4. 向下滾動到 **Your apps**（你的應用程式）區域
5. 找到你的 Android 應用程式
6. 點擊 **Add fingerprint**（添加指紋）
7. 貼上你的 SHA-1 fingerprint
8. 點擊 **Save**（儲存）

### 步驟 3: 確認 Google Sign-In 已啟用

1. 在 Firebase Console 中，點擊左側的 **Authentication**
2. 點擊 **Sign-in method**（登入方法）標籤
3. 確認 **Google** 登入方式的狀態為 **Enabled**（已啟用）
4. 如果未啟用，點擊編輯並啟用它

### 步驟 4: 下載最新的 google-services.json

1. 在 Firebase Console 的 **Project Settings** 頁面
2. 向下滾動到 **Your apps** 區域
3. 點擊 Android 應用程式旁的 **google-services.json** 下載按鈕
4. 將下載的檔案替換到：
   ```
   android/app/google-services.json
   ```

### 步驟 5: 清理並重新構建

在專案根目錄執行：

```bash
# 清理構建快取
flutter clean

# 重新獲取依賴
flutter pub get

# 重新構建應用程式
flutter run
```

## 檢查清單

- [ ] 已獲取 Debug SHA-1 fingerprint
- [ ] 已將 SHA-1 添加到 Firebase Console
- [ ] Google 登入已在 Firebase Authentication 中啟用
- [ ] 已下載並替換最新的 google-services.json
- [ ] 已執行 `flutter clean` 和 `flutter pub get`
- [ ] 已重新構建並測試應用程式

## 常見問題

### Q1: 找不到 debug.keystore 檔案
**A:** Debug keystore 通常位於：
- Windows: `C:\Users\你的用戶名\.android\debug.keystore`
- macOS/Linux: `~/.android/debug.keystore`

如果不存在，運行一次 `flutter run` 會自動生成。

### Q2: 我需要添加 Release SHA-1 嗎？
**A:** 
- **開發/測試階段**：只需要 Debug SHA-1
- **正式發布到 Play Store**：需要 Release SHA-1（使用你的發布 keystore）
- **使用 Play App Signing**：需要添加 Play Console 提供的 SHA-1

### Q3: 我添加了 SHA-1 但還是出錯
**A:** 
1. 確保下載了最新的 `google-services.json`
2. 執行 `flutter clean`
3. 完全卸載應用程式，然後重新安裝
4. 檢查 Firebase Console 中的包名是否與 `build.gradle.kts` 中的 `applicationId` 一致

### Q4: 如何驗證 google-services.json 是否正確？
**A:** 打開 `android/app/google-services.json`，檢查：
```json
{
  "client": [
    {
      "client_info": {
        "android_client_info": {
          "package_name": "com.example.music_practice_app"  // 應該與你的 applicationId 一致
        }
      },
      "oauth_client": [
        {
          "client_id": "...",
          "client_type": 1,
          "android_info": {
            "package_name": "com.example.music_practice_app",
            "certificate_hash": "你的SHA1"  // 應該包含你添加的 SHA-1
          }
        }
      ]
    }
  ]
}
```

## 技術細節

### 為什麼需要 SHA-1？
Google Sign-In 使用 SHA-1 fingerprint 來驗證應用程式的真實性。這是一種安全機制，確保只有你的應用程式才能使用你的 OAuth 2.0 客戶端 ID。

### 更新內容（2025-12-29）
- ✅ 更新 Google Services 插件版本從 4.3.15 到 4.4.2
- ✅ 改進錯誤處理，提供更詳細的錯誤訊息
- ✅ 添加詳細的設定指南

## 相關連結

- [Firebase Console](https://console.firebase.google.com/)
- [Google Sign-In for Android 官方文件](https://developers.google.com/identity/sign-in/android/start)
- [Flutter Firebase Auth 文件](https://firebase.flutter.dev/docs/auth/usage)

## 需要協助？

如果按照以上步驟仍然無法解決問題，請檢查：
1. Firebase 專案設定是否正確
2. 網路連線是否正常
3. Google Play Services 是否已安裝並更新
4. 裝置時間是否正確（OAuth 需要準確的時間）

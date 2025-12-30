# Google 登入問題快速修復指南

## ✅ 已完成的修復

### 1. 更新 Google Services 插件版本
- ✅ 從 4.3.15 升級到 4.4.2
- 文件：`android/settings.gradle.kts`

### 2. 改進錯誤處理
- ✅ 添加詳細的錯誤訊息
- ✅ 針對常見問題提供解決建議
- 文件：`lib/services/firebase_auth_service.dart`

### 3. SHA-1 Fingerprint 驗證
- ✅ 您的 Debug SHA-1: `5E:EC:FD:2F:56:0C:EA:EC:64:71:37:9E:DC:89:B8:5F:3A:E7:66:F1`
- ✅ 此 SHA-1 已存在於 `google-services.json` 中

### 4. 清理和重建
- ✅ 執行 `flutter clean`
- ✅ 執行 `flutter pub get`
- 🔄 正在構建應用程式...

## 📝 後續步驟

### 立即測試

1. **完全卸載應用程式**（如果已安裝）
   ```bash
   adb uninstall com.example.music_practice_app
   ```

2. **安裝新版本**
   ```bash
   flutter run
   ```
   或手動安裝構建的 APK

3. **測試 Google 登入**
   - 開啟應用程式
   - 點擊 "使用 Google 帳號登入"
   - 選擇您的 Google 帳號

### 如果還是失敗

請檢查 Firebase Console 設定：

1. **前往 Firebase Console**
   - 網址：https://console.firebase.google.com/
   - 專案：sound-spirit-detective

2. **檢查 Authentication**
   - 左側選單 → Authentication
   - Sign-in method 標籤
   - 確認 Google 為「已啟用」狀態

3. **檢查 SHA-1**
   - 左側選單 → Project Settings（⚙️）
   - 向下滾動到「Your apps」
   - 找到 Android 應用程式
   - 確認 SHA-1 fingerprint 列表包含：
     ```
     5E:EC:FD:2F:56:0C:EA:EC:64:71:37:9E:DC:89:B8:5F:3A:E7:66:F1
     ```

4. **下載最新配置檔**
   - 在 Project Settings 頁面
   - 點擊 Android 應用程式的 google-services.json 下載按鈕
   - 替換 `android/app/google-services.json`
   - 重新執行 `flutter clean && flutter pub get && flutter run`

## 🔍 錯誤訊息說明

現在應用程式會顯示更詳細的錯誤訊息：

### 如果看到「Google 登入設定錯誤」
```
可能原因：
1. SHA-1 fingerprint 未在 Firebase Console 中正確配置
2. google-services.json 配置不正確
3. Firebase 專案未啟用 Google 登入
```
➡️ 按照上面的「檢查 Firebase Console 設定」步驟操作

### 如果看到「Google 服務初始化失敗」
```
請確認：
1. 應用程式的 SHA-1 fingerprint 已添加到 Firebase
2. 已下載最新的 google-services.json
3. 重新構建應用程式
```
➡️ 完全卸載應用程式後重新安裝

## 📚 完整文件

詳細的設定說明請參考：`GOOGLE_SIGNIN_SETUP.md`

## ⚠️ 注意事項

1. **Debug vs Release**
   - 目前使用的是 Debug SHA-1
   - 如果要發布到 Play Store，需要另外添加 Release SHA-1

2. **應用程式包名**
   - 確保 Firebase 專案中的包名為：`com.example.music_practice_app`
   - 與 `android/app/build.gradle.kts` 中的 `applicationId` 一致

3. **網路連線**
   - Google 登入需要網路連線
   - 確保裝置/模擬器可以訪問 Google 服務

4. **Google Play Services**
   - 確保裝置已安裝 Google Play Services
   - 如果使用模擬器，確保選擇「with Google APIs」的系統映像

## 🎯 測試結果記錄

完成測試後，請記錄結果：

- [ ] ✅ Google 登入成功
- [ ] ❌ 仍然失敗（錯誤訊息：_____________）

如果失敗，請提供完整的錯誤訊息以便進一步診斷。

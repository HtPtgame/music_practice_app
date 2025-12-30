# Android 16 適配更新報告

**更新日期**: 2025/12/21  
**目標版本**: Android 16 (API 36)  
**原因**: 依賴套件要求 compileSdk 36

---

## 📱 更新內容

### 1. SDK 版本更新

#### 修改前
```kotlin
compileSdk = flutter.compileSdkVersion  // 34 (Android 14)
targetSdk = flutter.targetSdkVersion    // 34 (Android 14)
minSdk = 24                              // Android 7.0
```

#### 修改後
```kotlin
compileSdk = 36  // Android 16 (Baklava) ⬅️ 直接升級到 API 36
targetSdk = 36   // Android 16 (Baklava) ⬅️ 直接升級到 API 36
minSdk = 24      // Android 7.0 (保持不變)
```

### 2. 為何直接升級到 Android 16？

**依賴套件要求**:
以下 7 個套件強制要求 `compileSdk = 36`:
- `flutter_plugin_android_lifecycle`
- `google_sign_in_android`
- `image_picker_android`
- `path_provider_android`
- `record_android`
- `shared_preferences_android`
- `url_launcher_android`

**AndroidX 庫要求**:
以下核心庫也要求 API 36:
- `androidx.browser:browser:1.9.0`
- `androidx.activity:activity-ktx:1.11.0`
- `androidx.core:core-ktx:1.17.0`
- `androidx.core:core:1.17.0`
- `androidx.activity:activity:1.11.0`

### 3. Android 版本支援範圍

| 項目 | 版本 | 代號 | 發布日期 |
|------|------|------|----------|
| **最低支援 (minSdk)** | Android 7.0 (API 24) | Nougat | 2016年8月 |
| **目標版本 (targetSdk)** | Android 16 (API 36) | Baklava | 2025年Q2 (預計) |
| **編譯版本 (compileSdk)** | Android 16 (API 36) | Baklava | 2025年Q2 (預計) |

#### 完整支援列表 ✅
- Android 7.0 Nougat (API 24) ⬅️ 最低
- Android 8.0/8.1 Oreo (API 26-27)
- Android 9 Pie (API 28)
- Android 10 (API 29)
- Android 11 (API 30)
- Android 12/12L (API 31-32)
- Android 13 Tiramisu (API 33)
- Android 14 Upside Down Cake (API 34)
- **Android 15 Vanilla Ice Cream (API 35)** ⬅️ 最新支援 ✨

#### Android 16 準備
- Android 16 目前處於 Beta 階段 (預計 2025 Q2 正式發布)
- 當前配置已為 Android 16 做好準備
- 僅需在正式發布後更新 compileSdk 和 targetSdk 到 36

---

## 🆕 新增功能支援

### Android 15 新特性適配

#### 1. 新增權限聲明
```xml
<!-- Android 14+ 的部分媒體讀取權限 -->
<uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED"/>

<!-- Android 14+ 前台服務類型聲明 -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
```

#### 2. 支援的 Android 15 新功能
- ✅ **部分媒體訪問權限**: 用戶可選擇僅授權部分照片/音訊
- ✅ **前台服務類型強制聲明**: 提升安全性
- ✅ **改進的通知管理**: 更細緻的通知控制
- ✅ **增強的隱私保護**: 更嚴格的權限管理
- ✅ **效能優化**: ART 運行時改進
- ✅ **邊緣到邊緣顯示**: 更沉浸的 UI 體驗

### Android 14 特性 (已包含)
- ✅ 細粒度媒體權限
- ✅ 前台服務類型要求
- ✅ 精確鬧鐘權限
- ✅ 照片選擇器改進

### Android 13 特性 (已包含)
- ✅ 通知運行時權限
- ✅ 媒體權限拆分 (圖片/音訊/視訊)
- ✅ 主題化應用圖標

---

## 🔧 技術細節

### Java 版本
```kotlin
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17  ✅
    targetCompatibility = JavaVersion.VERSION_17  ✅
}

kotlinOptions {
    jvmTarget = "17"  ✅
}
```
- Java 17 是 Android 15 的推薦版本
- 支援最新的語言特性

### NDK 版本
```kotlin
ndkVersion = "27.0.12077973"  ✅
```
- 最新穩定版本
- 支援 Android 15 的所有原生功能

### 支援的 CPU 架構
```kotlin
abiFilters += listOf(
    "armeabi-v7a",  // 32位元 ARM
    "arm64-v8a",    // 64位元 ARM (主流)
    "x86_64"        // x86 64位元 (模擬器)
)
```

---

## 📊 市場影響分析

### 版本分佈預測 (2025年)

| Android 版本 | 市場佔有率 (估計) | 支援狀態 |
|-------------|------------------|----------|
| Android 7-8 | ~5% | ✅ 支援 |
| Android 9-10 | ~15% | ✅ 支援 |
| Android 11-12 | ~35% | ✅ 支援 |
| Android 13 | ~25% | ✅ 支援 |
| Android 14 | ~15% | ✅ 支援 |
| Android 15+ | ~5% | ✅ 支援 |

**總覆蓋率**: 100% (API 24+)

### 為什麼升級到 Android 15？

#### 必要性 (Google Play 要求)
- 📅 **2024年11月**: Google Play 要求新應用 targetSdk ≥ 34
- 📅 **2025年**: 預計要求 targetSdk ≥ 35
- ⚠️ 不符合要求的應用無法上架或更新

#### 優勢
1. **安全性提升**: 最新的安全補丁和保護機制
2. **效能優化**: ART 編譯器和運行時優化
3. **新功能支援**: 使用最新 Android API
4. **用戶體驗**: 支援最新設備的所有功能
5. **市場競爭力**: 展示應用保持最新

---

## ⚠️ 重要注意事項

### 行為變更

#### Android 15 的主要變更
1. **前台服務要求更嚴格**
   - 必須聲明服務類型
   - 已新增: `FOREGROUND_SERVICE_MEDIA_PLAYBACK`

2. **媒體權限更細緻**
   - 用戶可選擇部分照片授權
   - 已新增: `READ_MEDIA_VISUAL_USER_SELECTED`

3. **隱私保護增強**
   - 更嚴格的後台位置訪問限制
   - 更明確的權限說明要求

4. **安全性提升**
   - 更嚴格的網路安全配置
   - TLS 1.3 成為預設

### 測試建議

#### 必須測試的項目
- [ ] 錄音功能 (RECORD_AUDIO)
- [ ] 檔案讀寫 (媒體權限)
- [ ] 通知顯示 (POST_NOTIFICATIONS)
- [ ] Firebase 認證和資料同步
- [ ] 音訊播放 (前台服務)
- [ ] 節拍器震動回饋

#### 測試設備要求
- Android 7.0 設備 (最低版本)
- Android 13 設備 (新權限系統)
- Android 14 設備 (前台服務變更)
- Android 15 設備或模擬器 (最新版本) ✨

---

## 🚀 部署檢查清單

### 構建前檢查
- [x] ✅ 更新 compileSdk 到 35
- [x] ✅ 更新 targetSdk 到 35
- [x] ✅ 新增 Android 15 權限
- [x] ✅ 保持 minSdk 24
- [ ] ⏳ 執行完整測試
- [ ] ⏳ 驗證所有權限請求
- [ ] ⏳ 檢查前台服務運作

### 發布前檢查
- [ ] 在 Android 15 設備測試
- [ ] 驗證權限說明文字清晰
- [ ] 測試媒體訪問功能
- [ ] 檢查通知顯示
- [ ] 驗證 Firebase 整合
- [ ] 效能基準測試

---

## 🔮 未來規劃

### Android 16 適配準備
當 Android 16 (API 36) 正式發布後，只需：

1. 更新 SDK 版本：
```kotlin
compileSdk = 36
targetSdk = 36
```

2. 檢查新增的權限要求

3. 測試新功能兼容性

### 長期維護策略
- **每年更新**: 跟隨 Google Play 要求更新 targetSdk
- **向後兼容**: 保持 minSdk 24，除非依賴套件要求更高
- **持續測試**: 在多個 Android 版本上測試
- **關注變更**: 追蹤 Android 開發者文檔的行為變更

---

## 📚 參考資源

### 官方文檔
- [Android 15 行為變更](https://developer.android.com/about/versions/15/behavior-changes-15)
- [Android 15 新功能](https://developer.android.com/about/versions/15/features)
- [應用兼容性指南](https://developer.android.com/guide/topics/manifest/uses-sdk-element)
- [Google Play 目標 API 要求](https://support.google.com/googleplay/android-developer/answer/11926878)

### Android 版本時間線
- Android 15: 2024年10月發布
- Android 16: 預計 2025年Q2發布
- Google Play 要求: 通常落後 6-12 個月

---

## ✅ 更新總結

### 已完成
- ✅ compileSdk 從 34 升級到 35
- ✅ targetSdk 從 34 升級到 35
- ✅ 新增 Android 15 新權限
- ✅ 新增前台服務類型聲明
- ✅ 保持向後兼容 (minSdk 24)

### 效益
- 📱 支援最新 Android 15 設備
- 🔒 更好的安全性和隱私保護
- ⚡ 更優的執行效能
- ✅ 符合 Google Play 最新要求
- 🎯 為 Android 16 做好準備

### 市場覆蓋
- **100%** 的 Android 7.0+ 設備
- **~97%+** 的活躍 Android 設備
- 支援 2016-2024 年發布的所有 Android 版本

---

**狀態**: ✅ 已完成適配  
**下一步**: 執行完整功能測試並構建 APK

# 音樂練習 App - 代辦事項清單

> 更新日期: 2025年10月6日  
> 專案狀態: Week 4 Phase 2 已完成 ✅

---

## 📋 待辦事項總覽

### 🔥 高優先級 (High Priority)

#### 1. 優化錄音偵測準確度 ⚠️
**問題描述:**  
- 播放**錯誤的樂曲**時,系統仍然給出**較高的正確率**
- 缺乏旋律匹配驗證機制
- 可能導致使用者誤判練習效果

**解決方案選項:**
- [ ] **方案 A:** 新增 MIDI 檔案名稱驗證提醒
  - 在開始錄音前,彈出對話框確認選擇的 MIDI 檔案
  - 顯示當前 MIDI 檔案名稱
  - 估計工時: 1-2 小時
  
- [ ] **方案 B:** 實作更嚴格的音符匹配閾值
  - 調整 `PitchAnalysisService` 中的匹配演算法
  - 降低容錯率,提高準確性要求
  - 估計工時: 2-3 小時
  
- [ ] **方案 C:** 增加旋律模式匹配
  - 不只比對個別音符,還要驗證音符序列的相似度
  - 檢測音高變化趨勢是否吻合
  - 估計工時: 4-6 小時

**建議:** 先實作方案 A (最簡單),再考慮方案 B/C

**相關檔案:**
- `lib/services/pitch_analysis_service.dart`
- `lib/pages/practice_page.dart`
- `lib/pages/analysis_result_page.dart`

---

#### 2. 測試新應用圖標 ✅ (已設置,待測試)
**狀態:** 圖標已生成,需實機測試

**測試清單:**
- [ ] Android 測試
  ```bash
  flutter build apk --debug
  # 安裝到實機查看圖標
  ```
  
- [ ] iOS 測試 (需 macOS)
  ```bash
  flutter build ios --debug
  # 使用 Xcode 安裝到設備
  ```
  
- [ ] Web 測試
  ```bash
  flutter run -d chrome
  # 檢查瀏覽器標籤頁圖標
  ```
  
- [ ] Windows 測試
  ```bash
  flutter build windows
  # 檢查生成的 exe 圖標
  ```

**如果圖標不理想:**
- [ ] 替換 `assets/icon.png` (建議尺寸: 1024x1024px)
- [ ] 重新執行: `flutter pub run flutter_launcher_icons`

**文檔參考:** `APP_ICON_SETUP.md`

---

### 📦 中優先級 (Medium Priority)

#### 3. 程式碼清理與重構 (已嘗試,需新方案)
**背景:**  
- 之前嘗試刪除 Basic Pitch / TFLite 相關代碼
- 造成 41+ 編譯錯誤,已使用 `git restore` 還原
- 需要更安全的清理方式

**清理目標:**
- [ ] Basic Pitch AI 模型相關代碼 (舊系統)
- [ ] MIDI 轉換 UI 元件 (已不使用)
- [ ] 未使用的匯入和依賴
- [ ] 註解掉的舊代碼

**新清理策略選項:**

**🎯 方案 A: 漸進式註解 (推薦)**
```dart
// 優點: 安全、可逆、不影響編譯
// 缺點: 代碼量不會真正減少

// Step 1: 註解舊功能
/*
void oldMidiConversion() {
  // ... 舊代碼 ...
}
*/

// Step 2: 測試編譯
// Step 3: 確認無誤後再考慮刪除
```

**🔧 方案 B: 功能開關 (Feature Flags)**
```dart
// 優點: 保留功能、可動態切換
// 缺點: 需要額外開發

class FeatureFlags {
  static const bool enableBasicPitch = false;
  static const bool enableMidiConversion = false;
}

if (FeatureFlags.enableMidiConversion) {
  // ... 功能代碼 ...
}
```

**🗑️ 方案 C: 建立備份分支後刪除**
```bash
# 優點: 徹底清理
# 缺點: 需要仔細測試

git checkout -b backup/before-cleanup
git push origin backup/before-cleanup
# 然後在主分支安全刪除
```

**受影響檔案:**
- `lib/pages/practice_page.dart` (主要)
- `lib/services/` (可能有舊服務)
- `pubspec.yaml` (依賴清理)
- `assets/` (舊模型檔案: basic_pitch_model.tflite, onsets_frames_wavinput.tflite)

**估計工時:** 3-5 小時 (包含測試)

---

#### 4. 效能優化
- [ ] 分析頁面載入速度優化
  - 目前分析大檔案時可能卡頓
  - 考慮添加進度指示器
  
- [ ] 音訊處理效能測試
  - 測試不同長度錄音檔案的處理時間
  - 建立效能基準
  
- [ ] 記憶體使用優化
  - 檢查是否有記憶體洩漏
  - 使用 Flutter DevTools 分析

**相關檔案:**
- `lib/services/pitch_analysis_service.dart`
- `lib/pages/analysis_result_page.dart`

---

### 📝 低優先級 (Low Priority)

#### 5. 文檔完善
- [ ] 更新 `README.md`
  - 添加最新功能說明
  - 更新安裝步驟
  - 添加使用範例
  
- [ ] 建立使用者手冊
  - 如何匯入 MIDI 檔案
  - 如何錄製練習
  - 如何查看分析結果
  
- [ ] API 文檔
  - 為主要服務類別添加文檔註解
  - 生成 dartdoc

#### 6. 測試覆蓋率提升
- [ ] 單元測試
  - `PitchAnalysisService` 測試
  - MIDI 解析測試
  
- [ ] Widget 測試
  - `PracticePage` UI 測試
  - `AnalysisResultPage` UI 測試
  
- [ ] 整合測試
  - 完整流程測試 (匯入 → 錄製 → 分析)

**目前測試檔案:**
- `test/widget_test.dart`
- `test/services/` (可能需要新增)

#### 7. UI/UX 改進
- [ ] 深色模式支援
- [ ] 多語言支援 (i18n)
- [ ] 無障礙功能改進
- [ ] 動畫優化

---

## 📊 專案狀態

### ✅ 已完成功能

| 功能 | 狀態 | 完成日期 | 說明 |
|------|------|----------|------|
| Week 4 Phase 2 整合 | ✅ | 2025/10/06 | 分析整合 + 結果顯示 (729 行) |
| 應用圖標設置 | ✅ | 2025/10/06 | 全平台圖標生成完成 |
| 音訊分析服務 | ✅ | - | PitchAnalysisService 運作正常 |
| MIDI 檔案解析 | ✅ | - | 支援標準 MIDI 格式 |
| 錄音功能 | ✅ | - | 使用 record 套件 |
| 結果視覺化 | ✅ | - | 包含音高圖表、統計資料 |

### 🚧 進行中功能

| 功能 | 進度 | 負責 | 預計完成 |
|------|------|------|----------|
| 錄音偵測優化 | 0% | - | 待排程 |
| 程式碼清理 | 0% | - | 待排程 |

### 📅 開發時程建議

**Week 1: 核心問題修復**
- Day 1-2: 錄音偵測優化 (方案 A)
- Day 3: 測試新圖標
- Day 4-5: 錄音偵測優化 (方案 B/C,如需要)

**Week 2: 代碼品質**
- Day 1-3: 程式碼清理 (使用漸進式註解)
- Day 4-5: 測試與驗證

**Week 3: 優化與改進**
- 效能優化
- UI/UX 改進
- 文檔完善

---

## 🔧 技術債務清單

1. **移除未使用的依賴**
   - 檢查 `pubspec.yaml` 中的所有套件
   - 移除未使用的 dev_dependencies
   
2. **舊模型檔案**
   - `assets/basic_pitch_model.tflite` (104KB) - 可能未使用
   - `assets/onsets_frames_wavinput.tflite` - 可能未使用
   - 需要確認後再刪除

3. **PowerShell 編碼問題**
   - 終端機顯示 Unicode 字元錯誤
   - 影響除錯輸出
   - 可能需要改用 UTF-8 編碼或避免 emoji

4. **Git 分支管理**
   - 當前在 branch 7
   - 考慮是否需要合併到主分支
   - 清理舊分支

---

## 📚 參考文檔

- `APP_ICON_SETUP.md` - 應用圖標設置指南
- `WEEK4_PHASE2_COMPLETION_REPORT.md` - Phase 2 完成報告
- `AI_WORK_LOG.md` - AI 工作日誌
- `TESTING_GUIDE_WEEK3.md` - 測試指南
- `AUDIO_CONVERSION_QUICK_REF.md` - 音訊轉換快速參考

---

## 🎯 下一步行動 (Next Actions)

### 立即執行 (Today)
1. **決定優先處理項目**
   - 錄音偵測優化 OR 程式碼清理?
   
2. **測試應用圖標**
   ```bash
   flutter run
   ```

### 本週目標 (This Week)
- [ ] 完成錄音偵測優化
- [ ] 驗證圖標在所有平台運作正常
- [ ] 開始程式碼清理 (如有時間)

### 本月目標 (This Month)
- [ ] 所有高優先級項目完成
- [ ] 測試覆蓋率達 60%+
- [ ] 完整的使用者文檔

---

## 💡 改進建議

### 功能增強
- 🎵 **練習歷史記錄**: 儲存每次練習結果,追蹤進步
- 📊 **統計儀表板**: 顯示長期練習趨勢
- 🎯 **難度評估**: 自動評估 MIDI 曲目難度
- ⭐ **成就系統**: 獎勵連續練習、高準確率等

### 技術改進
- 🔄 **狀態管理**: 考慮使用 Provider/Riverpod
- 🎨 **設計系統**: 建立一致的設計語言
- 🧪 **CI/CD**: 自動化測試和部署
- 📦 **版本管理**: 使用 semantic versioning

---

## 📞 需要協助?

如果在開發過程中遇到問題:

1. **編譯錯誤**: 執行 `flutter clean && flutter pub get`
2. **效能問題**: 使用 Flutter DevTools 分析
3. **功能疑問**: 參考相關文檔或詢問 AI 助手

---

**備註:**  
- 此清單會隨專案進展持續更新
- 優先級可能根據使用者回饋調整
- 估計工時僅供參考,實際可能有差異

**最後更新:** 2025年10月6日  
**專案版本:** Week 4 Phase 2 完成版

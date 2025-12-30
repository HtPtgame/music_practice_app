# Archive 目錄說明

此目錄存放專案開發過程中產生的歷史文檔、測試結果和實驗性腳本。

## 📁 目錄結構

### `/docs` - 技術文檔 (已整合至 AI_WORK_LOG.md)
包含開發過程中的所有技術報告和指南：

**音符檢測系統**:
- `ACCURACY_EVALUATION_REPORT.md` - 音符檢測準確度評估報告 (313 行)
- `IMPROVEMENT_IMPLEMENTATION_REPORT.md` - 音符檢測改進實施報告 (303 行)
- `OPTIMIZATION_IMPLEMENTATION.md` - 音符檢測優化實施報告 (506 行)
- `PITCH_DETECTION_ANALYSIS.md` - 音高偵測方法深度分析 (628 行)
- `DEBOUNCE_FIX_GUIDE.md` - 去抖動與泛音過濾指南 (128 行)

**即時比對系統**:
- `REALTIME_INTEGRATION_COMPLETE.md` - 即時樂譜比對整合完成報告 (513 行)
- `REALTIME_INTEGRATION_PLAN.md` - 即時樂譜比對整合計劃
- `REALTIME_MATCHING_GUIDE.md` - 即時樂譜比對功能使用指南
- `REALTIME_TEST_GUIDE.md` - 即時樂譜比對測試指南
- `REAL_TIME_SCORE_MATCHER_INTEGRATION.md` - 即時樂譜比對整合文檔

**Android 平台**:
- `ANDROID_15_UPGRADE.md` - Android 16 適配更新報告 (278 行)
- `ANDROID_BUILD_FIX.md` - Android 構建錯誤修復報告 (254 行)
- `JAVA_WARNINGS_EXPLANATION.md` - Java 警告說明
- `R8_BUILD_ERROR_FIX.md` - R8 構建錯誤修復

**專案管理**:
- `PROJECT_REVIEW_REPORT.md` - 專案審視與優化報告 (331 行)
- `OPTIMIZATION_REPORT.md` - 優化總結報告 (581 行)
- `OPTIMIZATION_TODO.md` - 優化待辦清單
- `RUN_OPTIMIZATION_TESTS.md` - 優化測試執行指南

**Firebase 整合**:
- `GOOGLE_SIGNIN_FIX_SUMMARY.md` - Google 登入問題快速修復指南
- `GOOGLE_SIGNIN_SETUP.md` - Google 登入設定指南

**機器學習**:
- `ML_DATA_COLLECTION_GUIDE.md` - 機器學習資料收集指南

**總計**: 21 個技術文檔，約 3,635+ 行

---

### `/test_results` - 測試結果檔案
音符檢測系統的測試輸出：

- `accuracy_results.txt` - 原始準確度測試結果 (10.5 KB)
- `accuracy_results_improved.txt` - 改進後準確度測試結果 (9.2 KB)
- `final_results.txt` - 最終測試結果 (15.7 KB)
- `final_test_results.txt` - 最終完整測試結果 (10.9 KB)
- `test_debug.txt` - 偵錯測試日誌 (444.4 KB)
- `test_final.txt` - 最終測試日誌 (24.2 KB)

**用途**: 記錄音符檢測演算法的準確率演進過程

---

### `/test_scripts` - 測試腳本
開發與測試用腳本：

**Dart 測試程式**:
- `test_ml_data_collection.dart` (19.4 KB) - 機器學習資料收集測試
- `test_real_time_matcher.dart` (9.6 KB) - 即時比對器測試

**批次腳本**:
- `run_debug_test.bat` - Windows 偵錯測試執行腳本
- `run_debug_test.ps1` - PowerShell 偵錯測試執行腳本

**用途**: 自動化測試與資料收集

---

### `/ml_experiments` - 機器學習實驗
早期探索的機器學習音符分類實驗（未整合至最終版本）：

**訓練資料與腳本**:
- `ml_training_data.csv` - 機器學習訓練資料集
- `train_classifier.py` - Python 分類器訓練腳本

**視覺化圖表**:
- `confusion_matrix.png` - 混淆矩陣
- `feature_correlation.png` - 特徵相關性分析
- `feature_distribution.png` - 特徵分佈圖

**說明**: 這些檔案記錄了使用 ML 進行音符分類的嘗試。最終採用基於 DSP 的諧波分析方法，因其準確率更高且無需訓練資料。

---

### `/setup_scripts` - 設定腳本
專案初始設定與工具腳本：

- `setup_firebase.ps1` - Firebase 自動設定腳本 (PowerShell)
- `setup_firebase.sh` - Firebase 自動設定腳本 (Bash)
- `get_sha1.bat` - 取得 SHA-1 fingerprint 的批次檔
- `generate_metronome_sounds.dart` - 節拍器音效生成工具 (2.6 KB)

**用途**: 簡化 Firebase 設定流程與開發工具

---

## 📊 統計資訊

| 類別 | 檔案數 | 總大小 | 說明 |
|------|--------|--------|------|
| 技術文檔 | 21 | ~200 KB | 已整合至 AI_WORK_LOG.md |
| 測試結果 | 6 | ~515 KB | 音符檢測測試日誌 |
| 測試腳本 | 4 | ~30 KB | 自動化測試工具 |
| ML 實驗 | 5 | ~500 KB | 機器學習探索 |
| 設定腳本 | 4 | ~15 KB | 環境設定工具 |
| **總計** | **40** | **~1.26 MB** | 專案歷史資料 |

---

## 🗂️ 檔案歸檔日期

- **歸檔日期**: 2025年12月30日
- **歸檔原因**: 專案實體評分完結，整理專案結構
- **主文檔**: 所有技術文檔已整合至根目錄 `AI_WORK_LOG.md`
- **狀態**: 歸檔完成 ✅

---

## 📝 使用說明

### 如何查閱技術文檔
1. **最新完整內容**: 請查看根目錄的 `AI_WORK_LOG.md`
2. **歷史版本**: 本目錄保留原始單獨文檔供參考
3. **特定主題**: 可直接開啟對應的 MD 檔案

### 如何使用測試腳本
```bash
# Windows
cd archive\test_scripts
run_debug_test.bat

# PowerShell
cd archive\test_scripts
.\run_debug_test.ps1
```

### 如何重現 ML 實驗
```bash
# Python 3.x
cd archive\ml_experiments
python train_classifier.py
```

---

## ⚠️ 注意事項

1. **文檔整合**: 所有技術文檔內容已整合至 `AI_WORK_LOG.md`，此目錄僅供歷史參考
2. **測試檔案**: 測試結果為特定版本的輸出，不一定代表最終版本的效能
3. **ML 實驗**: 機器學習方法未採用於最終版本，保留僅供研究參考
4. **腳本相容性**: 設定腳本可能需要根據當前環境調整

---

**維護者**: Music Practice App Team  
**最後更新**: 2025年12月30日  
**狀態**: ✅ 歸檔完成

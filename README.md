# 音靈偵探 Veloria

基於 AI 音訊檢測的智能音樂練習系統

## 🎵 專案簡介

音靈偵探 (Veloria) 是一個 Flutter 開發的音樂練習應用，採用先進的音訊檢測技術，幫助使用者練習樂器演奏。

### 核心功能

- ✅ **即時音訊檢測** - 精準識別演奏音符
- ✅ **動態參數系統** - 根據難度自動調整檢測參數
- ✅ **性能分析** - Precision/Recall 指標評估
- ✅ **MIDI 支援** - 支援多種 MIDI 曲目

### 技術亮點

- **Round 10 動態參數系統**
  - 初學者：energyThreshold 0.39, timingTolerance ±200ms
  - 中等：energyThreshold 0.35, timingTolerance ±150ms
  - 專業：energyThreshold 0.30, timingTolerance ±100ms

- **測試數據**
  - 整體通過率：71.9% (23/32)
  - 正確演奏檢測率：91.7% (11/12)
  - 平均 Recall：87.3%

## 📁 專案結構

```
music_practice_app/
├── lib/                      # 主程式碼
│   ├── main.dart            # 應用入口
│   ├── pages/               # 頁面
│   ├── services/            # 服務層（含音訊分析）
│   ├── utils/               # 工具函數
│   └── widgets/             # UI 元件
├── test/                     # 單元測試
│   ├── integration/         # 整合測試（NEW）
│   │   ├── performance_test.dart  # 主要測試檔案
│   │   └── README.md        # 測試說明
│   └── services/            # 服務測試
├── tools/                    # 開發工具（NEW）
│   ├── convert_to_mono.dart # 音訊格式轉換
│   ├── fix_test_audio.dart  # 音檔修復工具
│   └── README.md            # 工具說明
├── assets/                   # 資源檔案
│   ├── test_voice/          # 測試 MIDI 和音檔
│   └── TimGM6mb.sf2         # SoundFont
├── test_recordings/          # 測試錄音（未納入版控）
└── docs/                     # 文檔（待建立）
    ├── AUDIO_DETECTION_OPTIMIZATION.md  # 優化歷史
    ├── TEST_FILES_CONSOLIDATION_PLAN.md # 測試檔案整合計劃
    └── AI_WORK_LOG.md                   # 開發日誌
```

## 🚀 快速開始

### 環境需求

- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- FFmpeg（音訊處理）

### 安裝步驟

1. **克隆專案**
   ```bash
   git clone <repository-url>
   cd music_practice_app
   ```

2. **安裝依賴**
   ```bash
   flutter pub get
   ```

3. **執行應用**
   ```bash
   flutter run
   ```

### 執行測試

**完整測試（4輪共32個案例）**:
```bash
dart test/integration/performance_test.dart
```

**單一輪次測試**:
```bash
# 第一輪：生日快樂
dart test/integration/performance_test.dart 1

# 第四輪：名偵探柯南
dart test/integration/performance_test.dart 4
```

詳細測試說明請參考：[test/integration/README.md](test/integration/README.md)

## 📊 測試配置

| 輪次 | 曲目 | 音符數 | 時長 | 描述 |
|------|------|--------|------|------|
| Round 1 | 生日快樂 | 25 | 17秒 | 簡單基準 |
| Round 2 | 測試音檔 | 94 | 34秒 | 單音無伴奏 |
| Round 3 | 小星星 | 147 | 27秒 | 有伴奏 |
| Round 4 | 名偵探柯南 | 1431 | 164秒 | 複雜長曲 |

## 🛠️ 開發工具

### 音訊轉換工具

```bash
# 轉換為單聲道
dart tools/convert_to_mono.dart <input.wav> <output.wav>

# 修復音檔格式
dart tools/fix_test_audio.dart <audio_directory>
```

詳細工具說明請參考：[tools/README.md](tools/README.md)

## 📝 文檔

- [音訊檢測優化歷史](AUDIO_DETECTION_OPTIMIZATION.md) - Round 1-10 完整測試數據
- [測試檔案整合計劃](TEST_FILES_CONSOLIDATION_PLAN.md) - 測試檔案重構記錄
- [AI 開發日誌](AI_WORK_LOG.md) - 開發過程記錄
- [測試指南](TEST_GUIDE.md) - 測試執行指引

## 🗂️ 最近更新

### 2025/12/21 - Phase 5 程式碼品質優化完成 ✨

- ✅ **Task 5.1**: 移除重複程式碼
  - ErrorHandler 已在主要檔案中使用
  - SharedPreferences 使用模式統一
  - 減少程式碼重複性

- ✅ **Task 5.2**: Lint 規則優化
  - 新增 20+ 個嚴格 lint 規則
  - lib/ 目錄 0 個錯誤
  - 提升程式碼品質和一致性

- ✅ **Task 5.3**: 文件註解完善
  - 核心工具類已有完整文檔
  - 公開 API 附有使用範例

- ✅ **Task 5.4**: README 更新（本次更新）

### 2025/12/16 - Phase 4 測試框架建立完成 🧪

- ✅ 建立完整測試目錄結構
- ✅ 新增 6 個測試檔案（services、models、widgets）
- ✅ 測試輔助工具 `test_helpers.dart`

### 2025/12/15 - Phase 1-2 優化完成 🚀

**程式碼優化成果**:
- ✅ 刪除 2,175 行淘汰程式碼（59.7% 減少）
- ✅ 新增 22 個 const 建構子（減少 widget 重建）
- ✅ 修復 StreamController 記憶體洩漏
- ✅ 實作 LRU 快取限制圖片記憶體
- ✅ 建立統一錯誤處理工具（ErrorHandler）
- ✅ 提取魔術數字至常數類別

**新增工具類**:
- `lib/utils/error_handler.dart` (164 行)
- `lib/utils/lru_cache.dart` (55 行)
- `lib/core/constants/audio_constants.dart` (71 行)
- `lib/core/constants/midi_constants.dart` (59 行)

### 2025/01/26 - 測試系統重構完成

- ✅ **測試檔案整合完成**
  - 整合 15+ 舊版測試檔案至 `test/integration/`
  - 建立統一的 `performance_test.dart`
  - 移除重複和過時的測試檔案
  - 建立 `tools/` 目錄管理開發工具

- ✅ **Round 10 測試完成**
  - 動態參數系統驗證
  - 四輪完整測試（32個案例）
  - 整體通過率 71.9%

## 📄 授權

本專案採用 MIT 授權。

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request！

---

**開發團隊**: Music Practice App Team  
**最後更新**: 2025/01/26

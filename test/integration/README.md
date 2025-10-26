# 整合測試檔案說明

本目錄包含音訊檢測系統的所有整合測試檔案。

## 📁 檔案結構

### 主要測試檔案

- **`performance_test.dart`** - 音訊分析性能測試（整合自 Round 10）
  - 動態參數系統測試
  - 四輪完整測試（32個案例）
  - 支援分輪執行，避免運行中斷

### 工具檔案

- **`test_utils.dart`** - 共用測試工具函數
  - 音檔路徑定義
  - 測試輔助函數
  - 結果格式化

## 🚀 使用方法

### 執行完整測試（所有4輪）

```bash
# 方法1: 使用 dart 直接執行
dart test/integration/performance_test.dart

# 方法2: 使用 flutter test
flutter test test/integration/performance_test.dart
```

### 執行單一輪次測試

```bash
# 第一輪：生日快樂
dart test/integration/performance_test.dart 1

# 第二輪：測試音檔
dart test/integration/performance_test.dart 2

# 第三輪：小星星
dart test/integration/performance_test.dart 3

# 第四輪：名偵探柯南
dart test/integration/performance_test.dart 4
```

### 注意事項

⚠️ **重要**：測試需要實際的錄音檔案才能執行。錄音檔案應位於：
```
D:/Flutter_project/music_practice_app/test_recordings/
├── 生日快樂/
│   ├── correct_performance_初學.wav
│   ├── correct_performance_中等.wav
│   ├── correct_performance_專業.wav
│   ├── background_noise_初學.wav
│   ├── background_noise_中等.wav
│   ├── background_noise_專業.wav
│   └── silence_專業.wav
├── 測試音檔/
├── 小星星/
└── 名偵探柯南/
```

如果音檔不存在，測試會自動跳過並顯示警告訊息。

## 📊 測試配置

- **第一輪**: 生日快樂.mid (25音符, ~17秒) - 簡單基準
- **第二輪**: 測試音檔.mid (94音符, ~34秒) - 單音無伴奏
- **第三輪**: 小星星.mid (147音符, ~27秒) - 有伴奏+中時常
- **第四輪**: 名偵探柯南.mid (1431音符, ~164秒) - 複雜+極快+長時常

## 🗑️ 已廢棄的檔案（已移除）

以下舊版測試檔案已整合至新版本：

- `test_comprehensive.dart` (Round 5-7 舊版)
- `test_round8_*.dart` (Round 8 固定參數版本)
- `test_week3.dart`, `test_week4_desktop.dart` (早期測試)
- `test_conan*.dart` (柯南專用測試)
- `test_midi_simple.dart` (簡單 MIDI 測試)
- `test_detection_comprehensive.dart` (空檔案)

## 📝 版本歷史

- **Round 10** (2025/10/26) - 動態參數系統，當前版本
- **Round 8** (2025/10/25) - 固定參數版本（已整合）
- **Round 5-7** (2025/10/08-25) - 早期版本（已整合）

## 🔗 相關文檔

- 詳細測試結果：`AUDIO_DETECTION_OPTIMIZATION.md`
- 整合計劃：`TEST_FILES_CONSOLIDATION_PLAN.md`

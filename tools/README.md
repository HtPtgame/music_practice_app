# 工具檔案目錄

本目錄包含音訊處理、MIDI 分析和參數優化相關的輔助工具。

## 📁 檔案列表

### 音訊處理工具

#### `convert_to_mono.dart`
**用途**: 將立體聲音檔轉換為單聲道

**使用方法**:
```bash
dart tools/convert_to_mono.dart <輸入檔案路徑> <輸出檔案路徑>
```

**範例**:
```bash
dart tools/convert_to_mono.dart test_recordings/生日快樂/stereo.wav test_recordings/生日快樂/mono.wav
```

**技術細節**:
- 混音方式: 平均左右聲道
- 保留原始採樣率和位深度
- 支援 16-bit PCM WAV 格式

---

#### `batch_convert_to_mono.dart`
**用途**: 批次轉換立體聲音檔為單聲道

**使用方法**:
```bash
dart tools/batch_convert_to_mono.dart
```

**功能**:
- 掃描 `assets/test_voice/` 資料夾
- 自動檢測雙聲道 WAV 檔案
- 轉換並覆蓋原檔案（⚠️ 注意備份）

**範例輸出**:
```
🔍 掃描 test_voice 資料夾...
✅ 轉換: 小星星.wav (2ch → 1ch)
✅ 轉換: 名偵探柯南.wav (2ch → 1ch)
⏭️  跳過: 生日快樂.wav (已是單聲道)
📊 總計: 轉換 2 個檔案，跳過 1 個
```

---

#### `fix_test_audio.dart`
**用途**: 修復測試音檔格式問題

**使用方法**:
```bash
dart tools/fix_test_audio.dart <音檔目錄>
```

**功能**:
- 檢查音檔格式
- 轉換為正確格式（16-bit PCM WAV, 44100Hz, 單聲道）
- 修復損壞的音檔頭

**範例**:
```bash
dart tools/fix_test_audio.dart test_recordings/生日快樂
```

---

### MIDI 分析工具

#### `analyze_midi_files.dart`
**用途**: 分析 MIDI 檔案結構和特性

**使用方法**:
```bash
dart tools/analyze_midi_files.dart
```

**分析項目**:
- � 檔案大小
- 🎵 音符總數
- ⏱️ TPQ (Ticks Per Quarter)
- 🎼 Tempo 事件數和詳情
- 📈 音符密度
- 🎹 音高範圍
- ⏰ 樂曲總時長

**範例輸出**:
```
🔍 MIDI 檔案延遲分析工具
======================================================================
📁 檔案: assets/test_voice/名偵探柯南.mid
📊 檔案大小: 45.23 KB
🎵 音符總數: 1431
⏱️  TPQ (Ticks Per Quarter): 480
🎼 Tempo 事件數: 1

📌 Tempo 事件詳情:
   0. Tick 0: 165.0 BPM (363636 μs/quarter)

📊 音符分布:
   最低音符: C3 (48)
   最高音符: C7 (96)
   音域跨度: 48 半音 (4 個八度)

⏰ 時長分析:
   總時長: 164.2 秒
   音符密度: 8.7 notes/sec
   評級: 🔥 極快節奏
======================================================================
```

---

### 參數優化工具

#### `find_best_parameters.dart`
**用途**: 基於歷史測試數據分析最佳參數

**使用方法**:
```bash
dart tools/find_best_parameters.dart
```

**分析基準**:
- Round 5-8 測試結果
- 正確演奏召回率 vs energyThreshold
- 環境噪音召回率 vs energyThreshold

**優化目標**:
- 正確演奏召回率 ≥ 85%
- 環境噪音召回率 ≤ 5%

**範例輸出**:
```
📊 參數分析報告
======================================================================
Round 5 (threshold=0.38):
  正確演奏: 86.5% ✅
  環境噪音: 10.3% ⚠️

Round 6 (threshold=0.40):
  正確演奏: 82.1% ⚠️
  環境噪音: 7.2% ✅

Round 7 (threshold=0.36):
  正確演奏: 89.3% ✅
  環境噪音: 13.5% ❌

Round 8 (threshold=0.38):
  正確演奏: 88.7% ✅
  環境噪音: 9.1% ⚠️

🎯 推薦參數: 0.38
   理由: 最佳平衡點，正確演奏高召回 + 環境噪音可接受
======================================================================
```

**結論**: 引發 Round 9 動態參數系統開發

---

## 🔧 工具使用場景

### 場景 1: 準備新的測試音檔

```bash
# 1. 修復格式
dart tools/fix_test_audio.dart test_recordings/新曲目

# 2. 轉換為單聲道
dart tools/batch_convert_to_mono.dart

# 3. 分析 MIDI 特性
dart tools/analyze_midi_files.dart
```

### 場景 2: 參數調優研究

```bash
# 1. 分析歷史數據
dart tools/find_best_parameters.dart

# 2. 執行參數掃描
dart test/research/parameter_sweep_test.dart

# 3. 驗證新參數
dart test/validation/final_validation_test.dart
```

### 場景 3: MIDI 檔案診斷

```bash
# 分析 MIDI 結構
dart tools/analyze_midi_files.dart

# 查看:
# - 音符數量（影響測試時長）
# - Tempo 設定（影響速度分級）
# - 音高範圍（影響頻譜匹配）
# - 音符密度（影響難度分級）
```

---

## ⚙️ 依賴項

這些工具需要 Flutter/Dart SDK，部分工具可能需要：

### 音訊處理（convert_to_mono, batch_convert, fix_test_audio）
- ✅ 純 Dart 實現，無需外部依賴
- ✅ 支援 16-bit PCM WAV 格式

### MIDI 分析（analyze_midi_files）
- ✅ 使用專案內的 MidiParser
- ✅ 無需外部工具

### FFmpeg（可選，用於複雜轉換）

安裝 FFmpeg:
```bash
# Windows (Chocolatey)
choco install ffmpeg

# macOS (Homebrew)
brew install ffmpeg

# Ubuntu
sudo apt install ffmpeg
```

**注意**: 本專案工具已實現基本音訊處理，FFmpeg 僅在需要進階功能時使用。

---

## 📝 開發筆記

### 音訊格式要求

本專案的音訊分析系統要求：
- **格式**: WAV (PCM)
- **位深度**: 16-bit
- **採樣率**: 44100Hz（推薦）或 48000Hz
- **聲道**: 單聲道（必須）

**為什麼要求單聲道？**
- 簡化頻譜分析
- 減少運算量
- 避免立體聲相位問題

### MIDI 分析用途

1. **難度分級**:
   - 音符密度 > 5 notes/sec → 複雜
   - 音符密度 < 2 notes/sec → 簡單

2. **速度分級**:
   - BPM > 140 → 快速
   - BPM < 80 → 慢速

3. **參數調整**:
   - 複雜曲目 → 降低 energyThreshold
   - 快速曲目 → 縮小 timingTolerance

---

## 🔗 相關文檔

- [test/research/README.md](../test/research/README.md) - 參數研究
- [test/validation/README.md](../test/validation/README.md) - 驗證測試
- [AUDIO_DETECTION_OPTIMIZATION.md](../AUDIO_DETECTION_OPTIMIZATION.md) - 優化歷史
- [lib/services/audio_analysis/dynamic_parameter_service.dart](../lib/services/audio_analysis/dynamic_parameter_service.dart) - 動態參數實現

---

**建立日期**: 2025/10/26  
**最後更新**: 2025/10/26  
**維護者**: GitHub Copilot

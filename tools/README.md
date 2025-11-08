# 工具檔案目錄

本目錄包含音訊處理和 MIDI 分析的整合工具，用於未來新增測試音檔時的格式處理。

##  工具列表

###  audio_tools.dart - 音訊處理工具集

整合了音訊格式轉換、修復、批次處理和分析功能。

**功能**:
- **convert** - 將立體聲轉為單聲道
- **batch** - 批次轉換目錄中的所有 WAV 檔案
- **fix** - 修復音訊格式（轉為 16-bit PCM, 44100Hz, 單聲道）
- **analyze** - 分析音訊檔案資訊

**使用方式**:
```bash
# 單檔轉換為單聲道
dart tools/audio_tools.dart convert <輸入檔案> <輸出檔案>

# 批次轉換目錄中的所有 WAV 檔案
dart tools/audio_tools.dart batch <目錄路徑>

# 修復音訊格式
dart tools/audio_tools.dart fix <檔案路徑>

# 分析音訊檔案資訊
dart tools/audio_tools.dart analyze <檔案路徑>
```

**範例**:
```bash
# 轉換單個檔案
dart tools/audio_tools.dart convert input.wav output.wav

# 批次處理測試音檔目錄
dart tools/audio_tools.dart batch assets/test_voice/

# 修復格式問題
dart tools/audio_tools.dart fix test.wav

# 查看音訊資訊
dart tools/audio_tools.dart analyze test.wav
```

---

###  midi_tools.dart - MIDI 分析工具

分析 MIDI 檔案的結構、音符、Tempo 等資訊。

**功能**:
- **analyze** - 分析單個 MIDI 檔案
- **batch** - 批次分析目錄中的所有 MIDI 檔案

**分析項目**:
-  檔案大小
-  音符總數
-  TPQ (Ticks Per Quarter)
-  Tempo 事件數和詳情
-  音符密度
-  音高範圍
-  樂曲總時長

**使用方式**:
```bash
# 分析單個 MIDI 檔案
dart tools/midi_tools.dart analyze <檔案路徑>

# 批次分析目錄中的所有 MIDI 檔案
dart tools/midi_tools.dart batch <目錄路徑>
```

**範例**:
```bash
# 分析單個檔案
dart tools/midi_tools.dart analyze assets/test_voice/生日快樂.mid

# 批次分析
dart tools/midi_tools.dart batch assets/test_voice/
```

**範例輸出**:
```
 MIDI 檔案分析工具
======================================================================
 檔案: 名偵探柯南.mid
 檔案大小: 45.23 KB
 格式類型: 0
 軌道數: 1
  TPQ (Ticks Per Quarter): 480
 音符總數: 1431
 Tempo 事件數: 1

 Tempo 事件詳情:
   1. Tick 0: 165.0 BPM (363636 μs/quarter)

 音符分布:
   最低音符: C3 (48)
   最高音符: C7 (96)
   音域跨度: 48 半音 (4.0 個八度)

 時長分析:
   總時長: 164.2 秒
   音符密度: 8.7 notes/sec
   評級:  極快節奏
======================================================================
```

---

##  使用場景

### 場景 1: 準備新的測試音檔

```bash
# 1. 分析音訊檔案
dart tools/audio_tools.dart analyze new_recording.wav

# 2. 修復格式（如需要）
dart tools/audio_tools.dart fix new_recording.wav

# 3. 批次處理整個目錄
dart tools/audio_tools.dart batch test_recordings/新曲目/
```

### 場景 2: 分析 MIDI 樂譜特性

```bash
# 1. 分析 MIDI 檔案
dart tools/midi_tools.dart analyze new_song.mid

# 2. 批次分析所有 MIDI
dart tools/midi_tools.dart batch assets/test_voice/

# 根據分析結果調整測試參數:
# - 音符密度 > 5 notes/sec  複雜曲目
# - BPM > 140  快速曲目
# - 時長 > 60s  長時間測試
```

### 場景 3: 音訊格式標準化

```bash
# 確保所有測試音檔符合系統要求
# (16-bit PCM, 44100Hz, 單聲道)

# 批次轉換
dart tools/audio_tools.dart batch assets/test_voice/

# 驗證格式
dart tools/audio_tools.dart analyze assets/test_voice/生日快樂.wav
```

---

##  音訊格式要求

本專案的音訊分析系統要求：
- **格式**: WAV (PCM)
- **位深度**: 16-bit
- **採樣率**: 44100Hz
- **聲道**: 單聲道（必須）

**為什麼要求單聲道？**
- 簡化頻譜分析
- 減少運算量
- 避免立體聲相位問題

---

##  相關資源

### 測試系統
- **test/integration/** - 整合測試
- **test/validation/** - 驗證測試
- **test/research/** - 參數研究測試

### 主程式功能
- **lib/services/audio_analysis/** - 音訊分析服務
- **lib/services/midi_service.dart** - MIDI 處理服務

### 文檔
- **AI_WORK_LOG.md** - 完整開發歷程記錄
- **test/integration/README.md** - 整合測試說明

---

##  更新記錄

**2025/11/08** - 工具整合
- 將三個音訊處理工具整合為 `audio_tools.dart`
- 保留 MIDI 分析工具為 `midi_tools.dart`
- 採用指令式介面，更易於使用
- 所有功能整合至兩個檔案，便於維護

**保留原因**:
- 未來可能新增測試音檔
- 需要統一音訊格式
- MIDI 分析有助於參數調整

---

**最後更新**: 2025/11/08  
**維護者**: GitHub Copilot
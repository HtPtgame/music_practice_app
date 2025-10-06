# Week 3 完成報告 - 錯誤分類與整合

## 📅 完成日期
2025年10月6日

## ✅ 已完成任務

### 1. 錯誤分類服務 (ErrorClassificationServiceImpl)
**文件**: `lib/services/audio_analysis/error_classification_service_impl_v2.dart`

**功能**:
- ✅ 漏音檢測 (Missed Notes Detection)
- ✅ 節奏錯誤檢測 (Timing Error Detection)
  - 搶拍檢測 (Early Timing)
  - 拖拍檢測 (Late Timing)
- ✅ Onset Detection (音符起始點檢測)
- ✅ 節奏容錯機制 (±100ms tolerance)

**核心算法**:
```dart
// 漏音判定
for (note in verificationResults) {
  if (!detected) {
    → PerformanceError(type: ErrorType.missedNote)
  }
}

// 節奏偏差判定
actualOnset = detectOnset(spectrogram, expectedTime, frequency)
timeOffset = actualOnset - expectedTime
if (abs(timeOffset) > 100ms) {
  → PerformanceError(type: early/late)
}
```

**參數**:
- `timingTolerance = 0.1秒` (±100ms容錯)
- `energyThreshold = 0.15` (能量檢測閾值)

### 2. 演奏分析器 (PerformanceAnalyzer)
**文件**: `lib/services/audio_analysis/performance_analyzer.dart`

**整合流程**:
```
Step 1 (20%): 解析 MIDI 標準答案 (MidiParser)
Step 2 (40%): 分析 WAV 頻譜 (AudioAnalyzer)
Step 3 (20%): 驗證音符 (NoteVerifier)
Step 4 (10%): 分類錯誤 (ErrorClassifier)
Step 5 (10%): 生成報告 (AnalysisReport)
```

**接口匹配**:
- ✅ 實現 `IPerformanceAnalyzer` 接口
- ✅ 參數: `analyze(wavPath, midiPath, onProgress)`
- ✅ 返回: `AnalysisReport`
- ✅ 進度回調 (0.0 - 1.0)

### 3. 測試工具 (test_week3.dart)
**文件**: `test_week3.dart`

**測試功能**:
- ✅ 完整分析流程測試
- ✅ 進度條顯示
- ✅ 詳細報告輸出
- ✅ 錯誤統計和分類
- ✅ 評級和建議生成

**輸出內容**:
- 基本統計 (總音符、正確、漏音、錯音、節奏偏差)
- 準確率、節奏分數、總分
- 評級 (A/B/C/D/F)
- 錯誤詳情 (前20個)
- 練習建議

## 📊 代碼統計

| 文件 | 行數 | 功能 |
|------|------|------|
| error_classification_service_impl_v2.dart | 128 | 錯誤分類核心 |
| performance_analyzer.dart | 107 | 完整分析流程 |
| test_week3.dart | 151 | 整合測試工具 |
| **總計** | **386 行** | **Week 3 新增** |

## 🎯 核心算法實現

### Onset Detection (音符起始點檢測)
```dart
// 在預期時間 ±200ms 範圍內搜索
searchWindow = [expectedTime - 0.2, expectedTime + 0.2]

// 1. 找到能量峰值
maxEnergy, maxFrame = findPeakEnergy(searchWindow, frequency)

// 2. 回溯找能量上升起點
for frame from maxFrame down to startFrame:
  if prevEnergy < currentEnergy * 0.5:
    return frame  // 這就是起始點
```

### 節奏偏差計算
```dart
timeOffset = actualOnset - expectedTime

if abs(timeOffset) > 100ms:
  severity = calculateSeverity(timeOffset)
  type = timeOffset > 0 ? lateTiming : earlyTiming
  → PerformanceError(type, timeOffset, severity)
```

## ✅ 編譯狀態
```
✅ error_classification_service_impl_v2.dart: No errors
✅ performance_analyzer.dart: No errors
✅ test_week3.dart: No errors
```

## 🧪 測試狀態

### 已測試
- ✅ MIDI 解析 (test_midi_simple.dart)
  - 94個音符,34秒,10ms處理時間
- ✅ 編譯檢查通過
- ✅ 代碼結構正確

### 待測試 (需要 WAV 文件)
- ⏳ 完整分析流程
- ⏳ 錯誤分類準確性
- ⏳ Onset Detection 精確度
- ⏳ 評級系統校準

## 📝 數據模型使用

### AnalysisReport
```dart
totalNotes: int      // 總音符數
correctNotes: int    // 正確音符數
wrongNotes: int      // 錯音數
missedNotes: int     // 漏音數
earlyNotes: int      // 搶拍數
lateNotes: int       // 拖拍數
errors: List<PerformanceError>
processingTime: Duration

// 計算屬性
accuracy: double (0-1)
rhythmScore: double (0-100)
overallScore: double (0-100)
grade: String (A/B/C/D/F)
```

### PerformanceError
```dart
type: ErrorType (missedNote, wrongNote, earlyTiming, lateTiming)
expectedNote: int?
actualNote: int?
expectedTime: double
actualTime: double?
timingOffset: double?
message: String
confidence: double (0-1)
```

## 🔧 可調參數

| 參數 | 當前值 | 用途 | 調整建議 |
|------|--------|------|----------|
| `timingTolerance` | 100ms | 節奏容錯 | 寬鬆: 150ms, 嚴格: 50ms |
| `energyThreshold` | 0.15 | 音符檢測閾值 | 低音量: 0.10, 高要求: 0.20 |
| `searchWindow` | ±200ms | Onset搜索範圍 | 快速樂曲: ±150ms |

## 🚀 下一步 (Week 4)

### UI 整合
1. 創建分析進度頁面
2. 展示視覺化報告
3. 整合到 practice_page.dart
4. 替換舊的 Basic Pitch 系統

### 優化
1. 調整參數 (基於真實測試)
2. 性能優化 (大文件處理)
3. 錯誤訊息本地化
4. 添加更多錯誤類型 (如音量、時值)

### 測試
1. 多種樂器測試
2. 不同難度曲目
3. 極端情況 (很慢/很快)
4. 錯音檢測完善

## 💡 技術亮點

1. **模塊化設計**: 每個服務獨立,易於測試和替換
2. **進度反饋**: 實時進度回調,提升用戶體驗
3. **錯誤詳情**: 不僅報錯,還提供具體時間和建議
4. **Onset Detection**: 精確捕捉音符起始,而非僅檢測能量
5. **容錯機制**: 節奏容錯避免誤報

## 📦 Week 3 文件清單

```
lib/services/audio_analysis/
├── error_classification_service_impl_v2.dart (新)
├── performance_analyzer.dart (新)
└── models/
    ├── note_event.dart (已有)
    ├── spectrogram.dart (已有)
    ├── performance_error.dart (已有)
    └── analysis_report.dart (已有)

測試文件:
├── test_week3.dart (新)
├── test_midi_simple.dart (Week 2)
├── test_midi_parser.dart (Week 2)
└── test_wav_analyzer.dart (Week 2)
```

## ✅ Week 1-3 總進度

| 週次 | 任務 | 狀態 | 代碼量 |
|------|------|------|--------|
| Week 1 | 架構 + 錄音升級 | ✅ | 548 行 |
| Week 2 | 核心算法 | ✅ | 587 行 |
| Week 3 | 錯誤分類 + 整合 | ✅ | 386 行 |
| **總計** | **3 週** | **✅ 75%** | **1,521 行** |

## 🎯 待完成 (Week 4)

- [ ] UI 整合到 practice_page.dart
- [ ] 視覺化報告頁面
- [ ] 替換 Basic Pitch
- [ ] 真實場景測試
- [ ] 參數調優
- [ ] 文檔完善

---

## 📞 下一步行動

**現在需要做**:
1. 錄製一個測試 WAV 文件 (演奏 assets/測試.mid)
2. 運行 `dart test_week3.dart`
3. 查看分析報告
4. 根據結果調整參數

**或者**:
- 我可以幫您創建一個**合成測試音訊生成器**
- 用正弦波模擬鋼琴音符
- 故意加入一些錯誤 (漏音、節奏偏差)
- 測試錯誤分類是否正確

**準備好進入 Week 4 了嗎?** 🚀

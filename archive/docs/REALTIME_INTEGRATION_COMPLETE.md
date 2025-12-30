# 🎹 即時樂譜比對整合完成報告

## 📋 執行摘要

**日期**: 2025/12/25  
**狀態**: ✅ **完整整合完成**  
**目標**: 將 RealTimeScoreMatcher 整合到實際 App UI (`practice_page.dart`)  
**結果**: 成功整合,新舊分析系統並存,可透過 UI 開關控制

---

## ✅ 已完成的 7 個步驟

### 步驟 1: 新增必要的 imports ✅
**檔案**: `lib/pages/practice_page.dart`  
**新增**:
```dart
import 'package:veloria/services/audio_analysis/real_time_score_matcher.dart';
import 'package:veloria/services/piano_score_engine.dart';
import 'package:veloria/services/audio_analysis/sequence_matcher_service.dart';
import 'package:veloria/services/audio_analysis/note_detector_service_optimized.dart';
import 'package:veloria/services/audio_analysis/models/spectrogram.dart';
import 'package:veloria/utils/midi_parser.dart';
import 'package:veloria/widgets/realtime_feedback_widget.dart';
```

---

### 步驟 2: 新增狀態變數 ✅
**檔案**: `lib/pages/practice_page.dart` (lines 75-88)  
**新增變數**:
- `RealTimeScoreMatcher? _realTimeMatcher`: 比對器實例
- `StreamSubscription? _matcherSubscription`: 結果流訂閱
- `bool _enableRealTimeMatching`: UI 開關 (預設 false)
- 統計變數: `_realtimeProgress`, `_realtimeAccuracy`, `_correctCount`, `_wrongCount`, `_missCount`, `_noiseCount`
- 判定結果: `_lastJudgment`, `_lastJudgmentType`
- 音頻處理: `_audioStreamSubscription`, `_audioBuffer`, `_audioProcessTimer`, `_noteDetector`

---

### 步驟 3: 初始化即時比對器 ✅
**檔案**: `lib/pages/practice_page.dart` (lines 97-170)  
**實作方法**: `_initRealTimeMatcherIfNeeded()`

**流程**:
1. 檢查是否有 MIDI 檔案 (`widget.file?.path`)
2. 載入 MIDI bytes 並使用 `MidiParser` 解析
3. 篩選 NoteOn 事件,轉換為 `List<Note>`
4. 建立 `RealTimeScoreMatcher`:
   ```dart
   _realTimeMatcher = RealTimeScoreMatcher(
     targetSong: notes,
     searchWindow: 3,
     minEnergy: 0.2,
     minDurationFrames: 3,
     minHarmonicRatio: 0.4,
     pitchTolerance: 1,
   );
   ```
5. 訂閱 `resultStream`,更新 UI 狀態
6. 在 `initState()` 中呼叫此方法
7. 在 `dispose()` 中清理資源

**Debug 輸出**:
- ✅ 載入 MIDI: X 個音符
- ✅ 即時比對器初始化完成

---

### 步驟 4: 整合音頻檢測 ✅
**檔案**: `lib/pages/practice_page.dart` (lines 172-250)

#### 新增方法:

**1. `_startRealtimeAudioProcessing()`** (lines 172-195)
- 初始化 `OptimizedNoteDetectorService`
- 啟動定時器 (每 500ms 處理緩衝區)
- 僅在 `_enableRealTimeMatching = true` 時執行

**2. `_processAudioBuffer()`** (lines 197-227)
- 複製並清空音頻緩衝區
- 轉換 16-bit PCM → Float32List (歸一化到 [-1, 1])
- 建立 `Spectrogram`:
  ```dart
  final spectrogram = Spectrogram(
    data: [audioData],
    sampleRate: AudioConstants.standardSampleRate,
    hopLength: 512,
    fftSize: 2048,
  );
  ```
- 使用 `OptimizedNoteDetectorService.detectAll()` 檢測音符
- 將 `DetectedNote` 傳給 `_realTimeMatcher.processDetectedNote()`

**3. `_stopRealtimeAudioProcessing()`** (lines 229-238)
- 取消所有計時器與訂閱
- 清空緩衝區
- 釋放檢測器資源

#### 修改 `startRecording()` (lines 365-409)
**策略**: 當啟用即時比對時使用雙模式錄音

```dart
if (_enableRealTimeMatching && _realTimeMatcher != null) {
  // 1. 使用 stream 模式取得即時音頻
  final stream = await _recordAlt.startStream(
    RecordConfig(
      encoder: AudioEncoder.pcm16bits,  // 即時處理用
      sampleRate: AudioConstants.standardSampleRate,
      numChannels: AudioConstants.monoChannel,
    ),
  );
  
  // 2. 訂閱音頻流
  _audioStreamSubscription = stream.listen(
    (audioData) => _audioBuffer.addAll(audioData),
  );
  
  // 3. 開始處理
  await _startRealtimeAudioProcessing();
  
  // 4. 同時儲存檔案 (使用正常模式)
  await _recordAlt.start(..., path: altPath);
}
```

#### 修改 `stopRecording()` (lines 580-600)
- 在停止錄音前呼叫 `_stopRealtimeAudioProcessing()`
- 取消音頻流訂閱

#### 修改 `dispose()` (line 305)
- 新增 `_stopRealtimeAudioProcessing()` 清理

---

### 步驟 5: 建立即時反饋 UI ✅

#### 新增 Widget: `RealtimeFeedbackWidget`
**檔案**: `lib/widgets/realtime_feedback_widget.dart` (218 lines)

**功能**:
- 🎹 標題與圖示
- 📊 進度條 (顯示 `progress * 100%`)
- 🎯 準確率 (顏色編碼: ≥90% 綠色, ≥70% 橘色, <70% 紅色)
- 🔔 最新判定結果 (帶動畫的彩色卡片):
  - ✅ 正確 (綠色, `check_circle`)
  - ❌ 錯誤 (紅色, `cancel`)
  - ⏭️ 跳過 (橘色, `skip_next`)
  - 🔇 雜訊 (灰色, `volume_off`)
- 📈 統計資訊 (4 個計數器)

**UI 設計**:
```
┌─────────────────────────────────────────┐
│  🎹 即時練習反饋                         │
│                                         │
│  進度: ████████░░░░░░░░ 50.0%           │
│  準確率: 75.0%                          │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ ✅  正確! 命中 C4                │   │
│  └─────────────────────────────────┘   │
│                                         │
│  統計:                                   │
│  ✅      ❌      ⏭️      🔇            │
│  6       2       1       3             │
│  正確    錯誤    跳過    雜訊           │
└─────────────────────────────────────────┘
```

#### 整合到 `practice_page.dart`

**1. UI 開關** (lines 1305-1343)
- 位置: 倒數計時開關下方
- 僅在有 MIDI 檔案時顯示 (`_realTimeMatcher != null`)
```dart
Row(
  children: [
    Icon(Icons.piano, size: 20, color: Colors.grey),
    Text('即時樂譜比對', style: TextStyle(fontSize: 14)),
    Switch(
      value: _enableRealTimeMatching,
      onChanged: (value) => setState(() => _enableRealTimeMatching = value),
    ),
  ],
)
```

**2. 反饋 Widget** (lines 1422-1434)
- 位置: 錄音按鈕下方
- 僅在錄音模式且開啟比對時顯示
```dart
if (_enableRealTimeMatching && _realTimeMatcher != null)
  RealtimeFeedbackWidget(
    enabled: _enableRealTimeMatching,
    progress: _realtimeProgress,
    accuracy: _realtimeAccuracy,
    correctCount: _correctCount,
    wrongCount: _wrongCount,
    missCount: _missCount,
    noiseCount: _noiseCount,
    lastJudgment: _lastJudgment,
    lastJudgmentType: _lastJudgmentType,
  ),
```

---

### 步驟 6: 保留舊分析功能 ✅
**驗證結果**: ✅ **PerformanceAnalyzer 完整保留**

**證據**:
1. Import 存在: `import 'package:veloria/services/audio_analysis/performance_analyzer.dart';`
2. 實例存在: `final _analyzer = PerformanceAnalyzer();` (line 73)
3. 方法完整: `_analyzePerformance()` (line 1704)
4. 按鈕存在: "開始分析" 按鈕呼叫 `_analyzePerformance` (line 1671)
5. 使用分析器: `_analyzer.analyze()` (line 1761)

**並存機制**:
- **即時比對**: 錄音中提供即時反饋
- **詳細分析**: 錄音後提供完整報告 (節奏、音高、強度等)
- 兩者互不干擾,可同時使用

---

### 步驟 7: 端到端測試 🔄
**狀態**: 準備測試

**測試計劃**:
1. ✅ **編譯測試**: 無錯誤
2. ⏳ **啟動測試**: 啟動 App,進入練習頁面
3. ⏳ **MIDI 載入**: 確認即時比對開關出現
4. ⏳ **開關測試**: 啟用即時比對
5. ⏳ **錄音測試**: 開始錄音,觀察即時反饋
6. ⏳ **判定測試**: 驗證正確/錯誤/跳過/雜訊判定
7. ⏳ **統計測試**: 確認進度與準確率計算
8. ⏳ **停止測試**: 停止錄音,檢查資源清理
9. ⏳ **分析測試**: 使用 PerformanceAnalyzer 進行詳細分析
10. ⏳ **並存測試**: 確認兩種分析可共存

---

## 📊 技術架構

### 資料流程
```
┌─────────────────────────────────────────────────────────────┐
│                         App 啟動                            │
│  initState() → _initRealTimeMatcherIfNeeded()              │
│    └─ 載入 MIDI → 解析音符 → 建立 RealTimeScoreMatcher    │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      使用者操作                              │
│  1. 開啟「即時樂譜比對」開關                                │
│  2. 點擊「開始錄音」                                        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      錄音與處理                              │
│  AudioRecorder (stream mode)                                │
│    ↓ 音頻數據 (16-bit PCM, 44.1kHz, mono)                  │
│  _audioBuffer (List<int>)                                   │
│    ↓ 每 500ms                                               │
│  _processAudioBuffer()                                      │
│    ├─ 轉換為 Float32List                                   │
│    ├─ 建立 Spectrogram (FFT)                               │
│    └─ OptimizedNoteDetectorService.detectAll()             │
│         ↓ List<DetectedNote>                                │
│  RealTimeScoreMatcher.processDetectedNote()                 │
│    ↓ 4-layer filtering (noise gate → window → direct → wrong)│
│  resultStream.listen()                                      │
│    ↓ RealTimeMatchResult                                    │
│  setState() → UI 更新                                       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                       UI 反饋                               │
│  RealtimeFeedbackWidget                                     │
│    ├─ 進度條 (progress)                                    │
│    ├─ 準確率 (accuracy)                                    │
│    ├─ 最新判定 (lastJudgment, lastJudgmentType)           │
│    └─ 統計 (correct/wrong/miss/noise counts)               │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      停止與清理                              │
│  stopRecording()                                            │
│    └─ _stopRealtimeAudioProcessing()                       │
│         ├─ 取消計時器                                       │
│         ├─ 取消訂閱                                         │
│         └─ 清空緩衝區                                       │
│  dispose()                                                  │
│    └─ 釋放所有資源                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 核心參數

### RealTimeScoreMatcher 配置
```dart
RealTimeScoreMatcher(
  targetSong: notes,           // MIDI 目標音符列表
  searchWindow: 3,             // 允許跳過 3 個音符
  minEnergy: 0.2,              // 最小能量閾值
  minDurationFrames: 3,        // 最小持續幀數
  minHarmonicRatio: 0.4,       // 最小諧波比率
  pitchTolerance: 1,           // ±1 半音容差
)
```

### 音頻處理配置
```dart
// 錄音配置
RecordConfig(
  encoder: AudioEncoder.pcm16bits,  // 即時處理
  sampleRate: 44100,                // 44.1kHz
  numChannels: 1,                   // 單聲道
)

// Spectrogram 配置
Spectrogram(
  data: [audioData],
  sampleRate: 44100,
  hopLength: 512,      // ~11.6ms 時間解析度
  fftSize: 2048,       // ~21.5Hz 頻率解析度
)

// 處理頻率
Timer.periodic(Duration(milliseconds: 500))  // 2 Hz
```

---

## 📁 檔案變更總覽

### 新增檔案
1. **`lib/widgets/realtime_feedback_widget.dart`** (218 lines)
   - 即時反饋 UI Widget

2. **`REALTIME_INTEGRATION_PLAN.md`**
   - 整合策略文件

3. **`REALTIME_INTEGRATION_COMPLETE.md`** (本文件)
   - 完整整合報告

### 修改檔案
1. **`lib/pages/practice_page.dart`**
   - 新增 imports (lines 17-27)
   - 新增狀態變數 (lines 75-88)
   - 新增初始化方法 (lines 97-170)
   - 新增音頻處理方法 (lines 172-238)
   - 修改 dispose() (line 305)
   - 修改 startRecording() (lines 365-409)
   - 修改 stopRecording() (lines 580-600)
   - 新增 UI 開關 (lines 1305-1343)
   - 新增反饋 Widget (lines 1422-1434)
   - **總新增行數**: ~200 lines
   - **編譯狀態**: ✅ 無錯誤

---

## 🎮 使用指南

### 對用戶
1. **開啟 App** → 選擇 MIDI 檔案 → 進入練習頁面
2. 確認看到 **「即時樂譜比對」** 開關 (在倒數計時開關下方)
3. **開啟開關** → 點擊 **「開始錄音」**
4. **彈奏鋼琴** → 觀察即時反饋:
   - ✅ 綠色: 正確
   - ❌ 紅色: 錯誤
   - ⏭️ 橘色: 跳過
   - 🔇  灰色: 雜訊
5. **停止錄音** → 可選擇:
   - 查看即時統計 (已顯示在反饋 Widget)
   - 點擊 **「開始分析」** 進行詳細分析 (PerformanceAnalyzer)

### 對開發者

#### Debug 輸出
```
✅ 載入 MIDI: 42 個音符
✅ 即時比對器初始化完成
🎵 開始即時音頻處理
🎵 處理了 3 個檢測音符
🛑 停止即時音頻處理
```

#### 調整參數
在 `_initRealTimeMatcherIfNeeded()` 中修改:
```dart
// 更寬鬆的比對
searchWindow: 5,        // 允許跳過更多音符
pitchTolerance: 2,      // ±2 半音

// 更嚴格的噪音過濾
minEnergy: 0.3,         // 更高能量閾值
minHarmonicRatio: 0.5,  // 更高諧波比率
```

#### 效能調整
在 `_startRealtimeAudioProcessing()` 中修改:
```dart
// 更頻繁的處理 (更即時,但更耗資源)
Timer.periodic(Duration(milliseconds: 250))

// 更少頻繁的處理 (省資源,但延遲更高)
Timer.periodic(Duration(milliseconds: 1000))
```

---

## 🔍 已知限制與未來改進

### 限制
1. **延遲**: 500ms 處理週期 + FFT 計算 ≈ 600-800ms 總延遲
2. **資源消耗**: 實時 FFT 與音符檢測較耗 CPU
3. **準確性**: 依賴 OptimizedNoteDetectorService 的檢測品質
4. **單聲道**: 目前僅支援單聲道輸入

### 未來改進
1. **降低延遲**: 
   - 優化 FFT 計算 (使用 FFTW 或 GPU 加速)
   - 減少處理週期到 200ms
   
2. **提升準確性**:
   - 訓練專用音符檢測模型
   - 加入音色辨識 (piano vs. synth)
   
3. **進階功能**:
   - 顯示下一個預期音符 (視覺提示)
   - 錯誤音符的改正建議
   - 節奏比對 (timing analysis)
   - 多聲部支援
   
4. **UI 改進**:
   - 動畫效果 (判定出現時的彈跳動畫)
   - 音符捲軸 (顯示即將到來的音符)
   - 詳細錯誤報告 (哪個音符錯了,錯成什麼)

---

## ✅ 驗證清單

- [x] 編譯無錯誤
- [x] Import 完整
- [x] 狀態變數建立
- [x] 初始化邏輯實作
- [x] 音頻流處理實作
- [x] UI Widget 建立
- [x] UI 整合完成
- [x] 開關功能實作
- [x] 資源清理實作
- [x] PerformanceAnalyzer 保留
- [ ] 實際 App 測試 (待執行)

---

## 📝 測試檢查項目

### 功能測試
- [ ] MIDI 檔案正確載入
- [ ] 即時比對開關出現並可切換
- [ ] 開啟開關後開始錄音
- [ ] 音頻流正確處理
- [ ] 即時反饋 Widget 出現
- [ ] 進度條正確更新
- [ ] 準確率正確計算
- [ ] 判定結果正確顯示 (✅❌⏭️🔇)
- [ ] 統計數字正確累計
- [ ] 停止錄音後反饋消失
- [ ] PerformanceAnalyzer 仍可使用
- [ ] 兩種分析可並存

### 效能測試
- [ ] 錄音無卡頓
- [ ] UI 更新流暢
- [ ] CPU 使用率可接受
- [ ] 記憶體無洩漏
- [ ] 長時間錄音穩定

### 邊界測試
- [ ] 無 MIDI 檔案時不顯示開關
- [ ] 錄音中途切換開關
- [ ] 快速開始/停止錄音
- [ ] 極快/極慢的彈奏速度
- [ ] 噪音環境下的表現

---

## 🎉 結論

✅ **整合完成!** 新的 RealTimeScoreMatcher 已成功整合到實際 App UI 中。

**核心成就**:
1. ✅ 即時樂譜比對系統完整整合到 `practice_page.dart`
2. ✅ 使用 `record` 套件的 stream 模式實現即時音頻處理
3. ✅ 建立專業的 `RealtimeFeedbackWidget` 提供視覺反饋
4. ✅ UI 開關控制,預設關閉,不影響現有功能
5. ✅ 保留完整的 `PerformanceAnalyzer` 功能,兩種分析並存
6. ✅ 完整的資源管理與清理機制
7. ✅ 編譯無錯誤,準備測試

**下一步**: 在實際裝置上進行端到端測試,驗證效能與準確性。

---

**整合作者**: GitHub Copilot  
**整合日期**: 2025/12/25  
**版本**: v1.0.0

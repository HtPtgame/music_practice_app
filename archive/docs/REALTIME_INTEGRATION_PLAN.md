# 🎹 即時樂譜比對整合計劃

## 整合策略

由於 `practice_page.dart` 目前使用的是 **錄音後分析** 的模式,而即時比對需要 **錄音中實時處理**,我們有兩個選項:

### 選項 A: 保守整合 (推薦)
**特點**:
- ✅ 保留現有錄音功能完整性
- ✅ 新增獨立的「即時練習模式」按鈕
- ✅ 兩種模式可並存
- ❌ 需要額外 UI 空間

**實作**:
1. 新增「即時練習模式」切換開關
2. 當開啟時,在錄音同時進行音頻檢測與比對
3. 顯示即時反饋 UI (進度條、準確率、最新判定)
4. 錄音結束後仍可進行完整分析

### 選項 B: 激進整合
**特點**:
- ✅ UI 更簡潔統一
- ❌ 需要重寫錄音流程
- ❌ 風險較高,可能影響現有功能

## 選擇方案 A 的實作步驟

### 1. 音頻緩衝區處理
```dart
// 需要在錄音時收集音頻數據
List<List<int>> _audioBuffer = [];
Timer? _realtimeProcessTimer;

// 每 0.5 秒處理一次緩衝區
void _startRealtimeProcessing() {
  _realtimeProcessTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
    if (_audioBuffer.isNotEmpty && _enableRealTimeMatching) {
      _processAudioBuffer();
    }
  });
}

Future<void> _processAudioBuffer() async {
  // 1. 將緩衝區轉換為 Spectrogram
  // 2. 使用 OptimizedNoteDetectorService 檢測音符
  // 3. 將檢測結果傳給 RealTimeScoreMatcher
  // 4. 清空緩衝區
}
```

### 2. UI 反饋設計
```
┌─────────────────────────────────────────┐
│  🎹 即時練習模式: ON                     │
│                                         │
│  進度: ████████░░░░░░░░░ 50%            │
│  準確率: 75.0%                          │
│                                         │
│  ✅ 正確! 命中 C4                        │
│                                         │
│  統計:                                   │
│  ✅ 正確: 6  ❌ 錯誤: 2                  │
│  ⏭️ 跳過: 1  🔇 雜訊: 3                 │
└─────────────────────────────────────────┘
```

### 3. 技術限制

**問題**: Flutter Sound Recorder 不提供即時音頻流訪問

**解決方案**:
- 使用 `record` 套件的 `AudioRecorder` (已在程式碼中)
- 使用 `record` 的 stream 功能取得即時音頻數據

**修改**:
```dart
// 改用 record 套件的 stream 模式
await _recordAlt.start(
  RecordConfig(encoder: AudioEncoder.wav),
  path: outputPath,
);

// 監聽音頻流
final stream = await _recordAlt.startStream(RecordConfig(...));
stream.listen((audioData) {
  _audioBuffer.add(audioData);
});
```

## 建議

考慮到:
1. 目前 `record` 套件已在使用
2. 需要即時音頻流處理
3. 最小化風險

**最佳方案**: 
- 階段 1: 先完成 UI 框架與開關
- 階段 2: 實作簡化版(使用預錄音頻測試)
- 階段 3: 整合真實音頻流處理

## 當前決定

由於即時音頻流處理需要:
1. 音頻 streaming API
2. FFT 實時計算
3. 高頻率更新 (每 0.5 秒)

**建議先實作 UI 框架與資料流程,音頻部分使用模擬數據驗證邏輯正確性**。

完整的音頻 streaming 整合需要更多時間測試與調整。

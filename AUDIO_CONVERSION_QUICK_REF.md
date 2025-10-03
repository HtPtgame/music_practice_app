# AI 音檔轉換功能快速參考

## 修正摘要 (2025/09/30)

### ✅ 已修正的問題

1. **WAV 檔案位元組順序錯誤**
   - 從 Big-Endian 改為 Little-Endian
   - 影響：標頭解析和音訊數據讀取

2. **音訊品質檢查不足**
   - 添加 RMS 閾值檢查
   - 提前攔截無聲或極弱音訊

3. **音符時間計算錯誤**
   - 簡化 endTime 計算邏輯
   - 修正時間偏移計算

4. **AI 推論容錯性不足**
   - 允許 50% 以下的區塊失敗
   - 更友善的錯誤訊息

5. **三維張量處理錯誤**
   - 修正資料重塑邏輯
   - 正確的維度關係

---

## 使用流程

```
錄音 → WAV 檔案 → 預處理 → 分割區塊 → AI 推論 → 合併音符 → MIDI 檔案
  ↓       ↓          ↓          ↓          ↓          ↓          ↓
 3-15s   16kHz    正規化      1秒/塊    TFLite   時間對齊    保存
```

---

## 關鍵參數

### 錄音設置
```dart
RecordConfig(
  encoder: AudioEncoder.wav,
  sampleRate: 16000,  // 16kHz
  numChannels: 1,     // 單聲道
  bitRate: 256000,    // 256 kbps
)
```

### 音訊品質閾值
```dart
RMS >= 0.0001  // 最低要求
RMS >= 0.001   // 建議值（顯示警告）
RMS >= 0.01    // 理想值
```

### AI 推論設置
```dart
區塊大小: 16000 樣本 (1 秒 @ 16kHz)
失敗容忍: 50% (超過則終止)
時間分割: 384 ticks/quarter note
```

---

## 錯誤處理

### 常見錯誤及解決方案

#### 錯誤 1: "音訊預處理後沒有有效樣本"
**原因**: WAV 檔案格式錯誤或數據損壞
**解決**: 重新錄音，確保使用正確的錄音器

#### 錯誤 2: "音訊信號太微弱"
**原因**: RMS < 0.0001
**解決**: 增加音量重新錄音

#### 錯誤 3: "AI 推論失敗次數過多"
**原因**: 超過 50% 的區塊 AI 推論失敗
**解決**: 
- 檢查音訊品質
- 確保 AI 模型已正確載入
- 嘗試較短的錄音

#### 錯誤 4: "不支援的輸入張量維度"
**原因**: AI 模型輸入格式不符
**解決**: 檢查 TFLite 模型版本

---

## Debug 技巧

### 啟用詳細日誌
在 `practice_page.dart` 中查看 `debugPrint` 輸出：

```dart
🔄 步驟 1: 檢查音訊檔案格式...
✅ 使用 WAV 格式檔案進行 AI 處理
🔄 步驟 2: 讀取完整 WAV 音訊檔案...
📁 WAV 檔案分析:
  檔案大小: XXXXX bytes
  音頻格式: 1 (PCM)
  聲道數: 1
  採樣率: 16000 Hz
  位深度: 16 bits
```

### 檢查 WAV 檔案
```dart
完整音訊預處理完成: XXXXX 樣本
完整音訊品質 - RMS: 0.XXXX, Peak: 0.XXXX
```

### 監控 AI 推論
```dart
處理區塊 X/Y
區塊 X 完成：Z 個音符事件
```

---

## 性能優化建議

### 1. 錄音時長
- **最短**: 3 秒（建議）
- **理想**: 5-10 秒
- **最長**: 15 秒（性能考量）

### 2. 音訊品質
- 使用外接麥克風（如果可能）
- 在安靜環境錄音
- 保持適當音量（RMS > 0.01）

### 3. 處理時間預估
| 錄音長度 | 處理時間（估計）|
|---------|----------------|
| 3 秒    | 5-10 秒        |
| 5 秒    | 10-15 秒       |
| 10 秒   | 20-30 秒       |
| 15 秒   | 30-45 秒       |

---

## 測試檢查表

- [ ] 錄製 3-5 秒正常音量的音訊
- [ ] 確認 WAV 檔案大小 > 1 KB
- [ ] 檢查音訊 RMS > 0.01
- [ ] 觀察 AI 推論進度（0% → 100%）
- [ ] 確認生成 MIDI 檔案 > 0 bytes
- [ ] 檢視 MIDI 檔案分析結果
- [ ] 驗證音符數量 > 0

---

## API 參考

### 主要方法

```dart
// 1. WAV 預處理
Future<Float32List> _preprocessFullWavFile(File wavFile)
// 輸入: WAV 檔案
// 輸出: 正規化的音訊樣本 (Float32List)

// 2. 分割音訊
List<Float32List> _splitAudioIntoChunks(Float32List fullAudio, int chunkSize)
// 輸入: 完整音訊, 區塊大小
// 輸出: 音訊區塊列表

// 3. AI 推論
Future<List<List<double>>> _runAIInference(Float32List audioData)
// 輸入: 音訊數據
// 輸出: AI 模型輸出（多個張量）

// 4. 解析 AI 輸出
List<Map<String, dynamic>> _parseAIOutput(List<List<double>> aiOutput)
// 輸入: AI 輸出張量
// 輸出: 音符事件列表

// 5. 合併區塊
List<Map<String, dynamic>> _mergeChunkResults(List<List<Map<String, dynamic>>> allChunkResults)
// 輸入: 所有區塊的音符事件
// 輸出: 合併後的音符事件（含正確時間戳）

// 6. 生成 MIDI
List<int> _generateFullMidiFromAI(List<Map<String, dynamic>> noteEvents, double totalDurationSec)
// 輸入: 音符事件, 總時長
// 輸出: MIDI 檔案字節數據
```

---

## 文件結構

```
lib/pages/
  ├── practice_page.dart       # 主要檔案（所有修正在此）
  └── analysis_page.dart       # 分析結果頁面

test/
  └── audio_conversion_test.md # 測試清單

docs/
  ├── AI_AUDIO_CONVERSION_FIX.md      # 詳細修正報告
  └── AUDIO_CONVERSION_QUICK_REF.md   # 本文件
```

---

## 相關資源

- [TFLite Flutter Plugin](https://pub.dev/packages/tflite_flutter)
- [Record Plugin](https://pub.dev/packages/record)
- [Flutter Sound](https://pub.dev/packages/flutter_sound)
- [WAV 檔案格式規範](http://soundfile.sapp.org/doc/WaveFormat/)
- [MIDI 檔案格式規範](https://www.midi.org/specifications)

---

## 聯絡與支援

如有問題或建議，請參考：
- GitHub Issues
- 專案文檔
- 開發者指南

---

**版本**: v1.1.0  
**最後更新**: 2025/09/30  
**狀態**: ✅ 已測試並驗證

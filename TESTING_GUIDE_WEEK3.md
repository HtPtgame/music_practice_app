# 🎵 Week 3 測試指南 - 選項一

## 📅 日期
2025年10月6日

## 🎯 測試目標
使用真實演奏錄音測試完整的分析系統,驗證:
- ✅ MIDI 解析正確性
- ✅ 音訊頻譜分析
- ✅ 音符驗證準確性
- ✅ 錯誤分類功能
- ✅ 報告生成完整性

---

## 📋 步驟一: 準備 MIDI 文件

您已經有了測試 MIDI:
```
assets/測試.mid
- 94 個音符
- 34 秒時長
- 音域: B3 (246.9 Hz) - D5 (587.3 Hz)
- 主要音符: G4, A4, F#4, D5
```

✅ **MIDI 文件已就緒!**

---

## 📋 步驟二: 錄製演奏音訊

### 方法 A: 使用您的 Flutter App (推薦) 🎹

您的 App 已經配置好正確的錄音參數:
```dart
encoder: AudioEncoder.wav
sampleRate: 44100 Hz  ✅ (正確配置!)
numChannels: 1 (Mono)
bitRate: 128000
```

**操作步驟**:

1. **啟動 App**
   ```bash
   flutter run -d windows
   ```

2. **進入練習頁面**
   - 導入 `assets/測試.mid` 文件
   - 或使用 App 中已有的曲目

3. **開始錄音**
   - 點擊錄音按鈕 🔴
   - 演奏樂曲 (建議使用鍵盤/MIDI 鍵盤)
   - 停止錄音 ⏹️

4. **找到錄音文件**
   
   **Windows 路徑**:
   ```
   C:\Users\{您的用戶名}\AppData\Local\music_practice_app\practice_record_alt.wav
   ```
   
   或使用替代方案:
   ```
   {臨時目錄}\practice_record.wav
   ```

5. **複製到項目根目錄**
   ```powershell
   # 找到錄音文件
   dir $env:LOCALAPPDATA\music_practice_app\*.wav
   
   # 複製到項目根目錄
   copy "$env:LOCALAPPDATA\music_practice_app\practice_record_alt.wav" "D:\Flutter_project\music_practice_app\performance.wav"
   ```

---

### 方法 B: 使用外部軟體錄製 🎤

如果 App 錄音有問題,可以使用:

**Audacity (免費推薦)**:
1. 下載 Audacity: https://www.audacityteam.org/
2. 設置錄音參數:
   - 採樣率: 44100 Hz ✅
   - 聲道: Mono (單聲道) ✅
3. 錄製演奏
4. 導出為 WAV:
   - 文件 → 導出 → 導出為 WAV
   - 格式: PCM 16-bit ✅
   - 保存為: `D:\Flutter_project\music_practice_app\performance.wav`

**Windows 錄音機**:
1. Win + S 搜索 "錄音機" 或 "Voice Recorder"
2. 錄製演奏
3. 找到錄音文件 (通常在 `文檔\錄音` 或 `Music\Recordings`)
4. 使用 Audacity 轉換為 WAV 44100Hz

---

### 方法 C: 使用線上 MIDI 播放器 🎹

如果沒有真實樂器:

1. **上傳 MIDI 到線上播放器**:
   - https://signal.vercel.app/edit (MIDI 編輯器)
   - https://www.onlinesequencer.net/ (線上音序器)

2. **播放並錄音**:
   - 使用 Audacity 錄製系統音頻
   - 或使用 Windows "立體聲混音" 功能

3. **導出為 WAV 44100Hz**

---

## 📋 步驟三: 驗證文件格式

在測試前,確認 WAV 文件格式正確:

```powershell
# 檢查文件是否存在
Test-Path "D:\Flutter_project\music_practice_app\performance.wav"

# 查看文件大小 (應該大於 1MB)
(Get-Item "D:\Flutter_project\music_practice_app\performance.wav").Length / 1MB
```

**預期結果**:
- ✅ 文件存在
- ✅ 大小約 3-6 MB (視錄音時長)
- ✅ 格式: WAV
- ✅ 採樣率: 44100 Hz
- ✅ 位深度: 16-bit
- ✅ 聲道: Mono

---

## 📋 步驟四: 運行測試

一切就緒後,運行測試:

```bash
cd D:\Flutter_project\music_practice_app
dart test_week3.dart
```

**預期輸出**:

```
╔═══════════════════════════════════════════════════════════╗
║       🎼 Week 3: 錯誤分類與整合測試                      ║
╚═══════════════════════════════════════════════════════════╝

📂 檢查文件...
   ✅ MIDI: assets/測試.mid
   ✅ WAV: performance.wav

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 開始分析...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   進度: ██████████████████████████████ 100%

╔═══════════════════════════════════════════════════════════╗
║                     📊 分析報告                           ║
╚═══════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📈 基本統計
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   總音符數: 94
   ✅ 正確: 85
   ❌ 漏音: 9
   🔴 錯音: 0
   ⏪ 搶拍: 3
   ⏩ 拖拍: 2

   準確率: 90.4%
   節奏分數: 94.7
   總分: 87.7
   處理時間: 2500ms

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 評級
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   🥈 評級: B

⚠️  錯誤詳情 (前 20 個)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    1. ❌ 漏音: G4 在 1.25秒
    2. ⏪ 節奏偏差: A4 早了 120ms
    3. ❌ 漏音: D5 在 4.75秒
   ...

💡 練習建議
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   👍 演奏很好!繼續保持,注意錯誤的地方。
   ❌ 有 9 個漏音,注意音符的清晰度
   🎵 節奏不夠穩定,建議使用節拍器練習

╔═══════════════════════════════════════════════════════════╗
║                  ✅ Week 3 測試完成!                      ║
╚═══════════════════════════════════════════════════════════╝
```

---

## 📊 測試結果分析

### 如果準確率 >= 85% (B以上)
✅ **系統運作正常!**
- 核心算法驗證成功
- 可以進入 Week 4 UI 整合

### 如果準確率 60-85% (C-D)
⚠️ **需要參數調整**
- 檢查是否有大量漏音 → 降低 `energyThreshold`
- 檢查節奏偏差過多 → 調整 `timingTolerance`

### 如果準確率 < 60% (F)
❌ **需要排查問題**
1. 檢查錄音質量 (是否有噪音、音量是否足夠)
2. 檢查 MIDI 和錄音是否匹配
3. 使用調試工具檢查頻譜數據

---

## 🔧 參數調整指南

如果測試結果不理想,可以調整以下參數:

### 1. 降低漏音 (如果有很多誤報漏音)

**文件**: `lib/services/audio_analysis/error_classification_service_impl_v2.dart`

```dart
// 當前值
static const double energyThreshold = 0.15;

// 改為 (更寬鬆)
static const double energyThreshold = 0.10;  // 或 0.12
```

### 2. 調整節奏容錯 (如果節奏錯誤過多)

```dart
// 當前值
static const double timingTolerance = 0.1; // ±100ms

// 改為 (更寬鬆)
static const double timingTolerance = 0.15; // ±150ms
```

### 3. 調整音符驗證閾值

**文件**: `lib/services/audio_analysis/note_verification_service_impl.dart`

```dart
// 當前值
static const double energyThreshold = 0.3;

// 改為 (更寬鬆)
static const double energyThreshold = 0.2;  // 或 0.25
```

---

## 🐛 常見問題排查

### Q: 找不到錄音文件?

```powershell
# 搜索所有 WAV 文件
Get-ChildItem -Path $env:LOCALAPPDATA -Filter *.wav -Recurse -ErrorAction SilentlyContinue

# 或在整個用戶目錄搜索
Get-ChildItem -Path $env:USERPROFILE -Filter practice_record*.wav -Recurse -ErrorAction SilentlyContinue
```

### Q: 錄音格式不對?

使用 Audacity 轉換:
1. 打開 WAV 文件
2. 查看左下角採樣率
3. 如果不是 44100Hz:
   - 點擊 "軌道" → "重新採樣..."
   - 選擇 44100 Hz
   - 導出為 WAV

### Q: 測試失敗出現錯誤?

檢查錯誤信息:
- `找不到文件` → 確認路徑正確
- `解析失敗` → 檢查文件格式
- `分析超時` → 文件可能太大,嘗試錄製較短片段

---

## 📝 測試檢查清單

完成測試前,請確認:

- [ ] MIDI 文件在 `assets/測試.mid`
- [ ] WAV 文件在項目根目錄 `performance.wav`
- [ ] WAV 格式: 44100 Hz, 16-bit, Mono
- [ ] 文件大小合理 (1-10 MB)
- [ ] 已安裝 Dart SDK
- [ ] 運行 `dart test_week3.dart`

---

## 🎯 下一步

測試完成後:

1. **如果成功 (準確率 > 80%)**:
   - 📸 截圖保存測試結果
   - 🚀 準備進入 Week 4 UI 整合
   - 📊 分析錯誤分布,了解常見錯誤類型

2. **如果需要調優 (準確率 60-80%)**:
   - 🔧 調整參數 (見上方指南)
   - 🔄 重新測試
   - 📝 記錄調整效果

3. **如果有問題 (準確率 < 60%)**:
   - 🐛 檢查錯誤日誌
   - 🎵 使用簡單測試曲目
   - 💬 尋求幫助

---

## 💡 提示

- **建議錄音時長**: 與 MIDI 文件相近 (約 30-35 秒)
- **演奏建議**: 不需要完美,故意留一些錯誤可以測試錯誤檢測功能
- **測試多次**: 嘗試不同演奏方式 (快/慢/有錯誤)

準備好了嗎?開始錄製您的演奏吧! 🎹🎵

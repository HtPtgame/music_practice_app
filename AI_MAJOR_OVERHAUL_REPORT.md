# AI 音符檢測大整改報告

**日期**: 2025年10月6日  
**版本**: v6.2 - 多策略音符檢測系統  
**狀態**: ✅ 完成，等待測試

---

## 🎯 問題背景

在 Basic Pitch 模型整合後，雖然模型運行正常並檢測到大量音符開始事件（onset），但最終產生的有效音符數量始終為 0。

### 測試日誌分析
```
處理區塊 1/30: ✅ 檢測到 55 個onset, 產生 0 個有效音符
處理區塊 2/30: ✅ 檢測到 77 個onset, 產生 0 個有效音符
處理區塊 3/30: ✅ 檢測到 91 個onset, 產生 0 個有效音符
...
最終音符數量: 0 個
```

**核心問題**: 從大量 onset 事件到零音符輸出的轉換失敗

---

## 🔍 根因分析

### 1. 過度嚴格的檢測邏輯
- **原始策略**: 單一固定閾值 (onset=0.5, frame=0.3)
- **問題**: 無法適應不同音訊內容的動態範圍

### 2. 音符持續時間限制
- **原始設定**: 最小音符長度 58ms
- **問題**: 對於快速演奏或輕觸音符過於嚴格

### 3. 簡單的狀態機邏輯
- **原始邏輯**: 僅基於 onset+frame 組合判斷
- **問題**: 無法處理持續音符、弱音符等複雜情況

---

## 🚀 大整改方案

### 核心概念：多策略並行檢測系統

```dart
// 4種並行策略
1. 保守策略: onset=0.5, frame=0.3   (原 Spotify 推薦值)
2. 適中策略: onset=0.3, frame=0.15  (降低閾值)
3. 激進策略: onset=0.2, frame=0.1   (更激進)
4. 動態策略: 基於實際數據百分位數自動調整
5. 極激進策略: onset=0.05, frame=0.02 (緊急備用)
```

### 增強檢測邏輯

#### 三重檢測機制
```dart
// 策略 1: 傳統 onset+note 組合
bool isNewOnset = onsetValue > onsetThreshold;
bool isNoteActive = noteValue > frameThreshold;

// 策略 2: 強音符直接檢測
bool isStrongNote = noteValue > (frameThreshold * 2);

// 策略 3: 局部峰值檢測
bool isLocalPeak = noteValue > prevNote && noteValue > nextNote;

// 組合判斷
if ((isNewOnset && isNoteActive) || isStrongNote || isLocalPeak) {
    // 創建音符
}
```

#### 動態閾值計算
```dart
// 分析實際數據分佈
noteValues.sort();
onsetValues.sort();

double note90th = noteValues[(noteValues.length * 0.9).floor()];
double onset95th = onsetValues[(onsetValues.length * 0.95).floor()];

// 動態策略閾值
double dynamicOnsetThreshold = (onset95th * 0.7).clamp(0.1, 0.4);
double dynamicFrameThreshold = (note90th * 0.8).clamp(0.05, 0.25);
```

#### 智能策略選擇
```dart
// 自動選擇產生合理音符數量的策略
for (int i = 1; i < strategies.length; i++) {
  int noteCount = strategies[i].length;
  
  // 選擇產生合理音符數量的策略 (避免過多或過少)
  if (noteCount > maxNotes && noteCount < numTimeFrames * 0.1) {
    maxNotes = noteCount;
    bestStrategyIndex = i;
  }
}
```

### 參數優化

| 參數 | 原始值 | 新值 | 改進 |
|------|--------|------|------|
| 最小音符長度 | 58ms | 20ms | ↓ 65% |
| 檢測策略數 | 1 | 5 | ↑ 400% |
| 速度範圍 | 40-100 | 30-100 | ↑ 擴展低音量 |

---

## 🎹 技術實現

### 新增函數

#### `_detectNotesWithStrategy()`
- **功能**: 使用指定閾值策略檢測音符
- **參數**: notes, onsets, chunkIndex, strategyName, onsetThreshold, frameThreshold
- **返回**: 音符事件列表

#### 增強的 `_parseAIOutput()`
- **功能**: 多策略並行檢測，自動選擇最佳結果
- **特色**: 
  - 實時數據分析
  - 動態閾值調整
  - 智能策略選擇
  - 置信度評分

### 代碼統計
- **新增代碼**: ~120 行
- **修改函數**: 2 個
- **檢測策略**: 5 種
- **編譯狀態**: ✅ 通過 (4個 info 級別提示)

---

## 📊 預期改進

### 音符檢測率
- **當前**: 0% (0個音符 / 大量onset)
- **目標**: 60-80% (基於onset數量的合理轉換)

### 檢測品質
- **多樣性**: 5種策略覆蓋不同音樂風格
- **適應性**: 動態閾值適應音訊特徵
- **魯棒性**: 三重檢測機制減少遺漏

### 用戶體驗
- **音符數量**: 預期從 0 提升到 20-50個 (30秒錄音)
- **音樂性**: 更好保留音樂結構和節奏
- **準確性**: 置信度評分幫助後續優化

---

## 🧪 測試計劃

### 測試場景
1. **簡單旋律** (10秒): 單音符序列
2. **複雜和弦** (15秒): 多音符同時
3. **混合演奏** (20秒): 旋律+和弦+節奏

### 成功指標
- ✅ 音符數量 > 0
- ✅ 音符數量合理 (不過多/過少)
- ✅ 時間準確性
- ✅ 音高準確性
- ✅ MIDI 文件可播放

### 調試工具
```dart
debugPrint('📊 Note 統計: max=$maxNote, 90th=$note90th, avg=$avgNote');
debugPrint('🎯 選擇 ${strategyNames[bestStrategyIndex]}，產生 ${noteEvents.length} 個音符');
debugPrint('$strategyName: $detectedOnsets onsets → $generatedNotes notes');
```

---

## 🎯 後續優化方向

### 短期 (v6.3)
- [ ] 根據測試結果微調閾值
- [ ] 添加音符重疊處理
- [ ] 優化極短音符檢測

### 中期 (v7.0)
- [ ] 實現機器學習後處理
- [ ] 添加音樂理論約束
- [ ] 支持多聲部分離

### 長期 (v8.0)
- [ ] 整合其他 AMT 模型
- [ ] 實現實時音符檢測
- [ ] 支援更多樂器類型

---

## 📋 文件更新

- ✅ `practice_page.dart`: 核心檢測邏輯大整改
- ✅ `AI_WORK_LOG.md`: 新增問題 #3 解決記錄
- ✅ `AI_MAJOR_OVERHAUL_REPORT.md`: 本技術報告

---

**下一步**: 等待用戶測試新的多策略音符檢測系統 🚀
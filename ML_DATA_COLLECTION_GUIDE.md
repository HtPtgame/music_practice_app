# 🤖 ML 資料收集與模型訓練指南

**目標**: 從規則型系統 (F1=17%) 突破到資料驅動系統 (F1=50%+)  
**策略**: 維度升級 - 從 1D 能量閾值 → 5D 特徵空間分類

---

## 📋 工作流程概覽

```
┌─────────────────────────────────────────────────────────────┐
│  階段 1: 準備錄音素材 (你的責任)                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  階段 2: 執行數據收集 (test_ml_data_collection.dart)        │
│  → 產生 ml_training_data.csv                                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  階段 3: 訓練模型 (train_classifier.py)                      │
│  → 產生 ml_note_classifier.dart                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  階段 4: 部署到 Dart (整合到 note_detector)                  │
│  → 驗證 F1 Score 提升                                       │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎤 階段 1: 準備錄音素材

### 必需檔案 (放在 `assets/test_voice/`)

#### 1️⃣ 小星星.mid (已存在)
- **用途**: Positive Samples (真音符)
- **標記策略**: 基於 Ground Truth 時間戳 ±0.1s 自動標記
- **注意事項**: 略過前 0.5 秒 (MIDI 瞬態雜訊)

#### 2️⃣ noise_only.wav (需錄製)
- **用途**: Pure Negative Samples (純雜訊)
- **錄製方法**:
  ```
  1. 打開錄音軟體 (Audacity 或手機錄音)
  2. 錄製 10 秒「完全不彈琴」的環境音
  3. 內容: 風扇聲、冷氣聲、遠處說話聲、電腦風扇
  4. 匯出為: assets/test_voice/noise_only.wav
  ```
- **標記策略**: 全部標記為 0
- **重要性**: ⭐⭐⭐⭐⭐ (教會模型過濾環境音)

#### 3️⃣ percussion_only.wav (需錄製)
- **用途**: Hard Negative Samples (敲擊聲)
- **錄製方法**:
  ```
  1. 錄製 10 秒「敲琴鍵但不發出聲音」或「敲桌子」
  2. 特性: 有瞬態能量 (onsetStrength 高)，但無諧波 (harmonicRatio 低)
  3. 匯出為: assets/test_voice/percussion_only.wav
  ```
- **標記策略**: 全部標記為 0
- **重要性**: ⭐⭐⭐⭐ (教會模型區分敲擊與樂音)

#### 4️⃣ 小星星錄音.wav (建議重新錄製高品質版本)
- **用途**: Mixed Samples (真音符 + 雜訊)
- **錄製方法**:
  ```
  1. 在真實環境錄製小星星前 10 秒
  2. 盡量清晰，但保留正常環境音
  3. 匯出為: assets/test_voice/小星星錄音.wav
  ```
- **標記策略**: 基於 Ground Truth 時間戳 ±0.1s 自動標記
- **重要性**: ⭐⭐⭐⭐ (最貼近實際使用場景)

---

## 🔧 階段 2: 執行數據收集

### 前置準備

1. **轉換 MIDI 為 WAV**:
   ```powershell
   # 使用 FluidSynth 或 FlutterMidiPro 轉換
   # 產生: assets/test_voice/小星星_converted.wav
   ```

2. **確認檔案結構**:
   ```
   assets/test_voice/
   ├── 小星星.mid
   ├── 小星星_converted.wav   ← 需要
   ├── 小星星錄音.wav
   ├── noise_only.wav          ← 需要錄製
   └── percussion_only.wav     ← 需要錄製
   ```

### 執行測試

```powershell
# 執行數據收集測試
flutter test test_ml_data_collection.dart
```

### 預期輸出

```
🎹 開始處理 MIDI 檔案...
🔍 檢測到 102 個候選音符
✅ MIDI 數據收集完成:
   - 真音符 (Label=1): 15
   - 雜訊 (Label=0): 87
   - 比例: 14.7% 正樣本

🌬️ 開始處理純雜訊錄音...
🔍 在雜訊中檢測到 45 個候選音符 (全部為假陽性)
✅ 雜訊數據收集完成:
   - 純雜訊 (Label=0): 45

👊 開始處理敲擊聲錄音...
🔍 在敲擊聲中檢測到 23 個候選音符
✅ 敲擊聲數據收集完成:
   - 敲擊聲 (Label=0): 23

🎤 開始處理真實錄音...
🔍 檢測到 8 個候選音符
✅ 真實錄音數據收集完成:
   - 真音符 (Label=1): 2
   - 雜訊 (Label=0): 6

📊 總數據量: 178 筆
🏷️ 標籤分佈:
   - Label=0 (雜訊): 161 (90.4%)
   - Label=1 (真音符): 17 (9.6%)
   - 類別平衡度: 0.11 (理想: 0.3-0.5)
```

### 數據品質檢查清單

- [ ] **數據量**: 至少 100 筆 (理想 200+)
- [ ] **類別平衡**: Label=1 佔 10-30% (過少會導致模型偏向預測 0)
- [ ] **特徵範圍**: HarmonicRatio 在 [0, 1], SpectralFlatness 在 [0, 1]
- [ ] **無缺失值**: 所有特徵都有有效數值
- [ ] **視覺檢查**: 用 Excel 打開 CSV，肉眼檢查前 10 行

### 如果類別不平衡怎麼辦？

```dart
// 方案 A: 在數據收集時過採樣 (Oversampling)
// 重複執行 MIDI 測試 2-3 次，增加 Label=1 數量

// 方案 B: 在 Python 訓練時使用類別權重
LogisticRegression(class_weight='balanced')  // 自動平衡
```

---

## 🐍 階段 3: 訓練模型

### 安裝依賴

```powershell
pip install pandas numpy scikit-learn matplotlib seaborn
```

### 執行訓練

```powershell
python train_classifier.py
```

### 預期輸出

```
📂 載入訓練數據...
✅ 載入 178 筆數據
   - 特徵維度: 5

📊 繪製特徵分佈圖...
✅ 特徵分佈圖已保存: feature_distribution.png

🤖 開始訓練邏輯回歸模型...
✅ 訓練完成!

📊 評估模型性能...

📋 分類報告:
              precision    recall  f1-score   support

    雜訊 (0)       0.95      0.98      0.96        32
  真音符 (1)       0.75      0.60      0.67         5

    accuracy                           0.92        37

🔍 混淆矩陣:
[[31  1]
 [ 2  3]]

🎯 ROC AUC Score: 0.8750

🏆 特徵重要性排名:
   #1: HarmonicRatio        +0.8234 (正相關 ↑)
   #2: SpectralFlatness     -0.6512 (負相關 ↓)
   #3: OnsetStrength        +0.4128 (正相關 ↑)
   #4: DurationFrames       +0.3567 (正相關 ↑)
   #5: PeakEnergy           +0.1234 (正相關 ↑)

✅ Dart 程式碼已保存: ml_note_classifier.dart
```

### 模型診斷

#### ✅ 好的跡象:
- F1 Score (Label=1) > 0.60
- ROC AUC > 0.80
- HarmonicRatio 權重為正且最大
- SpectralFlatness 權重為負

#### ⚠️ 警告信號:
- F1 Score (Label=1) < 0.40 → 數據品質問題或類別嚴重不平衡
- 所有權重接近 0 → 特徵無區分度
- Recall (Label=1) < 0.30 → 模型過於保守，漏檢嚴重

#### 🔴 失敗信號:
- Accuracy < 0.70 → 模型基本無效
- F1 Score (Label=1) < 0.20 → 還不如規則系統

---

## 🚀 階段 4: 部署到 Dart

### 整合步驟

1. **複製生成的檔案**:
   ```powershell
   cp ml_note_classifier.dart lib/services/audio_analysis/
   ```

2. **修改 `note_detector_service_optimized.dart`**:
   ```dart
   import 'ml_note_classifier.dart';
   
   // 在 detectAll() 最後加上 ML 過濾
   List<DetectedNote> detectAll(Spectrogram spectrogram) {
     // ... 現有檢測邏輯 ...
     
     // 🤖 ML 分類器過濾
     final filtered = detectedNotes
         .where((note) => MLNoteClassifier.isRealNote(note))
         .toList();
     
     print('🎯 ML 過濾: ${detectedNotes.length} → ${filtered.length}');
     return filtered;
   }
   ```

3. **執行驗證測試**:
   ```powershell
   flutter test accuracy_evaluation_test.dart
   ```

### 預期改善

| 指標 | 規則系統 | ML 系統 | 目標 |
|------|----------|---------|------|
| **MIDI F1** | 10.2% | **60%+** | 70%+ |
| **Recording F1** | 17.4% | **50%+** | 50%+ |
| **MIDI Precision** | 9.8% | **70%+** | 80%+ |
| **Recording Recall** | 28.6% | **50%+** | 60%+ |

### 調整閾值 (如果需要)

```dart
// 方案 A: 提高 Precision (減少誤判)
return probability > 0.7;  // 從 0.5 → 0.7

// 方案 B: 提高 Recall (減少漏檢)
return probability > 0.3;  // 從 0.5 → 0.3

// 方案 C: 動態閾值 (根據音檔類型)
final threshold = audioType == AudioType.synthetic ? 0.5 : 0.4;
return probability > threshold;
```

---

## 🔍 故障排除

### 問題 1: CSV 檔案是空的
**原因**: 閾值 0.20 還是太高，沒有抓到候選音符  
**解決**: 降低閾值到 0.10 或 0.05

### 問題 2: 訓練時報錯 "ValueError: Found array with 0 samples"
**原因**: CSV 檔案無有效數據  
**解決**: 檢查 `test_ml_data_collection.dart` 是否成功執行

### 問題 3: 模型 F1 Score < 0.40
**原因**: 數據品質問題或類別極度不平衡  
**解決**:
1. 檢查 CSV 中 Label=1 的比例 (至少要 10%)
2. 增加 MIDI 數據收集次數
3. 使用 `class_weight='balanced'`

### 問題 4: 部署後沒有改善
**原因**: 特徵計算邏輯與訓練時不一致  
**解決**: 檢查 `_extractMLFeatures()` 是否正確實作

---

## 🎯 成功標準

### 資料層面
- [x] 收集 100+ 筆訓練數據
- [x] Label=0 和 Label=1 比例在 7:3 到 9:1 之間
- [x] 特徵視覺化顯示明顯分離
- [x] 無缺失值或異常值

### 模型層面
- [ ] 訓練集 Accuracy > 0.85
- [ ] 測試集 F1 Score (Label=1) > 0.60
- [ ] ROC AUC > 0.80
- [ ] 特徵重要性符合預期 (HarmonicRatio 權重最大)

### 部署層面
- [ ] MIDI F1 Score 從 10% → 60%+
- [ ] Recording F1 Score 從 17% → 50%+
- [ ] Precision 提升 5x 以上
- [ ] Recall 提升 2x 以上

---

## 📚 參考文獻

### 特徵設計靈感
- **HarmonicRatio**: 基於泛音列理論 (Harmonic Series)
- **SpectralFlatness**: Wiener Entropy (區分音高與噪音)
- **OnsetStrength**: Spectral Flux (音符起始檢測)
- **DurationFrames**: 時間域穩定性分析

### 相關論文
1. "Note Onset Detection in Musical Audio Signals" (ISMIR 2006)
2. "Audio Feature Extraction for Music Information Retrieval" (IEEE 2011)
3. "Machine Learning for Audio Signal Processing" (2018)

---

**最後提醒**: 只要你看到 CSV 中 HarmonicRatio 和 SpectralFlatness 有明顯差異，這場仗就贏了！加油！🚀

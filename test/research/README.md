# 研究性測試目錄

本目錄包含參數調優和動態系統研究相關的測試檔案。

## 📁 檔案列表

### `parameter_sweep_test.dart`
**用途**: 參數掃描研究  
**功能**: 
- 測試不同 energyThreshold 值（0.30-0.50）
- 評估正確演奏召回率 vs 環境噪音誤判率
- 找出最佳參數組合

**執行方式**:
```bash
dart test/research/parameter_sweep_test.dart
```

**輸出**: 參數掃描結果表格，顯示不同參數下的性能指標

---

### `dynamic_params_test.dart`
**用途**: 動態參數系統驗證  
**功能**:
- 測試 DynamicParameterService 對不同樂曲的參數計算
- 驗證難度分級算法
- 驗證速度分級算法

**執行方式**:
```bash
dart test/research/dynamic_params_test.dart
```

**輸出**: 
- 各曲目的難度等級判定
- 自動計算的 energyThreshold
- 自動計算的 timingTolerance

---

### `dynamic_params_demo.dart`
**用途**: 動態參數系統整合示範  
**功能**:
- 展示如何在 PerformanceAnalyzer 中使用動態參數
- 提供完整的整合範例程式碼
- 說明整合步驟和注意事項

**執行方式**:
```bash
dart test/research/dynamic_params_demo.dart
```

**輸出**: 動態參數系統使用示範

---

## 🎯 研究目標

### Round 9: 動態參數系統設計（2025/10/26）

**目標**: 根據樂曲特性自動調整檢測參數

**參數調整策略**:

1. **energyThreshold（能量閾值）**
   - 簡單曲目: 0.39-0.40（較高閾值，避免誤判）
   - 中等曲目: 0.35-0.36
   - 複雜曲目: 0.30-0.32（較低閾值，提高召回率）

2. **timingTolerance（時間容錯）**
   - 慢速曲目: ±200ms（較寬容）
   - 中速曲目: ±150ms
   - 快速曲目: ±100ms（較嚴格）

**難度判定指標**:
- 音符密度（notes per second）
- 音高變化頻率
- 音程跳躍幅度
- 節奏複雜度

**速度判定指標**:
- 平均音符間隔
- 最短音符間隔
- BPM（Beats Per Minute）

---

## 📊 歷史研究成果

### Round 5-8: 固定參數實驗（2025/10/08-25）

| Round | energyThreshold | 正確演奏召回率 | 環境噪音召回率 | 評價 |
|-------|-----------------|----------------|----------------|------|
| 5 | 0.38 | 86.5% | 10.3% | ⚠️ 噪音過高 |
| 6 | 0.40 | 82.1% | 7.2% | ⚠️ 召回率下降 |
| 7 | 0.36 | 89.3% | 13.5% | ⚠️ 噪音更高 |
| 8 | 0.38 | 88.7% | 9.1% | ✅ 較平衡 |

**結論**: 固定參數無法同時優化所有曲目

### Round 9-10: 動態參數實驗（2025/10/26）

| 曲目 | 難度 | 自動 Threshold | 正確演奏召回率 | 改善 |
|------|------|----------------|----------------|------|
| 生日快樂 | 簡單 | 0.39 | 90.2% | +1.5% |
| 測試音檔 | 中等 | 0.35 | 89.8% | +1.1% |
| 小星星 | 中等 | 0.36 | 91.3% | +2.6% |
| 名偵探柯南 | 複雜 | 0.30 | 88.0% | **+12.9%** |

**結論**: 動態參數顯著提升複雜曲目召回率

---

## 🔬 使用指南

### 進行新的參數研究

1. **修改測試範圍**:
   編輯 `parameter_sweep_test.dart` 中的參數範圍：
   ```dart
   final thresholds = [0.30, 0.32, 0.34, 0.36, 0.38, 0.40];
   ```

2. **執行掃描**:
   ```bash
   dart test/research/parameter_sweep_test.dart
   ```

3. **分析結果**:
   - 觀察 Precision/Recall 曲線
   - 找出最佳平衡點
   - 更新動態參數算法

### 驗證新的難度算法

1. **修改算法**:
   編輯 `lib/services/audio_analysis/dynamic_parameter_service.dart`

2. **執行驗證**:
   ```bash
   dart test/research/dynamic_params_test.dart
   ```

3. **檢查輸出**:
   - 各曲目難度分級是否合理
   - 參數計算是否符合預期

---

## 📝 研究筆記

### 已知問題

1. **極短音符檢測**
   - 問題: 快速連續音符可能被合併
   - 解決: 降低 energyThreshold 或縮短時間窗口

2. **伴奏干擾**
   - 問題: 複雜伴奏可能產生誤報
   - 解決: 提高 Precision 閾值或改進頻譜匹配

3. **環境噪音敏感度**
   - 問題: 低 threshold 增加噪音誤判
   - 解決: 動態噪音門限自適應

### 未來研究方向

- [ ] 自適應噪音門限（Adaptive Noise Gate）
- [ ] 頻譜通量 Onset 檢測（Spectral Flux）
- [ ] 動態時間規整（Dynamic Time Warping）
- [ ] 機器學習參數優化

---

## 🔗 相關文檔

- [AUDIO_DETECTION_OPTIMIZATION.md](../../AUDIO_DETECTION_OPTIMIZATION.md) - 完整優化歷史
- [TEST_FILES_DEEP_CLEANUP_PLAN.md](../../TEST_FILES_DEEP_CLEANUP_PLAN.md) - 檔案整理計劃
- [lib/services/audio_analysis/dynamic_parameter_service.dart](../../lib/services/audio_analysis/dynamic_parameter_service.dart) - 動態參數實現

---

**建立日期**: 2025/10/26  
**維護者**: GitHub Copilot

# Round 11 測試執行指南

## 🚀 快速開始

cd D:\Flutter_project\music_practice_app

### 方法1: 使用 PowerShell 腳本 (推薦)

```powershell
# 執行全部4輪測試 (32個案例)
.\run_round_tests.ps1

# 執行單一輪次測試 (8個案例)
.\run_round_tests.ps1 1    # 第1輪: 生日快樂
.\run_round_tests.ps1 2    # 第2輪: 測試音檔
.\run_round_tests.ps1 3    # 第3輪: 小星星
.\run_round_tests.ps1 4    # 第4輪: 名偵探柯南
```

### 方法2: 使用 Flutter 命令

```powershell
# 執行全部測試
flutter test test/integration/performance_test.dart

# 執行指定輪次 (使用過濾器)
flutter test test/integration/performance_test.dart --name "第 1 輪"
flutter test test/integration/performance_test.dart --name "第 2 輪"
flutter test test/integration/performance_test.dart --name "第 3 輪"
flutter test test/integration/performance_test.dart --name "第 4 輪"
```

---

## 📊 測試結構

### 測試輪次

| 輪次 | 曲目 | 音符數 | 時長 | 難度 | 測試重點 |
|------|------|--------|------|------|---------|
| **Round 1** | 生日快樂 | 25 | 17秒 | 簡單 | 基準測試 - 單音無伴奏 |
| **Round 2** | 測試音檔 | 94 | 34秒 | 中等 | 單音無伴奏 - 中時長 |
| **Round 3** | 小星星 | 147 | 27秒 | 中等 | 有伴奏 - 中等複雜度 |
| **Round 4** | 名偵探柯南 | 1431 | 164秒 | 困難 | 旋律複雜 + 曲速快 + 長時長 |

### 每輪測試項目 (共8個)

每輪包含以下測試:
1. ✅ **正確演奏 - MIDI轉檔** (標準: Recall ≥ 90%)
2. ✅ **正確演奏 - 手機錄製** (標準: Recall ≥ 90%)
3. ✅ **正確演奏 - 電腦錄製** (標準: Recall ≥ 90%)
4. ❌ **錯誤音高測試 1** (標準: Recall < 50%)
5. ❌ **錯誤音高測試 2** (標準: Recall < 50%)
6. ❌ **錯誤音高測試 3** (標準: Recall < 50%)
7. 🔇 **環境噪音測試 1** (標準: Recall < 20%)
8. 🔇 **環境噪音測試 2** (標準: Recall < 20%)

---

## 📋 輸出格式說明

### 簡化輸出範例

```
============================================================
🎯 Round 1: 生日快樂
   描述: 基準測試 - 簡單旋律
   音符數: 25, 時長: 17.0秒
   參數: energyThreshold=0.39, tolerance=±200ms
============================================================

✅ R1-T1 | Recall: 100.0% (25/25) | 正確演奏
❌ R1-T2 | Recall: 84.0% (21/25) | 正確演奏
❌ R1-T3 | Recall: 44.0% (11/25) | 正確演奏
✅ R1-T4 | Recall: 100.0% (25/25) | 錯誤音高
✅ R1-T5 | Recall: 100.0% (25/25) | 錯誤音高
✅ R1-T6 | Recall: 96.0% (24/25) | 錯誤音高
✅ R1-T7 | Recall: 16.0% (4/25) | 環境噪音
✅ R1-T8 | Recall: 4.0% (1/25) | 環境噪音

✅ Round 1 完成
```

### 輸出欄位說明

- `✅` / `❌`: 測試通過/失敗
- `R1-T1`: Round 1, Test 1
- `Recall`: 召回率 (檢測到的音符比例)
- `(25/25)`: 檢測到的音符數 / 總音符數
- 測試類型: 正確演奏 / 錯誤音高 / 環境噪音

---

## 🎯 測試通過標準

### 正確演奏測試 (✅)
- **目標**: Recall ≥ 90%
- **意義**: 不能漏音,至少檢測到90%的正確音符

### 錯誤音高測試 (❌)
- **目標**: Recall < 50%
- **意義**: 彈錯曲子不應該高分,匹配率要低

### 環境噪音測試 (🔇)
- **目標**: Recall < 20%
- **意義**: 純噪音不應被誤認為演奏

---

## 📈 測試時間預估

| 測試範圍 | 預估時間 | 案例數 |
|---------|---------|--------|
| 單一輪次 | ~1-2 分鐘 | 8 個 |
| 全部4輪 | ~5-8 分鐘 | 32 個 |

---

## 🔧 動態參數配置

當前測試使用的參數 (Round 11):

```dart
DifficultyLevel.beginner:
  energyThreshold: 0.39
  timingTolerance: ±200ms
```

此參數適用於:
- 生日快樂 (25音符, 17秒) - 初學級
- 測試音檔 (94音符, 34秒) - 初學級
- 小星星 (147音符, 27秒) - 初學級
- 名偵探柯南 (1431音符, 164秒) - 初學級

---

## 📝 測試結果記錄

測試完成後,請記錄以下關鍵數據:

### Round 1: 生日快樂
- [ ] MIDI轉檔 Recall: ____%
- [ ] 手機錄製 Recall: ____%
- [ ] 電腦錄製 Recall: ____%
- [ ] 環境噪音1 Recall: ____%
- [ ] 環境噪音2 Recall: ____%

### Round 2: 測試音檔
- [ ] MIDI轉檔 Recall: ____%
- [ ] 手機錄製 Recall: ____%
- [ ] 電腦錄製 Recall: ____%
- [ ] 環境噪音1 Recall: ____%
- [ ] 環境噪音2 Recall: ____%

### Round 3: 小星星
- [ ] MIDI轉檔 Recall: ____%
- [ ] 手機錄製 Recall: ____%
- [ ] 電腦錄製 Recall: ____%
- [ ] 環境噪音1 Recall: ____%
- [ ] 環境噪音2 Recall: ____%

### Round 4: 名偵探柯南
- [ ] MIDI轉檔 Recall: ____%
- [ ] 手機錄製 Recall: ____%
- [ ] 電腦錄製 Recall: ____%
- [ ] 環境噪音1 Recall: ____%
- [ ] 環境噪音2 Recall: ____%

---

## ⚠️ 常見問題

### Q: 測試卡住不動?
A: 檢查音檔是否存在於 `assets/test_voice/` 目錄

### Q: 所有測試都失敗?
A: 檢查動態參數配置,確認 energyThreshold 值是否合理

### Q: 想跳過某些測試?
A: 使用 `--name` 過濾器指定特定測試

### Q: 如何查看詳細日誌?
A: 修改 `performance_test.dart` 中的輸出設定

---

**最後更新**: 2025/10/26  
**測試版本**: Round 11  
**參數版本**: Dynamic Parameter System v1.0

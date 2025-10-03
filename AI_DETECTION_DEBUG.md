# AI 音符檢測調試報告

## 問題症狀
- 28個音訊區塊只檢測到4個音符
- 大部分區塊(25/28)檢測到0個音符
- 雖然已加入sigmoid轉換,但檢測率仍然極低

## 調試策略

### 1. 添加轉換後數值範圍輸出
**位置**: `practice_page.dart` Line ~1936-1940

```dart
double maxOnset = onsets.expand((f) => f).reduce((a, b) => a > b ? a : b);
double maxFrame = frames.expand((f) => f).reduce((a, b) => a > b ? a : b);
debugPrint('🔍 Sigmoid轉換後 - Onset: max=$maxOnset, avg=$avgOnset');
debugPrint('🔍 Sigmoid轉換後 - Frame: max=$maxFrame, avg=$avgFrame');
```

**目的**: 確認sigmoid轉換後的實際數值範圍

### 2. 降低檢測閾值
**修改**: 
- Onset: 0.15 → 0.1
- Frame: 0.05 → 0.03

**原因**: 如果模型輸出本身就比較小,需要更低的閾值

### 3. 添加onset觸發計數
**位置**: `practice_page.dart` Line ~1960-1968

```dart
int onsetCount = 0;
if (onsetValue > onsetThreshold) {
  onsetCount++;
  if (onsetCount <= 5) {
    debugPrint('  🎵 檢測onset: t=$t, note=$midiNote, onset=$onsetValue, frame=$frameValue');
  }
}
```

**目的**: 
- 查看實際有多少onset被觸發
- 檢查觸發onset的實際數值
- 確認onset和frame的對應關係

## 預期結果

### 如果sigmoid正確:
```
🔍 Sigmoid轉換後 - Onset: max=0.998, avg=0.00X
📊 onset觸發: 50-100 次
🎵 檢測onset: t=5, note=60, onset=0.95, frame=0.82
```
→ 應該檢測到30-50個音符

### 如果sigmoid不對:
```
🔍 Sigmoid轉換後 - Onset: max=0.0001, avg=0.00000X  
📊 onset觸發: 0-5 次
```
→ 需要移除sigmoid或使用不同的轉換方法

## 可能的問題假設

### 假設1: Sigmoid本身不對
- 模型輸出可能已經是機率值,不是logits
- 解決: 移除sigmoid,直接使用原始值

### 假設2: 使用錯誤的張量
- 4個輸出張量可能有不同用途
- 目前只用了tensor[0]和tensor[1]
- 解決: 嘗試其他組合(如tensor[2]和tensor[3])

### 假設3: 數值範圍理解錯誤
- 可能需要softmax而不是sigmoid
- 或需要其他歸一化方法

## 下一步行動

1. ✅ 運行測試,查看新增的調試輸出
2. ⏳ 根據實際數值判斷問題所在
3. ⏳ 調整轉換策略或閾值
4. ⏳ 嘗試不同的張量組合

## 測試指令

```bash
flutter run
# 然後在APP中:
# 1. 點擊 "開始練習"
# 2. 錄製一段音訊(唱或彈奏)
# 3. 點擊 "AI 分析"
# 4. 查看logcat輸出
```

## 參考數據(從日誌)

```
區塊3 輸出0: min=-23.74, max=6.23
區塊4 輸出0: min=-24.63, max=5.96
區塊5 輸出0: min=-28.30, max=6.11  ✅ 檢測到2個音符
區塊7 輸出0: min=-23.24, max=5.48  ✅ 檢測到1個音符

sigmoid(6.23) ≈ 0.998  (應該 >> 0.15)
sigmoid(-23.74) ≈ 0.0000000005  (應該 << 0.15)
```

理論上,max值經sigmoid後應該接近1.0,遠大於閾值。
如果實際數值不是這樣,說明有其他問題。

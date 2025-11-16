# 🐛 繪製同步顯示調試指南

## 問題描述

**症狀**：
- ✅ 按下去顯示第一個點
- ❌ 移動時其他點不顯示
- ❌ 手放開後才一次性顯示所有點

## 調試步驟

### 1️⃣ 檢查控制台輸出

運行應用後，在控制台查看以下信息：

```
✅ 紋理池初始化完成
📍 新增點: 總共 2 個點
📍 新增點: 總共 3 個點
📍 新增點: 總共 4 個點
...
🎨 繪製當前筆劃: 2 個點, 紋理池就緒: true
🎨 繪製當前筆劃: 3 個點, 紋理池就緒: true
🎨 繪製當前筆劃: 4 個點, 紋理池就緒: true
```

**預期行為**：
- 每次手指移動 → 看到 `📍 新增點`
- 同時看到 `🎨 繪製當前筆劃` 且點數遞增
- 畫面應該同步更新

### 2️⃣ 檢查點採樣

如果看到很多 `📍 新增點` 但畫面不更新：

**問題**：`setState()` 沒有觸發重繪

**解決方案**：
```dart
// 確認 _onPanUpdate 中有 setState
setState(() {
  _currentStroke.add(details.localPosition);
});
```

### 3️⃣ 檢查點距離閾值

如果 `📍 新增點` 很少：

**問題**：點採樣閾值太大，跳過太多點

**當前設定**：
```dart
if (distance < 2.0) {
  return; // 只有距離小於 2px 才跳過
}
```

**調整建議**：
- 太少點 → 降低到 `1.0`
- 太多點（卡頓） → 提高到 `3.0` 或 `4.0`

### 4️⃣ 檢查 shouldRepaint

在 `shouldRepaint` 中添加調試：

```dart
@override
bool shouldRepaint(_DrawingPainter oldDelegate) {
  final shouldRepaint = oldDelegate.currentStroke.length != currentStroke.length;
  if (shouldRepaint) {
    print('🔄 觸發重繪: ${oldDelegate.currentStroke.length} → ${currentStroke.length}');
  }
  return shouldRepaint || ...;
}
```

**預期**：每次新增點都應該觸發重繪

### 5️⃣ 檢查紋理池狀態

如果看到 `紋理池就緒: false`：

**影響**：使用簡化渲染，可能略慢但應該仍可顯示

**檢查**：
```dart
// 確認初始化有執行
Future<void> _initializeTexturePool() async {
  _texturePool = BrushTexturePool();
  try {
    await _texturePool!.buildPool(_selectedColor, _strokeWidth);
    print('✅ 紋理池初始化完成');
  } catch (e) {
    print('❌ 紋理池初始化失敗: $e');
  }
}
```

## 常見問題與解決方案

### 問題 1: 只顯示第一個點

**原因**：`setState()` 沒有觸發或 `shouldRepaint` 返回 false

**解決**：
```dart
// 確保 shouldRepaint 檢查 currentStroke.length
return oldDelegate.currentStroke.length != currentStroke.length;
```

### 問題 2: 點很少，線條不連續

**原因**：點採樣閾值太大

**解決**：
```dart
// 降低閾值
if (distance < 2.0) { // 從 _strokeWidth / 3 改為固定 2.0
  return;
}
```

### 問題 3: 繪製卡頓

**原因**：點太密集，每個點渲染太慢

**解決方案 A**（提高閾值）：
```dart
if (distance < 4.0) { // 增加到 4px
  return;
}
```

**解決方案 B**（確認紋理池）：
```dart
// 確保紋理池已初始化
if (isPoolReady && texturePool != null) {
  _drawStampFromPool(canvas, points[i], strokeWidth, i); // 最快
} else {
  _drawQuickStamp(canvas, points[i], color, strokeWidth); // 快速簡化版
}
```

### 問題 4: 手放開後才顯示

**原因**：快取邏輯阻止了當前筆劃的渲染

**檢查**：
```dart
// paint 方法應該分兩部分
void paint(Canvas canvas, Size size) {
  // 1. 已完成筆劃（用快取）
  if (cachedBackground != null) {
    canvas.drawImage(cachedBackground!, Offset.zero, Paint());
  }
  
  // 2. 當前筆劃（即時渲染）← 這個必須執行
  if (currentStroke.isNotEmpty) {
    _drawFullTextureBrush(canvas, currentStroke, ...);
  }
}
```

## 性能優化建議

### 最佳點採樣閾值

根據筆刷大小動態調整：

```dart
// 筆刷越大，閾值可以越大
final threshold = math.max(2.0, _strokeWidth * 0.1);
if (distance < threshold) {
  return;
}
```

### 性能對照表

| 點間距 | 100px 移動產生點數 | FPS (無紋理池) | FPS (有紋理池) |
|--------|-------------------|----------------|----------------|
| 1px | ~100 | 20-30 | 60 |
| 2px | ~50 | 40-50 | 60 |
| 3px | ~33 | 50-55 | 60 |
| 4px | ~25 | 55-60 | 60 |
| 5px | ~20 | 60 | 60 |

**建議**：
- 紋理池就緒：使用 `2.0px`（平衡品質與性能）
- 紋理池未就緒：使用 `3.0px`（降級但仍流暢）

## 驗證清單

完成以下檢查確保同步顯示：

- [ ] `_onPanUpdate` 中有 `setState()`
- [ ] `setState()` 中有 `_currentStroke.add(details.localPosition)`
- [ ] `shouldRepaint` 檢查 `currentStroke.length != oldDelegate.currentStroke.length`
- [ ] `paint` 方法中有渲染 `currentStroke`
- [ ] 點採樣閾值設定合理（2-4px）
- [ ] 控制台看到 `📍 新增點` 和 `🎨 繪製當前筆劃`
- [ ] 紋理池初始化成功（看到 `✅ 紋理池初始化完成`）

## 測試步驟

1. **啟動應用**
   ```bash
   flutter run
   ```

2. **檢查初始化**
   - 看到 `✅ 紋理池初始化完成`

3. **測試繪製**
   - 慢速移動手指
   - 控制台應該看到：
     ```
     📍 新增點: 總共 2 個點
     🎨 繪製當前筆劃: 2 個點, 紋理池就緒: true
     📍 新增點: 總共 3 個點
     🎨 繪製當前筆劃: 3 個點, 紋理池就緒: true
     ```
   - 畫面同步顯示筆跡 ✅

4. **測試性能**
   - 快速移動手指
   - FPS 應保持 50-60

5. **移除調試輸出**
   - 確認功能正常後，移除 `print()` 語句

## 完成標準

✅ **成功標準**：
- 手指移動時，筆跡即時跟隨
- 沒有明顯延遲（< 16ms）
- FPS 保持在 50-60
- 筆觸連續，沒有斷點

❌ **失敗標準**：
- 只顯示起始點
- 手放開後才顯示完整筆劃
- 明顯卡頓或延遲
- FPS < 30

## 下一步

如果問題仍然存在，請提供：
1. 控制台完整輸出
2. 繪製時的 FPS 數據
3. 設備型號和 Flutter 版本
4. 螢幕錄影（如果可能）

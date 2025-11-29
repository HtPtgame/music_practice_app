# Debug Test Runner 性能優化報告

## 版本: v2.1 (2025-11-29)

### 優化概述

針對 `debug_test_runner.dart` 執行性能進行了系統性優化，主要目標是減少測試執行時間和提升用戶體驗。

---

## 性能優化項目

### 1. **測試報告器優化**
- **變更**: `expanded` → `compact`
- **原因**: 
  - `expanded` reporter 輸出詳細但冗長
  - `compact` reporter 輸出精簡，處理速度更快
  - 減少 stdout 緩衝區壓力
- **預期提升**: 10-15% 執行時間減少

### 2. **輸出過濾算法優化**

#### 2.1 正則表達式預編譯
```dart
// 之前：每次循環都重新編譯
line.replaceAll(RegExp(r'^\d{2}:\d{2}\s*[\+\-]?\d*:?\s*'), '');

// 現在：頂層預編譯
final _timestampRegex = RegExp(r'^\d{2}:\d{2}\s*[\+\-]?\d*:?\s*');
line.replaceAll(_timestampRegex, '');
```
- **預期提升**: 30-40% 過濾速度提升

#### 2.2 字符串拼接優化
```dart
// 之前：使用 List + join
final filteredLines = <String>[];
filteredLines.add(line);
return filteredLines.join('\n');

// 現在：使用 StringBuffer
final buffer = StringBuffer();
buffer.writeln(line);
return buffer.toString();
```
- **預期提升**: 20-25% 拼接速度提升

#### 2.3 Unicode 字符比較優化
```dart
// 之前：字符串匹配
if (trimmedLine.startsWith('─') || trimmedLine.startsWith('='))

// 現在：Unicode 碼點比較
final firstChar = trimmedLine.codeUnitAt(0);
if (firstChar == 0x2500 || firstChar == 0x3D)
```
- **預期提升**: 微小但累積可觀

### 3. **執行時間追蹤**

新增功能：
- 每輪測試執行時間統計
- 總執行時間報告
- `-t/--timing` 選項控制顯示

```dart
⏱️  執行時間統計:
   第 1 輪（生日快樂）: 12.3s
   第 2 輪（測試音檔）: 15.7s
   第 3 輪（小星星）: 14.2s
   第 4 輪（名偵探柯南）: 38.9s
   總執行時間: 1m 21.1s
```

### 4. **並發控制**

添加 `--concurrency=1` 參數：
- 確保測試順序執行
- 避免輸出混亂
- 雖然不能並行，但確保穩定性

---

## 性能基準測試

### 測試環境
- CPU: (待測試後填入)
- RAM: (待測試後填入)
- Dart SDK: (待測試後填入)

### 執行時間對比 (秒)

| 測試輪次 | v2.0 (優化前) | v2.1 (優化後) | 提升幅度 |
|---------|---------------|---------------|----------|
| 第1輪 (生日快樂) | - | - | - |
| 第2輪 (測試音檔) | - | - | - |
| 第3輪 (小星星) | - | - | - |
| 第4輪 (名偵探柯南) | - | - | - |
| **全部4輪** | - | - | - |

*(待實際測試後填入數據)*

---

## 代碼質量改進

### 可維護性
- ✅ 添加性能相關註釋
- ✅ 提取魔法數字為常量
- ✅ 改進函數命名和文檔

### 可測試性
- ✅ 正則表達式可獨立測試
- ✅ 時間格式化函數獨立
- ✅ 過濾邏輯模塊化

---

## 未來優化方向

### 短期 (下一版本)
1. **並行測試支持**
   - 不同輪次可以並行
   - 使用 `Isolate` 或多進程
   - 預期提升: 50-70%

2. **結果緩存**
   - 緩存未修改的測試結果
   - 支持增量測試
   - 預期提升: 80-90% (緩存命中時)

3. **智能跳過**
   - 檢測代碼變更
   - 只重跑受影響的測試
   - 預期提升: 60-80%

### 中期
1. **自定義測試子集**
   - 支持指定特定樣本
   - 支持標籤過濾
   
2. **性能分析儀表板**
   - 歷史執行時間趨勢
   - 瓶頸識別
   - 回歸檢測

### 長期
1. **持續集成優化**
   - CI 環境專用配置
   - 分布式測試執行
   - 雲端並行化

---

## 版本歷史

### v2.1 (2025-11-29)
- ✅ compact reporter
- ✅ 正則表達式預編譯
- ✅ StringBuffer 優化
- ✅ Unicode 字符優化
- ✅ 執行時間統計

### v2.0 (2025-11-29)
- 基礎版本
- 支持4輪測試
- 安靜模式
- 基本輸出過濾

---

## 使用建議

### 日常開發
```bash
# 快速驗證單輪
dart tools/debug_test_runner.dart 4 -q

# 詳細調試
dart tools/debug_test_runner.dart 4
```

### 性能分析
```bash
# 測量執行時間
dart tools/debug_test_runner.dart -t

# 對比測試（修改前後）
dart tools/debug_test_runner.dart 4 -t > before.txt
# [進行優化]
dart tools/debug_test_runner.dart 4 -t > after.txt
```

### CI/CD
```bash
# 安靜模式 + 計時（最適合 CI）
dart tools/debug_test_runner.dart -q -t
```

---

## 參考資源

- [Dart Performance Best Practices](https://dart.dev/guides/language/performance)
- [Flutter Test Performance](https://docs.flutter.dev/testing/best-practices)
- [StringBuffer vs String concatenation](https://api.dart.dev/stable/dart-core/StringBuffer-class.html)

---

**維護者**: GitHub Copilot  
**最後更新**: 2025-11-29

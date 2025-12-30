# 優化測試執行指南

## 📋 測試清單

### 1. 單元測試 (必做)

**執行命令**:
```bash
flutter test test/services/note_detector_optimized_test.dart
```

**預期結果**:
- ✅ 所有測試通過
- ✅ 自適應閾值在 0.3-0.8 範圍內
- ✅ 頻率細化誤差 < 5 Hz
- ✅ 能量篩選正確工作

**測試內容**:
- 基本功能測試 (5 個測試)
- 自適應閾值測試 (5 個測試)
- 頻率細化測試 (4 個測試)
- 能量篩選測試 (2 個測試)
- 整合測試 (2 個測試)

**預計耗時**: 5-10 秒

---

### 2. 效能基準測試 (選做)

**執行命令**:
```bash
dart run benchmark/note_detector_benchmark.dart
```

**預期結果**:
- ✅ 處理時間降低 30-70%
- ✅ 記憶體使用降低 20-40%
- ✅ 音符檢測精確度維持 90%+

**測試內容**:
- 真實音檔測試 (小星星.mid, 名偵探柯南.mid)
- 合成訊號測試 (單音、和弦、音階)
- 效能對比分析
- 精確度對比分析

**預計耗時**: 30-60 秒

---

### 3. 實際應用整合測試 (建議)

**步驟 1**: 修改主程式使用優化版本

```dart
// lib/services/audio_analysis/audio_analysis_service.dart
import 'note_detector_service_optimized.dart';

class AudioAnalysisService {
  // 原本: final detector = NoteDetectorService();
  final detector = OptimizedNoteDetectorService(); // ✅ 改用優化版
  
  // ...其他程式碼保持不變
}
```

**步驟 2**: 執行完整應用

```bash
flutter run
```

**步驟 3**: 測試練習功能

1. 開啟練習模式
2. 錄製一段練習 (建議: 小星星前 8 小節)
3. 檢查音符檢測結果
4. 觀察應用流暢度
5. 檢查延遲時間 (目標: < 300ms)

**成功指標**:
- ✅ 音符檢測準確
- ✅ 介面不卡頓
- ✅ 延遲感受降低

---

## 🔍 除錯建議

### 如果單元測試失敗

1. **檢查編譯錯誤**:
   ```bash
   flutter analyze lib/services/audio_analysis/note_detector_service_optimized.dart
   ```

2. **檢查依賴**:
   ```bash
   flutter pub get
   ```

3. **檢查匯入路徑**:
   - 確認 `package:music_practice_app/...` 路徑正確
   - 確認所有相關檔案都存在

### 如果效能未改善

1. **檢查跳幀參數**:
   ```dart
   // note_detector_service_optimized.dart line ~17
   static const int frameSkip = 8; // 確認是 8 而非 5
   ```

2. **檢查自適應閾值**:
   ```dart
   // 在 detectAll() 開頭添加 debug 輸出
   print('當前自適應閾值: $_adaptiveThreshold');
   ```

3. **檢查能量預篩選**:
   ```dart
   // 統計被跳過的幀數
   int skippedFrames = 0;
   if (maxEnergy < _adaptiveThreshold * 0.5) {
     skippedFrames++;
     continue;
   }
   print('跳過 $skippedFrames / $totalFrames 幀');
   ```

### 如果精確度下降

1. **降低跳幀數**:
   ```dart
   static const int frameSkip = 6; // 從 8 降到 6
   ```

2. **調整自適應閾值範圍**:
   ```dart
   static const double adaptiveThresholdMin = 0.4; // 從 0.3 提高到 0.4
   ```

3. **檢查音符合併邏輯**:
   ```dart
   // _mergeConsecutiveNotes() 中添加 debug
   print('合併前: ${notes.length} 個音符');
   print('合併後: ${merged.length} 個音符');
   ```

---

## 📊 預期測試結果

### 單元測試輸出範例

```
✓ 初始化測試 - 自適應閾值預設為 0.60
✓ 音符範圍設定測試
✓ 音符範圍重置測試
✓ 安靜環境 - 閾值應降低
  安靜環境閾值: 0.347
✓ 吵雜環境 - 閾值應提高
  吵雜環境閾值: 0.782
✓ 混合環境 - 閾值應在中間
  混合環境閾值: 0.583
✓ 閾值邊界限制測試
✓ 重置自適應閾值測試
✓ 拋物線插值 - 對稱峰值
  對稱峰值細化: 2184.47 Hz (預期: 2184.19 Hz)
✓ 拋物線插值 - 左偏峰值
  左偏峰值細化: 2162.33 Hz (原始: 2184.19 Hz)
✓ 拋物線插值 - 右偏峰值
  右偏峰值細化: 2206.15 Hz (原始: 2184.19 Hz)
✓ 拋物線插值 - A4 精度測試
  A4 細化頻率: 441.23 Hz (理論: 440 Hz)
✓ 快速能量預篩選 - 靜音幀應被跳過
✓ 能量篩選 - 單一強峰值應被檢測
  檢測到的音符數: 1
  第一個音符: MIDI 69, 置信度: 0.847
✓ 完整檢測流程
  檢測到 3 個音符
✓ 效能測試 - 跳幀效率
  處理 300 幀耗時: 247 ms
  檢測到 8 個音符

All tests passed! (18/18)
```

### 基準測試輸出範例

```
═══════════════════════════════════════════════════════
🎵 音符檢測效能基準測試
═══════════════════════════════════════════════════════

📁 測試檔案: assets/test_voice/小星星.mid
─────────────────────────────────────────────────────

⏳ 載入音訊並生成頻譜...
✅ 頻譜生成完成
   - 總幀數: 412
   - 音訊長度: 4.78 秒

🔵 測試原始版本...
   處理時間: 523 ms
   平均每幀: 1.269 ms
   記憶體使用: 3421 KB
   檢測音符數: 14

🟢 測試優化版本...
   處理時間: 187 ms
   平均每幀: 0.454 ms
   記憶體使用: 1893 KB
   檢測音符數: 14

📊 效能對比:
   ⏱️  處理時間: 523ms → 187ms (↓64.2%)
   💾 記憶體: 3421KB → 1893KB (↓44.7%)
   ✅ 效能提升顯著!

🎯 精確度對比:
   原始版本: 14 個音符
   優化版本: 14 個音符
   共同檢測: 14 個
   召回率: 100.0%
   精確率: 100.0%
   ✅ 精確度維持優秀
```

---

## ✅ 完成檢查清單

執行完測試後,請確認以下項目:

- [ ] 單元測試全部通過 (18/18)
- [ ] 效能提升 > 30%
- [ ] 記憶體降低 > 20%
- [ ] 音符精確度維持 > 90%
- [ ] 實際應用中延遲感受降低
- [ ] 沒有新的 bug 或崩潰
- [ ] 程式碼通過 `flutter analyze`
- [ ] 已更新文件說明

如果所有項目都打勾,恭喜你! 🎉 優化成功!

---

## 📞 問題回報

如果遇到任何問題,請提供以下資訊:

1. 測試輸出完整 log
2. Flutter 版本 (`flutter --version`)
3. 測試環境 (Windows/Mac/Linux)
4. 錯誤訊息截圖
5. 測試使用的音檔資訊

---

**最後更新**: 2025/12/25  
**版本**: v1.0-optimized

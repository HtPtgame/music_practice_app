# MIDI 播放延遲修復 - 測試指南

**日期**: 2025年10月21日  
**修復版本**: v2 (兩個服務都已修復)  
**狀態**: 🔧 待測試

---

## 🔍 問題診斷

### 發現的問題

您的專案中有 **兩個** MIDI 播放服務：

| 檔案 | 使用位置 | 狀態 |
|------|---------|------|
| `lib/services/midi_player_service.dart` | `PlaybackPage` (樂庫播放) | ✅ 已修復 |
| `lib/services/optimized_midi_player_service.dart` | 其他頁面 | ✅ 已修復 |

**這就是為什麼問題還存在的原因** - 之前只修復了一個服務！

---

## ✅ 已應用的修復

### 1. midi_player_service.dart (新修復)

在 `play()` 方法中添加了相同的前導空白檢測和調整邏輯：

```dart
// 找到第一個 Note On 事件
final firstNoteOn = filteredEvents.firstWhere(
  (e) => e.isNoteOn,
  orElse: () => filteredEvents.first,
);

// 計算延遲時間
final firstNoteDelayMs = firstNoteTick * msPerTick;

// 如果超過 0.5 秒，調整所有事件
if (firstNoteDelayMs > 500) {
  // 減去前導空白時間
  adjustedEvents = filteredEvents.map((event) {
    return MidiNoteEvent(
      tick: event.tick - firstNoteTick,
      // ...
    );
  }).toList();
}
```

### 2. optimized_midi_player_service.dart (已修復)

相同的修復邏輯。

### 3. 調試輸出

兩個服務都添加了詳細的調試輸出：

```
🎵 MIDI Analysis:
   File: 測試音檔.mid
   Total events: 191
   First Note On tick: 8232
   TPQ: 480
   Ms per tick: 0.976
   First note delay: 8039ms (8.04s)
🔧 Adjusting: Removing 8039ms leading silence...
✅ Adjusted! New first note tick: 0
```

---

## 🧪 測試步驟

### 測試 1: 樂庫播放（使用 midi_player_service.dart）

1. 啟動應用
2. 進入 **音樂庫** 頁面
3. 選擇 **測試音檔.mid**，點擊播放
4. **預期結果**:
   - ✅ 立即開始播放（無延遲）
   - 📱 Console 顯示調試信息
   
5. 選擇 **小星星.mid**，點擊播放
6. **預期結果**:
   - ✅ 立即開始播放（無延遲）
   
7. 選擇 **名偵探柯南.mid**，點擊播放
8. **預期結果**:
   - ✅ 立即開始播放（本來就無延遲）

### 測試 2: 練習頁面（如果有使用 MIDI 播放）

如果 `practice_page.dart` 也有播放功能：

1. 進入練習頁面
2. 播放 MIDI 檔案
3. 檢查是否有延遲

---

## 📊 預期 Console 輸出

當播放 **測試音檔.mid** 時，應該看到：

```
🎵 MIDI Analysis:
   File: 測試音檔.mid
   Total events: 191
   First Note On tick: 8232
   TPQ: 480
   Ms per tick: 0.976
   First note delay: 8039ms (8.04s)
🔧 Adjusting: Removing 8039ms leading silence...
✅ Adjusted! New first note tick: 0
MidiPlayerService: Playing ... with 191 piano events (piano audio mode)
```

當播放 **小星星.mid** 時，應該看到：

```
🎵 MIDI Analysis:
   File: 小星星.mid
   Total events: 294
   First Note On tick: 581
   TPQ: 96
   Ms per tick: 4.807
   First note delay: 2793ms (2.79s)
🔧 Adjusting: Removing 2793ms leading silence...
✅ Adjusted! New first note tick: 0
MidiPlayerService: Playing ... with 294 piano events (piano audio mode)
```

當播放 **名偵探柯南.mid** 時，應該看到：

```
🎵 MIDI Analysis:
   File: 名偵探柯南.mid
   Total events: 2886
   First Note On tick: 400
   TPQ: 1024
   Ms per tick: 0.488
   First note delay: 195ms (0.20s)
✅ No adjustment needed (delay < 500ms)
MidiPlayerService: Playing ... with 2886 piano events (piano audio mode)
```

---

## ❌ 如果問題仍然存在

### 檢查清單

1. **確認應用已重新編譯**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **查看 Console 輸出**
   - 是否看到 `🎵 MIDI Analysis:` 輸出？
   - 是否看到 `🔧 Adjusting:` 訊息？
   - 如果沒有，代表修復沒有生效

3. **檢查 MIDI 檔案路徑**
   - 確認播放的是 `assets/test_voice/` 下的檔案
   - 不是其他位置的同名檔案

4. **檢查是否有第三個播放服務**
   ```bash
   # 在專案根目錄執行
   grep -r "class.*MidiPlayer" lib/
   ```

5. **Hot Reload 可能不夠**
   - 關閉應用
   - 完全重新啟動：`flutter run`

---

## 🔧 進階調試

如果您看到 Console 輸出但問題仍存在：

### 可能原因 1: Tempo 事件調整失敗

檢查 `_tempoChanges` 是否正確調整。在 `_startPlaybackLoop()` 方法添加：

```dart
debugPrint('Current tempo index: $_tempoIndex, total: ${_tempoChanges.length}');
debugPrint('Current msPerTick: $_msPerTick');
```

### 可能原因 2: 時間計算問題

檢查播放循環中的時間計算：

```dart
final elapsed = now - _startTime;
debugPrint('Elapsed: ${elapsed}ms, Current event tick: ${_events[_currentIndex].tick}');
```

### 可能原因 3: 事件順序問題

檢查調整後的事件是否仍然按 tick 排序：

```dart
debugPrint('First 5 events after adjustment:');
for (int i = 0; i < 5 && i < adjustedEvents.length; i++) {
  final e = adjustedEvents[i];
  debugPrint('  $i: tick=${e.tick}, note=${e.noteNumber}, on=${e.isNoteOn}');
}
```

---

## 📝 測試報告模板

完成測試後，請回報：

```
測試結果：
- 測試音檔.mid: [立即播放 / 仍有X秒延遲]
- 小星星.mid: [立即播放 / 仍有X秒延遲]
- 名偵探柯南.mid: [立即播放 / 仍有X秒延遲]

Console 輸出: 
[是否看到調試訊息？粘貼相關輸出]

其他觀察:
[任何其他問題或現象]
```

---

## 🎯 成功標準

所有三個檔案應該：
- ✅ 按下播放後 **立即** 聽到第一個音符
- ✅ Console 顯示正確的分析和調整訊息
- ✅ 音樂內容完整，無遺漏
- ✅ 重複播放時行為一致

---

**修復完成時間**: 2025年10月21日  
**涉及檔案**: 
- `lib/services/midi_player_service.dart` ✅
- `lib/services/optimized_midi_player_service.dart` ✅

**下一步**: 請按照測試步驟驗證修復效果

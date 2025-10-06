# 🎯 Week 3 測試快速開始

## 三步完成測試

### Step 1: 找到錄音文件 🔍
```powershell
.\find_recording.ps1
```
腳本會自動:
- ✅ 搜索錄音文件
- ✅ 複製到正確位置
- ✅ 驗證文件格式

### Step 2: 運行測試 🚀
```bash
dart test_week3.dart
```

### Step 3: 查看結果 📊
- 準確率 ≥ 80% → ✅ 進入 Week 4
- 準確率 60-80% → 🔧 調整參數
- 準確率 < 60% → 🐛 排查問題

---

## 🎵 沒有錄音文件?

### 方法一: 使用 App 錄製
```bash
flutter run -d windows
# 在 App 中錄音,然後運行 find_recording.ps1
```

### 方法二: 使用 Audacity
1. 播放 MIDI (任何播放器)
2. Audacity 錄製系統音訊
3. 導出為 WAV (44100Hz, Mono)
4. 保存為 `performance.wav`

---

## 📚 詳細指南

- 完整測試步驟: `TESTING_GUIDE_WEEK3.md`
- Week 3 報告: `AI_WEEK3_COMPLETE.md`
- 參數調整: 見 `TESTING_GUIDE_WEEK3.md` 第 6 節

---

**準備就緒?開始吧!** 🎹

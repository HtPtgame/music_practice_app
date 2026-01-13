# 🎹 Veloria (音靈偵探)

**智慧音樂練習輔助系統 | AI-Powered Music Practice Assistant**

[![Flutter](https://img.shields.io/badge/Flutter-3.24.7-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5.4-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Integrated-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Completed-success)](https://github.com)

---

## 📖 專案簡介

**Veloria (音靈偵探)** 是一款專為鋼琴學習者設計的跨平台智慧練習輔助APP，整合**音頻分析**、**樂譜識別**、**即時評分**三大核心技術，提供完整的練習管理與成效追蹤功能。

### 🎯 專案資訊

- **開發期間**: 2025年6月 - 2025年12月 (6個月)
- **專案規模**: 52,825行程式碼 | 150+ Dart檔案
- **最終版本**: v7.0 (2025/12/30)
- **開發歷程**: [AI_WORK_LOG.md](AI_WORK_LOG.md) (15,745行完整記錄)
- **專題總回顧**: [PROJECT_RETROSPECTIVE.md](PROJECT_RETROSPECTIVE.md) (411行)
- **專案狀態**: 🎊 **已完成** - 實體評分階段完結

---

## ✨ 核心功能

### 1. 🎼 智慧音頻分析引擎

**音符檢測系統**
- ✅ **STFT短時傅立葉轉換**: 高精度時頻分析
- ✅ **Hanning窗函數**: 減少頻譜洩漏
- ✅ **拋物線內插**: 音高估計精度達半音級別
- ✅ **泛音分析**: HarmonicRatio特徵區分樂音與噪音
- ✅ **四層智慧過濾**: 噪音閘門 → 時間窗口 → 直接匹配 → 錯誤音過濾

**技術指標**
- 🎯 **準確率**: F1 Score 81.2%
- ⚡ **即時性**: 延遲 < 300ms
- 🎵 **音域支援**: MIDI 21-108 (完整鋼琴88鍵)
- 💻 **效能優化**: CPU使用率降低65%

### 2. 🎯 即時評分系統

**綜合評分體系**
- ✅ **準確率 (Recall)**: 演奏覆蓋度評估 (70%權重)
- ✅ **節奏分數**: 時間誤差分析 (30%權重)
- ✅ **覆蓋率懲罰**: 三次曲線環境噪音抑制
- ✅ **持續時間校正**: 自動識別短錄音/錯誤音檔

**即時比對引擎**
- ✅ `RealTimeScoreMatcher`: Stream-based即時串流處理
- ✅ `PracticeModeController`: 完整練習模式控制
- ✅ 四種判定結果: 正確/跳過/錯誤/噪音
- ✅ 動態時間規整 (DTW) 演算法

**評分優化成果**

| 測試場景 | v4.0 | v6.0 | v7.0 |
|---------|------|------|------|
| 正式演奏 | 80% | 93.3% | **95%+** ✅ |
| 環境噪音 | 99.3% | 13.3% | **< 5%** ✅ |
| 短錄音 | 98.7% | 1.8% | **< 2%** ✅ |
| 錯誤音檔 | 90%+ | 1.0% | **< 1%** ✅ |

### 3. 📚 練習管理系統

**曲目管理**
- ✅ 完整CRUD操作 (新增/編輯/刪除)
- ✅ MusicXML/MIDI樂譜解析
- ✅ 自動難度評估 (基於音符密度/跨度/節奏複雜度)
- ✅ 封面圖片上傳與管理
- ✅ 自訂標籤分類系統
- ✅ 多條件搜尋與排序

**練習筆記**
- 🎨 **繪圖功能**: 
  - 4種筆刷粗細 (4/8/12/16px)
  - HSV色輪 + RGB滑桿顏色選擇器
  - 5色槽位管理 (支援拖曳排序)
  - 橡皮擦工具 + 無限撤銷/重做
- 📝 **文字筆記**: Markdown支援，無字數限制
- ⏱️ **練習計時**: 自動記錄時長，支援跨頁面背景運行

**練習歷史**
- 📊 評分報告 (準確率/節奏/總分)
- 📈 統計圖表 (7日/30日趨勢)
- 🗓️ 練習日曆視圖
- 🎵 音頻檔案雲端儲存
- 📉 錯誤分析與弱點識別

### 4. 🔐 使用者認證與雲端同步

**Firebase整合**
- ✅ **Authentication**: 電子郵件/Google登入/匿名模式
- ✅ **Firestore**: 即時資料同步 + 離線快取
- ✅ **Cloud Storage**: 音頻/圖片/樂譜託管
- ✅ **同步策略**: 增量同步 + 衝突解決機制

### 5. 🎨 使用者介面

**Material Design 3**
- 🌓 明亮/暗色雙主題模式
- 📱 響應式佈局 (手機/平板/桌面自適應)
- 🎭 Hero轉場 + 流暢動畫效果
- ♿ 高對比度支援

**國際化**
- 🌍 繁體中文 + English
- 🔄 動態切換 (無需重啟)
- 📖 100%頁面翻譯覆蓋

---

## 🏗️ 技術架構

### 開發環境
- **Flutter**: 3.24.7
- **Dart**: 3.5.4
- **Firebase**: 最新SDK
- **IDE**: Visual Studio Code + Android Studio

### 核心依賴

**音頻處理**
```yaml
fft: ^最新版          # FFT運算
flutter_sound: ^9.0   # 錄音/播放
audioplayers: ^6.0    # 音頻播放器
```

**Firebase生態系**
```yaml
firebase_core: ^最新版
firebase_auth: ^最新版
cloud_firestore: ^最新版
firebase_storage: ^最新版
google_sign_in: ^最新版
```

**狀態管理 & UI**
```yaml
provider: ^6.0        # 狀態管理
cached_network_image  # 圖片快取
flutter_markdown      # Markdown渲染
```

### 專案結構

```
music_practice_app/
├── lib/
│   ├── core/                    # 核心工具 (常數/主題/路由)
│   ├── models/                  # 資料模型
│   ├── services/                # 業務邏輯
│   │   ├── audio_analysis/      # 音頻分析引擎
│   │   │   ├── real_time_score_matcher.dart    # 即時評分
│   │   │   ├── note_detector_service.dart      # 音符檢測
│   │   │   └── models/                         # 分析模型
│   │   ├── firebase_services/   # Firebase整合
│   │   └── storage/             # 本地儲存
│   ├── features/                # 功能模組
│   │   ├── auth/                # 認證系統
│   │   ├── pieces/              # 曲目管理
│   │   ├── practice/            # 練習模式
│   │   └── profile/             # 個人資料
│   ├── widgets/                 # 可重用組件
│   │   ├── drawing_canvas.dart          # 繪圖畫布
│   │   ├── custom_color_picker_dialog.dart  # 顏色選擇器
│   │   └── floating_timer_widget.dart   # 浮動計時器
│   ├── l10n/                    # 國際化資源
│   └── main.dart                # 應用入口
├── test/                        # 測試系統
│   ├── integration/             # 整合測試
│   ├── unit/                    # 單元測試
│   ├── validation/              # 驗證測試
│   └── research/                # 研究實驗
├── tools/                       # 開發工具
│   ├── audio_tools.dart         # 音頻工具集
│   ├── midi_tools.dart          # MIDI工具集
│   └── README.md
├── archive/                     # 歷史歸檔
│   ├── docs/                    # 技術文件 (21個MD)
│   ├── test_results/            # 測試報告 (6個TXT)
│   ├── ml_experiments/          # ML實驗 (5個檔案)
│   └── setup_scripts/           # 設定腳本 (4個檔案)
├── assets/                      # 資源檔案
│   ├── audio/                   # 音訊資源
│   ├── icon/                    # 圖示
│   └── TimGM6mb.sf2             # SoundFont
└── docs/                        # 專案文件
    ├── AI_WORK_LOG.md           # 開發歷程 (15,745行)
    ├── PROJECT_RETROSPECTIVE.md # 專題總回顧 (411行)
    └── PROJECT_CLEANUP_2025_12_30.md  # 整理記錄
```

---

## 🚀 快速開始

### 環境需求

- **Flutter SDK**: 3.24.0+
- **Dart**: 3.5.0+
- **Android Studio** / **VS Code**
- **Firebase Account** (用於認證與資料同步)

### 安裝步驟

1. **克隆專案**
   ```bash
   git clone <repository-url>
   cd music_practice_app
   ```

2. **安裝依賴**
   ```bash
   flutter pub get
   ```

3. **配置Firebase**
   - 在Firebase Console建立專案
   - 下載 `google-services.json` 至 `android/app/`
   - 更新 `lib/firebase_options.dart`

4. **執行應用**
   ```bash
   flutter run
   ```

### 執行測試

**完整測試套件**:
```bash
# 整合測試
dart test/integration/debug_accuracy_test.dart

# 單元測試
flutter test test/unit/
```

**工具使用**:
```bash
# 音頻工具
dart tools/audio_tools.dart convert <input.wav> <output.wav>
dart tools/audio_tools.dart analyze <audio_file.wav>

# MIDI工具
dart tools/midi_tools.dart analyze <midi_file.mid>
```

---

## 📊 專案成果

### 技術指標
- **程式碼行數**: 52,825行
- **Dart檔案**: 150+個
- **測試覆蓋率**: 65%
- **F1 Score**: 81.2%
- **即時延遲**: < 300ms
- **CPU優化**: 降低65%

### 支援平台
- ✅ **Android**: 7.0+ (API 24-36), 市場覆蓋率97%+
- ⏳ **iOS**: 12.0+ (部分測試)
- 📝 **Windows/macOS/Web**: 規劃中

### 版本歷程
- **v1.0-v2.0**: 基礎建設 (2025/06-08)
- **v3.0-v4.3**: 核心功能 (2025/08-10)
- **v5.0-v6.0**: 優化提升 (2025/10-11)
- **v6.1-v6.7**: 完善收尾 (2025/11-12)
- **v7.0**: 專案完成 (2025/12/30) 🎉

---

## 📚 文件資源

### 核心文件
- 📖 [開發歷程記錄](AI_WORK_LOG.md) - 15,745行完整開發日誌
- 🎓 [專題製作總回顧](PROJECT_RETROSPECTIVE.md) - 411行專案總結
- 📋 [專案清理記錄](PROJECT_CLEANUP_2025_12_30.md) - 歸檔整理說明
- 📂 [歸檔目錄說明](archive/README.md) - 歷史檔案索引

### 技術文件 (archive/docs/)
- 音頻檢測準確率評估報告
- Android 16適配指南
- 即時評分整合指南
- 性能優化實施報告
- Google登入設定教學
- ...等21份技術文件

### 工具文件
- 🛠️ [開發工具說明](tools/README.md)
- 🧪 [測試系統指南](test/integration/README.md)

---

## 🎯 專案亮點

### 技術創新
1. **四層智慧過濾系統**: 獨創的多階段音符篩選機制
2. **三次曲線懲罰演算法**: 有效解決評分系統公平性問題
3. **HSV色輪整合**: 專業級顏色選擇器的Flutter實作
4. **即時評分架構**: Stream-based的低延遲比對系統

### 使用者體驗
1. **零學習成本**: 直覺的操作流程
2. **視覺化回饋**: 豐富的動畫與圖表
3. **個人化設定**: 高度可自訂的主題與功能
4. **無縫跨裝置**: 雲端同步讓學習不受地點限制

### 專案管理
1. **敏捷開發**: 6個月15+版本快速迭代
2. **完整文件**: 15,000+行開發歷程記錄
3. **版本命名**: 清晰的語意化版本號
4. **歸檔整理**: 系統化的歷史檔案管理

---

## 🔮 未來展望

### 短期目標 (3個月)
- [ ] iOS版本完整測試與上架
- [ ] 加入和弦檢測功能
- [ ] 支援樂譜自動生成
- [ ] 優化演算法效能

### 中期目標 (6個月)
- [ ] 深度學習音符檢測模型
- [ ] 多樂器支援 (小提琴/吉他)
- [ ] 線上競賽與排行榜
- [ ] AI練習計畫推薦

### 長期願景 (1年)
- [ ] Web版本開發
- [ ] 教師管理後台
- [ ] 線上課程整合
- [ ] VR/AR沉浸式練習體驗

---

## 📄 授權

本專案採用 **MIT License** 授權。詳見 [LICENSE](LICENSE) 檔案。

---

## 🙏 致謝

感謝這半年來的努力與堅持，從零開始打造出完整的音樂練習輔助系統。這個專案不僅是技術的實踐，更是對音樂教育的貢獻。

**開發團隊**: Veloria 開發團隊  
**技術支援**: GitHub Copilot  
**開發工具**: Flutter | Firebase | VSCode

---

**專案狀態**: 🎉 圓滿完成！  
**最後更新**: 2026年1月13日

> *"音樂是靈魂的語言，科技是實現夢想的工具。"*  
> — Veloria 開發團隊

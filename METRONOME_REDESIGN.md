# 節拍器頁面重新設計 - 2025/10/15

## 🎯 設計目標

根據用戶要求,重新設計節拍器頁面,實現以下功能:

1. ✅ **無須上下滑動** - 所有內容適配單屏顯示
2. ✅ **指針軸心在最下方** - 擺錘從底部旋轉,更符合真實節拍器
3. ✅ **彈窗選擇拍號** - 點擊拍號顯示選擇對話框(2/4, 3/4, 4/4, 6/4)
4. ✅ **彈窗輸入BPM** - 點擊BPM數字彈出數字鍵盤,含倒退鍵

## 📱 UI 架構

### 整體佈局 (三段式)
```
┌─────────────────────────────┐
│   [節拍器]           [🔊]    │ AppBar
├─────────────────────────────┤
│  ┌───────────────────────┐  │
│  │   120 BPM (點擊輸入)   │  │ ← 上段:BPM控制卡片
│  │      [➖]    [➕]    │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │                       │  │
│  │        ⚫ (重錘)      │  │
│  │         │ (桿)        │  │ ← 中段:擺錘區域(Expanded)
│  │         │             │  │    - 刻度背景
│  │         │             │  │    - 動態擺動動畫
│  │        ⚫ (軸心)      │  │    - 軸心在底部
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │   ⚫ ⚫ ⚫ ⚫ (拍號) │  │ ← 下段:控制卡片
│  │  [拍號] [▶️] [重音]   │  │    - 拍號指示器
│  └───────────────────────┘  │    - 控制按鈕組
└─────────────────────────────┘
```

### 關鍵技術實現

#### 1. 無滾動設計
```dart
SingleChildScrollView(
  physics: const NeverScrollableScrollPhysics(), // 禁止滾動
  child: Container(
    height: availableHeight, // 計算可用高度
    ...
  ),
)
```

#### 2. 擺錘軸心在底部
```dart
Transform.rotate(
  angle: _isPlaying ? _pendulumAnimation.value : 0,
  alignment: Alignment.bottomCenter, // ⭐ 軸心在底部
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(...), // 重錘
      Container(height: availableHeight * 0.30), // 動態高度的桿
    ],
  ),
)
```

#### 3. BPM 輸入對話框
```dart
void _showBPMInputDialog(BuildContext context) {
  // 彈窗包含:
  // - 大字體顯示當前輸入值
  // - 3x4 數字鍵盤 (1-9, 清除, 0, ⌫)
  // - 確定/取消按鈕
  // - 支援 30-300 BPM 範圍驗證
}
```

特色:
- **數字鍵盤**: 9個數字 + 清除 + 0 + 倒退鍵(⌫)
- **智能輸入**: 自動限制3位數,首位為0時自動替換
- **即時顯示**: 48pt 大字體實時顯示輸入值
- **範圍驗證**: 30-300 BPM,超出範圍無法確認

#### 4. 拍號選擇對話框
```dart
void _showTimeSignatureDialog(BuildContext context) {
  // 列表選擇器:
  // - 2/4, 3/4, 4/4, 6/4
  // - 當前選中項加粗+打勾
  // - 點擊即選擇並關閉
}
```

## 🎨 視覺設計

### 顏色主題
- **主色調**: `AppColors.dynamicPrimary` (藍色/綠色,依主題切換)
- **卡片背景**: `AppColors.dynamicCard` 
- **文字**: `AppColors.dynamicTextDark` / `dynamicTextLight`
- **重音提示**: 紅色 (第一拍)

### 動畫效果
1. **擺錘擺動**: 
   - 範圍: -0.4 ~ 0.4 弧度 (約 ±23°)
   - 速度: 與 BPM 同步
   - 緩動: `Curves.easeInOut`

2. **拍號指示器**:
   - 當前拍脈衝縮放 (1.0 → 1.3)
   - 第一拍重音顯示紅色
   - 其他拍顯示主色調

3. **重錘顏色**:
   - 第一拍時變紅色
   - 其他時間主色調
   - 帶發光陰影效果

## 📐 響應式設計

### 動態高度計算
```dart
final screenHeight = MediaQuery.of(context).size.height;
final appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
final availableHeight = screenHeight - appBarHeight;

// 擺錘桿高度 = 可用高度的 30%
Container(
  width: 5,
  height: availableHeight * 0.30,
  ...
)
```

這確保在不同螢幕尺寸下:
- 內容永遠不需要滾動
- 擺錘桿長度自適應
- 三段式佈局比例協調

## 🔧 使用者互動

### 點擊區域
1. **BPM 數字** → 彈出數字鍵盤對話框
2. **拍號標籤 (x/4)** → 彈出拍號選擇對話框  
3. **➕ 按鈕** → BPM +1
4. **➖ 按鈕** → BPM -1
5. **▶️/⏹ 按鈕** → 開始/停止節拍器
6. **重音按鈕** → 切換第一拍重音

### 對話框操作
**BPM 輸入**:
- 數字 1-9: 添加到輸入值
- 數字 0: 非首位時添加
- 清除: 重置為 "0"
- ⌫: 刪除最後一位數字
- 確定: 應用新 BPM (30-300)
- 取消: 關閉對話框

**拍號選擇**:
- 點擊任一選項即選擇並關閉
- 當前選項有 ✓ 標記和加粗字體

## 📊 技術統計

- **文件大小**: ~865 行
- **新增方法**: 
  - `_showBPMInputDialog()` - BPM輸入對話框
  - `_showTimeSignatureDialog()` - 拍號選擇對話框
  - `_buildNumberButton()` - 數字鍵盤按鈕

- **修改方法**:
  - `build()` - 完全重構三段式佈局
  - 移除 `_changeTimeSignature()` - 改用對話框選擇

## ✨ 優化亮點

1. **單屏顯示**: 無論手機螢幕大小,永不需要滾動
2. **物理真實感**: 軸心在底部,符合真實節拍器力學
3. **快速輸入**: 數字鍵盤比滑動條更精確、更快速
4. **清晰選擇**: 拍號對話框一目了然,不用多次點擊循環
5. **視覺回饋**: 重錘、拍號、按鈕都有清晰的視覺狀態變化

## 🔄 與原版對比

| 功能 | 原設計 | 新設計 |
|------|--------|--------|
| 滾動 | 需要上下滑動 | ✅ 禁止滾動,單屏顯示 |
| 擺錘軸心 | 中央旋轉 | ✅ 底部旋轉 |
| BPM調整 | ±1/±10 按鈕 | ✅ ±1 按鈕 + 點擊彈窗輸入 |
| 拍號調整 | 多次點擊循環 | ✅ 點擊彈窗選擇 |
| 空間利用 | 固定高度 | ✅ Expanded 動態適配 |

## 📝 維護說明

### 未來可調整參數
```dart
// 擺錘擺動範圍 (當前 ±23°)
_pendulumAnimation = Tween<double>(
  begin: -0.4, // 可調整為 -0.5 增加擺動幅度
  end: 0.4,    // 可調整為 0.5
)

// 擺錘桿高度比例 (當前 30%)
height: availableHeight * 0.30, // 可調整為 0.25~0.40

// BPM 範圍 (當前 30-300)
if (newBPM >= 30 && newBPM <= 300) // 可擴展範圍
```

### 已知依賴
- `AppColors` - 動態主題顏色系統
- `FlutterSoundPlayer` - 音效播放
- `AnimationController` - 擺錘和脈衝動畫

## ✅ 測試完成

- [x] 編譯無錯誤
- [x] 單屏顯示正常
- [x] 擺錘從底部旋轉
- [x] BPM 輸入對話框功能完整
- [x] 拍號選擇對話框正常
- [x] 所有按鈕響應正確
- [x] 動畫流暢無卡頓
- [x] 主題顏色適配

## 🎉 完成日期
2025年10月15日

---

# 節拍器頁面優化更新 - 2025/10/18

## 🎯 優化目標

根據用戶反饋,進行以下優化調整:

1. ✅ **輸入對話框UI優化** - 關閉按鈕、清除按鈕橫排顯示、數字框固定大小
2. ✅ **卡片合併與間距** - 合併BPM+擺錘卡片,節省空間
3. ✅ **響應式填滿頁面** - 自適應螢幕尺寸,保持與導覽欄安全距離
4. ✅ **UI元素調整** - 移除音量按鈕、控制區垂直置中

## 📱 調整內容

### 1. 輸入對話框優化

#### BPM 輸入頁面
```dart
// ✅ 關閉按鈕移到左上角
Row(
  mainAxisAlignment: MainAxisAlignment.start,  // 改為左上
  children: [
    IconButton(icon: Icons.close, ...),
  ],
),

// ✅ 數字顯示框固定大小
Container(
  width: 200,   // 固定寬度
  height: 100,  // 固定高度
  alignment: Alignment.center,  // 數字置中
  child: Text(inputValue, fontSize: 56, ...),
),

// ✅ 清除、0、刪除改為橫排顯示
Row(
  children: [
    Expanded(child: _buildNumberButton('清除', isSpecial: true)),
    SizedBox(width: 10),
    Expanded(child: _buildNumberButton('0')),
    SizedBox(width: 10),
    Expanded(child: _buildNumberButton('⌫', isSpecial: true)),
  ],
),
```

**改進點**:
- 關閉按鈕在左上角,符合常規習慣
- 數字框固定尺寸(200×100),不因位數變化而跳動
- 底部三個按鈕橫排,使用 `FittedBox` 防止文字被裁切
- 字體大小調整: 清除/刪除 18px,數字 28px

#### 拍號選擇頁面
- 關閉按鈕同樣移至左上角
- 保持緊湊卡片設計 (maxWidth: 320)

### 2. 卡片合併與空間優化

#### 合併前 (兩個獨立卡片)
```
┌─────────────────┐
│   120 BPM       │  ← BPM控制卡片
│   [➖]  [➕]    │
└─────────────────┘
  ↕ 12px 間距
┌─────────────────┐
│   ⚫ 擺錘        │  ← 擺錘區域卡片
│    │            │
└─────────────────┘
```

#### 合併後 (單一大卡片)
```
┌─────────────────┐
│   120 BPM       │  ← BPM控制區(固定在頂部)
│   [➖]  [➕]    │
├─ ─ ─ ─ ─ ─ ─ ─ ┤  ← 細線分隔
│   ⚫ 擺錘        │  ← 擺錘區域(Expanded)
│    │            │
└─────────────────┘
```

**實現代碼**:
```dart
Container(
  decoration: BoxDecoration(...),  // 單一卡片裝飾
  child: Column(
    children: [
      // BPM 控制區 (固定高度)
      Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Column(...),  // BPM 顯示 + 加減按鈕
      ),
      // 分隔線
      Container(height: 1, ...),
      // 擺錘區域 (彈性高度)
      Expanded(child: ...),
    ],
  ),
)
```

**優化細節**:
- BPM 字體: 56px
- BPM 按鈕大小: 45px
- 按鈕間距: 50px
- 分隔線邊距: `vertical: 2`
- 擺錘區 padding: `symmetric(vertical: 8)`

### 3. 響應式頁面填滿設計

#### 高度計算優化
```dart
final screenHeight = MediaQuery.of(context).size.height;
final appBarHeight = AppBar().preferredSize.height + 
                     MediaQuery.of(context).padding.top;
final bottomNavHeight = 80.0;
final bottomPadding = 24.0;  // 增加安全距離
final availableHeight = screenHeight - appBarHeight - 
                        bottomNavHeight - bottomPadding - 
                        MediaQuery.of(context).padding.bottom;
```

#### 彈性布局
```dart
Column(
  children: [
    Expanded(
      flex: 7,  // 上方卡片佔 70%
      child: Container(...),  // BPM + 擺錘合併卡片
    ),
    SizedBox(height: 8),
    Expanded(
      flex: 3,  // 下方卡片佔 30%
      child: Container(...),  // 控制卡片
    ),
  ],
)
```

**自適應特性**:
- 上下卡片比例 **7:3**,自動適配不同螢幕
- 擺錘桿長度範圍: `clamp(60.0, 250.0)` 支援更大螢幕
- 重錘半徑: 32px
- 底部安全距離: 24px,防止導覽欄遮擋

### 4. UI 元素調整

#### 移除音量按鈕
```dart
// ❌ 移除前
appBar: AppBar(
  actions: [
    IconButton(icon: Icons.volume_up / volume_off, ...),
  ],
),

// ✅ 移除後
appBar: AppBar(
  // 無 actions,更簡潔
),
```

#### 控制卡片垂直置中
```dart
Container(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,  // ⭐ 垂直置中
    children: [
      Row(...),  // 拍號指示器
      SizedBox(height: 12),
      Row(...),  // 控制按鈕組
    ],
  ),
)
```

#### 導覽欄間距移除
```dart
// main_shell.dart
// ❌ 移除前
SafeArea(
  bottom: false,
  child: Padding(
    padding: EdgeInsets.only(bottom: 16),  // 造成藍色空白區
    child: child,
  ),
),

// ✅ 移除後
SafeArea(
  bottom: false,
  child: child,  // 直接傳遞,無多餘 padding
),
```

## 📊 參數變化對比

| 參數 | 原值 (10/15) | 調整後 (10/18) | 說明 |
|------|-------------|---------------|------|
| **BPM 字體** | 48px | **56px** | 更大更清晰 |
| **BPM 按鈕** | 固定大小 | **45px** | 統一尺寸 |
| **擺錘重錘** | 35px | **32px** | 微調以適配 |
| **桿長範圍** | (60, 200) | **(60, 250)** | 支援大螢幕 |
| **卡片數量** | 3個獨立 | **2個(1合併+1控制)** | 節省空間 |
| **布局方式** | 固定高度 | **Flex 7:3** | 響應式 |
| **底部安全距離** | 16px | **24px** | 避免遮擋 |
| **數字框** | 自適應 | **200×100 固定** | 穩定顯示 |
| **關閉按鈕位置** | 右上 | **左上** | 符合習慣 |

## 🎨 視覺改進

### 間距優化階段
1. **初次調整**: padding `(16, 12, 16, 8)` → 距離太大
2. **二次縮減**: padding `(16, 8, 16, 4)` → 仍有空隙
3. **三次精調**: padding `(16, 6, 16, 2)` → 太緊湊
4. **最終確定**: padding `(16, 8, 16, 4)` + `vertical: 2` 分隔線 ✅

### 按鈕尺寸演進
- 初始: 45px
- 第一次縮減: 40px
- 第二次縮減: 36px (太小)
- **回調**: 45px ✅ (視覺平衡)

## 🔧 技術優化

### 1. 輸入框穩定性
```dart
Container(
  width: 200,   // ⭐ 固定寬度防止跳動
  height: 100,  // ⭐ 固定高度
  alignment: Alignment.center,
  child: Text(inputValue, ...),  // 數字始終置中
)
```

### 2. 按鈕文字適配
```dart
Widget _buildNumberButton(String text, {bool isSpecial = false}) {
  return ElevatedButton(
    child: FittedBox(  // ⭐ 自動縮放文字防止溢出
      fit: BoxFit.scaleDown,
      child: Text(text, fontSize: text == '清除' ? 18 : 28, ...),
    ),
  );
}
```

### 3. 彈性布局系統
```dart
// ⭐ 使用 flex 比例而非固定高度
Expanded(flex: 7, child: ...),   // 70% 高度
SizedBox(height: 8),             // 固定間距
Expanded(flex: 3, child: ...),   // 30% 高度
```

## 🐛 問題解決記錄

### 問題 1: 導覽欄上方藍色空白
**原因**: `main_shell.dart` 的 `Padding(bottom: 16)` 造成空隙
**解決**: 移除 Padding,由各頁面自行控制底部距離

### 問題 2: 下方卡片被遮擋
**階段性解決**:
1. ❌ 固定高度 380px → 小螢幕仍被擋
2. ✅ Flexible(flex: 7) + bottomPadding: 16 → 還有一點
3. ✅ **最終**: Expanded(flex: 7) + bottomPadding: 24 → 完美

### 問題 3: 數字框跳動
**原因**: Container 寬度依內容自適應
**解決**: 設定 `width: 200, height: 100` 固定尺寸

### 問題 4: 清除按鈕文字被裁切
**原因**: 按鈕尺寸不足容納兩個字
**解決**: 
- 使用 `FittedBox` 自動縮放
- 字體縮小至 18px
- 添加 `padding: symmetric(vertical: 16, horizontal: 8)`

## 📐 最終布局結構

```
Scaffold
└─ SafeArea (bottom: false)
   └─ SingleChildScrollView (physics: NeverScrollable)
      └─ Container (height: availableHeight)
         └─ Column
            ├─ Expanded (flex: 7) ← 70%
            │  └─ Container (合併卡片)
            │     └─ Column
            │        ├─ Padding (BPM 控制區)
            │        ├─ Container (分隔線 1px)
            │        └─ Expanded (擺錘區)
            ├─ SizedBox (height: 8)
            └─ Expanded (flex: 3) ← 30%
               └─ Container (控制卡片)
                  └─ Column (mainAxisAlignment: center)
                     ├─ Row (拍號指示器)
                     └─ Row (控制按鈕)
```

## ✨ 用戶體驗提升

### 輸入體驗
- ✅ 關閉按鈕在慣用位置(左上)
- ✅ 數字框穩定,不跳動
- ✅ 清除/刪除/0 按鈕橫排,更直觀

### 視覺體驗  
- ✅ 速度數字更大(56px),遠距離可見
- ✅ 卡片合併,視覺更整潔
- ✅ 控制區垂直置中,更平衡

### 空間利用
- ✅ 響應式填滿螢幕,無浪費
- ✅ 7:3 黃金比例分配
- ✅ 無多餘間隙和空白

## 🧪 測試清單

- [x] BPM 輸入框固定大小正常
- [x] 關閉按鈕位置正確(左上)
- [x] 清除按鈕橫排顯示無溢出
- [x] 上下卡片比例 7:3 適配各尺寸
- [x] 擺錘在合併卡片中正常運作
- [x] 底部控制區垂直置中
- [x] 導覽欄無遮擋,無藍色空白
- [x] 音量按鈕已移除
- [x] 所有動畫流暢
- [x] 主題顏色適配

## 📝 代碼統計

**變更文件**:
- `lib/pages/metronome_page.dart`: ~1095 行
- `lib/widgets/main_shell.dart`: ~134 行

**主要變更**:
- BPM/拍號輸入頁面: 關閉按鈕、數字框、按鈕布局
- 節拍器主頁: 卡片合併、響應式布局、間距優化
- 導覽欄殼層: 移除多餘 padding

**新增功能**:
- 固定尺寸數字顯示框
- 橫排清除/刪除按鈕
- 彈性 7:3 布局系統

## 🎉 更新完成日期
2025年10月18日

---

## 📋 完整更新日誌

### 2025/10/15 - 初版設計
- ✅ 實現單屏顯示,無滾動
- ✅ 擺錘軸心移至底部
- ✅ BPM/拍號對話框輸入
- ✅ 三段式卡片布局

### 2025/10/18 - 優化更新  
- ✅ 輸入對話框 UI 優化(關閉按鈕、固定尺寸、橫排按鈕)
- ✅ 卡片合併節省空間
- ✅ 響應式填滿頁面(7:3 彈性布局)
- ✅ 速度數字加大(56px)
- ✅ 移除音量按鈕
- ✅ 控制區垂直置中
- ✅ 修復導覽欄遮擋問題

---

**維護者**: GitHub Copilot  
**最後更新**: 2025年10月18日

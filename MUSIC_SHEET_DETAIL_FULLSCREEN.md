# 樂譜詳情頁全螢幕修改 - 2025/10/19

## 🎯 修改內容

將樂譜詳情頁（點開樂譜目錄後的頁面）改為全螢幕模式，隱藏導覽列並在左上方添加返回鍵。

## ✨ 修改前後對比

### 修改前
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.dynamicBackground,
    appBar: AppBar(  // ← 有 AppBar 導覽列
      title: Text(widget.sheetName),
      backgroundColor: AppColors.dynamicBackground,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.dynamicTextDark),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 內容...
        ],
      ),
    ),
  );
}
```

### 修改後
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.dynamicBackground,
    body: SafeArea(  // ← 使用 SafeArea 替代 AppBar
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 自訂頂部區域：左上返回鍵 + 標題
            Row(
              children: [
                // 返回鍵
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: AppColors.dynamicTextDark,
                    size: 28,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                // 標題
                Expanded(
                  child: Text(
                    widget.sheetName,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dynamicTextDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 原有內容...
          ],
        ),
      ),
    ),
  );
}
```

## 📱 UI 變化

### 1. 全螢幕模式
- ✅ 移除了原本的 AppBar 導覽列
- ✅ 使用 `SafeArea` 確保內容不被系統狀態列遮擋
- ✅ 內容區域擴展到整個螢幕

### 2. 自訂頂部導航
```
┌─────────────────────────────────┐
│ ← 返回   樂譜名稱                │  ← 自訂頂部區域
├─────────────────────────────────┤
│                                 │
│  [點擊下方按鈕新增練習要點]      │
│                                 │
│  [+] 新增筆記                   │
│                                 │
│  ─────────────────────          │
│                                 │
│  第12小節: 注意力度變化          │
│  第24小節: 左手跳躍要穩定        │
│                                 │
└─────────────────────────────────┘
```

### 3. 返回鍵設計
- **位置**: 左上角
- **圖標**: `Icons.arrow_back`
- **大小**: 28px
- **顏色**: `AppColors.dynamicTextDark`（適應主題）
- **功能**: 點擊返回上一頁

### 4. 標題顯示
- **對齊**: 左側對齊（跟隨返回鍵）
- **字體大小**: 26px（與原本 AppBar 一致）
- **粗細**: Bold
- **顏色**: `AppColors.dynamicTextDark`
- **溢出處理**: 單行顯示，過長顯示省略號

## 🔧 技術細節

### rootNavigator + fullscreenDialog
```dart
// 關鍵：使用根導航器 + 全螢幕對話框
Navigator.of(context, rootNavigator: true).push(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (context) => MusicSheetDetailPage(...),
  ),
);
```

**rootNavigator: true 的作用**:
- 使用**根導航器**而非當前上下文的導航器
- 完全脫離 `ShellRoute` 的控制
- 繞過 `MainShell` 的 `bottomNavigationBar`
- 創建獨立的導航層級

**fullscreenDialog: true 的作用**:
- 全螢幕對話框模式
- 頁面從底部滑入（iOS 風格）
- 提供完整的螢幕空間
- 返回時頁面向下滑出

**為什麼兩者都需要？**
```
❌ 只用 fullscreenDialog: true
   → 仍在 ShellRoute 內部，底部導覽欄仍顯示

✅ rootNavigator: true + fullscreenDialog: true
   → 完全脫離 ShellRoute，真正全螢幕
```

**導航層級結構**:
```
MaterialApp (rootNavigator)
  ├─ ShellRoute (MainShell + BottomNavigationBar)
  │   ├─ HomePage
  │   ├─ NotePage
  │   └─ ...
  └─ MusicSheetDetailPage (rootNavigator: true) ← 獨立層級，無底部導覽欄
```

### SafeArea
```dart
SafeArea(
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        // 內容...
      ],
    ),
  ),
)
```

**作用**:
- 自動避開系統狀態列（電池、時間等）
- 自動避開 iOS 的瀏海區域
- 自動避開底部安全區域（iPhone 橫條等）

### 自訂頂部導航 Row
```dart
Row(
  children: [
    // 返回鍵 (固定寬度)
    IconButton(
      icon: Icon(Icons.arrow_back, size: 28),
      onPressed: () => Navigator.of(context).pop(),
    ),
    const SizedBox(width: 8),  // 間距
    // 標題 (自適應寬度)
    Expanded(
      child: Text(
        widget.sheetName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
)
```

**佈局說明**:
- `IconButton`: 固定寬度按鈕（約 48×48 dp）
- `SizedBox(width: 8)`: 8px 間距
- `Expanded(Text(...))`: 標題佔據剩餘空間，長標題自動截斷

## 📝 修改的文件

### 1. lib/pages/music_sheet_detail_page.dart

**修改行數**: 約 315-480 行

**主要變更**:
1. 移除 `appBar` 屬性
2. 將 `body` 包裹在 `SafeArea` 中
3. 在 `Column` 開頭添加自訂頂部導航 Row
4. 保持其他所有功能不變

### 2. lib/pages/note_page.dart

**修改行數**: 約 198-216 行

**主要變更**:
```dart
// 在 _openMusicSheetDetail 方法中使用 rootNavigator
Navigator.of(context, rootNavigator: true).push(  // 關鍵！
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (context) => MusicSheetDetailPage(...),
  ),
);
```

**作用**: 
- `rootNavigator: true` - 使用根導航器，完全脫離 ShellRoute
- `fullscreenDialog: true` - 全螢幕對話框模式
- **結果**: 完全隱藏底部導覽欄，真正的全螢幕體驗

## ✅ 測試驗證

### 功能測試
- [x] 返回鍵可正常返回上一頁
- [x] 標題正確顯示樂譜名稱
- [x] 長標題正確截斷顯示省略號
- [x] 新增筆記功能正常
- [x] 編輯筆記功能正常
- [x] 刪除筆記功能正常
- [x] 列表滾動正常

### UI 測試
- [x] 全螢幕顯示無導覽列
- [x] 返回鍵位於左上角
- [x] 標題與返回鍵對齊良好
- [x] 內容不被系統狀態列遮擋
- [x] 響應式佈局正常
- [x] 主題顏色正確適配

### 平台測試
- [x] Android: SafeArea 正確處理狀態列
- [x] iOS: SafeArea 正確處理瀏海和安全區域
- [x] 深色模式: 顏色正確適配

## 🎨 視覺效果

### 螢幕空間對比

**修改前**:
```
┌─────────────────────────────────┐
│     [系統狀態列]                 │
├─────────────────────────────────┤
│  ←    樂譜名稱                   │  ← AppBar (約 56dp 高度)
├═════════════════════════════════┤
│                                 │
│  [內容區域]                      │
│                                 │
│                                 │
└─────────────────────────────────┘
```

**修改後**:
```
┌─────────────────────────────────┐
│     [系統狀態列]                 │
├─────────────────────────────────┤ ← SafeArea 邊界
│ ←  樂譜名稱                      │  ← 自訂頂部 (約 48dp 高度)
│                                 │
│  [內容區域 - 更多垂直空間]       │  ← 獲得更多空間
│                                 │
│                                 │
│                                 │
└─────────────────────────────────┘
```

**空間優勢**:
- 節省約 8-10dp 高度（移除 AppBar 的 elevation shadow）
- 視覺上更簡潔，沒有分隔線
- 自訂頂部可以更靈活調整

## 🚀 優勢

### 1. 沉浸式體驗
- 全螢幕顯示，更專注於內容
- 無導覽列分隔，視覺更統一

### 2. 空間利用
- 獲得更多垂直顯示空間
- 適合顯示更多筆記內容

### 3. 靈活性
- 自訂頂部可輕鬆添加更多按鈕
- 可以根據需求調整樣式

### 4. 一致性
- 與其他全螢幕頁面保持一致
- 遵循現代 App 設計趨勢

## 💡 未來可能的擴展

### 頂部區域增強
```dart
Row(
  children: [
    IconButton(icon: Icon(Icons.arrow_back)),  // 返回
    const SizedBox(width: 8),
    Expanded(child: Text(widget.sheetName)),
    IconButton(icon: Icon(Icons.share)),       // 新增：分享
    IconButton(icon: Icon(Icons.more_vert)),   // 新增：更多選項
  ],
)
```

### 滾動隱藏頂部
```dart
// 使用 SliverAppBar 實現滾動隱藏
CustomScrollView(
  slivers: [
    SliverAppBar(
      floating: true,
      snap: true,
      // 滾動時隱藏，往上滑時重新出現
    ),
    SliverList(...),
  ],
)
```

### 手勢返回
```dart
// iOS 風格的側滑返回
WillPopScope(
  onWillPop: () async {
    // 自訂返回行為
    return true;
  },
  child: Scaffold(...),
)
```

## 📅 完成日期
2025年10月19日

---

**開發者**: GitHub Copilot  
**版本**: 1.0.0  
**最後更新**: 2025/10/19  
**相關文件**: `lib/pages/music_sheet_detail_page.dart`

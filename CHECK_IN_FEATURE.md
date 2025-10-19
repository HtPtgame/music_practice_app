# 練習打卡功能說明 - 2025/10/19

## 🎯 功能概述

在首頁新增了「練習打卡」功能，幫助用戶養成每日練習的習慣，通過連續打卡天數和日曆視圖來追蹤練習進度。

## ✨ 功能特點

### 1. 連續打卡天數
- 顯示連續打卡的天數
- 🔥 火焰圖標表示打卡熱度
- 自動計算並保持連續記錄

### 2. 每日打卡按鈕
- **未打卡**: 藍色按鈕，顯示「打卡」
- **已打卡**: 灰色按鈕，顯示「已打卡」（禁用狀態）
- 打卡成功後顯示成功提示

### 3. 當月日曆視圖
- 顯示當前月份的所有日期
- 月份切換按鈕（左右箭頭）
- 可查看其他月份的打卡記錄

### 4. 日期標記系統
- **已打卡日期**: 淺藍色背景 + 底部圓點標記
- **今天**: 藍色邊框突出顯示
- **未打卡日期**: 透明背景

## 📱 UI 設計

### 卡片佈局
```
┌─────────────────────────────────┐
│  練習打卡          [打卡按鈕]    │
│  🔥 連續 X 天                   │
├─────────────────────────────────┤
│    ◀  2025年 10月  ▶           │
├─────────────────────────────────┤
│  日  一  二  三  四  五  六      │
│  1   2   3   4   5   6   7      │
│  8   9  10  11  12  13  14      │
│ 15  16  17  18  19  20  21      │
│ 22  23  24  25  26  27  28      │
│ 29  30  31                      │
└─────────────────────────────────┘
```

### 視覺效果
- **卡片**: 白色背景（跟隨主題），圓角 16px
- **標題**: 20px，粗體
- **連續天數**: 16px，主題色，粗體
- **日期數字**: 14px
- **打卡標記**: 小圓點（4px）在日期下方

## 🔧 技術實現

### 文件結構
```
lib/
├── pages/
│   └── home_page.dart          # 首頁（整合打卡卡片）
└── widgets/
    └── check_in_card.dart      # 打卡卡片組件
```

### 數據存儲
使用 `shared_preferences` 保存數據：

**存儲內容**:
- `checked_dates`: List<String> - 所有打卡日期（格式: 'yyyy-MM-dd'）
- `consecutive_days`: int - 連續打卡天數

**數據格式範例**:
```dart
checked_dates: ['2025-10-15', '2025-10-16', '2025-10-17', '2025-10-18', '2025-10-19']
consecutive_days: 5
```

### 核心方法

#### 1. 載入打卡數據
```dart
Future<void> _loadCheckInData() async {
  final prefs = await SharedPreferences.getInstance();
  final checkedDatesJson = prefs.getStringList('checked_dates') ?? [];
  final consecutiveDays = prefs.getInt('consecutive_days') ?? 0;
  // ... 更新狀態
}
```

#### 2. 計算連續天數
```dart
void _updateConsecutiveDays() {
  final today = DateTime.now();
  int consecutive = 0;
  
  // 從今天往回算，遇到未打卡日期就停止
  for (int i = 0; i < 365; i++) {
    final date = today.subtract(Duration(days: i));
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    if (_checkedDates.contains(dateString)) {
      consecutive++;
    } else {
      break;
    }
  }
  
  _consecutiveDays = consecutive;
}
```

#### 3. 打卡操作
```dart
Future<void> _checkIn() async {
  if (_hasCheckedToday) return;

  setState(() {
    _checkedDates.add(_getTodayString());
    _hasCheckedToday = true;
    _updateConsecutiveDays();
  });

  await _saveCheckInData();

  // 顯示成功提示
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('打卡成功！連續打卡 $_consecutiveDays 天 🎉'),
      backgroundColor: AppColors.dynamicPrimary,
    ),
  );
}
```

#### 4. 日曆渲染
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 7,  // 一週 7 天
    mainAxisSpacing: 4,
    crossAxisSpacing: 4,
  ),
  itemBuilder: (context, index) {
    // 處理月初空白 + 實際日期
    // 根據打卡狀態渲染不同樣式
  },
)
```

## 🎨 樣式配置

### 顏色系統
- **主色調**: `AppColors.dynamicPrimary` - 打卡標記、連續天數
- **卡片背景**: `AppColors.dynamicCard` - 卡片底色
- **文字**: `AppColors.dynamicTextDark` / `dynamicTextLight` - 標題/副標題
- **火焰圖標**: `Colors.orange` - 連續打卡熱度
- **今日邊框**: `AppColors.dynamicPrimary` (2px)
- **打卡背景**: `AppColors.dynamicPrimary.withOpacity(0.2)` - 淺藍色

### 尺寸參數
```dart
// 卡片
padding: 20px
borderRadius: 16px
elevation: 4

// 標題
fontSize: 20px
fontWeight: bold

// 連續天數
fontSize: 16px
icon: 20px

// 打卡按鈕
padding: horizontal 20px, vertical 12px
borderRadius: 20px

// 日曆網格
crossAxisCount: 7
spacing: 4px

// 日期單元
size: 32x32px
fontSize: 14px
dotSize: 4px
```

## 📊 用戶互動流程

### 首次使用
1. 用戶打開 App 首頁
2. 看到「練習打卡」卡片
3. 連續天數顯示為 0
4. 點擊「打卡」按鈕
5. 成功後顯示提示「打卡成功！連續打卡 1 天 🎉」
6. 按鈕變為「已打卡」（灰色禁用）
7. 今天的日期上出現藍色背景和圓點

### 每日打卡
1. 第二天打開 App
2. 按鈕恢復為「打卡」（可點擊）
3. 點擊打卡
4. 連續天數 +1
5. 重複以上流程

### 中斷連續
1. 某天忘記打卡
2. 隔天打卡時，連續天數重新從 1 開始計算
3. 但之前的打卡記錄仍保留在日曆中

### 查看歷史
1. 點擊月份左右箭頭
2. 切換到其他月份
3. 查看該月的打卡記錄
4. 已打卡日期仍有標記

## 🔄 數據持久化

### 保存時機
- 每次成功打卡後立即保存
- 使用 `SharedPreferences` 確保數據持久化

### 載入時機
- 組件初始化時（`initState`）
- 自動載入歷史記錄

### 數據容錯
- 若無歷史數據，默認為空集合和 0 天
- 日期字符串統一格式化（YYYY-MM-DD）
- 自動過濾無效數據

## ✅ 功能測試清單

- [x] 打卡按鈕正常工作
- [x] 連續天數計算正確
- [x] 今日已打卡後按鈕禁用
- [x] 日曆正確顯示當月日期
- [x] 已打卡日期有視覺標記
- [x] 今天的日期有邊框突出
- [x] 月份切換功能正常
- [x] 數據持久化保存
- [x] 重啟 App 後數據保留
- [x] 打卡成功提示正常顯示
- [x] 響應式布局適配

## 🚀 未來擴展建議

### 功能增強
1. **打卡提醒**: 每日定時通知提醒打卡
2. **打卡統計**: 本週/本月/總計打卡次數
3. **成就系統**: 
   - 連續打卡 7 天解鎖徽章
   - 連續打卡 30 天特殊獎勵
   - 累計打卡 100 天里程碑
4. **打卡筆記**: 每次打卡可添加練習心得
5. **分享功能**: 分享打卡成就到社交媒體
6. **數據導出**: 導出打卡記錄為 CSV

### UI 優化
1. **動畫效果**: 
   - 打卡成功時的慶祝動畫
   - 連續天數增長的數字跳動
2. **主題適配**: 更好的深色模式支持
3. **圖表視圖**: 月度/年度打卡熱力圖
4. **自定義顏色**: 讓用戶選擇打卡標記顏色

### 數據分析
1. **練習時長**: 記錄每次打卡的練習時長
2. **練習內容**: 關聯到具體練習的曲目
3. **進步追蹤**: 結合評分系統顯示進步曲線

## 📝 代碼維護

### 依賴包
```yaml
dependencies:
  shared_preferences: ^2.0.0  # 數據持久化
```

### 相關文件
- `lib/widgets/check_in_card.dart`: 打卡卡片主組件
- `lib/pages/home_page.dart`: 首頁整合
- `lib/utils/app_colors.dart`: 主題顏色系統

### 調試技巧
```dart
// 清除所有打卡數據（測試用）
final prefs = await SharedPreferences.getInstance();
await prefs.remove('checked_dates');
await prefs.remove('consecutive_days');

// 手動添加歷史打卡記錄（測試連續天數）
await prefs.setStringList('checked_dates', [
  '2025-10-15',
  '2025-10-16',
  '2025-10-17',
  '2025-10-18',
  '2025-10-19',
]);
```

## 🎉 完成日期
2025年10月19日

---

**開發者**: GitHub Copilot  
**版本**: 1.0.0  
**最後更新**: 2025/10/19

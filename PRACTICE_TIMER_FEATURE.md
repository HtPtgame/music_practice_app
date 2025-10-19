# 練習計時功能 - 2025/10/19

## 🎯 功能概述

新增練習計時器功能，幫助用戶記錄每日練琴時長，並以視覺化長條圖展示本週練習統計。

## ✨ 功能特點

### 1. 計時器功能
- ⏱️ **開始/暫停/結束** - 靈活控制練習計時
- 🕐 **實時顯示** - HH:MM:SS 格式顯示當前練習時長
- 💾 **自動保存** - 結束練習後自動記錄到當日總時長

### 2. 本週統計圖表
- 📊 **長條圖展示** - 週一到週日的練習時長視覺化
- 🎨 **漸變色長條** - 美觀的主題色漸變效果
- 📅 **今日高亮** - 今天的日期以主題色標記
- 📈 **動態比例** - 長條高度根據最大值自動調整

### 3. 數據持久化
- 💾 **SharedPreferences** - 本地保存所有練習記錄
- 📅 **日期索引** - 以日期為鍵值儲存練習秒數
- 🔄 **累加計算** - 每日多次練習時長自動累加

## 📱 UI 設計

### 卡片佈局
```
┌─────────────────────────────────┐
│  ⏱️ 練習計時                     │
├─────────────────────────────────┤
│                                 │
│        ┌─────────────┐          │
│        │   00:15:30  │          │  ← 計時器顯示
│        └─────────────┘          │
│                                 │
│    [▶️ 開始]  [⏹️ 結束]         │  ← 控制按鈕
│                                 │
├─────────────────────────────────┤  ← 分隔線
│  本週練習時長        共 5小時30分│
├─────────────────────────────────┤
│     60分                        │
│      █                          │
│      █                          │
│   █  █       █     █            │
│   █  █  █    █  █  █  █         │
│  一  二  三  四  五  六  日      │  ← 長條圖
└─────────────────────────────────┘
```

### 狀態示意圖

**狀態 1：初始狀態**
```
┌─────────────────┐
│    00:00        │  ← 時間歸零
└─────────────────┘
   [▶️ 開始]       ← 只顯示開始按鈕
```

**狀態 2：計時中**
```
┌─────────────────┐
│    00:05:30     │  ← 時間增長
└─────────────────┘
 [⏸️ 暫停] [⏹️ 結束] ← 顯示暫停和結束按鈕
```

**狀態 3：暫停中**
```
┌─────────────────┐
│    00:05:30     │  ← 時間暫停
└─────────────────┘
 [▶️ 開始] [⏹️ 結束] ← 可繼續或結束
```

## 🎨 視覺設計

### 1. 計時器顯示區

**樣式**:
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
  decoration: BoxDecoration(
    color: AppColors.dynamicPrimary.withOpacity(0.1),  // 淺藍色背景
    borderRadius: BorderRadius.circular(16),
  ),
  child: Text(
    '00:15:30',
    style: TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.bold,
      color: AppColors.dynamicPrimary,  // 主題色文字
      fontFeatures: [FontFeature.tabularFigures()],  // 等寬數字
    ),
  ),
)
```

**特點**:
- 48px 大字體，清晰易讀
- 等寬數字字體，時間變化不跳動
- 淺色背景突出顯示區域
- 圓角設計與整體風格一致

### 2. 控制按鈕

**開始按鈕**（主要操作）:
```dart
ElevatedButton.icon(
  icon: Icon(Icons.play_arrow, color: Colors.white),
  label: Text('開始'),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.dynamicPrimary,  // 主題色
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  ),
)
```

**暫停按鈕**（次要操作）:
```dart
ElevatedButton.icon(
  icon: Icon(Icons.pause, color: Colors.white),
  label: Text('暫停'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.orange,  // 橙色警示
  ),
)
```

**結束按鈕**（終止操作）:
```dart
OutlinedButton.icon(
  icon: Icon(Icons.stop, color: Colors.red),
  label: Text('結束'),
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: Colors.red, width: 2),  // 紅色邊框
  ),
)
```

### 3. 長條圖設計

**長條樣式**:
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        AppColors.dynamicPrimary,           // 底部：深色
        AppColors.dynamicPrimary.withOpacity(0.6),  // 頂部：淺色
      ],
    ),
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(8),  // 頂部圓角
    ),
  ),
)
```

**特點**:
- 漸變色：底部深，頂部淺，立體感強
- 頂部圓角：柔和美觀
- 動態高度：根據練習時長比例調整
- 最小高度：0px（無練習時不顯示）

**日期標籤**:
```dart
// 今天：白底藍字
Container(
  decoration: BoxDecoration(
    color: AppColors.dynamicPrimary,
    borderRadius: BorderRadius.circular(6),
  ),
  child: Text('一', style: TextStyle(color: Colors.white)),
)

// 其他日期：透明底深色字
Text('二', style: TextStyle(color: AppColors.dynamicTextDark))
```

## 🔧 技術實現

### 數據結構

**練習數據存儲格式**:
```json
{
  "2025-10-15": 3600,
  "2025-10-16": 5400,
  "2025-10-17": 4200,
  "2025-10-18": 0,
  "2025-10-19": 1800
}
```
- **鍵**: 日期字符串 (YYYY-MM-DD)
- **值**: 練習秒數 (int)

**SharedPreferences 鍵**:
- `practice_data`: 存儲所有練習記錄

### 核心邏輯

#### 1. 計時器實現
```dart
Timer? _timer;
int _elapsedSeconds = 0;

void _startTimer() {
  _timer = Timer.periodic(Duration(seconds: 1), (timer) {
    setState(() {
      _elapsedSeconds++;  // 每秒增加
    });
  });
}

void _pauseTimer() {
  _timer?.cancel();  // 取消定時器
}
```

#### 2. 保存練習時長
```dart
Future<void> _stopTimer() async {
  final today = _getTodayString();
  final currentSeconds = _weeklyPracticeData[today] ?? 0;
  
  setState(() {
    // 累加到當日總時長
    _weeklyPracticeData[today] = currentSeconds + _elapsedSeconds;
    _elapsedSeconds = 0;
  });
  
  await _savePracticeData();
}
```

#### 3. 本週日期計算
```dart
List<DateTime> _getWeekDates() {
  final now = DateTime.now();
  final weekday = now.weekday; // 1 = Monday, 7 = Sunday
  final monday = now.subtract(Duration(days: weekday - 1));
  
  return List.generate(7, (index) => monday.add(Duration(days: index)));
}
```

**邏輯說明**:
1. 獲取今天是星期幾（1-7）
2. 計算本週一的日期（往回推 weekday-1 天）
3. 生成週一到週日的 7 個日期

#### 4. 長條圖比例計算
```dart
int _getMaxMinutes() {
  final weekDates = _getWeekDates();
  int maxMinutes = 0;
  
  for (final date in weekDates) {
    final minutes = _getPracticeMinutes(date);
    if (minutes > maxMinutes) {
      maxMinutes = minutes;
    }
  }
  
  return maxMinutes > 0 ? maxMinutes : 60; // 最小刻度 60 分鐘
}

// 長條高度 = (該日分鐘數 / 最大分鐘數) * 最大高度
final heightRatio = minutes / maxMinutes;
final barHeight = heightRatio * 150; // 最大高度 150px
```

**比例示例**:
```
最大練習時長: 120 分鐘

週一: 60 分 → 高度 = (60/120) * 150 = 75px
週二: 120 分 → 高度 = (120/120) * 150 = 150px (最高)
週三: 30 分 → 高度 = (30/120) * 150 = 37.5px
```

### 時間格式化

```dart
String _formatTime(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  } else {
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
```

**輸出示例**:
- `0` 秒 → `00:00`
- `90` 秒 → `01:30`
- `3665` 秒 → `01:01:05`

### 生命週期管理

```dart
@override
void dispose() {
  _timer?.cancel();  // 清理定時器
  super.dispose();
}
```

**重要性**: 防止內存洩漏，頁面銷毀時取消定時器

## 📂 文件結構

### 新增文件

**lib/widgets/practice_timer_card.dart** (530+ 行)
- `PracticeTimerCard` - StatefulWidget
- 計時器邏輯
- 數據持久化
- 長條圖渲染

### 修改文件

**lib/pages/home_page.dart**
- 導入 `practice_timer_card.dart`
- 在 `CheckInCard` 下方添加 `PracticeTimerCard`

**修改內容**:
```dart
// 添加導入
import 'package:music_practice_app/widgets/practice_timer_card.dart';

// 在 ListView 中添加
const CheckInCard(),
const SizedBox(height: 16),
const PracticeTimerCard(),  // ← 新增
const SizedBox(height: 24),
```

## 🎯 用戶使用流程

### 場景 1：開始練習
```
1. 用戶打開 App 首頁
2. 看到「練習計時」卡片
3. 點擊 [▶️ 開始] 按鈕
4. 計時器開始跳動：00:00 → 00:01 → 00:02...
5. 按鈕變為 [⏸️ 暫停] 和 [⏹️ 結束]
```

### 場景 2：暫停與繼續
```
1. 練習中途需要休息
2. 點擊 [⏸️ 暫停]
3. 計時器停止（時間保持）
4. 按鈕變為 [▶️ 開始] 和 [⏹️ 結束]
5. 休息完畢，點擊 [▶️ 開始] 繼續計時
```

### 場景 3：結束練習
```
1. 練習完成，點擊 [⏹️ 結束]
2. 彈出提示：「已記錄本次練習時長！」
3. 計時器歸零：00:00
4. 本週長條圖更新（今天的長條變高）
5. 本週總時長數字更新
```

### 場景 4：查看本週統計
```
1. 滾動到長條圖區域
2. 看到週一到週日的練習時長
3. 今天的日期有藍色背景標記
4. 長條上方顯示具體分鐘數
5. 標題右側顯示本週總時長
```

## 📊 數據示例

### 練習記錄示例
```
週一: 60 分鐘 (1小時)
週二: 90 分鐘 (1小時30分)
週三: 45 分鐘
週四: 0 分鐘 (未練習)
週五: 120 分鐘 (2小時)
週六: 30 分鐘
週日: 0 分鐘 (當天)

本週總計: 345 分鐘 = 5小時45分鐘
```

### 長條圖視覺效果
```
120分 ─────────  ← 最高 (週五)
       
 90分 ─────  █   
            █   
 60分 ─  █  █    
       █  █  █    
 45分 █ █  █  █  █  
     █ █  █  █  █  █
 30分█ █ ██  █ ██ █
    ───────────────
    一二三四五六日
       ↑ 今天
```

## ✅ 功能測試清單

### 計時器功能
- [x] 開始按鈕啟動計時
- [x] 暫停按鈕停止計時
- [x] 繼續按鈕恢復計時
- [x] 結束按鈕保存並重置
- [x] 時間格式正確顯示
- [x] 多次練習累加正確

### 數據持久化
- [x] 練習時長正確保存
- [x] App 重啟後數據保留
- [x] 日期索引正確
- [x] 多日數據互不干擾

### 長條圖顯示
- [x] 本週7天正確顯示
- [x] 今天日期高亮
- [x] 長條高度比例正確
- [x] 時長文字顯示正確
- [x] 本週總時長計算正確
- [x] 無數據時顯示空長條

### UI/UX
- [x] 按鈕狀態切換流暢
- [x] 載入指示器正常顯示
- [x] 顏色主題適配
- [x] 響應式佈局正常
- [x] 提示訊息正確顯示

## 🚀 未來增強建議

### 1. 統計增強
```dart
// 月度統計
Widget _buildMonthlyChart() {
  // 顯示本月每週的練習時長
}

// 年度總覽
Widget _buildYearlyOverview() {
  // 顯示全年練習趨勢
}
```

### 2. 目標設定
```dart
// 每日目標
int _dailyGoalMinutes = 60; // 每日目標 60 分鐘

// 進度圓環
CircularProgressIndicator(
  value: todayMinutes / _dailyGoalMinutes,
  backgroundColor: Colors.grey[300],
  valueColor: AlwaysStoppedAnimation(AppColors.dynamicPrimary),
)
```

### 3. 成就系統
```dart
// 里程碑獎勵
Map<String, bool> _achievements = {
  'first_practice': false,     // 首次練習
  'continuous_7_days': false,  // 連續7天
  'total_100_hours': false,    // 累計100小時
};
```

### 4. 通知提醒
```dart
// 每日練習提醒
void _scheduleNotification() {
  // 每天晚上8點提醒練琴
  final scheduledTime = Time(20, 0, 0);
  // 使用 flutter_local_notifications
}
```

### 5. 數據導出
```dart
// CSV 導出
Future<void> _exportToCSV() async {
  final csv = '日期,練習時長(分鐘)\n';
  for (final entry in _weeklyPracticeData.entries) {
    csv += '${entry.key},${entry.value ~/ 60}\n';
  }
  // 保存到文件
}
```

### 6. 社交分享
```dart
// 分享本週成績
void _shareWeeklyProgress() {
  final text = '本週練琴 ${_formatWeekTotal()}，繼續加油！💪';
  // 使用 share_plus 分享
}
```

### 7. 智能分析
```dart
// AI 建議
String _getSmartSuggestion() {
  if (averageMinutes < 30) {
    return '建議每天至少練習30分鐘哦！';
  } else if (continuousDays >= 7) {
    return '太棒了！已連續練習7天！🎉';
  }
  return '保持規律練習，進步會更快！';
}
```

## 💡 設計考量

### 為什麼用長條圖？
1. **直觀易懂** - 一眼看出哪天練得多/少
2. **對比明顯** - 不同天數的差異清晰可見
3. **趨勢明顯** - 可以看出練習規律
4. **空間高效** - 7天數據緊湊呈現

### 為什麼分開始/暫停/結束？
1. **靈活性** - 中途休息可以暫停
2. **準確性** - 只記錄實際練習時間
3. **用戶控制** - 提供更多操作選擇
4. **防誤操作** - 暫停和結束分開，避免誤點

### 為什麼記錄秒數而非分鐘？
1. **精確性** - 保留完整時間資訊
2. **靈活顯示** - 可轉換為任意格式
3. **累加方便** - 直接相加無需轉換
4. **擴展性** - 未來可精確到秒級分析

## 📅 完成日期
2025年10月19日

---

**開發者**: GitHub Copilot  
**版本**: 1.0.0  
**最後更新**: 2025/10/19  
**相關文件**: 
- `lib/widgets/practice_timer_card.dart` (新增)
- `lib/pages/home_page.dart` (修改)

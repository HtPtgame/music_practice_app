# 動物圖鑑功能說明

## 📚 功能概述

動物圖鑑是一個收集系統,鼓勵使用者每天練習打卡,累積打卡天數來解鎖可愛的動物。

## 🔄 與首頁打卡系統整合

**重要更新**: 動物圖鑑現已與首頁的打卡日曆系統完全整合！

### 整合特色
- ✅ **統一數據源**: 使用首頁的 `checked_dates` 打卡記錄
- ✅ **自動同步**: 在首頁打卡後，動物圖鑑自動更新解鎖進度
- ✅ **即時更新**: 點擊圖鑑頁面的重新整理按鈕即可同步最新進度
- ✅ **雲端同步**: 打卡記錄透過 Firebase 同步，跨設備也能保持收集進度

### 使用流程
1. **在首頁打卡**: 到首頁的「練習打卡」日曆點擊打卡按鈕
2. **查看動物圖鑑**: 進入設定頁 → 動物圖鑑
3. **自動解鎖**: 達到指定天數後，動物自動變成彩色並解鎖
4. **手動重新整理**: 點擊右上角的重新整理圖示可立即同步最新進度

### 技術實現
```dart
// 動物圖鑑直接讀取首頁的打卡數據
final prefs = await SharedPreferences.getInstance();
final checkedDatesJson = prefs.getStringList('checked_dates') ?? [];
final consecutiveDays = prefs.getInt('consecutive_days') ?? 0;

// 根據打卡天數自動解鎖動物
_collectionService.checkAndUnlockAnimals(checkedDates.length);
```

## 🎯 核心功能

### 1. 打卡系統（整合首頁）
- **每日打卡**: 在首頁打卡日曆進行打卡
- **連續打卡**: 自動追蹤連續打卡天數
- **總打卡天數**: 累積總打卡天數用於解鎖動物
- **跨設備同步**: 透過 Firebase 雲端同步打卡記錄

### 2. 動物收集
目前有 **22 隻動物**可收集，每 7 天解鎖一隻:

| 順序 | 動物 | 名稱 | 解鎖條件 | 檔案 |
|------|------|------|----------|------|
| 1 | 🐱 | 可愛貓咪 | 打卡 7 天 | assets/cat.png |
| 2 | 🐶 | 忠誠小狗 | 打卡 14 天 | assets/dog.png |
| 3 | 🦊 | 聰明狐狸 | 打卡 21 天 | assets/fox.png |
| 4 | 🐼 | 萌萌熊貓 | 打卡 28 天 | assets/panda.png |
| 5 | 🐰 | 活潑兔子 | 打卡 35 天 | assets/rabbit.png |
| 6 | 🐻 | 可愛熊熊 | 打卡 42 天 | assets/bear.png |
| 7 | 🦌 | 優雅小鹿 | 打卡 49 天 | assets/deer.png |
| 8 | 🐧 | 企鵝寶寶 | 打卡 56 天 | assets/penguin.png |
| 9 | 🐨 | 無尾熊 | 打卡 63 天 | assets/koala.png |
| 10 | 🦝 | 浣熊小可愛 | 打卡 70 天 | assets/raccoon.png |
| 11 | 🐿️ | 松鼠 | 打卡 77 天 | assets/squirrel.png |
| 12 | 🦔 | 刺蝟 | 打卡 84 天 | assets/hedgehog.png |
| 13 | 🦭 | 海豹 | 打卡 91 天 | assets/seal.png |
| 14 | 🐑 | 綿羊 | 打卡 98 天 | assets/sheep.png |
| 15 | 🦁 | 獅子王 | 打卡 105 天 | assets/lion.png |
| 16 | 🦘 | 袋鼠 | 打卡 112 天 | assets/kangaroo.png |
| 17 | 🦥 | 樹懶 | 打卡 119 天 | assets/sloth.png |
| 18 | 🐹 | 天竺鼠 | 打卡 126 天 | assets/guinea pig.png |
| 19 | 🦫 | 土撥鼠 | 打卡 133 天 | assets/prairie dog.png |
| 20 | 😊 | 短尾矮袋鼠 | 打卡 140 天 | assets/Quokka.png |
| 21 | 🧚 | 小精靈 | 打卡 147 天 | assets/fairy.png |
| 22 | 🐻 | 台灣黑熊 | 打卡 154 天 | assets/taiwanbear.png |

**完整收集需要 154 天！**

### 3. 視覺效果
- **已解鎖**: 顯示彩色原圖 + 金色邊框 + "已收集"標籤
- **未解鎖**: 
  - 灰階濾鏡 (ColorFilter.matrix 轉成灰色)
  - 降低透明度 (opacity: 0.3)
  - 顯示 "???" 隱藏名稱
  - 顯示解鎖進度條

### 4. 統計資訊
- **收集進度**: 已收集/總數 (例如: 2/4)
- **總打卡天數**: 累積的所有打卡天數
- **連續打卡**: 當前連續打卡天數(如果中斷會重置)
- **進度條**: 視覺化顯示收集進度

## 🚀 使用流程

1. **進入圖鑑**
   - 設定頁面 → "動物圖鑑" 卡片
   - 路徑: `/animal-collection`

2. **在首頁打卡**
   - 返回首頁 → "練習打卡" 卡片
   - 點擊「打卡」按鈕完成當日打卡
   - 打卡記錄會自動同步到雲端（如已登入）

3. **查看動物**
   - 返回動物圖鑑頁面（或點擊重新整理按鈕）
   - 3x3 網格顯示所有動物
   - 點擊卡片查看詳細資訊
   - 未解鎖: 顯示需要天數和當前進度
   - 已解鎖: 顯示解鎖時間

4. **自動解鎖動物**
   - 達到指定天數時，動物自動解鎖
   - 解鎖後變成彩色並顯示金色邊框
   - 狀態標記為「已收集」

## 📁 檔案結構

```
lib/
├── models/
│   └── animal_collection.dart       # 動物模型 + 圖鑑服務
├── pages/
│   ├── animal_collection_page.dart  # 圖鑑頁面（整合首頁打卡）
│   └── settings_page.dart           # 設定頁面(含入口)
├── widgets/
│   └── check_in_card.dart           # 首頁打卡日曆卡片
├── services/
│   └── user_data_sync_service.dart  # 雲端同步服務
└── router/
    └── app_router.dart              # 路由配置

assets/
├── cat.png                          # 貓咪圖片
├── dog.png                          # 小狗圖片
├── fox.png                          # 狐狸圖片
└── panda.png                        # 熊貓圖片
... (共 22 張動物圖片)
```

## 💾 資料持久化

### SharedPreferences 儲存（首頁打卡系統）
```dart
'checked_dates'        // List<String> - 打卡日期列表 (格式: 'yyyy-MM-dd')
'consecutive_days'     // int - 連續打卡天數
```

### 動物圖鑑整合
- ✅ 直接讀取 `checked_dates` 計算累計打卡天數
- ✅ 直接讀取 `consecutive_days` 顯示連續打卡
- ✅ 解鎖狀態根據打卡天數即時計算（無需額外儲存）
- 🔄 未來可擴展: 添加 SharedPreferences 儲存解鎖時間

### 雲端同步（Firebase Firestore）
- ✅ 打卡記錄自動同步到雲端
- ✅ 跨設備數據一致性
- ✅ 離線優先架構（本地先存，後台同步）

## 🎨 UI 特色

### 1. 統計卡片
- 漸層藍色背景 (400 → 600)
- 三個統計指標並排
- 白色進度條

### 2. 動物卡片
- 正方形卡片 (aspectRatio: 0.75)
- **3列網格布局** (crossAxisCount: 3) - 容納 22 隻動物
- 動態陰影 (已解鎖: elevation 8, 未解鎖: elevation 2)
- 金色/灰色邊框
- 自適應字體大小 (13px 名稱, 11px 狀態)

### 3. 灰階濾鏡實現
```dart
ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, // 轉成灰階
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0,      0,      0,      1, 0,
])
```

### 4. 進度條
- 顯示當前進度/需求天數
- 藍色填充 (Colors.blue[400])
- 圓角設計

## 🔧 技術細節

### 整合首頁打卡系統
```dart
// 動物圖鑑頁面載入打卡數據
Future<void> _loadData() async {
  final prefs = await SharedPreferences.getInstance();
  final checkedDatesJson = prefs.getStringList('checked_dates') ?? [];
  final consecutiveDays = prefs.getInt('consecutive_days') ?? 0;
  
  setState(() {
    _checkedDates = checkedDatesJson.toSet();
    _consecutiveDays = consecutiveDays;
    // 根據打卡天數解鎖動物
    _collectionService.checkAndUnlockAnimals(_checkedDates.length);
  });
}
```

### 打卡按鈕引導邏輯
```dart
// 點擊圖鑑頁的打卡按鈕會提示用戶到首頁打卡
Future<void> _handleCheckIn() async {
  if (_hasCheckedToday()) {
    // 已打卡提示
    ScaffoldMessenger.showSnackBar('今天已經打卡過了！');
    return;
  }

  // 顯示對話框引導到首頁打卡
  final shouldGoHome = await showDialog<bool>(
    builder: (context) => AlertDialog(
      title: Text('打卡提示'),
      content: Text('請到首頁的打卡日曆進行打卡\n\n打卡後，動物圖鑑會自動同步解鎖進度！'),
      actions: [
        TextButton(child: Text('取消')),
        FilledButton(child: Text('前往首頁')),
      ],
    ),
  );

  if (shouldGoHome == true) {
    Navigator.pop(context); // 返回首頁
  }
}
```

### 連續打卡計算（使用首頁邏輯）
```dart
// 首頁的 CheckInCard 負責計算連續天數
void _updateConsecutiveDays() {
  final today = DateTime.now();
  int consecutive = 0;
  
  // 從今天開始往回檢查
  for (int i = 0; i < 365; i++) {
    final checkDate = today.subtract(Duration(days: i));
    final dateString = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
    
    if (_checkedDates.contains(dateString)) {
      consecutive++;
    } else {
      if (i == 0 && !_checkedDates.contains(todayString)) {
        continue; // 今天還沒打卡，從昨天開始算
      }
      break; // 遇到未打卡的日子就停止
    }
  }
  
  _consecutiveDays = consecutive;
}
```

### 自動解鎖機制
```dart
void checkAndUnlockAnimals(int totalCheckInDays) {
  for (var animal in _allAnimals) {
    if (_unlockedAnimals.any((a) => a.id == animal.id)) continue;
    
    if (totalCheckInDays >= animal.requiredCheckInDays) {
      final unlockedAnimal = animal.copyWith(unlockedAt: DateTime.now());
      _unlockedAnimals.add(unlockedAnimal);
    }
  }
}
```

## 🎮 未來擴展

1. **更多動物**: 添加更多可收集的動物
2. **特殊解鎖**: 完成特定任務解鎖稀有動物
3. **動物互動**: 點擊動物播放動畫或聲音
4. **分享功能**: 分享收集成就到社群媒體
5. **~~雲端同步~~**: ✅ 已實現！使用 Firebase 同步收集進度
6. **獎勵系統**: 收集全部動物獲得特殊稱號
7. **動物故事**: 每隻動物有獨特的背景故事
8. **成就徽章**: 不同收集里程碑的徽章系統

## 🐛 已知問題

- 無

## ✅ 測試清單

- [ ] 首次打開圖鑑,所有動物都是灰色
- [ ] 在首頁打卡後天數增加
- [ ] 達到 7/14/21/28 天時動物自動解鎖
- [ ] 解鎖動物顯示彩色並有金框
- [ ] 點擊圖鑑頁打卡按鈕顯示引導對話框
- [ ] 點擊「前往首頁」按鈕返回首頁
- [ ] 連續打卡天數正確顯示（與首頁一致）
- [ ] 總打卡天數正確顯示（與首頁一致）
- [ ] 點擊重新整理按鈕後數據更新
- [ ] 進度條百分比正確顯示
- [ ] 點擊動物卡片顯示詳細對話框
- [ ] 路由導航正常 (設定頁 ↔ 圖鑑頁)
- [ ] 雲端同步正常（登入後打卡記錄同步到 Firebase）

## 📝 整合總結

### 修改項目
1. **移除獨立打卡系統**
   - 刪除 `CheckInService` 的使用
   - 移除獨立的打卡邏輯

2. **整合首頁數據**
   - 讀取 `checked_dates` (首頁打卡記錄)
   - 讀取 `consecutive_days` (連續天數)
   - 使用 `_checkedDates.length` 計算總天數

3. **優化使用者體驗**
   - 打卡按鈕改為引導到首頁
   - 添加重新整理按鈕
   - 自動同步解鎖進度

4. **保持原有功能**
   - ✅ 動物收集系統完整保留
   - ✅ 解鎖機制正常運作
   - ✅ UI/UX 視覺效果不變
   - ✅ 統計資訊正確顯示

### 優點
- ✅ **單一數據源**: 避免數據不一致
- ✅ **減少冗餘**: 不需要維護兩套打卡系統
- ✅ **更好的 UX**: 統一的打卡入口
- ✅ **雲端同步**: 打卡記錄自動同步到 Firebase
- ✅ **簡化維護**: 減少代碼複雜度

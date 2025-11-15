# 動物圖鑑功能說明

## 📚 功能概述

動物圖鑑是一個收集系統,鼓勵使用者每天練習打卡,累積打卡天數來解鎖可愛的動物。

## 🎯 核心功能

### 1. 打卡系統
- **每日打卡**: 每天可以打卡一次
- **連續打卡**: 追蹤連續打卡天數
- **總打卡天數**: 累積總打卡天數用於解鎖動物

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

2. **查看動物**
   - 2x2 網格顯示所有動物
   - 點擊卡片查看詳細資訊
   - 未解鎖: 顯示需要天數和當前進度
   - 已解鎖: 顯示解鎖時間

3. **打卡獲得動物**
   - 點擊右下角藍色按鈕打卡
   - 每天只能打卡一次
   - 達到天數自動解鎖動物
   - 解鎖後會顯示 SnackBar 提示

## 📁 檔案結構

```
lib/
├── models/
│   └── animal_collection.dart       # 動物模型 + 圖鑑服務
├── services/
│   └── check_in_service.dart        # 打卡服務
├── pages/
│   ├── animal_collection_page.dart  # 圖鑑頁面
│   └── settings_page.dart           # 設定頁面(含入口)
└── router/
    └── app_router.dart              # 路由配置

assets/
├── cat.png                          # 貓咪圖片
├── dog.png                          # 小狗圖片
├── fox.png                          # 狐狸圖片
└── panda.png                        # 熊貓圖片
```

## 💾 資料持久化

使用 **SharedPreferences** 儲存:

### CheckInService
```dart
'check_in_dates'        // List<String> - 打卡日期列表
'total_check_in_days'   // int - 總打卡天數
```

### AnimalCollectionService
- 目前動物資料是靜態的 (不持久化)
- 解鎖狀態根據打卡天數即時計算
- 可擴展: 添加 SharedPreferences 儲存解鎖時間

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

### 連續打卡計算
```dart
// 從最近的日期往回數
// 只要有任何一天中斷就停止計數
int get currentStreak {
  if (_checkInDates.isEmpty) return 0;
  
  int streak = 0;
  final today = DateTime(now.year, now.month, now.day);
  var checkDate = today;
  
  for (var i = _checkInDates.length - 1; i >= 0; i--) {
    final date = DateTime(date.year, date.month, date.day);
    if (date == checkDate) {
      streak++;
      checkDate = checkDate.subtract(Duration(days: 1));
    } else break;
  }
  
  return streak;
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
5. **雲端同步**: 使用 Firebase 同步收集進度
6. **獎勵系統**: 收集全部動物獲得特殊稱號
7. **動物故事**: 每隻動物有獨特的背景故事
8. **成就徽章**: 不同收集里程碑的徽章系統

## 🐛 已知問題

- 無

## ✅ 測試清單

- [ ] 首次打開圖鑑,所有動物都是灰色
- [ ] 打卡後天數增加
- [ ] 達到 7/14/21/28 天時動物自動解鎖
- [ ] 解鎖動物顯示彩色並有金框
- [ ] 今天打卡後,再次打卡顯示"已打卡"
- [ ] 連續打卡天數正確計算
- [ ] 中斷打卡後連續天數重置
- [ ] 進度條百分比正確顯示
- [ ] 點擊動物卡片顯示詳細對話框
- [ ] 路由導航正常 (設定頁 ↔ 圖鑑頁)

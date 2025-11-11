# 使用者數據同步服務使用說明

## 概述

`UserDataSyncService` 提供了一個便捷的方式，將使用者的本地數據同步到 Firebase Firestore 雲端資料庫。

## 功能特性

### 支援的數據類型

1. **打卡記錄** (`checkInDates`)
   - 類型：`List<DateTime>`
   - 用途：記錄使用者每日打卡日期

2. **練習時間** (`practiceTime`)
   - 類型：`Map<String, int>`
   - 格式：`{"YYYY-MM-DD": 分鐘數}`
   - 用途：記錄每日練習時長

3. **個人化設定** (`settings`)
   - 類型：`Map<String, dynamic>`
   - 用途：儲存使用者偏好設定

4. **文字筆記** (`musicNotes`)
   - 類型：`List<MusicNote>`
   - 用途：音樂學習筆記和文字記錄

## 使用方法

### 1. 取得服務實例

```dart
final syncService = UserDataSyncService();
```

### 2. 同步打卡記錄

#### 完整同步
```dart
// 同步所有打卡記錄
await syncService.syncCheckInDates(checkInDates);
```

#### 新增單筆打卡
```dart
// 新增今日打卡
await syncService.addCheckIn(DateTime.now());
```

**使用範例：**
```dart
// 在打卡元件中
class CheckInCard extends StatelessWidget {
  Future<void> _handleCheckIn() async {
    final syncService = UserDataSyncService();
    
    // 本地打卡邏輯
    final prefs = await SharedPreferences.getInstance();
    // ... 本地儲存邏輯 ...
    
    // 同步到雲端
    await syncService.addCheckIn(DateTime.now());
  }
}
```

### 3. 同步練習時間

#### 完整同步
```dart
await syncService.syncPracticeTime(practiceTimeMap);
```

#### 新增練習時間
```dart
// 新增今日練習 30 分鐘
await syncService.addPracticeTime(DateTime.now(), 30);
```

**使用範例：**
```dart
// 在練習計時器中
class PracticeTimer {
  Future<void> _stopTimer() async {
    final elapsedMinutes = _stopwatch.elapsed.inMinutes;
    final syncService = UserDataSyncService();
    
    // 本地儲存
    // ...
    
    // 同步到雲端
    await syncService.addPracticeTime(DateTime.now(), elapsedMinutes);
  }
}
```

### 4. 同步設定

#### 完整同步
```dart
await syncService.syncSettings(settingsMap);
```

#### 更新單一設定
```dart
// 更新主題設定
await syncService.updateSetting('theme', 'dark');
```

**使用範例：**
```dart
// 在設定頁面
class SettingsPage extends StatelessWidget {
  Future<void> _updateTheme(String theme) async {
    final syncService = UserDataSyncService();
    
    // 更新本地設定
    final settingsService = SettingsService();
    await settingsService.setTheme(theme);
    
    // 同步到雲端
    await syncService.updateSetting('theme', theme);
  }
}
```

### 5. 同步筆記

#### 完整同步
```dart
await syncService.syncMusicNotes(notesList);
```

#### 儲存單筆筆記
```dart
final note = MusicNote(
  id: uuid.v4(),
  title: '練習筆記',
  content: '今天學習了新的和弦...',
  createdAt: DateTime.now(),
);

await syncService.saveNote(note);
```

#### 刪除筆記
```dart
await syncService.deleteNote(noteId);
```

**使用範例：**
```dart
// 筆記編輯器
class NoteEditor extends StatefulWidget {
  Future<void> _saveNote() async {
    final syncService = UserDataSyncService();
    
    final note = MusicNote(
      id: widget.note?.id ?? uuid.v4(),
      title: _titleController.text,
      content: _contentController.text,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // 同步到雲端
    await syncService.saveNote(note);
  }
}
```

### 6. 批量同步

```dart
await syncService.syncAllData(
  checkInDates: checkInDates,
  practiceTime: practiceTime,
  settings: settings,
  musicNotes: musicNotes,
);
```

**使用時機：**
- 使用者登入後首次同步
- 從雲端恢復本地數據
- 批量更新多種數據類型

### 7. 載入使用者數據

```dart
final authService = FirebaseAuthService();
final currentUser = authService.currentUser;

if (currentUser != null) {
  final userData = await syncService.loadUserData(currentUser.id);
  
  if (userData != null) {
    // 使用載入的數據更新本地狀態
    print('打卡次數: ${userData.checkInDates.length}');
    print('筆記數量: ${userData.musicNotes.length}');
  }
}
```

## 監聽同步狀態

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final syncService = UserDataSyncService();
  
  @override
  void initState() {
    super.initState();
    syncService.addListener(_onSyncStateChanged);
  }
  
  @override
  void dispose() {
    syncService.removeListener(_onSyncStateChanged);
    super.dispose();
  }
  
  void _onSyncStateChanged() {
    if (syncService.isSyncing) {
      // 顯示載入指示器
      print('正在同步...');
    } else {
      // 同步完成
      print('同步完成');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: syncService,
      builder: (context, child) {
        return syncService.isSyncing
            ? CircularProgressIndicator()
            : YourContentWidget();
      },
    );
  }
}
```

## 錯誤處理

```dart
try {
  await syncService.addCheckIn(DateTime.now());
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('同步成功')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('同步失敗: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

## 建議的整合模式

### 模式 1: 本地優先 + 被動同步

```dart
// 1. 先更新本地數據
await localDataService.addCheckIn(DateTime.now());

// 2. 異步同步到雲端（失敗不影響本地功能）
syncService.addCheckIn(DateTime.now()).catchError((e) {
  print('雲端同步失敗: $e');
});
```

### 模式 2: 雲端優先 + 主動同步

```dart
try {
  // 1. 同步到雲端
  await syncService.addCheckIn(DateTime.now());
  
  // 2. 更新本地數據
  await localDataService.addCheckIn(DateTime.now());
} catch (e) {
  // 雲端失敗時僅使用本地儲存
  await localDataService.addCheckIn(DateTime.now());
}
```

### 模式 3: 登入時全量同步

```dart
Future<void> syncOnLogin() async {
  final authService = FirebaseAuthService();
  final syncService = UserDataSyncService();
  
  final user = authService.currentUser;
  if (user == null) return;
  
  // 從雲端載入數據
  final cloudData = await syncService.loadUserData(user.id);
  
  if (cloudData != null) {
    // 合併本地和雲端數據
    final mergedCheckIns = _mergeCheckIns(localCheckIns, cloudData.checkInDates);
    final mergedPracticeTime = _mergePracticeTime(localTime, cloudData.practiceTime);
    
    // 上傳合併後的數據
    await syncService.syncAllData(
      checkInDates: mergedCheckIns,
      practiceTime: mergedPracticeTime,
      settings: cloudData.settings,
      musicNotes: cloudData.musicNotes,
    );
  }
}
```

## 注意事項

1. **認證檢查**: 所有同步方法會自動檢查使用者是否已登入，未登入時會靜默返回
2. **並發安全**: 服務使用單例模式，可安全在多處使用
3. **錯誤處理**: 所有同步方法都會拋出例外，需要適當的錯誤處理
4. **網路需求**: 同步需要網路連線，離線時操作會失敗
5. **數據格式**: 確保數據符合 Firestore 支援的類型

## 進階功能建議

### 離線佇列 (未實作)

```dart
// 可擴展的離線同步佇列
class OfflineSyncQueue {
  List<SyncOperation> _queue = [];
  
  void addOperation(SyncOperation op) {
    _queue.add(op);
    _persistQueue(); // 持久化到本地
  }
  
  Future<void> processQueue() async {
    for (var op in _queue) {
      try {
        await op.execute();
        _queue.remove(op);
      } catch (e) {
        // 保留失敗的操作
      }
    }
  }
}
```

### 衝突解決 (未實作)

```dart
// 自定義衝突解決策略
enum ConflictStrategy {
  localWins,    // 本地數據優先
  remoteWins,   // 雲端數據優先
  mergeByTimestamp, // 根據時間戳合併
}
```

## 相關文件

- [Firebase 設定指南](../docs/FIREBASE_SETUP_GUIDE.md)
- [使用者模型文件](../models/user.dart)
- [認證服務文件](firebase_auth_service.dart)

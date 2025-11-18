# 國際化使用指南 (Internationalization Guide)

## 📋 總覽

本專案已實現完整的多語言支援系統，目前支援：
- 🇹🇼 繁體中文（預設）
- 🇺🇸 英文（完整翻譯）
- 🇨🇳 簡體中文（占位）
- 🇯🇵 日文（占位）

## 🎯 使用方法

### 1. 在頁面中使用翻譯

```dart
import 'package:music_practice_app/l10n/app_localizations.dart';

class YourPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 獲取翻譯實例
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.commonAppName), // 使用翻譯文字
      ),
      body: Column(
        children: [
          Text(l10n.homeWelcome),
          ElevatedButton(
            onPressed: () {},
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }
}
```

### 2. 可用的翻譯字串類別

#### 通用 (Common)
- `l10n.commonAppName` - 應用名稱
- `l10n.commonConfirm` - 確認
- `l10n.commonCancel` - 取消
- `l10n.commonSave` - 儲存
- `l10n.commonDelete` - 刪除
- `l10n.commonEdit` - 編輯
- `l10n.commonBack` - 返回
- `l10n.commonClose` - 關閉
- `l10n.commonNext` - 下一步
- `l10n.commonPrevious` - 上一步
- `l10n.commonSettings` - 設定
- `l10n.commonLogout` - 登出

#### 導航 (Navigation)
- `l10n.navHome` - 首頁
- `l10n.navLibrary` - 音樂庫
- `l10n.navPractice` - 練習
- `l10n.navSettings` - 設定
- `l10n.navProfile` - 個人資料

#### 首頁 (Home)
- `l10n.homeWelcome` - 歡迎訊息
- `l10n.homeQuickStart` - 快速開始
- `l10n.homeTodayGoal` - 今日目標

#### 練習 (Practice)
- `l10n.practiceStart` - 開始練習
- `l10n.practiceStop` - 停止練習
- `l10n.practicePause` - 暫停
- `l10n.practiceResume` - 繼續

#### 音樂庫 (Library)
- `l10n.libraryTitle` - 音樂庫
- `l10n.libraryEmptyHint` - 空狀態提示
- `l10n.librarySearchHint` - 搜尋提示

#### 設定 (Settings)
- `l10n.settingsTitle` - 設定
- `l10n.settingsLanguageTitle` - 語言設定
- `l10n.settingsThemeTitle` - 主題設定
- `l10n.settingsAccountTitle` - 帳號設定

#### 錯誤訊息 (Errors)
- `l10n.errorNetworkUnavailable` - 網路錯誤
- `l10n.errorInvalidInput` - 輸入錯誤
- `l10n.errorPermissionDenied` - 權限錯誤

### 3. 切換語言

```dart
// 導入語言管理器
import 'package:music_practice_app/utils/language_manager.dart';

// 切換語言
await LanguageManager.instance.setLocale('en'); // 英文
await LanguageManager.instance.setLocale('zh_TW'); // 繁中
await LanguageManager.instance.setLocale('zh_CN'); // 簡中
await LanguageManager.instance.setLocale('ja'); // 日文

// 獲取當前語言
final currentLocale = LanguageManager.instance.currentLocale;

// 獲取當前語言名稱
final languageName = LanguageManager.instance.currentLanguageName;
```

## 📝 完整翻譯字串列表

查看 `lib/l10n/app_localizations.dart` 中的 `AppLocalizations` 類別，包含 300+ 翻譯字串，涵蓋：

1. **通用 (Common)** - 基本操作按鈕、狀態訊息
2. **導航 (Navigation)** - 頁面名稱、選單項目
3. **首頁 (Home)** - 歡迎訊息、快速操作
4. **打卡 (Check-in)** - 簽到、打卡相關
5. **計時器 (Timer)** - 練習計時功能
6. **動物圖鑑 (Animal)** - 收集系統
7. **音樂庫 (Library)** - 曲目管理
8. **練習 (Practice)** - 練習模式
9. **設定 (Settings)** - 應用設定
10. **登入/註冊 (Auth)** - 認證相關
11. **個人資料 (Profile)** - 用戶資訊
12. **上傳 (Upload)** - 檔案上傳
13. **播放 (Playback)** - MIDI 播放
14. **分析 (Analysis)** - 演奏分析
15. **節拍器 (Metronome)** - 節拍器功能
16. **錯誤訊息 (Errors)** - 各種錯誤
17. **成功訊息 (Success)** - 操作成功提示

## 🔧 新增翻譯字串

1. 打開 `lib/l10n/app_localizations.dart`
2. 在 `AppLocalizations` 類別中新增 getter：
   ```dart
   String get yourNewKey => '中文翻譯';
   ```
3. 在 `AppLocalizationsEn` 類別中覆寫：
   ```dart
   @override
   String get yourNewKey => 'English Translation';
   ```
4. 在需要的地方使用：
   ```dart
   Text(l10n.yourNewKey)
   ```

## ⚠️ 注意事項

1. **必須在 MaterialApp 下使用**：`AppLocalizations.of(context)` 只能在 `MaterialApp` 的子組件中使用
2. **非空斷言**：使用 `!` 進行非空斷言，因為已確保應用會提供翻譯
3. **熱重載限制**：修改翻譯字串後可能需要完全重新啟動應用
4. **上下文依賴**：確保 `context` 來自包含 `MaterialApp` 的 widget tree

## 📊 當前進度

- ✅ 多語言系統架構完成
- ✅ 英文翻譯完成（300+ 字串）
- ✅ 語言切換功能完成
- ✅ 設定頁面整合完成
- ⏳ 待更新：約 20 個頁面和組件需要替換硬編碼字串

## 🚀 下一步

建議按優先級更新以下頁面：

1. **高優先級**
   - `home_page.dart` - 首頁
   - `login_page.dart` - 登入頁
   - `register_page.dart` - 註冊頁

2. **中優先級**
   - `library_page.dart` - 音樂庫
   - `practice_page.dart` - 練習頁
   - `profile_page.dart` - 個人資料

3. **低優先級**
   - 其他功能頁面
   - 小型組件

## 📖 範例：更新現有頁面

### 更新前（硬編碼中文）
```dart
Text('歡迎使用'),
ElevatedButton(
  onPressed: () {},
  child: Text('開始練習'),
),
```

### 更新後（使用翻譯）
```dart
final l10n = AppLocalizations.of(context)!;

Text(l10n.homeWelcome),
ElevatedButton(
  onPressed: () {},
  child: Text(l10n.practiceStart),
),
```

## 🌐 支援的語言代碼

- `zh_TW` - 繁體中文（台灣）
- `en` - 英文（美國）
- `zh_CN` - 簡體中文（中國）
- `ja` - 日文（日本）

---

**更多資訊**：查看 `lib/l10n/app_localizations.dart` 和 `lib/utils/language_manager.dart`

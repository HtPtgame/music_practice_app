import 'package:flutter/material.dart';

/// 應用程式本地化類別
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// 獲取當前語言的本地化實例
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// 支援的語言代碼
  static const List<Locale> supportedLocales = [
    Locale('zh', 'TW'), // 繁體中文（台灣）
    Locale('en', 'US'), // 英文（美國）
    Locale('zh', 'CN'), // 簡體中文（中國）
    Locale('ja', 'JP'), // 日文（日本）
  ];

  /// 根據語言代碼獲取本地化實例
  static AppLocalizations _getLocalizations(String languageCode) {
    switch (languageCode) {
      case 'en_US':
        return AppLocalizationsEn(const Locale('en', 'US'));
      case 'zh_CN':
        return AppLocalizationsZhCn(const Locale('zh', 'CN'));
      case 'ja_JP':
        return AppLocalizationsJa(const Locale('ja', 'JP'));
      case 'zh_TW':
      default:
        return AppLocalizationsZhTw(const Locale('zh', 'TW'));
    }
  }

  // ========== 通用 ==========
  String get appName => '音靈偵探';
  String get yes => '是';
  String get no => '否';
  String get ok => '確定';
  String get cancel => '取消';
  String get save => '儲存';
  String get delete => '刪除';
  String get edit => '編輯';
  String get confirm => '確認';
  String get back => '返回';
  String get next => '下一步';
  String get skip => '跳過';
  String get retry => '重試';
  String get loading => '載入中...';
  String get success => '成功';
  String get error => '錯誤';
  String get warning => '警告';
  String get info => '資訊';

  // ========== 底部導航欄 ==========
  String get navHome => '首頁';
  String get navLibrary => '音樂庫';
  String get navPractice => '練習';
  String get navSettings => '設定';

  // ========== 首頁 ==========
  String get homeTitle => '首頁';
  String get homeWelcome => '歡迎回來';
  String get homeCheckIn => '練習打卡';
  String get homeCheckInDesc => '今天也要加油練習！';
  String get homeCheckInButton => '打卡';
  String get homeCheckedIn => '今日已打卡';
  String get homeConsecutiveDays => '連續';
  String get homeTotalDays => '累計';
  String get homeDays => '天';
  String get homeAnimalCollection => '動物圖鑑';
  String get homeAnimalCollectionDesc => '收集可愛動物，打卡解鎖驚喜！';
  String get homePracticeTimer => '練習計時';
  String get homePracticeTimerDesc => '記錄你的練習時光';
  String get homeThisWeek => '本週';
  String get homeThisMonth => '本月';
  String get homeAverage => '平均';
  String get homeTotal => '總計';
  String get homePerDay => '/天';
  
  // ========== 打卡 ==========
  String get checkInSuccess => '打卡成功！';
  String get checkInAlreadyChecked => '今天已經打卡過了！';
  String get checkInStreak => '連續打卡';
  String get checkInTotal => '累計打卡';
  
  // ========== 練習計時器 ==========
  String get timerTitle => '今日累計時長（隔日自動重置）';
  String get timerStart => '開始';
  String get timerPause => '暫停';
  String get timerReset => '重置';
  String get timerRecorded => '已記錄本次練習';
  String get timerTodayTotal => '今日累計';
  String get timerWeekAverage => '本週平均';
  String get timerMonthTotal => '本月累計';
  String get timerResetConfirm => '確定要重置今日計時嗎？';
  String get timerResetSuccess => '計時器已重置';
  String get timerWarningTitle => '計時器運行中';
  String get timerWarningMessage => '練習計時器正在運行中！\n\n切換頁面將導致本次計時數據不被記錄。\n建議先暫停計時器再切換頁面。\n\n確定要離開此頁面嗎？';
  String get timerStayHere => '留在此頁';
  String get timerLeave => '確定離開';
  
  // ========== 動物圖鑑 ==========
  String get animalCollectionTitle => '動物圖鑑';
  String get animalCollectionStats => '收集統計';
  String get animalCollectionUnlocked => '已解鎖';
  String get animalCollectionTotal => '總共';
  String get animalCollectionRate => '收集率';
  String get animalCollectionUnknown => '???';
  String get animalCollectionLocked => '未解鎖';
  String get animalCollectionNeedDays => '需';
  String get animalCollectionUnlockedAt => '解鎖時間';
  String get animalCollectionCollected => '已收集';
  String get animalCollectionClose => '關閉';

  // ========== 音樂庫 ==========
  String get libraryTitle => '音樂庫';
  String get libraryEmpty => '目前沒有音樂檔案';
  String get libraryEmptyDesc => '點擊下方按鈕上傳您的第一個 MIDI 檔案';
  String get libraryUpload => '上傳 MIDI';
  String get librarySearchHint => '搜尋音樂...';
  String get libraryFilterAll => '全部';
  String get libraryFilterFavorite => '最愛';
  String get libraryFilterRecent => '最近播放';
  String get libraryPlay => '播放';
  String get libraryDelete => '刪除';
  String get libraryDeleteConfirm => '確定要刪除這個檔案嗎？';
  String get libraryDeleteSuccess => '檔案已刪除';
  
  // ========== 練習頁面 ==========
  String get practiceTitle => '練習';
  String get practiceSelectFile => '選擇要練習的曲目';
  String get practiceNoFile => '沒有可用的 MIDI 檔案';
  String get practiceStart => '開始練習';
  String get practiceStop => '停止練習';
  String get practiceRecord => '開始錄音';
  String get practiceStopRecord => '停止錄音';
  String get practicePlayback => '播放錄音';
  String get practiceAnalyze => '分析';
  String get practiceSave => '儲存';
  
  // ========== 設定頁面 ==========
  String get settingsTitle => '設定';
  String get settingsAccount => '帳號設定';
  String get settingsAudio => '音訊設定';
  String get settingsLanguage => '語言設定';
  String get settingsOther => '其他設定';
  String get settingsAbout => '關於';
  
  // 帳號相關
  String get settingsLogin => '登入';
  String get settingsLogout => '登出';
  String get settingsRegister => '註冊';
  String get settingsProfile => '個人資料';
  String get settingsGuest => '訪客模式';
  String get settingsGuestDesc => '登入以同步您的數據';
  
  // 音訊設定
  String get settingsMasterVolume => '主音量';
  String get settingsMidiVolume => 'MIDI 音量';
  String get settingsMetronomeVolume => '節拍器音量';
  String get settingsRecordingVolume => '錄音音量';
  String get settingsPlaybackSpeed => '播放速度';
  
  // 語言設定
  String get settingsLanguageTitle => '語言';
  String get settingsLanguageSelect => '選擇語言';
  String get settingsLanguageCurrent => '當前語言';
  
  // 其他設定
  String get settingsNotification => '通知設定';
  String get settingsTheme => '主題設定';
  String get settingsThemeLight => '淺色';
  String get settingsThemeDark => '深色';
  String get settingsThemeSystem => '跟隨系統';
  
  // 關於
  String get settingsAboutApp => '關於應用程式';
  String get settingsVersion => '版本';
  String get settingsPrivacy => '隱私政策';
  String get settingsTerms => '使用條款';
  
  // ========== 登入頁面 ==========
  String get loginTitle => '登入';
  String get loginEmail => '電子郵件';
  String get loginPassword => '密碼';
  String get loginButton => '登入';
  String get loginForgotPassword => '忘記密碼？';
  String get loginNoAccount => '還沒有帳號？';
  String get loginRegisterNow => '立即註冊';
  String get loginWithGoogle => '使用 Google 登入';
  String get loginWithApple => '使用 Apple 登入';
  String get loginAsGuest => '以訪客身分繼續';
  String get loginEmailRequired => '請輸入電子郵件';
  String get loginPasswordRequired => '請輸入密碼';
  String get loginInvalidEmail => '電子郵件格式不正確';
  String get loginError => '登入失敗';
  String get loginSuccess => '登入成功';
  
  // ========== 註冊頁面 ==========
  String get registerTitle => '註冊';
  String get registerUsername => '使用者名稱';
  String get registerEmail => '電子郵件';
  String get registerPassword => '密碼';
  String get registerConfirmPassword => '確認密碼';
  String get registerButton => '註冊';
  String get registerHaveAccount => '已經有帳號？';
  String get registerLoginNow => '立即登入';
  String get registerUsernameRequired => '請輸入使用者名稱';
  String get registerEmailRequired => '請輸入電子郵件';
  String get registerPasswordRequired => '請輸入密碼';
  String get registerPasswordMismatch => '密碼不一致';
  String get registerError => '註冊失敗';
  String get registerSuccess => '註冊成功';
  
  // ========== 個人資料頁面 ==========
  String get profileTitle => '個人資料';
  String get profileEdit => '編輯資料';
  String get profileSave => '儲存';
  String get profileCancel => '取消';
  String get profileChangePassword => '變更密碼';
  String get profileDeleteAccount => '刪除帳號';
  String get profileDeleteConfirm => '確定要刪除帳號嗎？此操作無法復原。';
  String get profileLogout => '登出';
  String get profileLogoutConfirm => '確定要登出嗎？';
  
  // ========== 上傳頁面 ==========
  String get uploadTitle => '上傳 MIDI';
  String get uploadSelectFile => '選擇檔案';
  String get uploadDragDrop => '或拖曳檔案到此處';
  String get uploadSupported => '支援格式：.mid, .midi';
  String get uploadButton => '上傳';
  String get uploadProgress => '上傳中...';
  String get uploadSuccess => '上傳成功';
  String get uploadError => '上傳失敗';
  String get uploadNoFile => '請先選擇檔案';
  
  // ========== 播放頁面 ==========
  String get playbackTitle => '播放';
  String get playbackPlay => '播放';
  String get playbackPause => '暫停';
  String get playbackStop => '停止';
  String get playbackSpeed => '速度';
  String get playbackLoop => '循環';
  String get playbackLoopOn => '循環播放';
  String get playbackLoopOff => '關閉循環';
  
  // ========== 分析頁面 ==========
  String get analysisTitle => '演奏分析';
  String get analysisScore => '分數';
  String get analysisAccuracy => '準確度';
  String get analysisTiming => '節奏';
  String get analysisPitch => '音準';
  String get analysisDetails => '詳細分析';
  String get analysisExcellent => '優秀';
  String get analysisGood => '良好';
  String get analysisFair => '尚可';
  String get analysisNeedsWork => '需改進';
  
  // ========== 節拍器 ==========
  String get metronomeTitle => '節拍器';
  String get metronomeBPM => '速度 (BPM)';
  String get metronomeStart => '開始';
  String get metronomeStop => '停止';
  String get metronomeTimeSignature => '拍號';
  
  // ========== 錯誤訊息 ==========
  String get errorNetwork => '網路連線錯誤';
  String get errorServer => '伺服器錯誤';
  String get errorUnknown => '未知錯誤';
  String get errorFileNotFound => '找不到檔案';
  String get errorPermissionDenied => '權限被拒絕';
  String get errorInvalidFormat => '格式不正確';
  
  // ========== 成功訊息 ==========
  String get successSaved => '儲存成功';
  String get successDeleted => '刪除成功';
  String get successUploaded => '上傳成功';
  String get successUpdated => '更新成功';
}

/// 繁體中文（台灣）
class AppLocalizationsZhTw extends AppLocalizations {
  AppLocalizationsZhTw(Locale locale) : super(locale);
  // 使用預設實現（所有字串已在基類定義）
}

/// 英文（美國）
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn(Locale locale) : super(locale);

  @override
  String get appName => 'Sound Spirit Detective';
  @override
  String get yes => 'Yes';
  @override
  String get no => 'No';
  @override
  String get ok => 'OK';
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get confirm => 'Confirm';
  @override
  String get back => 'Back';
  @override
  String get next => 'Next';
  @override
  String get skip => 'Skip';
  @override
  String get retry => 'Retry';
  @override
  String get loading => 'Loading...';
  @override
  String get success => 'Success';
  @override
  String get error => 'Error';
  @override
  String get warning => 'Warning';
  @override
  String get info => 'Info';

  @override
  String get navHome => 'Home';
  @override
  String get navLibrary => 'Library';
  @override
  String get navPractice => 'Practice';
  @override
  String get navSettings => 'Settings';

  @override
  String get homeTitle => 'Home';
  @override
  String get homeWelcome => 'Welcome Back';
  @override
  String get homeCheckIn => 'Daily Check-in';
  @override
  String get homeCheckInDesc => 'Keep up the good work!';
  @override
  String get homeCheckInButton => 'Check In';
  @override
  String get homeCheckedIn => 'Checked in today';
  @override
  String get homeConsecutiveDays => 'Streak';
  @override
  String get homeTotalDays => 'Total';
  @override
  String get homeDays => 'days';
  @override
  String get homeAnimalCollection => 'Animal Collection';
  @override
  String get homeAnimalCollectionDesc => 'Collect cute animals by checking in!';
  @override
  String get homePracticeTimer => 'Practice Timer';
  @override
  String get homePracticeTimerDesc => 'Track your practice time';
  @override
  String get homeThisWeek => 'This Week';
  @override
  String get homeThisMonth => 'This Month';
  @override
  String get homeAverage => 'Average';
  @override
  String get homeTotal => 'Total';
  @override
  String get homePerDay => '/day';

  @override
  String get checkInSuccess => 'Check-in successful!';
  @override
  String get checkInAlreadyChecked => 'Already checked in today!';
  @override
  String get checkInStreak => 'Streak';
  @override
  String get checkInTotal => 'Total Check-ins';

  @override
  String get timerTitle => 'Today\'s Total (Resets Daily)';
  @override
  String get timerStart => 'Start';
  @override
  String get timerPause => 'Pause';
  @override
  String get timerReset => 'Reset';
  @override
  String get timerRecorded => 'Practice session recorded';
  @override
  String get timerTodayTotal => 'Today\'s Total';
  @override
  String get timerWeekAverage => 'Week Average';
  @override
  String get timerMonthTotal => 'Month Total';
  @override
  String get timerResetConfirm => 'Reset today\'s timer?';
  @override
  String get timerResetSuccess => 'Timer reset';
  @override
  String get timerWarningTitle => 'Timer Running';
  @override
  String get timerWarningMessage => 'The practice timer is running!\n\nSwitching pages will cause the current session data to be lost.\nPlease pause the timer before switching pages.\n\nAre you sure you want to leave?';
  @override
  String get timerStayHere => 'Stay Here';
  @override
  String get timerLeave => 'Leave';

  @override
  String get animalCollectionTitle => 'Animal Collection';
  @override
  String get animalCollectionStats => 'Collection Stats';
  @override
  String get animalCollectionUnlocked => 'Unlocked';
  @override
  String get animalCollectionTotal => 'Total';
  @override
  String get animalCollectionRate => 'Collection Rate';
  @override
  String get animalCollectionUnknown => '???';
  @override
  String get animalCollectionLocked => 'Locked';
  @override
  String get animalCollectionNeedDays => 'Need';
  @override
  String get animalCollectionUnlockedAt => 'Unlocked At';
  @override
  String get animalCollectionCollected => 'Collected';
  @override
  String get animalCollectionClose => 'Close';

  @override
  String get libraryTitle => 'Music Library';
  @override
  String get libraryEmpty => 'No music files yet';
  @override
  String get libraryEmptyDesc => 'Tap the button below to upload your first MIDI file';
  @override
  String get libraryUpload => 'Upload MIDI';
  @override
  String get librarySearchHint => 'Search music...';
  @override
  String get libraryFilterAll => 'All';
  @override
  String get libraryFilterFavorite => 'Favorites';
  @override
  String get libraryFilterRecent => 'Recent';
  @override
  String get libraryPlay => 'Play';
  @override
  String get libraryDelete => 'Delete';
  @override
  String get libraryDeleteConfirm => 'Delete this file?';
  @override
  String get libraryDeleteSuccess => 'File deleted';

  @override
  String get practiceTitle => 'Practice';
  @override
  String get practiceSelectFile => 'Select a piece to practice';
  @override
  String get practiceNoFile => 'No MIDI files available';
  @override
  String get practiceStart => 'Start Practice';
  @override
  String get practiceStop => 'Stop';
  @override
  String get practiceRecord => 'Record';
  @override
  String get practiceStopRecord => 'Stop Recording';
  @override
  String get practicePlayback => 'Playback';
  @override
  String get practiceAnalyze => 'Analyze';
  @override
  String get practiceSave => 'Save';

  @override
  String get settingsTitle => 'Settings';
  @override
  String get settingsAccount => 'Account';
  @override
  String get settingsAudio => 'Audio';
  @override
  String get settingsLanguage => 'Language';
  @override
  String get settingsOther => 'Other';
  @override
  String get settingsAbout => 'About';

  @override
  String get settingsLogin => 'Login';
  @override
  String get settingsLogout => 'Logout';
  @override
  String get settingsRegister => 'Register';
  @override
  String get settingsProfile => 'Profile';
  @override
  String get settingsGuest => 'Guest Mode';
  @override
  String get settingsGuestDesc => 'Sign in to sync your data';

  @override
  String get settingsMasterVolume => 'Master Volume';
  @override
  String get settingsMidiVolume => 'MIDI Volume';
  @override
  String get settingsMetronomeVolume => 'Metronome Volume';
  @override
  String get settingsRecordingVolume => 'Recording Volume';
  @override
  String get settingsPlaybackSpeed => 'Playback Speed';

  @override
  String get settingsLanguageTitle => 'Language';
  @override
  String get settingsLanguageSelect => 'Select Language';
  @override
  String get settingsLanguageCurrent => 'Current Language';

  @override
  String get settingsNotification => 'Notifications';
  @override
  String get settingsTheme => 'Theme';
  @override
  String get settingsThemeLight => 'Light';
  @override
  String get settingsThemeDark => 'Dark';
  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsAboutApp => 'About App';
  @override
  String get settingsVersion => 'Version';
  @override
  String get settingsPrivacy => 'Privacy Policy';
  @override
  String get settingsTerms => 'Terms of Service';

  @override
  String get loginTitle => 'Login';
  @override
  String get loginEmail => 'Email';
  @override
  String get loginPassword => 'Password';
  @override
  String get loginButton => 'Login';
  @override
  String get loginForgotPassword => 'Forgot Password?';
  @override
  String get loginNoAccount => 'Don\'t have an account?';
  @override
  String get loginRegisterNow => 'Register Now';
  @override
  String get loginWithGoogle => 'Sign in with Google';
  @override
  String get loginWithApple => 'Sign in with Apple';
  @override
  String get loginAsGuest => 'Continue as Guest';
  @override
  String get loginEmailRequired => 'Please enter email';
  @override
  String get loginPasswordRequired => 'Please enter password';
  @override
  String get loginInvalidEmail => 'Invalid email format';
  @override
  String get loginError => 'Login failed';
  @override
  String get loginSuccess => 'Login successful';

  @override
  String get registerTitle => 'Register';
  @override
  String get registerUsername => 'Username';
  @override
  String get registerEmail => 'Email';
  @override
  String get registerPassword => 'Password';
  @override
  String get registerConfirmPassword => 'Confirm Password';
  @override
  String get registerButton => 'Register';
  @override
  String get registerHaveAccount => 'Already have an account?';
  @override
  String get registerLoginNow => 'Login Now';
  @override
  String get registerUsernameRequired => 'Please enter username';
  @override
  String get registerEmailRequired => 'Please enter email';
  @override
  String get registerPasswordRequired => 'Please enter password';
  @override
  String get registerPasswordMismatch => 'Passwords do not match';
  @override
  String get registerError => 'Registration failed';
  @override
  String get registerSuccess => 'Registration successful';

  @override
  String get profileTitle => 'Profile';
  @override
  String get profileEdit => 'Edit Profile';
  @override
  String get profileSave => 'Save';
  @override
  String get profileCancel => 'Cancel';
  @override
  String get profileChangePassword => 'Change Password';
  @override
  String get profileDeleteAccount => 'Delete Account';
  @override
  String get profileDeleteConfirm => 'Delete your account? This cannot be undone.';
  @override
  String get profileLogout => 'Logout';
  @override
  String get profileLogoutConfirm => 'Are you sure you want to logout?';

  @override
  String get uploadTitle => 'Upload MIDI';
  @override
  String get uploadSelectFile => 'Select File';
  @override
  String get uploadDragDrop => 'Or drag and drop file here';
  @override
  String get uploadSupported => 'Supported formats: .mid, .midi';
  @override
  String get uploadButton => 'Upload';
  @override
  String get uploadProgress => 'Uploading...';
  @override
  String get uploadSuccess => 'Upload successful';
  @override
  String get uploadError => 'Upload failed';
  @override
  String get uploadNoFile => 'Please select a file first';

  @override
  String get playbackTitle => 'Playback';
  @override
  String get playbackPlay => 'Play';
  @override
  String get playbackPause => 'Pause';
  @override
  String get playbackStop => 'Stop';
  @override
  String get playbackSpeed => 'Speed';
  @override
  String get playbackLoop => 'Loop';
  @override
  String get playbackLoopOn => 'Loop On';
  @override
  String get playbackLoopOff => 'Loop Off';

  @override
  String get analysisTitle => 'Performance Analysis';
  @override
  String get analysisScore => 'Score';
  @override
  String get analysisAccuracy => 'Accuracy';
  @override
  String get analysisTiming => 'Timing';
  @override
  String get analysisPitch => 'Pitch';
  @override
  String get analysisDetails => 'Details';
  @override
  String get analysisExcellent => 'Excellent';
  @override
  String get analysisGood => 'Good';
  @override
  String get analysisFair => 'Fair';
  @override
  String get analysisNeedsWork => 'Needs Work';

  @override
  String get metronomeTitle => 'Metronome';
  @override
  String get metronomeBPM => 'BPM';
  @override
  String get metronomeStart => 'Start';
  @override
  String get metronomeStop => 'Stop';
  @override
  String get metronomeTimeSignature => 'Time Signature';

  @override
  String get errorNetwork => 'Network error';
  @override
  String get errorServer => 'Server error';
  @override
  String get errorUnknown => 'Unknown error';
  @override
  String get errorFileNotFound => 'File not found';
  @override
  String get errorPermissionDenied => 'Permission denied';
  @override
  String get errorInvalidFormat => 'Invalid format';

  @override
  String get successSaved => 'Saved successfully';
  @override
  String get successDeleted => 'Deleted successfully';
  @override
  String get successUploaded => 'Uploaded successfully';
  @override
  String get successUpdated => 'Updated successfully';
}

/// 簡體中文（中國）- 保留占位，暫不翻譯
class AppLocalizationsZhCn extends AppLocalizations {
  AppLocalizationsZhCn(Locale locale) : super(locale);
  // 使用預設實現（繁體中文）
}

/// 日文（日本）- 保留占位，暫不翻譯
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa(Locale locale) : super(locale);
  // 使用預設實現（繁體中文）
}

/// 本地化委託
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['zh', 'en', 'ja'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final String languageCode = '${locale.languageCode}_${locale.countryCode}';
    return AppLocalizations._getLocalizations(languageCode);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

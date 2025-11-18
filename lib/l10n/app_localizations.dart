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
  String get checkInTitle => '練習打卡';
  String get checkInButton => '打卡';
  String get checkInChecked => '已打卡';
  String get checkInConsecutive => '連續';
  String get checkInAccumulated => '累計';
  String get checkInDaysUnit => '天';
  String get checkInMonth => '月';
  String get checkInYear => '年';
  List<String> get checkInWeekdays => ['日', '一', '二', '三', '四', '五', '六'];
  String get checkInSuccessMessage => '打卡成功！連續 {consecutive} 天，累計 {total} 天 🎉';
  String get checkInFailure => '打卡失敗，請檢查網路連線';
  
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
  String get timerCardTitle => '練習計時';
  String get timerCardSubtitle => '今日累計時長（隔日自動重置）';
  String get timerPauseAndSave => '暫停並保存';
  String get timerStartTimer => '開始計時';
  String get timerWeeklyPractice => '本週練習時長';
  String get timerWeekTotal => '共';
  String get timerHourUnit => 'h';
  String get timerMinuteUnit => 'min';
  String get timerDayUnit => '/天';
  String get timerRecordedMessage => '已記錄本次練習 {session}，今日累計 {total}';
  String get timerTrendingUp => '本週平均';
  String get timerCalendarMonth => '本月累計';
  
  // ========== 動物圖鑑 ==========
  String get animalCollectionTitle => '動物圖鑑';
  String get animalCollectionStats => '收集統計';
  String get animalCollectionProgress => '收集進度';
  String get animalCollectionUnlocked => '已解鎖';
  String get animalCollectionTotal => '總共';
  String get animalCollectionTotalCheckIns => '總打卡天數';
  String get animalCollectionRate => '收集率';
  String get animalCollectionUnknown => '???';
  String get animalCollectionLocked => '未解鎖';
  String get animalCollectionNeedDays => '需';
  String get animalCollectionRequireDays => '天';
  String get animalCollectionUnlockedAt => '解鎖時間';
  String get animalCollectionCollected => '已收集';
  String get animalCollectionClose => '關閉';
  String get animalCollectionConsecutiveStreak => '連續打卡';
  String get animalCollectionDaysUnit => '天';
  String get animalCollectionStatus => '狀態';
  String get animalCollectionUnlockCondition => '解鎖條件';
  String get animalCollectionCheckInDays => '打卡';
  String get animalCollectionCurrentProgress => '目前進度';
  String get animalCollectionObtainedDate => '取得日期';
  String get animalCollectionUnknownDate => '未知';

  // ========== 音樂庫 ==========
  String get libraryTitle => '我的樂庫';
  String get libraryEmpty => '尚無音樂檔案';
  String get libraryEmptyDesc => '請前往上傳頁面添加MIDI檔案';
  String get libraryUpload => '新增樂曲';
  String get librarySearchHint => '搜尋音樂...';
  String get libraryFilterAll => '全部';
  String get libraryFilterFavorite => '最愛';
  String get libraryFilterRecent => '最近播放';
  String get libraryPlay => '播放';
  String get libraryPractice => '練習';
  String get libraryDelete => '刪除';
  String get libraryDeleteConfirm => '確定要刪除這個檔案嗎？';
  String get libraryDeleteConfirmTitle => '確認刪除';
  String get libraryDeleteConfirmMessage => '確定要刪除「{name}」嗎？';
  String get libraryDeleteSuccess => '檔案已刪除';
  String get libraryFileSize => '大小';
  String get libraryUploadTime => '上傳時間';
  
  // ========== 練習頁面 ==========
  String get practiceTitle => '練習模式';
  String get practiceSelectFile => '選擇要練習的曲目';
  String get practiceNoFile => '沒有可用的 MIDI 檔案';
  String get practiceStart => '開始練習';
  String get practiceStop => '停止練習';
  String get practiceRecord => '開始錄音';
  String get practiceRecording => '錄音中';
  String get practiceStopRecord => '停止錄音';
  String get practicePlayback => '播放錄音';
  String get practiceStopPlayback => '停止播放';
  String get practiceAnalyze => '開始分析';
  String get practiceAnalyzing => '分析中';
  String get practiceSave => '儲存';
  String get practiceSettings => '練習設定';
  String get practiceEnableCountdown => '錄音倒數計時';
  String get practiceCountdownDesc => '錄音前進行倒數計時';
  String get practiceRecordingTime => '錄音時間';
  String get practiceSeconds => '秒';
  String get practiceNoRecording => '尚未錄音';
  String get practiceRecordingHint => '點擊「開始錄音」開始練習';
  String get practicePlaybackHint => '點擊「播放錄音」聽取錄音';
  String get practiceAnalyzeHint => '點擊「開始分析」分析演奏';
  String get practiceAnalysisComplete => '分析完成';
  String get practiceAnalysisError => '分析失敗';
  String get practiceRecordingSuccess => '錄音成功';
  String get practiceRecordingError => '錄音失敗';
  
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
  String get settingsVolumeControl => '音量控制';
  String get settingsReset => '重置';
  String get settingsSoundEffect => '音效';
  String get settingsVibration => '震動';
  String get settingsEnableSoundEffect => '啟用音效';
  String get settingsEnableVibration => '啟用震動';
  String get settingsPersonalAccount => '個人帳號';
  String get settingsLoginRegister => '登入 / 註冊';
  String get settingsLoginToSync => '登入以同步您的練習記錄';
  String get settingsAnimalCollection => '動物圖鑑';
  String get settingsAnimalCollectionDesc => '查看您收集的可愛動物';
  String get settingsNotifications => '通知設定';
  String get settingsNotificationsDesc => '管理應用程式通知';
  String get settingsThemeTitle => '主題設定';
  String get settingsThemeDesc => '選擇應用程式主題顏色';
  String get settingsAboutTitle => '關於應用程式';
  String get settingsAboutDesc => '版本資訊和開發團隊';
  
  // 關於
  String get settingsAboutApp => '關於應用程式';
  String get settingsVersion => '版本';
  String get settingsPrivacy => '隱私政策';
  String get settingsTerms => '使用條款';
  
  // 主題選擇
  String get themeSelectTitle => '選擇主題';
  String get themeClose => '關閉';
  String get themeDawn => '晨曦';
  String get themeOcean => '海洋';
  String get themeForest => '森林';
  String get themeSunset => '夕陽';
  String get themeLavender => '櫻雪';
  
  // 關於 App 對話框
  String get aboutAppTitle => '關於音樂練習應用程式';
  String get aboutAppVersion => '版本';
  String get aboutAppDescription => '這是一個音樂練習應用程式，提供智能音樂分析、MIDI 播放、錄音練習、曲目管理和打卡激勵系統。幫助您在音樂學習之路上持續進步！';
  String get aboutAppFeatures => '主要功能：\n• AI 音準與節奏分析\n• MIDI 播放與練習\n• 錄音與回放\n• 打卡系統與動物圖鑑\n• 多主題切換';
  String get aboutAppTeam => '開發團隊：Music Practice Team';
  String get aboutAppConfirm => '確定';
  
  // 上傳 MIDI 頁面
  String get uploadMidiTitle => '從本機上傳 MIDI';
  String get uploadMidiSelectFile => '請選擇要上傳的 MIDI 檔案';
  String get uploadMidiSupportedFormats => '支援格式：.mid, .midi';
  String get uploadMidiSupportedFormatsWeb => '支援格式：.mid, .midi (Web版本使用記憶體載入)';
  String get uploadMidiFileSize => '檔案大小';
  String get uploadMidiPlatform => '平台';
  String get uploadMidiPlatformLocal => '本機儲存';
  String get uploadMidiReselect => '重新選擇';
  String get uploadMidiSaveToLibrary => '儲存到樂庫';
  String get uploadMidiNoFileSelected => '尚未選擇檔案';
  String get uploadMidiSuccess => 'MIDI檔案已成功儲存到樂庫！';
  
  // 動物圖鑑
  String get animalCat => '可愛貓咪';
  String get animalDog => '忠誠小狗';
  String get animalFox => '聰明狐狸';
  String get animalPanda => '萌萌熊貓';
  String get animalRabbit => '活潑兔子';
  String get animalBear => '可愛熊熊';
  String get animalDeer => '優雅小鹿';
  String get animalPenguin => '企鵝寶寶';
  String get animalKoala => '無尾熊';
  String get animalRaccoon => '浣熊小可愛';
  String get animalSquirrel => '松鼠';
  String get animalHedgehog => '刺蝟';
  String get animalSeal => '海豹';
  String get animalSheep => '綿羊';
  String get animalLion => '獅子王';
  String get animalKangaroo => '袋鼠';
  String get animalSloth => '樹懶';
  String get animalGuineaPig => '天竺鼠';
  String get animalPrairieDog => '土撥鼠';
  String get animalQuokka => '短尾矮袋鼠';
  String get animalFairy => '小精靈';
  String get animalTaiwanBear => '台灣黑熊';
  String get animalUnknown => '???';
  String get animalStatusLocked => '狀態：未解鎖';
  String get animalStatusUnlocked => '狀態：已解鎖';
  String get animalUnlockCondition => '解鎖條件';
  String get animalCheckInDays => '打卡 %d 天';
  String get animalCurrentProgress => '目前進度';
  String get animalProgressDays => '%d / %d 天';
  String get animalUnlockDate => '取得日期';
  String get animalDetailClose => 'Close';
  
  // 動物解鎖動畫
  String get animalUnlockCongrats => '🎉 恭喜獲得 🎉';
  String get animalUnlockCheckInDays => '打卡 %d 天解鎖';
  String get animalUnlockGreat => '太好了！';
  
  // 計時器警告
  String get timerRunningTitle => '計時器運行中';
  String get timerRunningMessage => '練習計時器正在運行中。\n\n切換頁面將自動暫停計時並保存當前記錄。\n\n確定要離開此頁面嗎？';
  String get timerStayOnPage => '留在此頁';
  String get timerLeavePage => '確定離開';
  
  // 錯誤類型
  String get errorTypeMissedNote => '漏音';
  String get errorTypeWrongNote => '錯音';
  String get errorTypeEarlyTiming => '節奏偏差';
  String get errorTypeLateTiming => '節奏偏差';
  String get errorMessageMissedNote => '漏音: %s 在 %s秒';
  String get errorMessageTimingOffset => '節奏偏差: %s %s %sms (Onset)';
  String get errorTimingEarly => '早了';
  String get errorTimingLate => '晚了';
  
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
  String get loginWelcomeBack => '歡迎回來';
  String get loginEmailLabel => 'Email';
  String get loginPasswordLabel => '密碼';
  String get loginEmailHint => '請輸入 Email';
  String get loginEmailInvalid => '請輸入有效的 Email';
  String get loginPasswordHint => '請輸入密碼';
  String get loginOr => '或';
  String get loginGoogleButton => '使用 Google 帳號登入';
  String get loginGoogleSuccess => 'Google 登入成功！';
  
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
  String get registerCreateAccount => '建立新帳號';
  String get registerEmailLabel => 'Email';
  String get registerEmailHint => '請輸入 Email';
  String get registerEmailInvalid => '請輸入有效的 Email';
  String get registerUsernameLabel => '使用者名稱';
  String get registerUsernameHint => '3-20個字元，將作為您的顯示名稱';
  String get registerUsernameLength => '使用者名稱長度需為 3-20 個字元';
  String get registerPasswordLabel => '密碼';
  String get registerPasswordHint => '至少 6 個字元';
  String get registerPasswordMinLength => '密碼至少需要 6 個字元';
  String get registerConfirmPasswordLabel => '確認密碼';
  String get registerConfirmPasswordHint => '請再次輸入密碼';
  String get registerPasswordNotMatch => '兩次輸入的密碼不一致';
  String get registerOr => '或';
  String get registerGoogleButton => '使用 Google 帳號註冊';
  String get registerDataRetentionTitle => '保留當前數據？';
  String get registerDataRetentionMessage => '檢測到您在訪客模式下已有打卡記錄或練習時長。\n\n您希望將這些數據導入新帳號，還是重新開始？';
  String get registerDataRetentionRestart => '重新開始';
  String get registerDataRetentionKeep => '保留當前數據';
  String get registerSuccessWithData => '註冊成功！已保留您的打卡和練習記錄';
  String get registerSuccessWelcome => '註冊成功！歡迎加入';
  String get registerGoogleSuccessWithData => 'Google 登入成功！已保留您的打卡和練習記錄';
  String get registerGoogleSuccess => 'Google 登入成功！';
  
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
  String get profilePleaseLogin => '請先登入';
  String get profileGoToLogin => '前往登入';
  String get profileEmail => 'Email';
  String get profileRegistrationDate => '註冊日期';
  String get profileEditProfile => '編輯個人資料';
  String get profileDisplayName => '顯示名稱';
  String get profileDataUpdated => '資料已更新';
  String get profileOldPassword => '舊密碼';
  String get profileNewPassword => '新密碼';
  String get profileConfirmNewPassword => '確認新密碼';
  String get profilePasswordMismatch => '新密碼不一致';
  String get profilePasswordChanged => '密碼已變更';
  String get profileChangeFailed => '變更失敗';
  String get profileLogoutTitle => '確認登出';
  String get profileLogoutMessage => '您確定要登出嗎？';
  String get profileLoggedOut => '已登出';
  String get profileDeleteTitle => '刪除帳號';
  String get profileDeleteWarning => '⚠️ 此操作無法復原！\n所有資料將被永久刪除。';
  String get profileDeleteGoogleHint => '您使用 Google 帳號登入。\n點擊「確認刪除」後需要重新登入 Google 以確認身份。';
  String get profileDeletePasswordHint => '請輸入密碼確認';
  String get profileDeletePasswordLabel => '需要輸入您的帳號密碼';
  String get profileDeleteButton => '確認刪除';
  String get profileAccountDeleted => '帳號已刪除';
  String get profileDeleteError => '刪除失敗';
  
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
  String get uploadPageTitle => '上傳音樂檔案';
  String get uploadLocalMidi => '從本機上傳 MIDI';
  String get uploadLocalMidiSubtitle => '支援 .mid 和 .midi 格式';
  String get uploadLocalScore => '從本機上傳樂譜';
  String get uploadLocalScoreSubtitle => '支援圖片格式的樂譜';
  String get uploadFeatureNotAvailable => '功能開發中';
  String get uploadFeatureNotAvailableMessage => '此功能正在開發中，敬請期待！';
  
  // ========== 播放頁面 ==========
  String get playbackTitle => '播放 MIDI';
  String get playbackPlay => '播放';
  String get playbackPause => '暫停';
  String get playbackStop => '停止';
  String get playbackSpeed => '速度';
  String get playbackLoop => '循環';
  String get playbackLoopOn => '循環播放';
  String get playbackLoopOff => '關閉循環';
  String get playbackUnknownFile => '未知檔案';
  String get playbackFileSize => '檔案大小';
  String get playbackReplay => '重新播放';
  String get playbackTooltipReplay => '重新播放';
  String get playbackTooltipPlay => '播放';
  String get playbackTooltipPause => '暫停';
  String get playbackTooltipStop => '停止';
  
  // ========== 分析頁面 ==========
  String get analysisTitle => '演奏分析';
  String get analysisReportTitle => '演奏分析報告';
  String get analysisScore => '分數';
  String get analysisThisScore => '本次得分';
  String get analysisAccuracy => '準確度';
  String get analysisAccuracyRate => '正確率';
  String get analysisTiming => '節奏';
  String get analysisPitch => '音準';
  String get analysisDetails => '詳細分析';
  String get analysisExcellent => '優秀';
  String get analysisGood => '良好';
  String get analysisFair => '尚可';
  String get analysisNeedsWork => '需改進';
  String get analysisPitchErrors => '音準錯誤';
  String get analysisRhythmErrors => '節奏錯誤';
  String get analysisReturnHome => '返回首頁';
  String get analysisRetryChallenge => '再次挑戰';
  String get analysisTimes => '次';
  String get analysisResultTitle => '演奏分析報告';
  String get analysisResultGrade => '級';
  String get analysisResultAccuracyLabel => '準確率';
  String get analysisResultRhythmLabel => '節奏';
  String get analysisResultStatistics => '統計數據';
  String get analysisResultCorrect => '正確';
  String get analysisResultMissed => '漏音';
  String get analysisResultWrong => '錯音';
  String get analysisResultEarly => '搶拍';
  String get analysisResultLate => '拖拍';
  String get analysisResultErrorDetails => '錯誤詳情';
  String get analysisResultShowingFirst => '(顯示前 20 個,共';
  String get analysisResultShowingUnit => '個)';
  String get analysisResultSuggestions => '練習建議';
  String get analysisResultRetry => '重新練習';
  String get analysisResultViewScore => '查看樂譜';
  String get analysisResultScoreInDevelopment => '樂譜功能開發中...';
  
  // ========== 練習頁面額外翻譯 ==========
  String get practiceAudioToMidi => '音訊轉 MIDI';
  String get practiceAnalyzingRecording => '🤖 使用 AI 模型分析您的完整錄音...';
  String get practiceAnalyzingTitle => '演奏分析中';
  String get practiceAnalysisFailed => '分析失敗';
  String get practiceSelectingInstruction => '點擊選擇想要練習的樂譜';
  String get practiceAnalysisDescription => '使用頻譜分析技術驗證您的演奏\n比對音準、節奏,並給予評分和建議';
  String practiceFileSavedDownloads(String fileName, String analysis) => '檔案已儲存到「下載」資料夾:\n$fileName\n\n$analysis\n\n🔍 在檔案管理器中搜索「$fileName」即可找到';
  String practiceFileSavedLocation(String path, String fileName, String analysis) => 'MIDI 檔案位置:\n$path\n\n$analysis\n\n🔍 在檔案管理器中搜索「$fileName」即可找到';
  String get practiceFileOpenSuccess => '\n\n✅ 已嘗試開啟檔案管理器';
  String get practiceFileOpenFailed => '\n\n⚠️ 無法自動開啟，請手動搜索檔案';
  
  // ========== 練習建議文字 ==========
  String get suggestionRandomPlaying => '🚨 系統檢測到疑似亂彈或錯誤曲目,請確認:';
  String get suggestionCheckCorrectFile => '   1. 是否選擇了正確的 MIDI 檔案';
  String get suggestionCheckCompleteSong => '   2. 是否完整演奏了指定曲目';
  String get suggestionCheckQuietEnvironment => '   3. 是否在安靜環境下錄音';
  String get suggestionWrongSong => '❌ 演奏內容與指定曲目嚴重不符!';
  String get suggestionConfirmCorrectSong => '   請確認是否演奏了正確的曲目';
  String get suggestionPitchNeedsPractice => '🎹 音準需要加強練習,建議放慢速度逐個音符確認';
  String get suggestionPitchBasic => '🎵 音準基本正確,但仍有進步空間';
  String get suggestionPitchPerfect => '🌟 音準表現完美!';
  String get suggestionPitchExcellent => '⭐ 音準表現優秀!';
  String suggestionExtraNotes(int count) => '⚠️ 檢測到 $count 個多餘音符,請注意:';
  String get suggestionAvoidWrongKeys => '   - 避免誤觸其他琴鍵';
  String get suggestionEnsureAccuracy => '   - 確保手指準確按在正確位置';
  String suggestionManyMissed(int count) => '❌ 漏音較多 ($count個),建議:';
  String get suggestionCheckKeyPress => '   - 檢查手指是否完全按下琴鍵';
  String get suggestionRetryQuietEnvironment => '   - 在安靜環境下重新錄音';
  String get suggestionCheckMicSensitivity => '   - 確保麥克風靈敏度足夠';
  String suggestionSomeMissed(int count) => '⚠️ 有少量漏音 ($count個),請檢查按鍵力度';
  String get suggestionRhythmUnstable => '⏱️ 節奏不穩定,建議使用節拍器練習';
  String get suggestionRhythmBasic => '🎼 節奏基本穩定,可以嘗試稍微提高速度';
  String get suggestionRhythmGood => '✨ 節奏掌握很好!';
  String get suggestionTendencyRushing => '⏩ 有搶拍傾向,可以放鬆一點,不要太急';
  String get suggestionTendencyDragging => '⏸️ 有拖拍傾向,可能需要加強節奏訓練';
  
  // ========== 節拍器 ==========
  String get metronomeTitle => '節拍器';
  String get metronomeBPM => '速度 (BPM)';
  String get metronomeStart => '開始';
  String get metronomeStop => '停止';
  String get metronomeTimeSignature => '拍號';
  String get metronomeAccent => '重音';
  String get metronomeBpmInputHint => '點擊輸入';
  String get metronomeBpmRange => 'BPM 必須在 30 到 300 之間';
  String get metronomeClear => '清除';
  String get metronomeWeekPractice => '本週練習時長';
  
  // ========== 錯誤訊息 ==========
  String get errorNetwork => '網路連線錯誤';
  String get errorServer => '伺服器錯誤';
  String get errorUnknown => '未知錯誤';
  String get errorFileNotFound => '找不到檔案';
  String get errorPermissionDenied => '權限被拒絕';
  String get errorInvalidFormat => '格式不正確';
  
  // 練習頁面錯誤
  String get errorMicPermission => '需要麥克風權限才能錄音，請在設定中手動授權';
  String errorRecordingStart(String error) => '錄音啟動失敗: $error\n\n請確保：\n1. 已授權麥克風權限\n2. 沒有其他應用程式使用麥克風';
  String errorRecordingFileSize(int size) => '錄音完成！檔案大小：${(size / 1024).toStringAsFixed(1)} KB';
  String errorRecordingFileTooSmall(int size) => '錄音檔案太小（$size bytes），可能是音訊捕獲問題';
  String errorRecordingFileCheck(String error) => '錄音檔案檢查失敗: $error';
  String errorRecordingStop(String error) => '停止錄音失敗: $error\n\n請嘗試重新錄音';
  String get errorRecordingFileNotFound => '未找到錄音檔案，請重新錄音';
  String get errorRecordingFileEmpty => '錄音檔案為空，無法撥放';
  String errorPlaybackFailed(String error) => '撥放失敗: $error';
  String get errorRecordFirst => '請先錄音再進行轉換';
  String get errorConvertMidiFirst => '請先轉換 MIDI 檔案';
  String errorFileAccess(String error) => '檔案存取失敗: $error';
  String errorAnalysisFailed(String error) => '分析失敗: $error';
  
  // 上傳頁面錯誤
  String errorFileSelection(String error) => '選擇檔案時發生錯誤: $error';
  String get errorFileReadFailed => '錯誤：無法讀取檔案內容，請重新選擇檔案。';
  
  // 圖片標註錯誤
  String get errorDrawingColorLabel => '顏色 ';
  String get errorDrawingSizeLabel => '大小 ';
  String get annotationSelectStar => '選擇星星圖標:';
  String get annotationMarkerColor => '標記顏色:';
  String get annotationDelete => '刪除';
  String get annotationCancel => '取消';
  String get annotationConfirm => '確定';
  String get annotationInputRequired => '請輸入筆記內容';
  String get annotationAddMarker => '新增標記';
  String get annotationEditMarker => '編輯標記';
  String get annotationNoteLabel => '筆記內容';
  String get annotationNoteHint => '輸入您的筆記...';
  
  // ========== 樂譜目錄頁面 ==========
  String get notePageTitle => '樂譜目錄';
  String get notePageSelectToDelete => '選擇要刪除的樂譜';
  String get notePageSheetAnnotation => '電子譜面標註';
  String get notePageEdit => '編輯';
  String get notePageCancel => '取消';
  String get notePageDeleteSelected => '刪除選中項';
  String get notePageLoading => '載入中...';
  String get notePageEmpty => '還沒有任何樂譜目錄';
  String get notePageEmptyHint => '點擊右下角的 + 按鈕新增樂譜';
  String get notePageOrUseAnnotation => '或使用電子譜面標註';
  String get notePageNotesCount => '條筆記';
  String get notePageAddSheet => '新增樂譜目錄';
  String get notePageSheetName => '樂譜名稱';
  String get notePageSheetNameHint => '例如:Beethoven op.53、Mozart K.545';
  String get notePageAdd => '新增';
  String get notePageConfirmDelete => '確認刪除';
  String get notePageConfirmDeleteMessage => '確定要刪除';
  String get notePageConfirmDeleteSuffix => '個樂譜及其所有筆記嗎?';
  String get notePageDelete => '刪除';
  
  // ========== 電子譜面標註頁面 ==========
  String get sheetAnnotationTitle => '電子譜';
  String get sheetAnnotationSelectToDelete => '選擇要刪除的譜面';
  String get sheetAnnotationMusicLibrary => '樂曲目錄';
  String get sheetAnnotationEdit => '編輯';
  String get sheetAnnotationCancel => '取消';
  String get sheetAnnotationDeleteSelected => '刪除選中項';
  String get sheetAnnotationEmpty => '尚無譜面';
  String get sheetAnnotationEmptyHint => '點擊右下角 + 按鈕匯入譜面';
  String get sheetAnnotationMarkersCount => '個標記';
  String get sheetAnnotationTypeImage => '圖片';
  String get sheetAnnotationTypePdf => 'PDF';
  String get sheetAnnotationUpdatedAt => '更新於';
  String get sheetAnnotationToday => '今天';
  String get sheetAnnotationYesterday => '昨天';
  String get sheetAnnotationDaysAgo => '天前';
  String get sheetAnnotationConfirmDelete => '確認刪除';
  String get sheetAnnotationConfirmDeleteMessage => '確定要刪除「{name}」嗎？';
  String get sheetAnnotationDelete => '刪除';
  String get sheetAnnotationDeleted => '已刪除譜面';
  String get sheetAnnotationDeleteFailed => '刪除失敗';
  String get sheetAnnotationImported => '已匯入譜面';
  String get sheetAnnotationImportFailed => '匯入失敗';
  String get sheetAnnotationPdfViewerInDev => 'PDF 檢視功能開發中';
  String get sheetAnnotationPdfViewerHint => '請先使用圖片格式';
  String get sheetAnnotationDeletedMultiple => '已刪除';
  String get sheetAnnotationDeletedSuffix => '個譜面';
  String get sheetAnnotationConfirmDeleteMultiple => '確定要刪除選中的';
  
  // ========== 樂譜詳情頁面 ==========
  String get sheetDetailAddNote => '新增練習要點';
  String get sheetDetailClickToAdd => '點擊下方按鈕新增練習要點';
  String get sheetDetailAddDescription => '可以針對特定小節記錄需要注意的地方';
  String get sheetDetailAddButton => '新增筆記';
  String get sheetDetailEmpty => '還沒有任何練習要點';
  String get sheetDetailEmptyHint => '開始記錄這首曲子的練習重點吧！';
  String get sheetDetailMeasureNumber => '小節數';
  String get sheetDetailMeasureHint => 'Ex: 12';
  String get sheetDetailContent => '注意事項';
  String get sheetDetailContentHint => '記錄需要注意的地方、技巧要點或練習重點...';
  String get sheetDetailCancel => '取消';
  String get sheetDetailAdd => '新增';
  String get sheetDetailSave => '儲存';
  String get sheetDetailConfirmDelete => '確認刪除';
  String get sheetDetailConfirmDeleteMessage => '確定要刪除這條筆記嗎？';
  String get sheetDetailDelete => '刪除';
  String get sheetDetailEditNote => '編輯練習要點';
  String get sheetDetailMeasureLabel => '小節數';
  String get sheetDetailMeasureExample => '例如：16';
  String get sheetDetailDrawing => '音樂畫面';
  String get sheetDetailDrawingEdit => '編輯音樂畫面';
  String get sheetDetailDrawingIncluded => '包含音樂畫面';
  String get sheetDetailMeasurePrefix => '第';
  String get sheetDetailMeasureSuffix => '小節';
  
  // ========== 倒數計時 ==========
  String get countdownCancel => '取消';
  
  // ========== 組件 ==========
  String get recentActivityContinue => '繼續';
  
  // ========== 播放頁面（簡易版）==========
  String get playbackPageTitle => 'MIDI 播放器';
  String get playbackPagePlaying => '播放中...';
  String get playbackPagePaused => '已暫停';
  String get playbackPageStopped => '已停止';
  
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
  String get checkInTitle => 'Practice Check-in';
  @override
  String get checkInButton => 'Check In';
  @override
  String get checkInChecked => 'Checked';
  @override
  String get checkInConsecutive => 'Streak';
  @override
  String get checkInAccumulated => 'Total';
  @override
  String get checkInDaysUnit => 'days';
  @override
  String get checkInMonth => 'Month';
  @override
  String get checkInYear => 'Year';
  @override
  List<String> get checkInWeekdays => ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  @override
  String get checkInSuccessMessage => 'Check-in successful! {consecutive} day streak, {total} days total 🎉';
  @override
  String get checkInFailure => 'Check-in failed, please check network connection';

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
  String get timerCardTitle => 'Practice Timer';
  @override
  String get timerCardSubtitle => 'Today\'s Total (Resets Daily)';
  @override
  String get timerPauseAndSave => 'Pause & Save';
  @override
  String get timerStartTimer => 'Start Timer';
  @override
  String get timerWeeklyPractice => 'Weekly Practice Time';
  @override
  String get timerWeekTotal => 'Total';
  @override
  String get timerHourUnit => 'h';
  @override
  String get timerMinuteUnit => 'min';
  @override
  String get timerDayUnit => '/day';
  @override
  String get timerRecordedMessage => 'Recorded {session} practice, {total} today';
  @override
  String get timerTrendingUp => 'Week Average';
  @override
  String get timerCalendarMonth => 'Month Total';

  @override
  String get animalCollectionTitle => 'Animal Collection';
  @override
  String get animalCollectionStats => 'Collection Stats';
  @override
  String get animalCollectionProgress => 'Collection Progress';
  @override
  String get animalCollectionUnlocked => 'Unlocked';
  @override
  String get animalCollectionTotal => 'Total';
  @override
  String get animalCollectionTotalCheckIns => 'Total Check-ins';
  @override
  String get animalCollectionRate => 'Collection Rate';
  @override
  String get animalCollectionUnknown => '???';
  @override
  String get animalCollectionLocked => 'Locked';
  @override
  String get animalCollectionNeedDays => 'Need';
  @override
  String get animalCollectionRequireDays => 'days';
  @override
  String get animalCollectionUnlockedAt => 'Unlocked At';
  @override
  String get animalCollectionCollected => 'Collected';
  @override
  String get animalCollectionClose => 'Close';
  @override
  String get animalCollectionConsecutiveStreak => 'Consecutive Streak';
  @override
  String get animalCollectionDaysUnit => 'days';
  @override
  String get animalCollectionStatus => 'Status';
  @override
  String get animalCollectionUnlockCondition => 'Unlock Condition';
  @override
  String get animalCollectionCheckInDays => 'Check in';
  @override
  String get animalCollectionCurrentProgress => 'Current Progress';
  @override
  String get animalCollectionObtainedDate => 'Obtained Date';
  @override
  String get animalCollectionUnknownDate => 'Unknown';

  @override
  String get libraryTitle => 'My Library';
  @override
  String get libraryEmpty => 'No music files';
  @override
  String get libraryEmptyDesc => 'Please go to the upload page to add MIDI files';
  @override
  String get libraryUpload => 'Add Music';
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
  String get libraryPractice => 'Practice';
  @override
  String get libraryDelete => 'Delete';
  @override
  String get libraryDeleteConfirm => 'Delete this file?';
  @override
  String get libraryDeleteConfirmTitle => 'Confirm Delete';
  @override
  String get libraryDeleteConfirmMessage => 'Are you sure you want to delete "{name}"?';
  @override
  String get libraryDeleteSuccess => 'File deleted';
  @override
  String get libraryFileSize => 'Size';
  @override
  String get libraryUploadTime => 'Upload Time';

  @override
  String get practiceTitle => 'Practice Mode';
  @override
  String get practiceSelectFile => 'Select a piece to practice';
  @override
  String get practiceNoFile => 'No MIDI files available';
  @override
  String get practiceStart => 'Start Practice';
  @override
  String get practiceStop => 'Stop';
  @override
  String get practiceRecord => 'Start Recording';
  @override
  String get practiceRecording => 'Recording';
  @override
  String get practiceStopRecord => 'Stop Recording';
  @override
  String get practicePlayback => 'Play Recording';
  @override
  String get practiceStopPlayback => 'Stop Playback';
  @override
  String get practiceAnalyze => 'Start Analysis';
  @override
  String get practiceAnalyzing => 'Analyzing';
  @override
  String get practiceSave => 'Save';
  @override
  String get practiceSettings => 'Practice Settings';
  @override
  String get practiceEnableCountdown => 'Recording Countdown';
  @override
  String get practiceCountdownDesc => 'Countdown before recording';
  @override
  String get practiceRecordingTime => 'Recording Time';
  @override
  String get practiceSeconds => 'seconds';
  @override
  String get practiceNoRecording => 'No recording yet';
  @override
  String get practiceRecordingHint => 'Tap "Start Recording" to begin practice';
  @override
  String get practicePlaybackHint => 'Tap "Play Recording" to listen';
  @override
  String get practiceAnalyzeHint => 'Tap "Start Analysis" to analyze performance';
  @override
  String get practiceAnalysisComplete => 'Analysis Complete';
  @override
  String get practiceAnalysisError => 'Analysis Failed';
  @override
  String get practiceRecordingSuccess => 'Recording Successful';
  @override
  String get practiceRecordingError => 'Recording Failed';

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
  String get settingsVolumeControl => 'Volume Control';
  @override
  String get settingsReset => 'Reset';
  @override
  String get settingsSoundEffect => 'Sound Effects';
  @override
  String get settingsVibration => 'Vibration';
  @override
  String get settingsEnableSoundEffect => 'Enable Sound Effects';
  @override
  String get settingsEnableVibration => 'Enable Vibration';
  @override
  String get settingsPersonalAccount => 'Personal Account';
  @override
  String get settingsLoginRegister => 'Login / Register';
  @override
  String get settingsLoginToSync => 'Login to sync your practice records';
  @override
  String get settingsAnimalCollection => 'Animal Collection';
  @override
  String get settingsAnimalCollectionDesc => 'View your collected cute animals';
  @override
  String get settingsNotifications => 'Notifications';
  @override
  String get settingsNotificationsDesc => 'Manage app notifications';
  @override
  String get settingsThemeTitle => 'Theme Settings';
  @override
  String get settingsThemeDesc => 'Choose app theme color';
  @override
  String get settingsAboutTitle => 'About App';
  @override
  String get settingsAboutDesc => 'Version info and dev team';

  @override
  String get settingsAboutApp => 'About App';
  @override
  String get settingsVersion => 'Version';
  @override
  String get settingsPrivacy => 'Privacy Policy';
  @override
  String get settingsTerms => 'Terms of Service';

  // Theme Selection
  @override
  String get themeSelectTitle => 'Select Theme';
  @override
  String get themeClose => 'Close';
  @override
  String get themeDawn => 'Dawn';
  @override
  String get themeOcean => 'Ocean';
  @override
  String get themeForest => 'Forest';
  @override
  String get themeSunset => 'Sunset';
  @override
  String get themeLavender => 'Lavender';
  
  // About App Dialog
  @override
  String get aboutAppTitle => 'About Music Practice App';
  @override
  String get aboutAppVersion => 'Version';
  @override
  String get aboutAppDescription => 'A music practice app with intelligent analysis, MIDI playback, recording, sheet management, and check-in rewards. Help you improve in your musical journey!';
  @override
  String get aboutAppFeatures => 'Key Features:\n• AI pitch & rhythm analysis\n• MIDI playback & practice\n• Recording & playback\n• Check-in system & animal collection\n• Multiple themes';
  @override
  String get aboutAppTeam => 'Development Team: Music Practice Team';
  @override
  String get aboutAppConfirm => 'OK';
  
  // Upload MIDI Page
  @override
  String get uploadMidiTitle => 'Upload MIDI from Device';
  @override
  String get uploadMidiSelectFile => 'Please select a MIDI file to upload';
  @override
  String get uploadMidiSupportedFormats => 'Supported formats: .mid, .midi';
  @override
  String get uploadMidiSupportedFormatsWeb => 'Supported formats: .mid, .midi (Web version uses memory loading)';
  @override
  String get uploadMidiFileSize => 'File Size';
  @override
  String get uploadMidiPlatform => 'Platform';
  @override
  String get uploadMidiPlatformLocal => 'Local Storage';
  @override
  String get uploadMidiReselect => 'Reselect';
  @override
  String get uploadMidiSaveToLibrary => 'Save to Library';
  @override
  String get uploadMidiNoFileSelected => 'No file selected';
  @override
  String get uploadMidiSuccess => 'MIDI file saved to library successfully!';
  
  // Animal Collection
  @override
  String get animalCat => 'Cute Cat';
  @override
  String get animalDog => 'Loyal Dog';
  @override
  String get animalFox => 'Smart Fox';
  @override
  String get animalPanda => 'Cute Panda';
  @override
  String get animalRabbit => 'Lively Rabbit';
  @override
  String get animalBear => 'Adorable Bear';
  @override
  String get animalDeer => 'Elegant Deer';
  @override
  String get animalPenguin => 'Baby Penguin';
  @override
  String get animalKoala => 'Koala';
  @override
  String get animalRaccoon => 'Cute Raccoon';
  @override
  String get animalSquirrel => 'Squirrel';
  @override
  String get animalHedgehog => 'Hedgehog';
  @override
  String get animalSeal => 'Seal';
  @override
  String get animalSheep => 'Sheep';
  @override
  String get animalLion => 'Lion King';
  @override
  String get animalKangaroo => 'Kangaroo';
  @override
  String get animalSloth => 'Sloth';
  @override
  String get animalGuineaPig => 'Guinea Pig';
  @override
  String get animalPrairieDog => 'Prairie Dog';
  @override
  String get animalQuokka => 'Quokka';
  @override
  String get animalFairy => 'Fairy';
  @override
  String get animalTaiwanBear => 'Taiwan Black Bear';
  @override
  String get animalUnknown => '???';
  @override
  String get animalStatusLocked => 'Status: Locked';
  @override
  String get animalStatusUnlocked => 'Status: Unlocked';
  @override
  String get animalUnlockCondition => 'Unlock Condition';
  @override
  String get animalCheckInDays => 'Check in %d days';
  @override
  String get animalCurrentProgress => 'Current Progress';
  @override
  String get animalProgressDays => '%d / %d days';
  @override
  String get animalUnlockDate => 'Unlock Date';
  @override
  String get animalDetailClose => 'Close';
  
  // Animal Unlock Animation
  @override
  String get animalUnlockCongrats => '🎉 Congratulations 🎉';
  @override
  String get animalUnlockCheckInDays => 'Unlocked by %d days check-in';
  @override
  String get animalUnlockGreat => 'Awesome!';
  
  // Timer Warning
  @override
  String get timerRunningTitle => 'Timer Running';
  @override
  String get timerRunningMessage => 'Practice timer is currently running.\n\nSwitching pages will automatically pause the timer and save current record.\n\nAre you sure you want to leave this page?';
  @override
  String get timerStayOnPage => 'Stay Here';
  @override
  String get timerLeavePage => 'Leave';
  
  // Error Types
  @override
  String get errorTypeMissedNote => 'Missed Note';
  @override
  String get errorTypeWrongNote => 'Wrong Note';
  @override
  String get errorTypeEarlyTiming => 'Timing Deviation';
  @override
  String get errorTypeLateTiming => 'Timing Deviation';
  @override
  String get errorMessageMissedNote => 'Missed Note: %s at %ss';
  @override
  String get errorMessageTimingOffset => 'Timing Deviation: %s %s %sms (Onset)';
  @override
  String get errorTimingEarly => 'early';
  @override
  String get errorTimingLate => 'late';

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
  String get loginWelcomeBack => 'Welcome Back';
  @override
  String get loginEmailLabel => 'Email';
  @override
  String get loginPasswordLabel => 'Password';
  @override
  String get loginEmailHint => 'Please enter email';
  @override
  String get loginEmailInvalid => 'Please enter a valid email';
  @override
  String get loginPasswordHint => 'Please enter password';
  @override
  String get loginOr => 'or';
  @override
  String get loginGoogleButton => 'Sign in with Google';
  @override
  String get loginGoogleSuccess => 'Google sign-in successful!';

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
  String get registerCreateAccount => 'Create Account';
  @override
  String get registerEmailLabel => 'Email';
  @override
  String get registerEmailHint => 'Please enter email';
  @override
  String get registerEmailInvalid => 'Please enter a valid email';
  @override
  String get registerUsernameLabel => 'Username';
  @override
  String get registerUsernameHint => '3-20 characters, will be your display name';
  @override
  String get registerUsernameLength => 'Username must be 3-20 characters';
  @override
  String get registerPasswordLabel => 'Password';
  @override
  String get registerPasswordHint => 'At least 6 characters';
  @override
  String get registerPasswordMinLength => 'Password must be at least 6 characters';
  @override
  String get registerConfirmPasswordLabel => 'Confirm Password';
  @override
  String get registerConfirmPasswordHint => 'Please enter password again';
  @override
  String get registerPasswordNotMatch => 'Passwords do not match';
  @override
  String get registerOr => 'or';
  @override
  String get registerGoogleButton => 'Sign up with Google';
  @override
  String get registerDataRetentionTitle => 'Keep Current Data?';
  @override
  String get registerDataRetentionMessage => 'We detected check-in records or practice time in guest mode.\n\nDo you want to import this data to your new account, or start fresh?';
  @override
  String get registerDataRetentionRestart => 'Start Fresh';
  @override
  String get registerDataRetentionKeep => 'Keep Current Data';
  @override
  String get registerSuccessWithData => 'Registration successful! Your check-in and practice records have been preserved';
  @override
  String get registerSuccessWelcome => 'Registration successful! Welcome';
  @override
  String get registerGoogleSuccessWithData => 'Google sign-in successful! Your check-in and practice records have been preserved';
  @override
  String get registerGoogleSuccess => 'Google sign-in successful!';

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
  String get profilePleaseLogin => 'Please login first';
  @override
  String get profileGoToLogin => 'Go to Login';
  @override
  String get profileEmail => 'Email';
  @override
  String get profileRegistrationDate => 'Registration Date';
  @override
  String get profileEditProfile => 'Edit Profile';
  @override
  String get profileDisplayName => 'Display Name';
  @override
  String get profileDataUpdated => 'Profile updated';
  @override
  String get profileOldPassword => 'Old Password';
  @override
  String get profileNewPassword => 'New Password';
  @override
  String get profileConfirmNewPassword => 'Confirm New Password';
  @override
  String get profilePasswordMismatch => 'Passwords do not match';
  @override
  String get profilePasswordChanged => 'Password changed';
  @override
  String get profileChangeFailed => 'Change failed';
  @override
  String get profileLogoutTitle => 'Confirm Logout';
  @override
  String get profileLogoutMessage => 'Are you sure you want to logout?';
  @override
  String get profileLoggedOut => 'Logged out';
  @override
  String get profileDeleteTitle => 'Delete Account';
  @override
  String get profileDeleteWarning => '⚠️ This action cannot be undone!\nAll data will be permanently deleted.';
  @override
  String get profileDeleteGoogleHint => 'You signed in with Google.\nAfter clicking "Confirm Delete", you will need to sign in to Google again to verify your identity.';
  @override
  String get profileDeletePasswordHint => 'Please enter password to confirm';
  @override
  String get profileDeletePasswordLabel => 'Your account password is required';
  @override
  String get profileDeleteButton => 'Confirm Delete';
  @override
  String get profileAccountDeleted => 'Account deleted';
  @override
  String get profileDeleteError => 'Delete failed';

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
  String get uploadPageTitle => 'Upload Music Files';
  @override
  String get uploadLocalMidi => 'Upload MIDI from Device';
  @override
  String get uploadLocalMidiSubtitle => 'Supports .mid and .midi formats';
  @override
  String get uploadLocalScore => 'Upload Score from Device';
  @override
  String get uploadLocalScoreSubtitle => 'Supports image-based sheet music';
  @override
  String get uploadFeatureNotAvailable => 'Feature Under Development';
  @override
  String get uploadFeatureNotAvailableMessage => 'This feature is under development, stay tuned!';

  @override
  String get playbackTitle => 'Play MIDI';
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
  String get playbackUnknownFile => 'Unknown File';
  @override
  String get playbackFileSize => 'File Size';
  @override
  String get playbackReplay => 'Replay';
  @override
  String get playbackTooltipReplay => 'Replay';
  @override
  String get playbackTooltipPlay => 'Play';
  @override
  String get playbackTooltipPause => 'Pause';
  @override
  String get playbackTooltipStop => 'Stop';

  @override
  String get analysisTitle => 'Performance Analysis';
  @override
  String get analysisReportTitle => 'Performance Analysis Report';
  @override
  String get analysisScore => 'Score';
  @override
  String get analysisThisScore => 'This Score';
  @override
  String get analysisAccuracy => 'Accuracy';
  @override
  String get analysisAccuracyRate => 'Accuracy Rate';
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
  String get analysisPitchErrors => 'Pitch Errors';
  @override
  String get analysisRhythmErrors => 'Rhythm Errors';
  @override
  String get analysisReturnHome => 'Return Home';
  @override
  String get analysisRetryChallenge => 'Retry Challenge';
  @override
  String get analysisTimes => 'times';
  @override
  String get analysisResultTitle => 'Performance Analysis Report';
  @override
  String get analysisResultGrade => 'Grade';
  @override
  String get analysisResultAccuracyLabel => 'Accuracy';
  @override
  String get analysisResultRhythmLabel => 'Rhythm';
  @override
  String get analysisResultStatistics => 'Statistics';
  @override
  String get analysisResultCorrect => 'Correct';
  @override
  String get analysisResultMissed => 'Missed';
  @override
  String get analysisResultWrong => 'Wrong Note';
  @override
  String get analysisResultEarly => 'Early';
  @override
  String get analysisResultLate => 'Late';
  @override
  String get analysisResultErrorDetails => 'Error Details';
  @override
  String get analysisResultShowingFirst => '(Showing first 20 of';
  @override
  String get analysisResultShowingUnit => ')';
  @override
  String get analysisResultSuggestions => 'Practice Suggestions';
  @override
  String get analysisResultRetry => 'Retry Practice';
  @override
  String get analysisResultViewScore => 'View Score';
  @override
  String get analysisResultScoreInDevelopment => 'Score feature in development...';

  @override
  String get practiceAudioToMidi => 'Audio to MIDI';
  @override
  String get practiceAnalyzingRecording => '🤖 Analyzing your complete recording with AI...';
  @override
  String get practiceAnalyzingTitle => 'Performance Analysis';
  @override
  String get practiceAnalysisFailed => 'Analysis Failed';
  @override
  String get practiceSelectingInstruction => 'Tap to select a sheet to practice';
  @override
  String get practiceAnalysisDescription => 'Use spectral analysis technology to verify your performance\nCompare pitch, rhythm, and provide ratings and suggestions';
  @override
  String practiceFileSavedDownloads(String fileName, String analysis) => 'File saved to Downloads folder:\n$fileName\n\n$analysis\n\n🔍 Search for "$fileName" in file manager to find it';
  @override
  String practiceFileSavedLocation(String path, String fileName, String analysis) => 'MIDI file location:\n$path\n\n$analysis\n\n🔍 Search for "$fileName" in file manager to find it';
  @override
  String get practiceFileOpenSuccess => '\n\n✅ Attempted to open file manager';
  @override
  String get practiceFileOpenFailed => '\n\n⚠️ Cannot open automatically, please search manually';

  @override
  String get suggestionRandomPlaying => '🚨 System detected possible random playing or wrong track, please confirm:';
  @override
  String get suggestionCheckCorrectFile => '   1. Have you selected the correct MIDI file';
  @override
  String get suggestionCheckCompleteSong => '   2. Have you played the specified piece completely';
  @override
  String get suggestionCheckQuietEnvironment => '   3. Did you record in a quiet environment';
  @override
  String get suggestionWrongSong => '❌ Performance content does not match the specified piece!';
  @override
  String get suggestionConfirmCorrectSong => '   Please confirm if you played the correct piece';
  @override
  String get suggestionPitchNeedsPractice => '🎹 Pitch needs more practice, suggest slowing down to verify each note';
  @override
  String get suggestionPitchBasic => '🎵 Pitch is basically correct, but there is still room for improvement';
  @override
  String get suggestionPitchPerfect => '🌟 Pitch performance is perfect!';
  @override
  String get suggestionPitchExcellent => '⭐ Pitch performance is excellent!';
  @override
  String suggestionExtraNotes(int count) => '⚠️ Detected $count extra notes, please pay attention:';
  @override
  String get suggestionAvoidWrongKeys => '   - Avoid accidentally pressing other keys';
  @override
  String get suggestionEnsureAccuracy => '   - Ensure fingers are accurately placed in the correct position';
  @override
  String suggestionManyMissed(int count) => '❌ Many missed notes ($count), suggestions:';
  @override
  String get suggestionCheckKeyPress => '   - Check if fingers fully press the keys';
  @override
  String get suggestionRetryQuietEnvironment => '   - Re-record in a quiet environment';
  @override
  String get suggestionCheckMicSensitivity => '   - Ensure microphone sensitivity is sufficient';
  @override
  String suggestionSomeMissed(int count) => '⚠️ Some missed notes ($count), please check key press strength';
  @override
  String get suggestionRhythmUnstable => '⏱️ Rhythm is unstable, suggest practicing with a metronome';
  @override
  String get suggestionRhythmBasic => '🎼 Rhythm is basically stable, you can try to increase the speed slightly';
  @override
  String get suggestionRhythmGood => '✨ Rhythm mastery is great!';
  @override
  String get suggestionTendencyRushing => '⏩ Tendency to rush, relax a bit and don\'t be too hasty';
  @override
  String get suggestionTendencyDragging => '⏸️ Tendency to drag, may need to strengthen rhythm training';

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
  String get metronomeAccent => 'Accent';
  @override
  String get metronomeBpmInputHint => 'Tap to input';
  @override
  String get metronomeBpmRange => 'BPM must be between 30 and 300';
  @override
  String get metronomeClear => 'Clear';
  @override
  String get metronomeWeekPractice => 'Weekly Practice Time';

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
  String get errorMicPermission => 'Microphone permission required for recording. Please grant permission in settings';
  @override
  String errorRecordingStart(String error) => 'Recording failed to start: $error\n\nPlease ensure:\n1. Microphone permission is granted\n2. No other app is using the microphone';
  @override
  String errorRecordingFileSize(int size) => 'Recording complete! File size: ${(size / 1024).toStringAsFixed(1)} KB';
  @override
  String errorRecordingFileTooSmall(int size) => 'Recording file too small ($size bytes), possible audio capture issue';
  @override
  String errorRecordingFileCheck(String error) => 'Recording file check failed: $error';
  @override
  String errorRecordingStop(String error) => 'Failed to stop recording: $error\n\nPlease try recording again';
  @override
  String get errorRecordingFileNotFound => 'Recording file not found, please record again';
  @override
  String get errorRecordingFileEmpty => 'Recording file is empty, cannot play';
  @override
  String errorPlaybackFailed(String error) => 'Playback failed: $error';
  @override
  String get errorRecordFirst => 'Please record first before converting';
  @override
  String get errorConvertMidiFirst => 'Please convert MIDI file first';
  @override
  String errorFileAccess(String error) => 'File access failed: $error';
  @override
  String errorAnalysisFailed(String error) => 'Analysis failed: $error';
  
  @override
  String errorFileSelection(String error) => 'Error selecting file: $error';
  @override
  String get errorFileReadFailed => 'Error: Unable to read file content, please select again.';
  
  @override
  String get errorDrawingColorLabel => 'Color ';
  @override
  String get errorDrawingSizeLabel => 'Size ';
  @override
  String get annotationSelectStar => 'Select star icon:';
  @override
  String get annotationMarkerColor => 'Marker color:';
  @override
  String get annotationDelete => 'Delete';
  @override
  String get annotationCancel => 'Cancel';
  @override
  String get annotationConfirm => 'Confirm';
  @override
  String get annotationInputRequired => 'Please enter note content';
  @override
  String get annotationAddMarker => 'Add Marker';
  @override
  String get annotationEditMarker => 'Edit Marker';
  @override
  String get annotationNoteLabel => 'Note Content';
  @override
  String get annotationNoteHint => 'Enter your note...';

  @override
  String get notePageTitle => 'Music Sheets';
  @override
  String get notePageSelectToDelete => 'Select sheets to delete';
  @override
  String get notePageSheetAnnotation => 'Sheet Annotation';
  @override
  String get notePageEdit => 'Edit';
  @override
  String get notePageCancel => 'Cancel';
  @override
  String get notePageDeleteSelected => 'Delete Selected';
  @override
  String get notePageLoading => 'Loading...';
  @override
  String get notePageEmpty => 'No music sheets yet';
  @override
  String get notePageEmptyHint => 'Tap the + button to add a sheet';
  @override
  String get notePageOrUseAnnotation => 'Or use sheet annotation';
  @override
  String get notePageNotesCount => 'notes';
  @override
  String get notePageAddSheet => 'Add Music Sheet';
  @override
  String get notePageSheetName => 'Sheet Name';
  @override
  String get notePageSheetNameHint => 'e.g., Beethoven op.53, Mozart K.545';
  @override
  String get notePageAdd => 'Add';
  @override
  String get notePageConfirmDelete => 'Confirm Delete';
  @override
  String get notePageConfirmDeleteMessage => 'Are you sure you want to delete';
  @override
  String get notePageConfirmDeleteSuffix => 'sheet(s) and all their notes?';
  @override
  String get notePageDelete => 'Delete';

  @override
  String get sheetAnnotationTitle => 'Digital Sheet';
  @override
  String get sheetAnnotationSelectToDelete => 'Select sheets to delete';
  @override
  String get sheetAnnotationMusicLibrary => 'Music Library';
  @override
  String get sheetAnnotationEdit => 'Edit';
  @override
  String get sheetAnnotationCancel => 'Cancel';
  @override
  String get sheetAnnotationDeleteSelected => 'Delete Selected';
  @override
  String get sheetAnnotationEmpty => 'No sheets yet';
  @override
  String get sheetAnnotationEmptyHint => 'Tap the + button to import a sheet';
  @override
  String get sheetAnnotationMarkersCount => 'markers';
  @override
  String get sheetAnnotationTypeImage => 'Image';
  @override
  String get sheetAnnotationTypePdf => 'PDF';
  @override
  String get sheetAnnotationUpdatedAt => 'Updated';
  @override
  String get sheetAnnotationToday => 'Today';
  @override
  String get sheetAnnotationYesterday => 'Yesterday';
  @override
  String get sheetAnnotationDaysAgo => 'days ago';
  @override
  String get sheetAnnotationConfirmDelete => 'Confirm Delete';
  @override
  String get sheetAnnotationConfirmDeleteMessage => 'Are you sure you want to delete "{name}"?';
  @override
  String get sheetAnnotationDelete => 'Delete';
  @override
  String get sheetAnnotationDeleted => 'Sheet deleted';
  @override
  String get sheetAnnotationDeleteFailed => 'Delete failed';
  @override
  String get sheetAnnotationImported => 'Sheet imported';
  @override
  String get sheetAnnotationImportFailed => 'Import failed';
  @override
  String get sheetAnnotationPdfViewerInDev => 'PDF viewer under development';
  @override
  String get sheetAnnotationPdfViewerHint => 'Please use image format for now';
  @override
  String get sheetAnnotationDeletedMultiple => 'Deleted';
  @override
  String get sheetAnnotationDeletedSuffix => 'sheet(s)';
  @override
  String get sheetAnnotationConfirmDeleteMultiple => 'Are you sure you want to delete the selected';

  @override
  String get sheetDetailAddNote => 'Add Practice Note';
  @override
  String get sheetDetailClickToAdd => 'Click the button below to add practice notes';
  @override
  String get sheetDetailAddDescription => 'Record important points for specific measures';
  @override
  String get sheetDetailAddButton => 'Add Note';
  @override
  String get sheetDetailEmpty => 'No practice notes yet';
  @override
  String get sheetDetailEmptyHint => 'Start recording practice points for this piece!';
  @override
  String get sheetDetailMeasureNumber => 'Measure Number';
  @override
  String get sheetDetailMeasureHint => 'Ex: 12';
  @override
  String get sheetDetailContent => 'Notes';
  @override
  String get sheetDetailContentHint => 'Record important points, techniques, or practice focus...';
  @override
  String get sheetDetailCancel => 'Cancel';
  @override
  String get sheetDetailAdd => 'Add';
  @override
  String get sheetDetailSave => 'Save';
  @override
  String get sheetDetailConfirmDelete => 'Confirm Delete';
  @override
  String get sheetDetailConfirmDeleteMessage => 'Are you sure you want to delete this note?';
  @override
  String get sheetDetailDelete => 'Delete';
  @override
  String get sheetDetailEditNote => 'Edit Practice Note';
  @override
  String get sheetDetailMeasureLabel => 'Measure Number';
  @override
  String get sheetDetailMeasureExample => 'e.g., 16';
  @override
  String get sheetDetailDrawing => 'Music Drawing';
  @override
  String get sheetDetailDrawingEdit => 'Edit Music Drawing';
  @override
  String get sheetDetailDrawingIncluded => 'Includes music drawing';
  @override
  String get sheetDetailMeasurePrefix => 'Measure';
  @override
  String get sheetDetailMeasureSuffix => '';

  @override
  String get countdownCancel => 'Cancel';

  @override
  String get recentActivityContinue => 'Continue';

  @override
  String get playbackPageTitle => 'MIDI Player';
  @override
  String get playbackPagePlaying => 'Playing...';
  @override
  String get playbackPagePaused => 'Paused';
  @override
  String get playbackPageStopped => 'Stopped';

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

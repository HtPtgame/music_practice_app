// lib/pages/settings_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:music_practice_app/core/theme/theme_manager.dart';
import 'package:music_practice_app/core/language/language_manager.dart';
import 'package:music_practice_app/l10n/app_localizations.dart';
import 'package:music_practice_app/core/services/settings_service.dart';
import 'package:music_practice_app/services/haptic_service.dart';
import 'package:music_practice_app/core/services/auth_service_config.dart';
import 'package:music_practice_app/services/user_data_sync_service.dart';
import 'package:music_practice_app/services/practice_timer_service.dart';
import 'package:music_practice_app/services/joke_service.dart';
import 'package:music_practice_app/utils/error_handler.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();
  final HapticService _hapticService = HapticService();
  final UserDataSyncService _syncService = UserDataSyncService();
  final PracticeTimerService _timerService = PracticeTimerService();

  String _selectedLanguage = 'zh_TW'; // 預設選擇繁體中文

  // 音效設定相關變數
  double _masterVolume = 0.8; // 主音量 (0.0 - 1.0)
  double _midiVolume = 0.7; // MIDI 播放音量
  double _recordingVolume = 0.9; // 錄音音量
  double _metronomeVolume = 0.6; // 節拍器音量
  bool _soundEnabled = true; // 是否啟用音效
  bool _vibrationEnabled = true; // 是否啟用震動

  // 練習計時器設定
  bool _showFloatingTimer = true; // 是否顯示浮動計時器
  bool _showNotification = false; // 是否顯示通知 (僅 Android)

  // 載入狀態
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    // 監聯認證狀態變化,登入後刷新數據
    authService.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  /// 認證狀態變化時的回調
  void _onAuthStateChanged() {
    // 當認證狀態改變時,重新載入數據
    // (登入後會從雲端同步到本地,然後這裡載入最新數據)
    if (mounted) {
      _loadSettings();
    }
  }

  /// 從持久化儲存載入所有設定
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ 優先從本地 SharedPreferences 載入最新數據
      final settings = await _settingsService.getAllSettings();

      if (mounted) {
        setState(() {
          _masterVolume = settings['masterVolume'] as double;
          _midiVolume = settings['midiVolume'] as double;
          _recordingVolume = settings['recordingVolume'] as double;
          _metronomeVolume = settings['metronomeVolume'] as double;
          _soundEnabled = settings['soundEnabled'] as bool;
          _vibrationEnabled = settings['vibrationEnabled'] as bool;
          _selectedLanguage = settings['selectedLanguage'] as String;

          // 載入計時器設定
          _showFloatingTimer = _timerService.showFloatingTimer;
          _showNotification = _timerService.showNotification;

          _isLoading = false;
        });
      }

      debugPrint('SettingsPage: ✅ Settings loaded from local (最新數據)');
    } catch (e) {
      debugPrint('SettingsPage: ⚠️ Failed to load settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 保存設定到本地和雲端
  Future<void> _saveSettings() async {
    // 保存到本地 SharedPreferences
    await _settingsService.setMasterVolume(_masterVolume);
    await _settingsService.setMidiVolume(_midiVolume);
    await _settingsService.setRecordingVolume(_recordingVolume);
    await _settingsService.setMetronomeVolume(_metronomeVolume);
    await _settingsService.setSoundEnabled(_soundEnabled);
    await _settingsService.setVibrationEnabled(_vibrationEnabled);
    await _settingsService.setSelectedLanguage(_selectedLanguage);

    // 如果已登入，同步到雲端
    final user = authService.currentUser;
    if (user != null) {
      try {
        final settings = {
          'masterVolume': _masterVolume,
          'midiVolume': _midiVolume,
          'recordingVolume': _recordingVolume,
          'metronomeVolume': _metronomeVolume,
          'soundEnabled': _soundEnabled,
          'vibrationEnabled': _vibrationEnabled,
          'selectedLanguage': _selectedLanguage,
          'timer_show_floating': _showFloatingTimer,
          'timer_show_notification': _showNotification,
        };

        await _syncService.syncSettings(settings);
        debugPrint('設定已同步到雲端');
      } catch (e) {
        debugPrint('同步設定到雲端失敗: $e');
        // 即使同步失敗,本地設定已保存
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.dynamicBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.dynamicPrimary,
              ),
              const SizedBox(height: 16),
              Text(
                '載入設定中...',
                style: TextStyle(
                  color: AppColors.dynamicTextLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 帳號設定區塊
              _buildSectionTitle(l10n?.settingsAccount ?? '帳號設定'),
              const SizedBox(height: 16),
              _buildAccountCard(),
              const SizedBox(height: 32),

              // 語言設定區塊
              _buildSectionTitle(l10n?.settingsLanguage ?? '語言設定'),
              const SizedBox(height: 16),
              _buildLanguageCard(),
              const SizedBox(height: 32),

              // 音效設定區塊
              _buildSectionTitle(l10n?.settingsAudio ?? '音效設定'),
              const SizedBox(height: 16),
              _buildSoundSettingsCard(),
              const SizedBox(height: 32),

              // 練習計時器設定區塊
              _buildSectionTitle(l10n?.timerSettingsTitle ?? '計時器設定'),
              const SizedBox(height: 16),
              _buildTimerSettingsCard(),
              const SizedBox(height: 32),

              // 其他設定區塊
              _buildSectionTitle(l10n?.settingsOther ?? '其他設定'),
              const SizedBox(height: 16),
              _buildOtherSettingsCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.dynamicTextDark,
      ),
    );
  }

  Widget _buildAccountCard() {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        final user = authService.currentUser;

        return Card(
          color: AppColors.dynamicCard,
          elevation: 1.5,
          shadowColor: const Color(0x196A5AE0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              if (user != null) {
                context.push('/profile');
              } else {
                context.push('/login');
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dynamicPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      user != null ? Icons.person : Icons.person_outline,
                      color: AppColors.dynamicPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            user != null
                                ? (l10n?.settingsPersonalAccount ?? '個人帳號')
                                : (l10n?.settingsLoginRegister ?? '登入 / 註冊'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dynamicTextDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            user != null
                                ? user.displayName ?? user.username
                                : (l10n?.settingsLoginToSync ?? '登入以同步您的練習記錄'),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.dynamicTextLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.dynamicTextLight,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageCard() {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: AppColors.dynamicCard,
      elevation: 1.5,
      shadowColor: const Color(0x196A5AE0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _showLanguageDialog,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dynamicPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.language,
                  color: AppColors.dynamicPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        l10n?.settingsLanguageTitle ?? '語言',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dynamicTextDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      LanguageManager.instance.currentLanguageName,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.dynamicTextLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.dynamicTextLight,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundSettingsCard() {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: AppColors.dynamicCard,
      elevation: 2,
      shadowColor: const Color(0x196A5AE0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題與重置按鈕
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n?.settingsVolumeControl ?? '音量控制',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dynamicTextDark,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _resetVolumesToDefault,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n?.settingsReset ?? '重置'),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.dynamicPrimary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 主音量
            _buildVolumeSlider(
              icon: Icons.volume_up,
              title: l10n?.settingsMasterVolume ?? '主音量',
              value: _masterVolume,
              onChanged: (value) async {
                setState(() => _masterVolume = value);
                await _saveSettings();
                _hapticService.selectionClick();
              },
            ),
            const SizedBox(height: 20),

            // MIDI 音量
            _buildVolumeSlider(
              icon: Icons.piano,
              title: l10n?.settingsMidiVolume ?? 'MIDI 音量',
              value: _midiVolume,
              onChanged: (value) async {
                setState(() => _midiVolume = value);
                await _saveSettings();
                _hapticService.selectionClick();
              },
            ),
            const SizedBox(height: 20),

            // 節拍器音量
            _buildVolumeSlider(
              icon: Icons.av_timer,
              title: l10n?.settingsMetronomeVolume ?? '節拍器音量',
              value: _metronomeVolume,
              onChanged: (value) async {
                setState(() => _metronomeVolume = value);
                await _saveSettings();
                _hapticService.selectionClick();
              },
            ),
            const SizedBox(height: 20),

            // 錄音音量
            _buildVolumeSlider(
              icon: Icons.mic,
              title: l10n?.settingsRecordingVolume ?? '錄音音量',
              value: _recordingVolume,
              onChanged: (value) async {
                setState(() => _recordingVolume = value);
                await _saveSettings();
                _hapticService.selectionClick();
              },
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // 音效開關
            _buildSwitchTile(
              icon: Icons.music_note,
              title: l10n?.settingsSoundEffect ?? '音效',
              subtitle: _soundEnabled
                  ? (l10n?.settingsEnableSoundEffect ?? '已啟用')
                  : (l10n?.settingsDisabled ?? '已關閉'),
              value: _soundEnabled,
              onChanged: (value) async {
                setState(() => _soundEnabled = value);
                await _saveSettings();
                _hapticService.lightImpact();
              },
            ),
            const SizedBox(height: 12),

            // 震動開關
            _buildSwitchTile(
              icon: Icons.vibration,
              title: l10n?.settingsVibration ?? '震動回饋',
              subtitle: _vibrationEnabled
                  ? (l10n?.settingsEnableVibration ?? '已啟用')
                  : (l10n?.settingsDisabled ?? '已關閉'),
              value: _vibrationEnabled,
              onChanged: (value) async {
                setState(() => _vibrationEnabled = value);
                await _saveSettings();
                _hapticService.lightImpact();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 建立練習計時器設定卡片
  Widget _buildTimerSettingsCard() {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: AppColors.dynamicCard,
      elevation: 2,
      shadowColor: const Color(0x196A5AE0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            Row(
              children: [
                Icon(Icons.timer, color: AppColors.dynamicPrimary, size: 24),
                const SizedBox(width: 12),
                Text(
                  l10n?.timerSettingsTitle ?? '計時器設定',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dynamicTextDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 浮動計時器開關
            _buildSwitchTile(
              icon: Icons.picture_in_picture_alt,
              title: l10n?.timerSettingsFloatingTimer ?? '浮動計時器',
              subtitle: _showFloatingTimer
                  ? (l10n?.timerSettingsFloatingTimerOn ?? '練習時會顯示浮動計時器')
                  : (l10n?.timerSettingsFloatingTimerOff ?? '已關閉浮動計時器'),
              value: _showFloatingTimer,
              onChanged: (value) async {
                setState(() => _showFloatingTimer = value);
                await _timerService.setShowFloatingTimer(value);
                if (authService.isAuthenticated) {
                  await _syncService.updateSetting(
                      'timer_show_floating', value);
                }
                _hapticService.lightImpact();
              },
            ),
            const SizedBox(height: 16),

            // 通知設定 (僅 Android)
            if (Platform.isAndroid) ...[
              _buildSwitchTile(
                icon: Icons.notifications_active,
                title: l10n?.timerSettingsBackgroundNotification ?? '背景通知',
                subtitle: _showNotification
                    ? (l10n?.timerSettingsBackgroundNotificationOn ??
                        '離開 App 時會顯示通知')
                    : (l10n?.timerSettingsBackgroundNotificationOff ??
                        '不顯示背景通知'),
                value: _showNotification,
                onChanged: (value) async {
                  if (value) {
                    // 開啟通知時，請求通知權限
                    final status = await Permission.notification.status;
                    if (status.isDenied || status.isPermanentlyDenied) {
                      final result = await Permission.notification.request();
                      if (!result.isGranted) {
                        // 權限被拒絕，提示用戶
                        if (mounted) {
                          ErrorHandler.showWarning(
                            context,
                            l10n?.timerSettingsNotificationPermission ??
                                '需要通知權限才能顯示背景通知',
                          );
                        }
                        return; // 不開啟功能
                      }
                    }
                  }
                  setState(() => _showNotification = value);
                  await _timerService.setShowNotification(value);
                  if (authService.isAuthenticated) {
                    await _syncService.updateSetting(
                        'timer_show_notification', value);
                  }
                  _hapticService.lightImpact();
                },
              ),
              const SizedBox(height: 16),
            ],

            // iOS 提示
            if (Platform.isIOS)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n?.timerSettingsIosLimitation ??
                              'iOS 系統限制：背景計時將在 App 進入背景後暫停。',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 重置所有音量到預設值
  Future<void> _resetVolumesToDefault() async {
    try {
      // 震動回饋
      await _hapticService.mediumImpact();

      // 重置到預設值
      setState(() {
        _masterVolume = 0.8;
        _midiVolume = 0.7;
        _recordingVolume = 0.9;
        _metronomeVolume = 0.6;
      });

      // 儲存設定
      await _saveSettings();

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ErrorHandler.showSuccess(
          context,
          l10n?.settingsVolumeReset ?? '已重置所有音量至標準值',
        );
      }
    } catch (e) {
      debugPrint('重置音量失敗: $e');
      if (mounted) {
        ErrorHandler.show(
          context,
          '重置失敗，請重試',
        );
      }
    }
  }

  Widget _buildVolumeSlider({
    required IconData icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.dynamicPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicTextDark,
                    ),
                  ),
                  Text(
                    '${(value * 100).round()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: AppColors.dynamicPrimary,
                  inactiveTrackColor:
                      AppColors.dynamicPrimary.withValues(alpha: 0.2),
                  thumbColor: AppColors.dynamicPrimary,
                  overlayColor: AppColors.dynamicPrimary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: value,
                  onChanged: onChanged,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100, // 設定為100個區間，每個區間為1% (0.01)
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.dynamicPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dynamicTextDark,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.dynamicTextLight,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.dynamicPrimary,
        ),
      ],
    );
  }

  Widget _buildOtherSettingsCards() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _buildSettingCard(
          icon: Icons.pets,
          title: l10n?.settingsAnimalCollection ?? '動物圖鑑',
          subtitle: l10n?.settingsAnimalCollectionDesc ?? '查看您收集的可愛動物',
          onTap: () {
            context.push('/animal-collection');
          },
        ),
        const SizedBox(height: 12),
        _buildSettingCard(
          icon: Icons.palette,
          title: l10n?.settingsThemeTitle ?? '主題設定',
          subtitle: l10n?.settingsThemeDesc ?? '選擇應用程式主題顏色',
          onTap: () => _showThemeDialog(),
        ),
        const SizedBox(height: 12),
        _buildSettingCard(
          icon: Icons.emoji_emotions,
          title: l10n?.settingsJokeTitle ?? '冷笑話',
          subtitle: l10n?.settingsJokeDesc ?? '音樂冷笑話，盡量不重複',
          onTap: () => _showJokeBottomSheet(),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.dynamicCard,
      elevation: 1.5,
      shadowColor: const Color(0x196A5AE0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dynamicPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.dynamicPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dynamicTextDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.dynamicTextLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.dynamicTextLight,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.dynamicCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsLanguageSelect,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dynamicTextDark,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: LanguageManager.languageNames.length,
                    itemBuilder: (context, index) {
                      final languageCode =
                          LanguageManager.languageNames.keys.elementAt(index);
                      final languageName =
                          LanguageManager.languageNames[languageCode]!;
                      final isSelected =
                          LanguageManager.instance.currentLanguageCode ==
                              languageCode;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        title: Text(
                          languageName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.blue[700]
                                : AppColors.dynamicTextDark,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check, color: Colors.blue[700])
                            : null,
                        onTap: () async {
                          Navigator.pop(context);

                          await _settingsService
                              .setSelectedLanguage(languageCode);
                          await LanguageManager.instance
                              .setLocale(languageCode);

                          // 使用 updateSetting 只更新單一設定項，不會影響其他設定
                          if (authService.isAuthenticated) {
                            await _syncService.updateSetting(
                                'selectedLanguage', languageCode);
                          }

                          if (mounted) {
                            setState(() {
                              _selectedLanguage = languageCode;
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemeDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.dynamicCard,
          title: Text(
            l10n?.themeSelectTitle ?? '選擇主題',
            style: TextStyle(
              color: AppColors.dynamicTextDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(
                  l10n?.themeDawn ?? '晨曦', 'default', const Color(0xFFCFAB8D)),
              _buildThemeOption(
                  l10n?.themeOcean ?? '海洋', 'ocean', const Color(0xFF7FADCC)),
              _buildThemeOption(
                  l10n?.themeForest ?? '森林', 'forest', const Color(0xFF96A78D)),
              _buildThemeOption(
                  l10n?.themeSunset ?? '夕陽', 'sunset', const Color(0xFFF6A85B)),
              _buildThemeOption(l10n?.themeLavender ?? '櫻雪', 'lavender',
                  const Color(0xFFE6B7BC)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n?.themeClose ?? '關閉',
                style: TextStyle(color: AppColors.dynamicPrimary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeOption(String name, String themeKey, Color color) {
    final isSelected = ThemeManager.instance.currentTheme == themeKey;
    return ListTile(
      leading: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(name),
      trailing: isSelected
          ? Icon(Icons.check, color: AppColors.dynamicPrimary)
          : null,
      onTap: () async {
        try {
          // 先關閉對話框，避免 context 問題
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }

          // 等待一小段時間確保對話框完全關閉
          await Future.delayed(const Duration(milliseconds: 100));

          // 然後切換主題
          await ThemeManager.instance.setTheme(themeKey);

          // 最後刷新頁面並顯示成功訊息
          if (mounted) {
            setState(() {});
            // 再等待一小段時間確保 setState 完成
            await Future.delayed(const Duration(milliseconds: 50));
            if (mounted) {
              final l10n = AppLocalizations.of(context);
              ErrorHandler.showSuccess(
                context,
                '${l10n?.settingsThemeSwitched ?? '已切換到'}$name${l10n?.settingsThemeSwitched != null ? '' : '主題'}',
              );
            }
          }
        } catch (e) {
          // 如果出現錯誤，至少確保主題被切換
          await ThemeManager.instance.setTheme(themeKey);
        }
      },
    );
  }

  void _showJokeBottomSheet() {
    final jokeService = JokeService();
    Map<String, String> currentJoke = jokeService.getNextJoke();
    bool showExplain = false;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomPadding =
            MediaQuery.of(sheetContext).viewInsets.bottom + 16;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final l10n = AppLocalizations.of(context);
            final tag = currentJoke['tag'] ?? '音樂梗';
            final accentColor = _jokeTagColor(tag);

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.dynamicCard,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x16000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.dynamicTextLight.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.sentiment_satisfied_alt,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n?.jokeDialogTitle ?? '冷笑話時間',
                                  style: TextStyle(
                                    color: AppColors.dynamicTextDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n?.jokeDialogSubtitle ?? '附解釋，不怕聽不懂',
                                  style: TextStyle(
                                    color: AppColors.dynamicTextLight,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            backgroundColor:
                                accentColor.withValues(alpha: 0.15),
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            label: Text(
                              tag,
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentJoke['setup'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.dynamicTextDark,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withValues(alpha: 0.16),
                              AppColors.dynamicAccent.withValues(alpha: 0.10),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          currentJoke['punchline'] ?? '',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dynamicPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.dynamicBackground
                                .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.jokeDialogExplainTitle ?? '為什麼好笑／有用',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.dynamicTextDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currentJoke['explain'] ?? '',
                                style: TextStyle(
                                  color: AppColors.dynamicTextLight,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        crossFadeState: showExplain
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await _hapticService.lightImpact();
                                setSheetState(() {
                                  showExplain = !showExplain;
                                });
                              },
                              icon: Icon(
                                showExplain
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.dynamicPrimary,
                              ),
                              label: Text(
                                showExplain
                                    ? (l10n?.jokeDialogHideExplain ?? '收起解釋')
                                    : (l10n?.jokeDialogShowExplain ?? '看解釋'),
                                style: TextStyle(
                                  color: AppColors.dynamicPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: accentColor),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _hapticService.lightImpact();
                                setSheetState(() {
                                  showExplain = false;
                                  currentJoke = jokeService.getNextJoke();
                                });
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(
                                l10n?.jokeDialogNext ?? '再來一個',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton.icon(
                          onPressed: () {
                            _hapticService.lightImpact();
                            Navigator.of(sheetContext).pop();
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(
                            l10n?.jokeDialogClose ?? '關閉',
                            style: TextStyle(
                              color: AppColors.dynamicTextLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _jokeTagColor(String tag) {
    switch (tag) {
      case '舞台日常':
        return const Color(0xFF4E9CFF);
      case '音樂梗':
        return const Color(0xFF7BCFAE);
      case '節奏梗':
        return const Color(0xFFFFB661);
      case '樂團吐槽':
        return const Color(0xFFA18BFF);
      case '錄音室':
        return const Color(0xFFF87070);
      case '樂器梗':
        return const Color(0xFF5CC8D7);
      case '和聲梗':
        return const Color(0xFF4DB6AC);
      case '生活梗':
        return const Color(0xFF8BC34A);
      case '歷史梗':
        return const Color(0xFF61A5F8);
      case '合唱梗':
        return const Color(0xFF6D7BE0);
      case '音準梗':
        return const Color(0xFF9C27B0);
      default:
        return AppColors.dynamicPrimary;
    }
  }
}

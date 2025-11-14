// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:music_practice_app/utils/theme_manager.dart';
import 'package:music_practice_app/services/settings_service.dart';
import 'package:music_practice_app/services/haptic_service.dart';
import 'package:music_practice_app/services/auth_service_config.dart';
import 'package:music_practice_app/services/user_data_sync_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();
  final HapticService _hapticService = HapticService();
  final UserDataSyncService _syncService = UserDataSyncService();
  
  String _selectedLanguage = 'zh_TW'; // 預設選擇繁體中文
  
  // 音效設定相關變數
  double _masterVolume = 0.8; // 主音量 (0.0 - 1.0)
  double _midiVolume = 0.7; // MIDI 播放音量
  double _recordingVolume = 0.9; // 錄音音量
  double _metronomeVolume = 0.6; // 節拍器音量
  bool _soundEnabled = true; // 是否啟用音效
  bool _vibrationEnabled = true; // 是否啟用震動
  
  // 防止重複顯示 SnackBar
  bool _isShowingSnackBar = false;
  
  // 載入狀態
  bool _isLoading = true;

  final Map<String, String> _languages = {
    'zh_TW': '繁體中文',
    'zh_CN': '繁体中文',
    'en': 'Traditional Chinese',
    'ja': '繁體中文',
    'ko': '繁體中文',
    'es': 'Chino Tradicional',
    'fr': 'Chinois Traditionnel',
    'de': 'Traditionelles Chinesisch',
    'it': 'Cinese Tradizionale',
    'pt': 'Chinês Tradicional',
    'ru': 'Традиционный китайский',
    'ar': 'الصينية التقليدية',
  };

  final Map<String, String> _languageDescriptions = {
    'zh_TW': '繁體中文（台灣）',
    'zh_CN': '繁体中文（中国大陆）',
    'en': 'English (Traditional Chinese)',
    'ja': '日本語（繁體中文）',
    'ko': '한국어（繁體中文）',
    'es': 'Español (Chino Tradicional)',
    'fr': 'Français (Chinois Traditionnel)',
    'de': 'Deutsch (Traditionelles Chinesisch)',
    'it': 'Italiano (Cinese Tradizionale)',
    'pt': 'Português (Chinês Tradicional)',
    'ru': 'Русский (Традиционный китайский)',
    'ar': 'العربية (الصينية التقليدية)',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
    
    // 監聽認證狀態變化,登入後刷新數據
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
    
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 帳號設定區塊
            _buildSectionTitle('帳號設定'),
            const SizedBox(height: 16),
            _buildAccountCard(),
            const SizedBox(height: 32),
            
            // 語言設定區塊
            _buildSectionTitle('語言設定'),
            const SizedBox(height: 16),
            _buildLanguageCard(),
            const SizedBox(height: 32),
            
            // 音效設定區塊
            _buildSectionTitle('音效設定'),
            const SizedBox(height: 16),
            _buildSoundSettingsCard(),
            const SizedBox(height: 32),
            
            // 其他設定區塊
            _buildSectionTitle('其他設定'),
            const SizedBox(height: 16),
            _buildOtherSettingsCards(),
          ],
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
    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        final user = authService.currentUser;

        return Card(
          color: AppColors.dynamicCard,
          elevation: 1.5,
          shadowColor: const Color(0x196A5AE0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        Text(
                          user != null ? '個人帳號' : '登入 / 註冊',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dynamicTextDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user != null 
                              ? user.displayName ?? user.username
                              : '登入以同步您的練習記錄',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.dynamicTextLight,
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
                    Text(
                      '語言',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dynamicTextDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _languageDescriptions[_selectedLanguage] ?? '繁體中文（台灣）',
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
                Text(
                  '音量控制',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dynamicTextDark,
                  ),
                ),
                TextButton.icon(
                  onPressed: _resetVolumesToDefault,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('重置'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.dynamicPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 主音量
            _buildVolumeSlider(
              icon: Icons.volume_up,
              title: '主音量',
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
              title: 'MIDI 音量',
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
              title: '節拍器音量',
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
              title: '錄音音量',
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
              title: '音效',
              subtitle: _soundEnabled ? '已啟用' : '已關閉',
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
              title: '震動回饋',
              subtitle: _vibrationEnabled ? '已啟用' : '已關閉',
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
        _showSuccessMessage('已重置所有音量至標準值');
      }
    } catch (e) {
      debugPrint('重置音量失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('重置失敗，請重試'),
            backgroundColor: Colors.red,
          ),
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
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: AppColors.dynamicPrimary,
                  inactiveTrackColor: AppColors.dynamicPrimary.withValues(alpha: 0.2),
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
          activeColor: AppColors.dynamicPrimary,
        ),
      ],
    );
  }

  Widget _buildOtherSettingsCards() {
    return Column(
      children: [
        _buildSettingCard(
          icon: Icons.notifications,
          title: '通知設定',
          subtitle: '管理應用程式通知',
          onTap: () => _showFeatureNotAvailable('通知設定'),
        ),
        const SizedBox(height: 12),
        _buildSettingCard(
          icon: Icons.palette,
          title: '主題設定',
          subtitle: '選擇應用程式主題顏色',
          onTap: () => _showThemeDialog(),
        ),
        const SizedBox(height: 12),
        _buildSettingCard(
          icon: Icons.info,
          title: '關於應用程式',
          subtitle: '版本資訊和開發團隊',
          onTap: () {
            _showAboutDialog();
          },
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
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dynamicTextDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
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

  void _showLanguageDialog() {
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
                  '選擇語言',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dynamicTextDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '請注意：所有語言選項都將顯示繁體中文介面',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.dynamicTextLight,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: _languages.length,
                    itemBuilder: (context, index) {
                      final languageCode = _languages.keys.elementAt(index);
                      final languageName = _languages[languageCode]!;
                      final isSelected = _selectedLanguage == languageCode;
                      
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Text(
                          languageName,
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected ? AppColors.dynamicPrimary : AppColors.dynamicTextDark,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          _languageDescriptions[languageCode] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? AppColors.dynamicPrimary.withValues(alpha: 0.7) : AppColors.dynamicTextLight,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: AppColors.dynamicPrimary,
                                size: 20,
                              )
                            : null,
                        onTap: () async {
                          try {
                            // 震動回饋
                            await _hapticService.selectionClick();
                            
                            // 先關閉對話框
                            if (Navigator.canPop(context)) {
                              Navigator.of(context).pop();
                            }
                            
                            // 等待對話框關閉完成
                            await Future.delayed(const Duration(milliseconds: 100));
                            
                            if (mounted) {
                              setState(() {
                                _selectedLanguage = languageCode;
                              });
                              
                              // 儲存設定
                              await _saveSettings();
                              
                              // 等待 setState 完成
                              await Future.delayed(const Duration(milliseconds: 50));
                              
                              if (mounted) {
                                _showSuccessMessage('已切換至 $languageName');
                              }
                            }
                          } catch (e) {
                            // 錯誤處理：至少設定語言
                            if (mounted) {
                              setState(() {
                                _selectedLanguage = languageCode;
                              });
                              await _saveSettings();
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        '關閉',
                        style: TextStyle(color: AppColors.dynamicTextLight),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.dynamicCard,
          title: Text(
            '選擇主題',
            style: TextStyle(
              color: AppColors.dynamicTextDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption('晨曦', 'default', const Color(0xFFCFAB8D)),
              _buildThemeOption('海洋', 'ocean', const Color(0xFF7FADCC)),
              _buildThemeOption('森林', 'forest', const Color(0xFF96A78D)),
              _buildThemeOption('夕陽', 'sunset', const Color(0xFFF6A85B)),
              _buildThemeOption('櫻雪', 'lavender', const Color(0xFFE6B7BC)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '關閉',
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
      trailing: isSelected ? Icon(Icons.check, color: AppColors.dynamicPrimary) : null,
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
              _showSuccessMessage('已切換到$name主題');
            }
          }
        } catch (e) {
          // 如果出現錯誤，至少確保主題被切換
          await ThemeManager.instance.setTheme(themeKey);
        }
      },
    );
  }

  void _showFeatureNotAvailable(String featureName) {
    if (_isShowingSnackBar) return; // 防止重複顯示
    
    _isShowingSnackBar = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName功能開發中'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // 使用 Timer 來重置狀態，而不是依賴 .closed
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _isShowingSnackBar = false;
      }
    });
  }

  void _showSuccessMessage(String message) {
    if (_isShowingSnackBar) return; // 防止重複顯示
    
    _isShowingSnackBar = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.dynamicPrimary,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // 使用 Timer 來重置狀態，而不是依賴 .closed
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _isShowingSnackBar = false;
      }
    });
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.dynamicCard,
          title: Text(
            '關於音樂練習應用程式',
            style: TextStyle(
              color: AppColors.dynamicTextDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '版本：1.0.0',
                style: TextStyle(color: AppColors.dynamicTextDark),
              ),
              const SizedBox(height: 8),
              Text(
                '這是一個音樂練習應用程式，提供MIDI播放、錄音練習和音樂庫管理功能。',
                style: TextStyle(color: AppColors.dynamicTextDark),
              ),
              const SizedBox(height: 8),
              Text(
                '開發團隊：Music Practice Team',
                style: TextStyle(color: AppColors.dynamicTextLight),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '確定',
                style: TextStyle(color: AppColors.dynamicPrimary),
              ),
            ),
          ],
        );
      },
    );
  }
}

// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:music_practice_app/utils/theme_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'zh_TW'; // 預設選擇繁體中文
  
  // 音效設定相關變數
  double _masterVolume = 0.8; // 主音量 (0.0 - 1.0)
  double _midiVolume = 0.7; // MIDI 播放音量
  double _recordingVolume = 0.9; // 錄音音量
  bool _soundEnabled = true; // 是否啟用音效
  bool _vibrationEnabled = true; // 是否啟用震動
  
  // 防止重複顯示 SnackBar
  bool _isShowingSnackBar = false;

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 語言設定區塊
            _buildSectionTitle('語言設定'),
            const SizedBox(height: 16),
            _buildLanguageCard(),
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
          icon: Icons.volume_up,
          title: '音效設定',
          subtitle: '主音量：${(_masterVolume * 100).round()}%，音效：${_soundEnabled ? "開啟" : "關閉"}',
          onTap: () => _showSoundSettingsDialog(),
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

  void _showSoundSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                      '音效設定',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dynamicTextDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 主音量控制
                    _buildVolumeSlider(
                      '主音量',
                      _masterVolume,
                      (value) {
                        setDialogState(() {
                          _masterVolume = value;
                        });
                        setState(() {}); // 更新主頁面狀態
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // MIDI 播放音量
                    _buildVolumeSlider(
                      'MIDI 播放音量',
                      _midiVolume,
                      (value) {
                        setDialogState(() {
                          _midiVolume = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 錄音音量
                    _buildVolumeSlider(
                      '錄音監聽音量',
                      _recordingVolume,
                      (value) {
                        setDialogState(() {
                          _recordingVolume = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // 音效開關
                    _buildSwitchTile(
                      '啟用音效',
                      '開啟或關閉應用程式音效',
                      Icons.volume_up,
                      _soundEnabled,
                      (value) {
                        setDialogState(() {
                          _soundEnabled = value;
                        });
                        setState(() {}); // 更新主頁面狀態
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // 震動開關
                    _buildSwitchTile(
                      '啟用震動',
                      '按鈕操作和通知震動回饋',
                      Icons.vibration,
                      _vibrationEnabled,
                      (value) {
                        setDialogState(() {
                          _vibrationEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // 按鈕區域
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            // 重置為預設值
                            setDialogState(() {
                              _masterVolume = 0.8;
                              _midiVolume = 0.7;
                              _recordingVolume = 0.9;
                              _soundEnabled = true;
                              _vibrationEnabled = true;
                            });
                            setState(() {}); // 更新主頁面
                          },
                          child: Text(
                            '重置',
                            style: TextStyle(color: AppColors.dynamicTextLight),
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                '取消',
                                style: TextStyle(color: AppColors.dynamicTextLight),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  if (Navigator.canPop(context)) {
                                    Navigator.of(context).pop();
                                  }
                                  await Future.delayed(const Duration(milliseconds: 100));
                                  if (mounted) {
                                    _showSuccessMessage('音效設定已儲存');
                                  }
                                } catch (e) {
                                  // 錯誤處理
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.dynamicPrimary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('確定'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVolumeSlider(String title, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.dynamicTextDark,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.dynamicPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.dynamicPrimary,
            inactiveTrackColor: AppColors.dynamicPrimary.withValues(alpha: 0.3),
            thumbColor: AppColors.dynamicPrimary,
            overlayColor: AppColors.dynamicPrimary.withValues(alpha: 0.2),
            trackHeight: 4.0,
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
            min: 0.0,
            max: 1.0,
            divisions: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dynamicPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.dynamicPrimary,
            size: 24,
          ),
          const SizedBox(width: 12),
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
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
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
      ),
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
              _buildThemeOption('預設', 'default', const Color(0xFFD8AE7E)),
              _buildThemeOption('海洋', 'ocean', const Color(0xFF4A90E2)),
              _buildThemeOption('森林', 'forest', const Color(0xFF5CB85C)),
              _buildThemeOption('夕陽', 'sunset', const Color(0xFFFF8C42)),
              _buildThemeOption('薰衣草', 'lavender', const Color(0xFF9B59B6)),
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

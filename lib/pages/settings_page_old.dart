// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:music_practice_app/utils/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'zh_TW'; // ?êË®≠?∏Ê?ÁπÅÈ?‰∏≠Ê?
  
  // ?≥Ê?Ë®≠Â??∏È?ËÆäÊï∏
  double _masterVolume = 0.8; // ‰∏ªÈü≥??(0.0 - 1.0)
  double _midiVolume = 0.7; // MIDI ?≠Êîæ?≥È?
  double _recordingVolume = 0.9; // ?ÑÈü≥?≥È?
  bool _soundEnabled = true; // ?ØÂê¶?üÁî®?≥Ê?
  bool _vibrationEnabled = true; // ?ØÂê¶?üÁî®?áÂ?
  
  // ?≤Ê≠¢?çË?È°ØÁ§∫ SnackBar
  bool _isShowingSnackBar = false;

  final Map<String, String> _languages = {
    'zh_TW': 'ÁπÅÈ?‰∏≠Ê?',
    'zh_CN': 'ÁπÅ‰?‰∏≠Ê?',
    'en': 'Traditional Chinese',
    'ja': 'ÁπÅÈ?‰∏≠Ê?',
    'ko': 'ÁπÅÈ?‰∏≠Ê?',
    'es': 'Chino Tradicional',
    'fr': 'Chinois Traditionnel',
    'de': 'Traditionelles Chinesisch',
    'it': 'Cinese Tradizionale',
    'pt': 'Chin√™s Tradicional',
    'ru': '–¢?–∞–¥–∏?–∏–æ–Ω–Ω?–π –∫–∏?–∞–π?–∫–∏–π',
    'ar': 'ÿß?ÿµ???ÿ© ÿß?ÿ™???ÿØ?ÿ©',
  };

  final Map<String, String> _languageDescriptions = {
    'zh_TW': 'ÁπÅÈ?‰∏≠Ê?ÔºàÂè∞???',
    'zh_CN': 'ÁπÅ‰?‰∏≠Ê?Ôºà‰∏≠?ΩÂ§ß?ÜÔ?',
    'en': 'English (Traditional Chinese)',
    'ja': '?•Êú¨Ë™ûÔ?ÁπÅÈ?‰∏≠Ê?Ôº?,
    'ko': '?úÍµ≠?¥Ô?ÁπÅÈ?‰∏≠Ê?Ôº?,
    'es': 'Espa√±ol (Chino Tradicional)',
    'fr': 'Fran√ßais (Chinois Traditionnel)',
    'de': 'Deutsch (Traditionelles Chinesisch)',
    'it': 'Italiano (Cinese Tradizionale)',
    'pt': 'Portugu√™s (Chin√™s Tradicional)',
    'ru': '????–∫–∏–π (–¢?–∞–¥–∏?–∏–æ–Ω–Ω?–π –∫–∏?–∞–π?–∫–∏–π)',
    'ar': 'ÿß?ÿπÿ±ÿ®?ÿ© (ÿß?ÿµ???ÿ© ÿß?ÿ™???ÿØ?ÿ©)',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text( ,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ë™ûË?Ë®≠Â??ÄÂ°?
            _buildSectionTitle('Ë™ûË?Ë®≠Â?'),
            const SizedBox(height: 16),
            _buildLanguageCard(),
            const SizedBox(height: 32),
            
            // ?∂‰?Ë®≠Â??ÄÂ°?
            _buildSectionTitle('?∂‰?Ë®≠Â?'),
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
      style: TextStyle( ,
    );
  }

  Widget _buildLanguageCard() {
    return Card(
      color: AppColors.card,
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon( ,
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
          title: '?öÁü•Ë®≠Â?',
          subtitle: 'ÁÆ°Á??âÁî®Á®ãÂ??öÁü•',
          onTap: () => _showFeatureNotAvailable('?öÁü•Ë®≠Â?'),
        ),
        const SizedBox(height: 12),
        _buildSettingCard(
          icon: Icons.volume_up,
          title: '?≥Ê?Ë®≠Â?',
          subtitle: '‰∏ªÈü≥?èÔ?${(_masterVolume * 100).round()}%ÔºåÈü≥?àÔ?${_soundEnabled ? "?ãÂ?" : "?úÈ?"}',
          onTap: () => _showSoundSettingsDialog(),
        ),
        const SizedBox(height: 12),
        _buildSettingCard(
          icon: Icons.info,
          title: '?úÊñº?âÁî®Á®ãÂ?',
          subtitle: '?àÊú¨Ë≥áË??åÈ??ºÂ???,
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
      color: AppColors.card,
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              SizedBox( ,
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
          backgroundColor: AppColors.card,
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
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedLanguage = languageCode;
                          });
                          Navigator.of(context).pop();
                          
                          // ‰ΩøÁî®?≤È?Ë§áÈ°ØÁ§∫Á??πÊ?
                          _showSuccessMessage('Â∑≤Â??õËá≥ $languageName');
                        },
                      );
                    },
                  ),
                ),
                SizedBox( ,
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
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text( ,
                    ),
                    const SizedBox(height: 20),
                    
                    // ‰∏ªÈü≥?èÊéß??
                    _buildVolumeSlider(
                      '‰∏ªÈü≥??,
                      _masterVolume,
                      (value) {
                        setDialogState(() {
                          _masterVolume = value;
                        });
                        setState(() {}); // ?¥Êñ∞‰∏ªÈ??¢Á???
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // MIDI ?≠Êîæ?≥È?
                    _buildVolumeSlider(
                      'MIDI ?≠Êîæ?≥È?',
                      _midiVolume,
                      (value) {
                        setDialogState(() {
                          _midiVolume = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // ?ÑÈü≥?≥È?
                    _buildVolumeSlider(
                      '?ÑÈü≥??ÅΩ?≥È?',
                      _recordingVolume,
                      (value) {
                        setDialogState(() {
                          _recordingVolume = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // ?≥Ê??ãÈ?
                    _buildSwitchTile(
                      '?üÁî®?≥Ê?',
                      '?ãÂ??ñÈ??âÊ??®Á?ÂºèÈü≥??,
                      Icons.volume_up,
                      _soundEnabled,
                      (value) {
                        setDialogState(() {
                          _soundEnabled = value;
                        });
                        setState(() {}); // ?¥Êñ∞‰∏ªÈ??¢Á???
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // ?áÂ??ãÈ?
                    _buildSwitchTile(
                      '?üÁî®?áÂ?',
                      '?âÈ??ç‰??åÈÄöÁü•?áÂ??ûÈ?',
                      Icons.vibration,
                      _vibrationEnabled,
                      (value) {
                        setDialogState(() {
                          _vibrationEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // ?âÈ??Ä??
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            // ?çÁΩÆ?∫È?Ë®≠ÂÄ?
                            setDialogState(() {
                              _masterVolume = 0.8;
                              _midiVolume = 0.7;
                              _recordingVolume = 0.9;
                              _soundEnabled = true;
                              _vibrationEnabled = true;
                            });
                            setState(() {}); // ?¥Êñ∞‰∏ªÈ???
                          },
                          child: Text( ,
                              child: const Text('Á¢∫Â?'),
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
              style: TextStyle( ,
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
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          SizedBox( ,
        ],
      ),
    );
  }

  void _showFeatureNotAvailable(String featureName) {
    if (_isShowingSnackBar) return; // ?≤Ê≠¢?çË?È°ØÁ§∫
    
    _isShowingSnackBar = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName?üËÉΩ?ãÁôº‰∏?),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    ).closed.then((_) {
      _isShowingSnackBar = false; // ?çÁΩÆ?Ä??
    });
  }

  void _showSuccessMessage(String message) {
    if (_isShowingSnackBar) return; // ?≤Ê≠¢?çË?È°ØÁ§∫
    
    _isShowingSnackBar = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    ).closed.then((_) {
      _isShowingSnackBar = false; // ?çÁΩÆ?Ä??
    });
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text( ,
              ),
            ),
          ],
        );
      },
    );
  }
}


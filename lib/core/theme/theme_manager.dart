import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  static ThemeManager? _instance;
  static ThemeManager get instance => _instance ??= ThemeManager._();
  ThemeManager._();

  String _currentTheme = 'default';
  String get currentTheme => _currentTheme;

  static const Map<String, Map<String, Color>> themes = {
    'default': {
      'primary': Color(0xFFCFAB8D),
      'background': Color(0xFFBBDCE5),
      'card': Color(0xFFF0F8FF),
      'accent': Color(0xFFECEEDF),
      'textDark': Color(0xFF333333),
      'textLight': Color(0xFF888888),
    },
    'ocean': {
      'primary': Color(0xFF7FADCC),
      'background': Color(0xFFE6F3FF),
      'card': Color(0xFFDDE8F4),
      'accent': Color(0xFFF2745E),
      'textDark': Color(0xFF1C3C5B),
      'textLight': Color(0xFF6A8BAA),
    },
    'forest': {
      'primary': Color(0xFF96A78D),
      'background': Color(0xFFF0F0F0),
      'card': Color(0xFFD9E9CF),
      'accent': Color(0xFFB6CEB4),
      'textDark': Color(0xFF2C3E2D),
      'textLight': Color(0xFF96A78D),
    },
    'sunset': {
      'primary': Color(0xFFF6A85B),
      'background': Color(0xFFFFF7ED),
      'card': Color(0xFFFFE3C3),
      'accent': Color(0xFFEFA8A4),
      'textDark': Color(0xFF4A2E05),
      'textLight': Color(0xFFB08A6B),
    },
    'lavender': {
      'primary': Color(0xFFE6B7BC),
      'background': Color(0xFFFAF7F0),
      'card': Color(0xFFFFF8F9),
      'accent': Color(0xFFB6D2CD),
      'textDark': Color(0xFF6A4C52),
      'textLight': Color(0xFFA89A9A),
    },
  };

  Future<void> initTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('selected_theme');
      if (savedTheme != null && themes.containsKey(savedTheme)) {
        _currentTheme = savedTheme;
      } else {
        _currentTheme = 'default';
      }
    } catch (e) {
      debugPrint('⚠️ ThemeManager: 載入主題設定失敗: $e');
      _currentTheme = 'default';
    }
  }

  Future<void> setTheme(String themeName) async {
    if (themes.containsKey(themeName)) {
      _currentTheme = themeName;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_theme', themeName);
        notifyListeners();
      } catch (e) {
        debugPrint('⚠️ ThemeManager: 保存主題設定失敗: $e');
      }
    }
  }

  Map<String, Color> get currentColors =>
      themes[_currentTheme] ?? themes['default']!;
}

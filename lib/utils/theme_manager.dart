// lib/utils/theme_manager.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  static ThemeManager? _instance;
  static ThemeManager get instance => _instance ??= ThemeManager._();
  ThemeManager._();

  String _currentTheme = 'default';
  String get currentTheme => _currentTheme;

  // 主題配置
  static const Map<String, Map<String, Color>> themes = {
    'default': {
      'primary': Color(0xFFCFAB8D),  // 柔和的淺藍
      'background': Color(0xFFBBDCE5), // 接近白色的淺灰綠
      'card': Color(0xFFF0F8FF),     // 淺米色/灰褐色
      'accent': Color(0xFFECEEDF),   // 柔和的土色/淺棕色
      'textDark': Color(0xFF333333),
      'textLight': Color(0xFF888888),
    },
    'ocean': {
      'primary': Color(0xFF7FADCC),    // 中度藍 (按鈕/主要操作)
      'background': Color(0xFFE6F3FF), // ✨ 極淺藍色 (背景藍調強化)
      'card': Color(0xFFDDE8F4),      // ✨ 柔和淺藍 (卡片背景)
      'accent': Color(0xFFF2745E),    // 珊瑚橙 (強調/點綴，對比強烈)
      'textDark': Color(0xFF1C3C5B),   // 深海藍 (主要文字)
      'textLight': Color(0xFF6A8BAA),  // 中度灰藍 (次要文字)
    },
    'forest': {
      'primary': Color(0xFF96A78D),    // 沉穩灰綠色 (按鈕/主要操作)
      'background': Color(0xFFF0F0F0), // 極淺中性灰 (背景)
      'card': Color(0xFFD9E9CF),      // 極淺薄荷綠 (卡片背景)
      'accent': Color(0xFFB6CEB4),    // 柔和淺綠 (強調/點綴)
      'textDark': Color(0xFF2C3E2D),   // 深墨綠色 (主要文字/森林陰影感)
      'textLight': Color(0xFF96A78D),  // 沉穩灰綠色 (次要文字)
    },
    'sunset': {
        'primary': Color(0xFFF6A85B),    // 暖夕橘金
  'background': Color(0xFFFFF7ED), // 柔霧杏白
  'card': Color(0xFFFFE3C3),       // 奶杏橙沙
  'accent': Color(0xFFEFA8A4),     // 夕陽玫瑰粉
  'textDark': Color(0xFF4A2E05),   // 深焦糖棕
  'textLight': Color(0xFFB08A6B),  // 淡暖可可
    },
    'lavender': {
        'primary': Color(0xFFE6B7BC),    // 柔霧粉
  'background': Color(0xFFFAF7F0), // 霧奶米白
  'card': Color(0xFFFFF8F9),       // 微粉暖白
  'accent': Color(0xFFB6D2CD),     // 柔薄荷灰
  'textDark': Color(0xFF6A4C52),   // 深霧玫棕
  'textLight': Color(0xFFA89A9A),  // 灰粉淺棕
    },
  };

  // 初始化主題
  Future<void> initTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentTheme = prefs.getString('selected_theme') ?? 'default';
    } catch (e) {
      print('載入主題設定時發生錯誤: $e');
      _currentTheme = 'default';
    }
  }

  // 更改主題
  Future<void> setTheme(String themeName) async {
    if (themes.containsKey(themeName)) {
      _currentTheme = themeName;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_theme', themeName);
        notifyListeners(); // 通知監聽器主題已更改
      } catch (e) {
        print('保存主題設定時發生錯誤: $e');
      }
    }
  }

  // 獲取當前主題顏色
  Map<String, Color> get currentColors => themes[_currentTheme] ?? themes['default']!;
}
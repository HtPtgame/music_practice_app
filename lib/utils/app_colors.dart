// lib/utils/app_colors.dart
import 'package:flutter/material.dart';
import 'theme_manager.dart';

class AppColors {
  // 靜態常數顏色（供 const 使用）
  static const Color primary = Color(0xFFD8AE7E);
  static const Color background = Color(0xFFFFF2D7);
  static const Color card = Color(0xFFFFE0B5);
  static const Color accent = Color(0xFFF8C794);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF888888);

  // 動態主題顏色（主題切換時使用）
  static Color get dynamicPrimary =>
      ThemeManager.instance.currentColors['primary']!;
  static Color get dynamicBackground =>
      ThemeManager.instance.currentColors['background']!;
  static Color get dynamicCard => ThemeManager.instance.currentColors['card']!;
  static Color get dynamicAccent =>
      ThemeManager.instance.currentColors['accent']!;
  static Color get dynamicTextDark =>
      ThemeManager.instance.currentColors['textDark']!;
  static Color get dynamicTextLight =>
      ThemeManager.instance.currentColors['textLight']!;
}

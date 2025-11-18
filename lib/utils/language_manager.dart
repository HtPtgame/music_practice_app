import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 語言管理器 - 單例模式
class LanguageManager extends ChangeNotifier {
  static final LanguageManager _instance = LanguageManager._internal();
  static LanguageManager get instance => _instance;
  
  LanguageManager._internal();

  Locale _currentLocale = const Locale('zh', 'TW'); // 預設繁體中文
  
  Locale get currentLocale => _currentLocale;

  /// 支援的語言
  static const List<Locale> supportedLocales = [
    Locale('zh', 'TW'), // 繁體中文（台灣）
    Locale('en', 'US'), // 英文（美國）
    Locale('zh', 'CN'), // 簡體中文（中國）
    Locale('ja', 'JP'), // 日文（日本）
  ];

  /// 語言代碼映射
  static const Map<String, Locale> localeMap = {
    'zh_TW': Locale('zh', 'TW'),
    'en_US': Locale('en', 'US'),
    'zh_CN': Locale('zh', 'CN'),
    'ja_JP': Locale('ja', 'JP'),
  };

  /// 語言顯示名稱
  static const Map<String, String> languageNames = {
    'zh_TW': '繁體中文（台灣）',
    'en_US': 'English (US)',
    'zh_CN': '简体中文（中国）',
    'ja_JP': '日本語（日本）',
  };

  /// 初始化語言設定
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('selectedLanguage') ?? 'zh_TW';
    _currentLocale = localeMap[languageCode] ?? const Locale('zh', 'TW');
    notifyListeners();
  }

  /// 切換語言
  Future<void> setLocale(String languageCode) async {
    final locale = localeMap[languageCode];
    if (locale != null && locale != _currentLocale) {
      _currentLocale = locale;
      
      // 保存到本地
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', languageCode);
      
      notifyListeners();
    }
  }

  /// 獲取當前語言代碼
  String get currentLanguageCode {
    return '${_currentLocale.languageCode}_${_currentLocale.countryCode}';
  }

  /// 獲取當前語言顯示名稱
  String get currentLanguageName {
    return languageNames[currentLanguageCode] ?? '繁體中文（台灣）';
  }
}

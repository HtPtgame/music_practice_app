import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageManager extends ChangeNotifier {
  static final LanguageManager _instance = LanguageManager._internal();
  static LanguageManager get instance => _instance;

  LanguageManager._internal();

  Locale _currentLocale = const Locale('zh', 'TW');
  Locale get currentLocale => _currentLocale;

  static const List<Locale> supportedLocales = [
    Locale('zh', 'TW'),
    Locale('en', 'US'),
  ];

  static const Map<String, Locale> localeMap = {
    'zh_TW': Locale('zh', 'TW'),
    'en_US': Locale('en', 'US'),
  };

  static const Map<String, String> languageNames = {
    'zh_TW': '繁體中文（台灣）',
    'en_US': 'English (US)',
  };

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('selectedLanguage') ?? 'zh_TW';
    _currentLocale = localeMap[languageCode] ?? const Locale('zh', 'TW');
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    final locale = localeMap[languageCode];
    if (locale != null && locale != _currentLocale) {
      _currentLocale = locale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', languageCode);
      notifyListeners();
    }
  }

  String get currentLanguageCode =>
      '${_currentLocale.languageCode}_${_currentLocale.countryCode}';

  String get currentLanguageName =>
      languageNames[currentLanguageCode] ?? '繁體中文（台灣）';
}

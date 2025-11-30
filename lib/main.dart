import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:music_practice_app/router/app_router.dart';
import 'package:music_practice_app/core/theme/theme_manager.dart';
import 'package:music_practice_app/core/language/language_manager.dart';
import 'package:music_practice_app/l10n/app_localizations.dart';
import 'package:music_practice_app/core/services/settings_service.dart';
import 'package:music_practice_app/core/services/auth_service_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  if (USE_FIREBASE_AUTH) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // 初始化設定服務
  await SettingsService().initialize();
  
  // 初始化語言管理器
  await LanguageManager.instance.initialize();

  // 初始化認證服務
  await authService.initialize();

  // 鎖定螢幕方向為直立模式，防止旋轉破圖
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _themeLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeTheme();
    // 監聽語言變化
    LanguageManager.instance.addListener(_onLanguageChanged);
  }

  Future<void> _initializeTheme() async {
    // 確保主題管理器已完全初始化
    await ThemeManager.instance.initTheme();
    if (mounted) {
      setState(() {
        _themeLoaded = true;
      });
      // 監聽主題變化
      ThemeManager.instance.addListener(_onThemeChanged);
    }
  }

  @override
  void dispose() {
    ThemeManager.instance.removeListener(_onThemeChanged);
    LanguageManager.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  
  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 顯示載入畫面直到主題完全載入
    if (!_themeLoaded) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final themeColors = ThemeManager.instance.currentColors;

    return MaterialApp.router(
      title: 'Sound Spirit Detective',
      
      // 多語言支援
      locale: LanguageManager.instance.currentLocale,
      supportedLocales: LanguageManager.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeColors['primary']!,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: themeColors['background'],
        cardColor: themeColors['card'],
        appBarTheme: AppBarTheme(
          backgroundColor: themeColors['primary'],
          foregroundColor: Colors.white,
        ),
      ),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}

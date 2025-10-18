import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_practice_app/router/app_router.dart';
import 'package:music_practice_app/utils/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    super.dispose();
  }

  void _onThemeChanged() {
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
      title: 'Music Practice App',
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
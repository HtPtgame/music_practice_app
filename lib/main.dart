import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_practice_app/router/app_router.dart';
import 'package:music_practice_app/utils/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化主題管理器
  await ThemeManager.instance.initTheme();
  
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
  @override
  void initState() {
    super.initState();
    // 監聽主題變化
    ThemeManager.instance.addListener(_onThemeChanged);
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
    final themeColors = ThemeManager.instance.currentColors;
    
    return MaterialApp.router(
      title: 'Music Practice App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeColors['primary']!,
          background: themeColors['background']!,
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
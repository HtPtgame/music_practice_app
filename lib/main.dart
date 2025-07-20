// lib/main.dart
import 'package:flutter/material.dart';
import 'package:music_practice_app/router/app_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';


void main() {
  runApp(const MusicPracticeApp());
}

class MusicPracticeApp extends StatelessWidget {
  const MusicPracticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '音樂練習',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'NotoSansTC', // 建議在 pubspec.yaml 中引入思源黑體
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textDark,
          elevation: 0,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
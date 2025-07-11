// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/pages/analysis_page.dart';
import 'package:music_practice_app/pages/home_page.dart';
import 'package:music_practice_app/pages/playback_page.dart';
import 'package:music_practice_app/pages/practice_page.dart';
import 'package:music_practice_app/pages/upload_page.dart';
import 'package:music_practice_app/widgets/main_shell.dart';

// 建立一個 GlobalKey 給我們的 ShellRoute
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // ShellRoute 會作為底下 routes 的 UI 外殼
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        // 這些頁面會共享 MainShell 的 UI (也就是有底部導覽列)
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/upload',
          builder: (context, state) => const UploadPage(),
        ),
        // 為了展示，先建立兩個空的頁面
        GoRoute(
          path: '/library',
          builder: (context, state) => const Center(child: Text('我的樂庫')),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Center(child: Text('設定')),
        ),
      ],
    ),
    
    // 這些是獨立的頁面，不會顯示底部導覽列
    GoRoute(
      path: '/playback',
      parentNavigatorKey: _rootNavigatorKey, // 確保它能覆蓋整個畫面
      builder: (context, state) => const PlaybackPage(),
    ),
    GoRoute(
      path: '/practice',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PracticePage(),
    ),
    GoRoute(
      path: '/analysis',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AnalysisPage(),
    ),
  ],
);
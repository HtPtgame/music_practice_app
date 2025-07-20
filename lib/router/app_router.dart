// lib/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:music_practice_app/pages/analysis_page.dart';
import 'package:music_practice_app/pages/home_page.dart';
import 'package:music_practice_app/pages/playback_page.dart';
import 'package:music_practice_app/pages/practice_page.dart';
import 'package:music_practice_app/pages/upload_page.dart';
import 'package:music_practice_app/pages/upload_page2.dart'; // 確保導入 UploadPage2
import 'package:music_practice_app/widgets/main_shell.dart'; // 確保導入 MainShell
import 'package:music_practice_app/utils/app_colors.dart'; // 確保導入 AppColors

// 建立一個 GlobalKey 給我們的 ShellRoute
final _rootNavigatorKey = GlobalKey<NavigatorState>();

// 這是 appRouter 的定義，它必須是一個頂層的 final GoRouter 變數
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // ShellRoute 會作為底下 routes 的 UI 外殼
    ShellRoute(
      // ShellRoute 本身仍然會有 build，但裡面的子路由會沒有動畫
      builder: (context, state, child) {
        // 將 state 傳遞給 MainShell，以便其內部可以獲取當前路由路徑
        return MainShell(child: child, state: state);
      },
      routes: [
        // 這些頁面會共享 MainShell 的 UI (也就是有底部導覽列)
        GoRoute(
          path: '/',
          // 使用 NoTransitionPage 實現無動畫切換
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const HomePage(),
          ),
        ),
        GoRoute(
          path: '/upload',
          // 使用 NoTransitionPage 實現無動畫切換
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const UploadPage(),
          ),
        ),
        GoRoute(
          path: '/library',
          // 使用 NoTransitionPage 實現無動畫切換
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const Center(child: Text('我的樂庫')),
          ),
        ),
        GoRoute(
          path: '/settings',
          // 使用 NoTransitionPage 實現無動畫切換
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const Center(child: Text('設定')),
          ),
        ),
      ],
    ),

    // 這些是獨立的頁面，它們的切換也會沒有動畫
    // 且它們不會有底部導航列，因為它們不在 ShellRoute 內部
    
    GoRoute(
      path: '/playback',
      parentNavigatorKey: _rootNavigatorKey, // 確保它能覆蓋整個畫面
      // 使用 NoTransitionPage 實現無動畫切換
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const PlaybackPage(),
      ),
    ),
    GoRoute(
      path: '/practice',
      parentNavigatorKey: _rootNavigatorKey,
      // 使用 NoTransitionPage 實現無動畫切換
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const PracticePage(),
      ),
    ),
    GoRoute(
      path: '/analysis',
      parentNavigatorKey: _rootNavigatorKey,
      // 使用 NoTransitionPage 實現無動畫切換
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const AnalysisPage(),
      ),
    ),
    GoRoute(
      path: '/upload2',
      builder: (context, state) => const UploadPage2(), // 新增這條路由
),
  ],
);

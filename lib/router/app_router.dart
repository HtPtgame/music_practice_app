// lib/router/app_router.dart

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:music_practice_app/pages/analysis_page.dart';
import 'package:music_practice_app/pages/home_page.dart';
import 'package:music_practice_app/pages/playback_page.dart';
import 'package:music_practice_app/pages/practice_page.dart';
import 'package:music_practice_app/pages/upload_page.dart';
import 'package:music_practice_app/pages/upload_page2.dart';
import 'package:music_practice_app/pages/library_page.dart';
import 'package:music_practice_app/pages/settings_page.dart';
import 'package:music_practice_app/pages/note_page.dart';
import 'package:music_practice_app/pages/metronome_page.dart';
import 'package:music_practice_app/widgets/main_shell.dart';

// 建立一個 GlobalKey 給我們的 ShellRoute，用於全螢幕跳轉
final _rootNavigatorKey = GlobalKey<NavigatorState>();

// 這是 appRouter 的定義
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // ShellRoute 會作為底下 routes 的 UI 外殼，讓底部導覽列常駐
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        // 共享底部導覽列的頁面
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomePage(),
          ),
        ),
        GoRoute(
          path: '/upload',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: UploadPage(),
          ),
        ),
        GoRoute(
          path: '/library',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LibraryPage(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsPage(),
          ),
        ),
        GoRoute(
          path: '/metronome',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MetronomePage(),
          ),
        ),
        GoRoute(
          path: '/notes',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NotePage(),
          ),
        ),
      ],
    ),

    // 獨立的全螢幕頁面 (不會顯示底部導覽列)
    GoRoute(
      path: '/playback',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final file = state.extra as PlatformFile?;
        return NoTransitionPage(
          child: PlaybackPage(file: file),
        );
      },
    ),
    GoRoute(
      path: '/practice',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final file = state.extra as PlatformFile?; // 練習頁面也需要檔案資訊
        return NoTransitionPage(
          child: PracticePage(file: file),
        );
      },
    ),
    GoRoute(
      path: '/analysis',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: AnalysisPage(),
      ),
    ),
    GoRoute(
      path: '/upload2',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: UploadPage2(),
      ),
    ),
  ],
);

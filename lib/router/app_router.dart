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
import 'package:music_practice_app/features/pieces/pages/piece_detail_page.dart';
import 'package:music_practice_app/pages/metronome_page.dart';
import 'package:music_practice_app/pages/login_page.dart';
import 'package:music_practice_app/pages/register_page.dart';
import 'package:music_practice_app/pages/profile_page.dart';
import 'package:music_practice_app/pages/animal_collection_page.dart';
import 'package:music_practice_app/models/sheet_annotation.dart';
import 'package:music_practice_app/widgets/main_shell.dart';
import 'package:music_practice_app/features/lessons/pages/lesson_book_page.dart';
import 'package:music_practice_app/features/practice/pages/slow_practice_page.dart';

// 建立一個 GlobalKey 給我們的 ShellRoute，用於全螢幕跳轉
final rootNavigatorKey = GlobalKey<NavigatorState>();

// 這是 appRouter 的定義
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
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
          routes: [
            // 樂曲詳情頁面作為筆記頁面的子路由,保留底部導航欄
            GoRoute(
              path: 'detail/:sheetIndex',
              pageBuilder: (context, state) {
                final extra = state.extra as Map<String, dynamic>;
                return NoTransitionPage(
                  child: MusicSheetDetailPage(
                    sheetName: extra['sheetName'] as String,
                    initialNotes: extra['initialNotes'] as List<String>,
                    initialSheets:
                        extra['initialSheets'] as List<AnnotatedSheet>,
                    onNotesChanged:
                        extra['onNotesChanged'] as Function(List<String>),
                    onSheetsChanged: extra['onSheetsChanged']
                        as Function(List<AnnotatedSheet>),
                  ),
                );
              },
            ),

          ],
        ),
      ],
    ),

    // 獨立的全螢幕頁面 (不會顯示底部導覽列)
    GoRoute(
      path: '/playback',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        final file = state.extra as PlatformFile?;
        return NoTransitionPage(
          child: PlaybackPage(file: file),
        );
      },
    ),
    GoRoute(
      path: '/analysis',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: AnalysisPage(),
      ),
    ),
    GoRoute(
      path: '/upload2',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: UploadPage2(),
      ),
    ),
    // 使用者認證頁面
    GoRoute(
      path: '/login',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: LoginPage(),
      ),
    ),
    GoRoute(
      path: '/register',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: RegisterPage(),
      ),
    ),
    GoRoute(
      path: '/profile',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ProfilePage(),
      ),
    ),
    // 動物圖鑑頁面
    GoRoute(
      path: '/animal-collection',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: AnimalCollectionPage(),
      ),
    ),
    // 練習頁面 (演奏偵錯)
    GoRoute(
      path: '/practice',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        final file = state.extra as PlatformFile?;
        return NoTransitionPage(
          child: PracticePage(file: file),
        );
      },
    ),
    GoRoute(
      path: '/lessons',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: LessonBookPage(),
      ),
    ),
    GoRoute(
      path: '/slow-practice',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: SlowPracticePage(),
      ),
    ),
  ],
);

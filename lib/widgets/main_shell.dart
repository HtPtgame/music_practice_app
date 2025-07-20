// lib/widgets/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart'; // 確保導入 AppColors

class MainShell extends StatefulWidget {
  final Widget child;
  // GoRouterState 參數用於獲取當前路由路徑，以便底部導航列能正確顯示選中狀態
  final GoRouterState state; // <-- 確保這裡有定義 state 參數

  const MainShell({
    super.key,
    required this.child,
    required this.state, // <-- 確保這裡有接收 state 參數
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0; // 用於追蹤當前選中的底部導航項目

  @override
  Widget build(BuildContext context) {
    // 根據當前路由路徑判斷選中的索引
    // 使用 widget.state.fullPath 來獲取當前路徑
    final String location = widget.state.fullPath!;

    // 根據您 app_router.dart 中的 ShellRoute 子路徑來設定 _currentIndex
    if (location == '/') {
      _currentIndex = 0;
    } else if (location == '/upload') {
      _currentIndex = 1;
    } else if (location == '/library') {
      _currentIndex = 2;
    } else if (location == '/settings') {
      _currentIndex = 3;
    }
    // 注意：如果其他頁面（如 /playback, /practice, /analysis）也需要底部導航列，
    // 且它們不是 ShellRoute 的子路由，那麼它們將不會顯示此底部導航列。
    // 在您當前的 app_router.dart 中，/playback, /practice, /analysis 是獨立路由，
    // 因此它們將不會有這個底部導航列。

    return Scaffold(
      body: widget.child, // 顯示當前路由的頁面內容
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // 根據點擊的索引導航到不同的頁面
          if (index == 0) {
            context.go('/'); // 首頁
          } else if (index == 1) {
            context.go('/upload'); // 上傳頁面
          } else if (index == 2) {
            context.go('/library'); // 我的樂庫
          } else if (index == 3) {
            context.go('/settings'); // 設定
          }
          // 更新狀態以反映選中的項目
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.primary, // 選中項目的顏色
        unselectedItemColor: AppColors.textLight, // 未選中項目的顏色
        type: BottomNavigationBarType.fixed, // 確保所有項目都顯示標籤
        backgroundColor: AppColors.card, // 底部導航欄的背景色
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首頁',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: '上傳',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music), // 我的樂庫圖標
            label: '樂庫',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}

// lib/widgets/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: child,
      ),
      bottomNavigationBar: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _calculateSelectedIndex(context),
          onTap: (index) => _onItemTapped(index, context),
          selectedItemColor: AppColors.dynamicPrimary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
            BottomNavigationBarItem(icon: Icon(Icons.library_music), label: '我的樂庫'),
            BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: '筆記'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
          ],
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
  final String location = GoRouterState.of(context).uri.toString();
  if (location.startsWith('/library')) return 1;
  if (location.startsWith('/notes')) return 2;
  if (location.startsWith('/settings')) return 3;
  return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/library');
        break;
      case 2:
        context.go('/notes');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }
}
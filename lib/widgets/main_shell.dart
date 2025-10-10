// lib/widgets/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
          items: [
            BottomNavigationBarItem(
              icon: _buildHomeIcon(context, false),
              activeIcon: _buildHomeIcon(context, true),
              label: '首頁',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.library_music), label: '我的樂庫'),
            BottomNavigationBarItem(
              icon: _buildMetronomeIcon(context, false),
              activeIcon: _buildMetronomeIcon(context, true),
              label: '節拍器',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: '筆記'),
            const BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeIcon(BuildContext context, bool isActive) {
    return SvgPicture.asset(
      'assets/首頁-_1_.svg',
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        isActive ? const Color(0xFF2E7D32) : Colors.grey[600]!,
        BlendMode.srcIn,
      ),
    );
  }

  Widget _buildMetronomeIcon(BuildContext context, bool isActive) {
    return SvgPicture.asset(
      'assets/節拍器.svg',
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        isActive ? const Color(0xFF2E7D32) : Colors.grey[600]!,
        BlendMode.srcIn,
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
  final String location = GoRouterState.of(context).uri.toString();
  if (location.startsWith('/library')) return 1;
  if (location.startsWith('/metronome')) return 2;
  if (location.startsWith('/notes')) return 3;
  if (location.startsWith('/settings')) return 4;
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
        context.go('/metronome');
        break;
      case 3:
        context.go('/notes');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }
}
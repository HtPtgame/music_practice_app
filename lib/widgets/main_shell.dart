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
      backgroundColor: AppColors.dynamicBackground,
      body: SafeArea(
        bottom: false, // 底部不使用 SafeArea,讓我們自己控制
        child: child,
      ),
      bottomNavigationBar: SafeArea(
        child: BottomNavigationBar(
          backgroundColor: AppColors.dynamicCard,
          currentIndex: _calculateSelectedIndex(context),
          onTap: (index) => _onItemTapped(index, context),
          selectedItemColor: AppColors.dynamicPrimary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8, // 增加陰影
          items: [
            BottomNavigationBarItem(
              icon: _buildHomeIcon(context, false),
              activeIcon: _buildHomeIcon(context, true),
              label: '首頁',
            ),
            BottomNavigationBarItem(
              icon: _buildLibraryIcon(context, false),
              activeIcon: _buildLibraryIcon(context, true),
              label: '我的樂庫',
            ),
            BottomNavigationBarItem(
              icon: _buildMetronomeIcon(context, false),
              activeIcon: _buildMetronomeIcon(context, true),
              label: '節拍器',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.note_alt, size: 35),
              label: '筆記',
            ),
            BottomNavigationBarItem(
              icon: _buildSettingsIcon(context, false),
              activeIcon: _buildSettingsIcon(context, true),
              label: '設定',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeIcon(BuildContext context, bool isActive) {
    return SvgPicture.asset(
      'assets/首頁.svg',
      width: 35,
      height: 35,
      colorFilter: ColorFilter.mode(
        isActive ? AppColors.dynamicPrimary : Colors.grey[600]!,
        BlendMode.srcIn,
      ),
    );
  }

  Widget _buildLibraryIcon(BuildContext context, bool isActive) {
    return SvgPicture.asset(
      'assets/音樂庫.svg',
      width: 35,
      height: 35,
      colorFilter: ColorFilter.mode(
        isActive ? AppColors.dynamicPrimary : Colors.grey[600]!,
        BlendMode.srcIn,
      ),
    );
  }

  Widget _buildMetronomeIcon(BuildContext context, bool isActive) {
    return SvgPicture.asset(
      'assets/節拍器.svg',
      width: 35,
      height: 35,
      colorFilter: ColorFilter.mode(
        isActive ? AppColors.dynamicPrimary : Colors.grey[600]!,
        BlendMode.srcIn,
      ),
    );
  }

  Widget _buildSettingsIcon(BuildContext context, bool isActive) {
    return SvgPicture.asset(
      'assets/設定.svg',
      width: 35,
      height: 35,
      colorFilter: ColorFilter.mode(
        isActive ? AppColors.dynamicPrimary : Colors.grey[600]!,
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
// lib/widgets/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_practice_app/l10n/app_localizations.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // 安全獲取翻譯，提供預設值
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      body: SafeArea(
        child: RepaintBoundary(
          child: child,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: RepaintBoundary(
          child: BottomNavigationBar(
            backgroundColor: AppColors.dynamicCard,
            currentIndex: _calculateSelectedIndex(context),
            onTap: (index) => _onItemTapped(index, context),
            selectedItemColor: AppColors.dynamicPrimary,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            elevation: 8,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: [
              BottomNavigationBarItem(
                icon: RepaintBoundary(
                  child: _buildHomeIcon(context, false),
                ),
                activeIcon: RepaintBoundary(
                  child: _buildHomeIcon(context, true),
                ),
                label: l10n?.navHome ?? '首頁',
              ),
              BottomNavigationBarItem(
                icon: RepaintBoundary(
                  child: _buildLibraryIcon(context, false),
                ),
                activeIcon: RepaintBoundary(
                  child: _buildLibraryIcon(context, true),
                ),
                label: l10n?.navLibrary ?? '我的樂庫',
              ),
              BottomNavigationBarItem(
                icon: RepaintBoundary(
                  child: _buildMetronomeIcon(context, false),
                ),
                activeIcon: RepaintBoundary(
                  child: _buildMetronomeIcon(context, true),
                ),
                label: l10n?.metronomeTitle ?? '節拍器',
              ),
              BottomNavigationBarItem(
                icon: RepaintBoundary(
                  child: _buildNotesIcon(context, false),
                ),
                activeIcon: RepaintBoundary(
                  child: _buildNotesIcon(context, true),
                ),
                label: l10n?.navPractice ?? '練習',
              ),
              BottomNavigationBarItem(
                icon: RepaintBoundary(
                  child: _buildSettingsIcon(context, false),
                ),
                activeIcon: RepaintBoundary(
                  child: _buildSettingsIcon(context, true),
                ),
                label: l10n?.navSettings ?? '設定',
              ),
            ],
          ),
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

  Widget _buildNotesIcon(BuildContext context, bool isActive) {
    return SvgPicture.asset(
      'assets/筆記_5.svg',
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
    if (location.startsWith('/notes')) return 3; // 包含 /notes/sheet-annotation
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    // 如果已經在目標頁面，不需要切換
    if (index == currentIndex) return;

    // 直接執行頁面切換（計時器現在可以跨頁面運行）
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

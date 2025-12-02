// lib/widgets/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_practice_app/services/practice_timer_service.dart';
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

  void _onItemTapped(int index, BuildContext context) async {
    // 檢查計時器是否運行中
    final timerService = PracticeTimerService();
    final currentIndex = _calculateSelectedIndex(context);

    // 如果已經在目標頁面，不需要切換
    if (index == currentIndex) return;

    // 如果計時器正在運行，彈出警告
    if (timerService.isTimerRunning) {
      final l10n = AppLocalizations.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 28),
              const SizedBox(width: 8),
              Text(l10n?.timerRunningTitle ?? '計時器運行中'),
            ],
          ),
          content: Text(
            l10n?.timerRunningMessage ?? '練習計時器正在運行中。\n\n切換頁面將自動暫停計時並保存當前記錄。\n\n確定要離開此頁面嗎？',
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n?.timerStayOnPage ?? '留在此頁', style: const TextStyle(fontSize: 16)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n?.timerLeavePage ?? '確定離開', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );

      // 如果用戶取消切換，直接返回
      if (confirmed != true) return;

      // 用戶確認離開，請求暫停並保存
      timerService.requestPauseAndSave();

      // 給一點時間讓計時器組件處理保存
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // 執行頁面切換
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

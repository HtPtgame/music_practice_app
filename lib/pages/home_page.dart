// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veloria/utils/app_colors.dart';
import 'package:veloria/widgets/check_in_card.dart';
import 'package:veloria/widgets/practice_timer_card.dart';
import 'package:veloria/core/services/auth_service_config.dart';
import 'package:veloria/l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // Scaffold 和 AppBar 已被移除，由 MainShell 處理
    // SafeArea 已在 MainShell 層級處理
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        // 從 ListView 改為 Column 以便放置 AppBar
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 我們自己的 AppBar 內容放在這裡
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.music_note,
                          color: AppColors.dynamicPrimary, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(l10n?.appName ?? '音靈偵探',
                              style: TextStyle(
                                  color: AppColors.dynamicTextDark,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 使用者頭像/登入按鈕
                _UserButton(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 主要內容
          const Expanded(
            child: _HomePageContent(),
          ),
        ],
      ),
    );
  }
}

// 使用者按鈕 Widget
class _UserButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        final user = authService.currentUser;

        if (user != null) {
          // 已登入：顯示使用者頭像
          return GestureDetector(
            onTap: () => context.push('/profile'),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.dynamicPrimary,
              child: user.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        user.avatarUrl!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        cacheWidth: 72, // 2x 解析度足夠
                        cacheHeight: 72,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    )
                  : Text(
                      user.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          );
        } else {
          // 未登入：顯示登入按鈕（使用 Tooltip 替換文字）
          return Tooltip(
            message: l10n?.loginTitle ?? '登入',
            child: IconButton(
              icon: Icon(Icons.person_outline,
                  color: AppColors.dynamicTextDark, size: 28),
              onPressed: () => context.push('/login'),
            ),
          );
        }
      },
    );
  }
}

// 將原本的 ListView 內容拆出來方便管理
class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 8),

        // 打卡卡片
        const CheckInCard(),

        const SizedBox(height: 16),

        // 練習計時卡片
        const PracticeTimerCard(),

        const SizedBox(height: 16),

        // 家庭聯絡簿入口
        _LessonBookButton(),

        const SizedBox(height: 12),

        // 慢練 SOP 入口
        _SlowPracticeButton(),

        const SizedBox(height: 100), // 底部間距
      ],
    );
  }
}

class _LessonBookButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: AppColors.dynamicCard,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/lessons'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dynamicPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_book,
                  color: AppColors.dynamicPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.lessonBookTitle ?? '家庭聯絡簿',
                      style: TextStyle(
                        color: AppColors.dynamicTextDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.homePageLessonBookDesc ?? '記錄老師上課內容與練習建議',
                      style: TextStyle(
                        color: AppColors.dynamicTextLight,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.dynamicTextLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlowPracticeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: AppColors.dynamicCard,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/slow-practice'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '🏰',
                  style: TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.slowPracticeTitle ?? '慢練 SOP',
                      style: TextStyle(
                        color: AppColors.dynamicTextDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.homePageSlowPracticeDesc ?? '建立正確動作，神經系統穩定記憶',
                      style: TextStyle(
                        color: AppColors.dynamicTextLight,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.dynamicTextLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

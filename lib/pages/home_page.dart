// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:music_practice_app/widgets/check_in_card.dart';
import 'package:music_practice_app/widgets/practice_timer_card.dart';
import 'package:music_practice_app/services/auth_service_config.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold 和 AppBar 已被移除，由 MainShell 處理
    // SafeArea 已在 MainShell 層級處理
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column( // 從 ListView 改為 Column 以便放置 AppBar
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 我們自己的 AppBar 內容放在這裡
             Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.music_note, color: AppColors.dynamicPrimary, size: 28),
                      const SizedBox(width: 8),
                      Text('音靈偵探', style: TextStyle(color: AppColors.dynamicTextDark, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
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
          // 未登入：顯示登入按鈕
          return IconButton(
            icon: Icon(Icons.person_outline, color: AppColors.dynamicTextDark, size: 28),
            onPressed: () => context.push('/login'),
            tooltip: '登入',
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
        
        const SizedBox(height: 100), // 底部間距
      ],
    );
  }
}

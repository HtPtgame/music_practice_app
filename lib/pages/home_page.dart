// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:music_practice_app/widgets/recent_activity_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold 和 AppBar 已被移除，由 MainShell 提供
    // SafeArea 已在 MainShell 層級處理
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Column( // 將 ListView 改為 Column 以便放置 AppBar
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 我們把 AppBar 的內容手動加到這裡
             Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.music_note, color:  Color.fromARGB(255, 90, 157, 224), size: 28),
                      SizedBox(width: 8),
                      Text('音樂練習', style: TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.person_outline, color: AppColors.textDark, size: 28),
                    onPressed: null, // 在 Shell 中，這個按鈕可能需要透過狀態管理來觸發行為
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // 主要內容
            Expanded(
              child: _HomePageContent(),
            ),
          ],
        ),
      );
  }
}

// 將原本的 ListView 內容抽出來，方便管理
class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => context.go('/library'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('開始練習（上次的曲目）', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 32),
        const Text('最近活動', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        RecentActivityCard(
          title: '小星星',
          subtitle: '上次練習: 2025/07/11 - 95分',
          onPressed: () => context.go('/playback'),
        ),
        const SizedBox(height: 12),
        RecentActivityCard(
          title: '給愛麗絲',
          subtitle: '上次練習: 2025/07/08 - 88分',
          onPressed: () => context.go('/playback'),
        ),
      ],
    );
  }
}
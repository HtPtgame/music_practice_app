// lib/pages/playback_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';

class PlaybackPage extends StatelessWidget {
  const PlaybackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('小星星 - 預覽模式', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                      // 【修正】直接定義帶有透明度的顏色
                      border: Border.all(color: const Color(0x7F6A5AE0)), // AppColors.primary.withOpacity(0.5)
                    ),
                    child: const Center(
                      child: Text('鋼琴捲簾 (Piano Roll) 視覺化區域', style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPlaybackControls(),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/practice'),
                        icon: const Icon(Icons.play_arrow_rounded, size: 28),
                        label: const Text('開始演奏', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(icon: const Icon(Icons.replay_10), iconSize: 32, color: AppColors.textLight, onPressed: () {}),
        IconButton(icon: const Icon(Icons.pause_circle_filled), iconSize: 64, color: AppColors.primary, onPressed: () {}),
        IconButton(icon: const Icon(Icons.forward_10), iconSize: 32, color: AppColors.textLight, onPressed: () {}),
      ],
    );
  }
}
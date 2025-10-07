// lib/pages/upload_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 頁面標題
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.upload, color: AppColors.dynamicPrimary, size: 28),
                const SizedBox(width: 8),
                Text(
                  '上傳音樂檔案',
                  style: TextStyle(
                    color: AppColors.dynamicTextDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildUploadOption(
            context,
            icon: MaterialCommunityIcons.midi_port,
            label: '從本機上傳 MIDI',
            subtitle: '支援 .mid 和 .midi 格式',
            onTap: () => context.go('/upload2'),
          ),
          const SizedBox(height: 16),
          _buildUploadOption(
            context,
            icon: MaterialCommunityIcons.image_multiple_outline,
            label: '從本機上傳樂譜',
            subtitle: '支援圖片格式的樂譜',
            onTap: () => _showFeatureNotAvailable(context),
          ),
        ],
      ),
    );
  }
  
  void _showFeatureNotAvailable(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.dynamicCard,
          title: Text(
            '功能開發中',
            style: TextStyle(
              color: AppColors.dynamicTextDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '此功能正在開發中，敬請期待！',
            style: TextStyle(color: AppColors.dynamicTextDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '確定',
                style: TextStyle(color: AppColors.dynamicPrimary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUploadOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.dynamicCard,
      elevation: 1.5,
      shadowColor: const Color(0x196A5AE0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dynamicPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.dynamicPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dynamicTextDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.dynamicTextLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.dynamicTextLight,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
    

// lib/widgets/recent_activity_card.dart
import 'package:flutter/material.dart';
import 'package:music_practice_app/utils/app_colors.dart';

class RecentActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const RecentActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      elevation: 1.5,
      // 【修正】直接定義帶有透明度的顏色
      shadowColor: const Color(0x196A5AE0), // AppColors.primary.withOpacity(0.1)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textLight)),
            trailing: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                // 【修正】直接定義帶有透明度的顏色
                backgroundColor: const Color(0x196A5AE0), // AppColors.primary.withOpacity(0.1)
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('繼續'),
            ),
          ),
        ),
      ),
    );
  }
}
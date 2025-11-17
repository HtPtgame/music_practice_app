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
      color: AppColors.dynamicCard,
      elevation: 1.5,
      shadowColor: AppColors.dynamicPrimary.withValues(alpha: 0.1),
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
            title: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.dynamicTextDark)),
            subtitle: Text(subtitle,
                style: TextStyle(color: AppColors.dynamicTextLight)),
            trailing: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.dynamicPrimary.withValues(alpha: 0.1),
                foregroundColor: AppColors.dynamicPrimary,
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

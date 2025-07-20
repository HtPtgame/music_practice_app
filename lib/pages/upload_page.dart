    // lib/pages/upload_page.dart
    import 'package:flutter/material.dart';
    import 'package:go_router/go_router.dart';
    import 'package:music_practice_app/utils/app_colors.dart';
    import 'package:flutter_vector_icons/flutter_vector_icons.dart';

    class UploadPage extends StatelessWidget {
      const UploadPage({super.key});

      @override
      Widget build(BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
                  child: Text(
                    '選擇樂譜',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildUploadOption(
                  context,
                  icon: MaterialCommunityIcons.midi_port,
                  label: '從本機上傳 MIDI',
                  // 【修改】點擊此選項時導航到新的 UploadPage2
                  onTap: () => context.go('/upload2'),
                ),
                const SizedBox(height: 16),
                _buildUploadOption(
                  context,
                  icon: MaterialCommunityIcons.image_multiple_outline,
                  label: '從本機上傳五線譜',
                  onTap: () => context.go('/playback'),
                ),
              ],
            ),
          ),
        );
      }

      Widget _buildUploadOption(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
        return Card(
          color: AppColors.card,
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
                  Icon(icon, color: AppColors.primary, size: 32),
                  const SizedBox(width: 20),
                  Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, color: AppColors.textLight, size: 16),
                ],
              ),
            ),
          ),
        );
      }
    }
    
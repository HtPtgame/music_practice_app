// lib/pages/analysis_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(title: const Text('演奏分析報告', style: TextStyle(fontWeight: FontWeight.bold)), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text('本次得分', style: TextStyle(fontSize: 20, color: AppColors.dynamicTextLight)),
                    const SizedBox(height: 8),
                    Text('95', style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: AppColors.dynamicPrimary)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) => Icon(index < 4 ? Icons.star : Icons.star_border, color: Colors.amber, size: 32))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildStatCard('正確率', '95%', Icons.check_circle_outline, Colors.green),
            const SizedBox(height: 12),
            _buildStatCard('音準錯誤', '8 次', Icons.music_off_outlined, Colors.red),
            const SizedBox(height: 12),
            _buildStatCard('節奏錯誤', '3 次', Icons.hourglass_empty_outlined, Colors.orange),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side:  BorderSide(color: AppColors.dynamicPrimary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child:  Text('返回首頁', style: TextStyle(fontSize: 16, color: AppColors.dynamicPrimary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go('/practice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 90, 157, 224),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('再次挑戰', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
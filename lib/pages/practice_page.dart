// lib/pages/practice_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';

class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('小星星 - 演奏中', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
                // 【修正】直接使用現有顏色
                border: Border.all(color: Colors.greenAccent),
              ),
              child: const Center(
                child: Text('即時偵測與互動區域', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Text('加油！', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                 SizedBox(height: 16),
                 Text('請跟隨節拍演奏...', style: TextStyle(fontSize: 18, color: AppColors.textLight)),
              ],
            ),
          ),
           Padding(
             padding: const EdgeInsets.all(24.0),
             child: SizedBox(
              width: double.infinity,
               child: ElevatedButton(
                onPressed: () => context.go('/analysis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('結束演奏', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       ),
             ),
           ),
        ],
      ),
    );
  }
}
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';

class PracticePage extends StatefulWidget {
  final PlatformFile? file;
  const PracticePage({super.key, this.file});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.file?.name ?? '演奏練習', style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) context.pop();
            else context.go('/library');
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.piano, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text('演奏偵測介面', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              '即將在此練習：${widget.file?.name ?? '未指定曲目'}',
              style: const TextStyle(fontSize: 16, color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.go('/analysis'),
              child: const Text('（模擬）完成練習'),
            ),
          ],
        ),
      ),
    );
  }
}

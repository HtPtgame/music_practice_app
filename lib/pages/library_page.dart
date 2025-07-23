// lib/pages/library_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:file_picker/file_picker.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

// 全域MIDI檔案管理類別
class MidiFileManager {
  static List<MidiFileInfo> _midiFiles = [];
  
  static List<MidiFileInfo> get midiFiles => List.unmodifiable(_midiFiles);
  
  static void addMidiFile(PlatformFile file) {
    final midiInfo = MidiFileInfo(
      name: file.name,
      size: file.size,
      uploadTime: DateTime.now(),
      file: file,
    );
    _midiFiles.add(midiInfo);
  }
  
  static void removeMidiFile(int index) {
    if (index >= 0 && index < _midiFiles.length) {
      _midiFiles.removeAt(index);
    }
  }
}

class _LibraryPageState extends State<LibraryPage> {

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
                '我的樂庫',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            if (MidiFileManager.midiFiles.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.library_music_outlined,
                        size: 64,
                        color: AppColors.textLight,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '尚無音樂檔案',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textLight,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '請前往上傳頁面添加MIDI檔案',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: MidiFileManager.midiFiles.length,
                  itemBuilder: (context, index) {
                    final midiFile = MidiFileManager.midiFiles[index];
                    return _buildMidiFileCard(context, midiFile, index);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMidiFileCard(BuildContext context, MidiFileInfo midiFile, int index) {
    return Card(
      color: AppColors.card,
      elevation: 1.5,
      shadowColor: const Color(0x196A5AE0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _playMidiFile(context, midiFile),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(
                Icons.music_note,
                color: AppColors.primary,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      midiFile.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '大小: ${(midiFile.size / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      '上傳時間: ${_formatDate(midiFile.uploadTime)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    color: AppColors.primary,
                    onPressed: () => _playMidiFile(context, midiFile),
                    tooltip: '播放',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: () => _deleteMidiFile(context, index),
                    tooltip: '刪除',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playMidiFile(BuildContext context, MidiFileInfo midiFile) {
    // 導航到播放頁面
    context.go('/playback', extra: midiFile.file);
  }

  void _deleteMidiFile(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text(
            '確認刪除',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '確定要刪除「${MidiFileManager.midiFiles[index].name}」嗎？',
            style: const TextStyle(
              color: AppColors.textDark,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  MidiFileManager.removeMidiFile(index);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('檔案已刪除'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('刪除'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// MIDI檔案資訊類別
class MidiFileInfo {
  final String name;
  final int size;
  final DateTime uploadTime;
  final PlatformFile file;

  MidiFileInfo({
    required this.name,
    required this.size,
    required this.uploadTime,
    required this.file,
  });
}

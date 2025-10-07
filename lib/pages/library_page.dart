// lib/pages/library_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:file_picker/file_picker.dart'; // 確保這個導入也存在

// 全域MIDI檔案管理類別
// 這些類別必須放在這裡 (文件頂層)，才能被其他文件導入和使用
class MidiFileManager {
  static final List<MidiFileInfo> _midiFiles = [];
  
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

// MIDI檔案資訊類別
// 這個類別也必須放在這裡 (文件頂層)
class MidiFileInfo {
  final String name;
  final int size;
  final DateTime uploadTime;
  final PlatformFile file; // 這裡儲存了 PlatformFile 對象

  MidiFileInfo({
    required this.name,
    required this.size,
    required this.uploadTime,
    required this.file,
  });
}


class LibraryPage extends StatefulWidget { // 將 StatelessWidget 改回 StatefulWidget
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {

  // 注意：如果您希望在添加或刪除檔案後立即更新列表，
  // 您需要在 _deleteMidiFile 或其他地方呼叫 setState()。
  // 並且，MidiFileManager 的更改需要通知到所有監聽者。
  // 這裡為了簡化，假設每次進入頁面時會重新構建。

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground, // 使用您定義的背景色
      appBar: AppBar(
        title: const Text(
          '我的樂庫',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.dynamicBackground, // AppBar 背景色與頁面背景色一致
        elevation: 0, // 移除 AppBar 陰影
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ...existing code...
            const SizedBox(height: 16),
            
            if (MidiFileManager.midiFiles.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.library_music_outlined,
                        size: 64,
                        color: AppColors.dynamicTextLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '尚無音樂檔案',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.dynamicTextLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '請前往上傳頁面添加MIDI檔案',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.dynamicTextLight,
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
      // 在這裡添加 FloatingActionButton
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 點擊按鈕後導航到上傳頁面 (upload_page.dart)
          context.go('/upload');
        },
        backgroundColor: AppColors.dynamicPrimary, // 使用您定義的主題色
        foregroundColor: Colors.white, // 加號圖標
        tooltip: '新增樂曲', // 圖標顏色
        child: const Icon(Icons.add), // 長按提示
      ),
    );
  }

  Widget _buildMidiFileCard(BuildContext context, MidiFileInfo midiFile, int index) {
    return Card(
      color: AppColors.dynamicCard,
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
              Icon(
                Icons.music_note,
                color: AppColors.dynamicPrimary,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      midiFile.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dynamicTextDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '大小: ${(midiFile.size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.dynamicTextLight,
                      ),
                    ),
                    Text(
                      '上傳時間: ${_formatDate(midiFile.uploadTime)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.dynamicTextLight,
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
                    color: AppColors.dynamicPrimary,
                    onPressed: () => _playMidiFile(context, midiFile),
                    tooltip: '播放',
                  ),
                  IconButton(
                    icon: const Icon(Icons.school),
                    color: Colors.green,
                    onPressed: () => _goToPractice(context, midiFile),
                    tooltip: '練習',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: () => _deleteMidiFile(context, index),
                    tooltip: '刪除',
                  ),
                  
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _playMidiFile(BuildContext context, MidiFileInfo midiFile) {
    // 導航到播放頁面，並傳遞 PlatformFile 對象
    // 注意：PlaybackPage 需要修改以接收 PlatformFile
    context.go('/playback', extra: midiFile.file);
  }

  void _goToPractice(BuildContext context, MidiFileInfo midiFile) {
    context.go('/practice', extra: midiFile.file);
  }

  void _deleteMidiFile(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.dynamicCard,
          title: Text(
            '確認刪除',
            style: TextStyle(
              color: AppColors.dynamicTextDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '確定要刪除「${MidiFileManager.midiFiles[index].name}」嗎？',
            style: TextStyle(
              color: AppColors.dynamicTextDark,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() { // 呼叫 setState 觸發 UI 更新
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

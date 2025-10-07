import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// 練習要點數據模型
class PracticeNote {
  final int measure;
  final String content;

  PracticeNote({
    required this.measure,
    required this.content,
  });

  @override
  String toString() {
    return '第${measure}小節: $content';
  }
}

class MusicSheetDetailPage extends StatefulWidget {
  final String sheetName;
  final List<String> initialNotes;
  final Function(List<String>) onNotesChanged;

  const MusicSheetDetailPage({
    super.key,
    required this.sheetName,
    required this.initialNotes,
    required this.onNotesChanged,
  });

  @override
  State<MusicSheetDetailPage> createState() => _MusicSheetDetailPageState();
}

class _MusicSheetDetailPageState extends State<MusicSheetDetailPage> {
  late List<PracticeNote> _notes;
  final TextEditingController _measureController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 將舊的字串格式轉換為新的 PracticeNote 格式
    _notes = widget.initialNotes.map((noteString) {
      // 嘗試解析舊格式 "第X小節: 內容"
      final match = RegExp(r'^第(\d+)小節:\s*(.+)$').firstMatch(noteString);
      if (match != null) {
        return PracticeNote(
          measure: int.parse(match.group(1)!),
          content: match.group(2)!,
        );
      } else {
        // 如果不是新格式，預設為第1小節
        return PracticeNote(measure: 1, content: noteString);
      }
    }).toList();
  }

  @override
  void dispose() {
    _measureController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _addNote() {
    _showAddNoteDialog();
  }

  void _showAddNoteDialog() {
    _measureController.clear();
    _contentController.clear();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.dynamicCard,
          title: Text(
            '新增練習要點',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.dynamicTextDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _measureController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '小節數',
                  labelStyle: TextStyle(color: AppColors.dynamicTextDark),
                  hintText: 'Ex: 12',
                  hintStyle: TextStyle(color: AppColors.dynamicTextLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.dynamicPrimary),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '注意事項',
                  labelStyle: TextStyle(color: AppColors.dynamicTextDark),
                  hintText: '記錄需要注意的地方、技巧要點或練習重點...',
                  hintStyle: TextStyle(color: AppColors.dynamicTextLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '取消',
                style: TextStyle(color: AppColors.dynamicTextLight),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final measureText = _measureController.text.trim();
                final contentText = _contentController.text.trim();
                
                if (measureText.isNotEmpty && contentText.isNotEmpty) {
                  final measure = int.tryParse(measureText);
                  if (measure != null && measure > 0) {
                    setState(() {
                      _notes.add(PracticeNote(
                        measure: measure,
                        content: contentText,
                      ));
                      // 按小節數排序
                      _notes.sort((a, b) => a.measure.compareTo(b.measure));
                    });
                    widget.onNotesChanged(_notes.map((note) => note.toString()).toList());
                    Navigator.of(context).pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dynamicPrimary,
              ),
              child: const Text(
                '新增',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteNote(int index) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.dynamicCard,
          title: Text(
            '確認刪除',
            style: TextStyle(color: AppColors.dynamicTextDark),
          ),
          content: Text(
            '確定要刪除這條筆記嗎？',
            style: TextStyle(color: AppColors.dynamicTextDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                '取消',
                style: TextStyle(color: AppColors.dynamicTextLight),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '刪除',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          _notes.removeAt(index);
        });
        widget.onNotesChanged(_notes.map((note) => note.toString()).toList());
      }
    });
  }

  void _editNote(int index) {
    final note = _notes[index];
    _measureController.text = note.measure.toString();
    _contentController.text = note.content;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.dynamicCard,
          title: Text(
            '編輯練習要點',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.dynamicTextDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _measureController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '小節數',
                  labelStyle: TextStyle(color: AppColors.dynamicTextDark),
                  hintText: '例如：16',
                  hintStyle: TextStyle(color: AppColors.dynamicTextLight), 
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.dynamicPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '注意事項',
                  labelStyle: TextStyle(color: AppColors.dynamicTextDark),
                  hintText: '記錄需要注意的地方、技巧要點或練習重點...',
                  hintStyle: TextStyle(color: AppColors.dynamicTextLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.dynamicPrimary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '取消',
                style: TextStyle(color: AppColors.dynamicTextLight),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final measureText = _measureController.text.trim();
                final contentText = _contentController.text.trim();
                
                if (measureText.isNotEmpty && contentText.isNotEmpty) {
                  final measure = int.tryParse(measureText);
                  if (measure != null && measure > 0) {
                    setState(() {
                      _notes[index] = PracticeNote(
                        measure: measure,
                        content: contentText,
                      );
                      // 重新排序
                      _notes.sort((a, b) => a.measure.compareTo(b.measure));
                    });
                    widget.onNotesChanged(_notes.map((note) => note.toString()).toList());
                    Navigator.of(context).pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dynamicPrimary,
              ),
              child: const Text(
                '儲存',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: Text(
          widget.sheetName,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.dynamicTextDark,
          ),
        ),
        backgroundColor: AppColors.dynamicBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.dynamicTextDark),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 新增筆記區域
            Card(
              color: AppColors.dynamicCard,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '點擊下方按鈕新增練習要點',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dynamicTextDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '可以針對特定小節記錄需要注意的地方',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.dynamicTextLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addNote,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          '新增筆記',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dynamicPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 筆記列表
            Expanded(
              child: _notes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.music_note_outlined,
                            size: 80,
                            color: AppColors.dynamicTextLight.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '還沒有任何練習要點',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.dynamicTextLight.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '開始記錄這首曲子的練習重點吧！',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.dynamicTextLight.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: AppColors.dynamicCard,
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.dynamicPrimary.withValues(alpha: 0.1),
                              child: Text(
                                '${_notes[index].measure}',
                                style: TextStyle(
                                  color: AppColors.dynamicPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            title: Text(
                              _notes[index].content,
                              style: TextStyle(
                                color: AppColors.dynamicTextDark,
                                fontSize: 16,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, color: AppColors.dynamicPrimary),
                                  onPressed: () => _editNote(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deleteNote(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
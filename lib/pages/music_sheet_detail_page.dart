import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:music_practice_app/l10n/app_localizations.dart';
import '../utils/app_colors.dart';
import '../models/drawing_data.dart';
import '../widgets/drawing_canvas.dart';

// 練習要點數據模型
class PracticeNote {
  final int measure;
  final String content;
  final DrawingData? drawing;

  PracticeNote({
    required this.measure,
    required this.content,
    this.drawing,
  });

  @override
  String toString() {
    final data = {
      'measure': measure,
      'content': content,
      if (drawing != null && drawing!.isNotEmpty) 'drawing': drawing!.toJson(),
    };
    return jsonEncode(data);
  }

  static PracticeNote fromString(String str) {
    try {
      final data = jsonDecode(str) as Map<String, dynamic>;
      return PracticeNote(
        measure: data['measure'] as int,
        content: data['content'] as String,
        drawing: data.containsKey('drawing')
            ? DrawingData.fromJson(data['drawing'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      // 如果解析失敗，嘗試舊格式 "第X小節: 內容"
      final match = RegExp(r'^第(\d+)小節:\s*(.+)$').firstMatch(str);
      if (match != null) {
        return PracticeNote(
          measure: int.parse(match.group(1)!),
          content: match.group(2)!,
        );
      }
      // 預設格式
      return PracticeNote(measure: 1, content: str);
    }
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
      return PracticeNote.fromString(noteString);
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
    final l10n = AppLocalizations.of(context);
    _measureController.clear();
    _contentController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.dynamicCard,
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              l10n?.sheetDetailAddNote ?? '新增練習要點',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.dynamicTextDark,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _measureController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n?.sheetDetailMeasureNumber ?? '小節數',
                  labelStyle: TextStyle(color: AppColors.dynamicTextDark),
                  hintText: l10n?.sheetDetailMeasureHint ?? 'Ex: 12',
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
                  labelText: l10n?.sheetDetailContent ?? '注意事項',
                  labelStyle: TextStyle(color: AppColors.dynamicTextDark),
                  hintText: l10n?.sheetDetailContentHint ?? '記錄需要注意的地方、技巧要點或練習重點...',
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
                l10n?.sheetDetailCancel ?? '取消',
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
                    widget.onNotesChanged(
                        _notes.map((note) => note.toString()).toList());
                    Navigator.of(context).pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dynamicPrimary,
              ),
              child: Text(
                l10n?.sheetDetailAdd ?? '新增',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteNote(int index) {
    final l10n = AppLocalizations.of(context);
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.dynamicCard,
          title: Text(
            l10n?.sheetDetailConfirmDelete ?? '確認刪除',
            style: TextStyle(color: AppColors.dynamicTextDark),
          ),
          content: Text(
            l10n?.sheetDetailConfirmDeleteMessage ?? '確定要刪除這條筆記嗎？',
            style: TextStyle(color: AppColors.dynamicTextDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n?.sheetDetailCancel ?? '取消',
                style: TextStyle(color: AppColors.dynamicTextLight),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                l10n?.sheetDetailDelete ?? '刪除',
                style: const TextStyle(color: Colors.red),
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

  void _showDrawingDialog(int index) {
    final l10n = AppLocalizations.of(context);
    final note = _notes[index];
    DrawingData drawingData = note.drawing ?? DrawingData();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.brush, color: AppColors.dynamicPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${l10n?.sheetDetailMeasurePrefix ?? '第'} ${note.measure} ${l10n?.sheetDetailMeasureSuffix ?? '小節'} - ${l10n?.sheetDetailDrawing ?? '音樂畫面'}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dynamicTextDark,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: DrawingCanvas(
                    initialDrawing: drawingData,
                    onDrawingChanged: (newDrawing) {
                      drawingData = newDrawing;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n?.sheetDetailCancel ?? '取消',
                        style: TextStyle(color: AppColors.dynamicTextLight),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _notes[index] = PracticeNote(
                            measure: note.measure,
                            content: note.content,
                            drawing:
                                drawingData.isNotEmpty ? drawingData : null,
                          );
                        });
                        widget.onNotesChanged(
                            _notes.map((n) => n.toString()).toList());
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dynamicPrimary,
                      ),
                      child: Text(
                        l10n?.sheetDetailSave ?? '儲存',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editNote(int index) {
    final l10n = AppLocalizations.of(context);
    final note = _notes[index];
    _measureController.text = note.measure.toString();
    _contentController.text = note.content;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.dynamicCard,
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              l10n?.sheetDetailEditNote ?? '編輯練習要點',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.dynamicTextDark,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _measureController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n?.sheetDetailMeasureLabel ?? '小節數',
                  labelStyle: TextStyle(color: AppColors.dynamicTextDark),
                  hintText: l10n?.sheetDetailMeasureExample ?? '例如：16',
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
                  labelText: l10n?.sheetDetailContent ?? '注意事項',
                  labelStyle: TextStyle(color: AppColors.dynamicTextDark),
                  hintText: l10n?.sheetDetailContentHint ?? '記錄需要注意的地方、技巧要點或練習重點...',
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
                l10n?.sheetDetailCancel ?? '取消',
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
                    widget.onNotesChanged(
                        _notes.map((note) => note.toString()).toList());
                    Navigator.of(context).pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dynamicPrimary,
              ),
              child: Text(
                l10n?.sheetDetailSave ?? '儲存',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      // 移除 AppBar，改為全螢幕
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 自訂頂部區域：左上返回鍵 + 標題
              Row(
                children: [
                  // 返回鍵
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppColors.dynamicTextDark,
                      size: 28,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  // 標題
                  Expanded(
                    child: Text(
                      widget.sheetName,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dynamicTextDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 新增筆記區域
              Card(
                color: AppColors.dynamicCard,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n?.sheetDetailClickToAdd ?? '點擊下方按鈕新增練習要點',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dynamicTextDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n?.sheetDetailAddDescription ?? '可以針對特定小節記錄需要注意的地方',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.dynamicTextLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addNote,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              l10n?.sheetDetailAddButton ?? '新增筆記',
                              style: const TextStyle(color: Colors.white),
                            ),
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
                              color: AppColors.dynamicTextLight
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                l10n?.sheetDetailEmpty ?? '還沒有任何練習要點',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.dynamicTextLight
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                l10n?.sheetDetailEmptyHint ?? '開始記錄這首曲子的練習重點吧！',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.dynamicTextLight
                                      .withValues(alpha: 0.5),
                                ),
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
                                backgroundColor: AppColors.dynamicPrimary
                                    .withValues(alpha: 0.1),
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
                              subtitle: _notes[index].drawing?.isNotEmpty ==
                                      true
                                  ? Row(
                                      children: [
                                        Icon(Icons.brush,
                                            size: 14,
                                            color: AppColors.dynamicPrimary),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n?.sheetDetailDrawingIncluded ?? '包含音樂畫面',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.dynamicPrimary,
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.brush_outlined,
                                      color:
                                          _notes[index].drawing?.isNotEmpty ==
                                                  true
                                              ? AppColors.dynamicPrimary
                                              : Colors.grey,
                                    ),
                                    onPressed: () => _showDrawingDialog(index),
                                    tooltip: l10n?.sheetDetailDrawingEdit ?? '編輯音樂畫面',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined,
                                        color: AppColors.dynamicPrimary),
                                    onPressed: () => _editNote(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
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
      ),
    );
  }
}

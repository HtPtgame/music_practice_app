import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../models/sheet_annotation.dart';
import '../widgets/annotatable_image_viewer.dart';
import '../utils/app_colors.dart';

class SheetAnnotationPage extends StatefulWidget {
  const SheetAnnotationPage({super.key});

  @override
  State<SheetAnnotationPage> createState() => _SheetAnnotationPageState();
}

class _SheetAnnotationPageState extends State<SheetAnnotationPage> {
  List<AnnotatedSheet> _sheets = [];
  bool _isLoading = true;
  bool _isEditMode = false;
  Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadSheets();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _selectedIndices.clear();
      }
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  Future<void> _deleteSelectedSheets() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除選中的 ${_selectedIndices.length} 個譜面嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 刪除選中的檔案
      final indicesToDelete = _selectedIndices.toList()
        ..sort((a, b) => b.compareTo(a));
      for (final index in indicesToDelete) {
        final sheet = _sheets[index];
        final file = File(sheet.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        _sheets.removeAt(index);
      }

      await _saveSheets();

      setState(() {
        _selectedIndices.clear();
        _isEditMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已刪除 ${indicesToDelete.length} 個譜面')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刪除失敗: $e')),
        );
      }
    }
  }

  Future<void> _loadSheets() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final sheetsJson = prefs.getStringList('annotated_sheets') ?? [];

    setState(() {
      _sheets = sheetsJson
          .map((json) => AnnotatedSheet.fromJsonString(json))
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _saveSheets() async {
    final prefs = await SharedPreferences.getInstance();
    final sheetsJson = _sheets.map((sheet) => sheet.toJsonString()).toList();
    await prefs.setStringList('annotated_sheets', sheetsJson);
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  Future<void> _pickAndAddSheet() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      // 複製檔案到應用目錄
      final appDir = await getApplicationDocumentsDirectory();
      final sheetsDir = Directory('${appDir.path}/sheets');
      if (!await sheetsDir.exists()) {
        await sheetsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.extension ?? 'pdf';
      final newFileName = 'sheet_$timestamp.$extension';
      final newPath = '${sheetsDir.path}/$newFileName';

      await File(file.path!).copy(newPath);

      // 創建新的標註譜面
      final sheet = AnnotatedSheet(
        sheetId: timestamp.toString(),
        filePath: newPath,
        fileName: file.name,
      );

      setState(() {
        _sheets.insert(0, sheet);
      });

      await _saveSheets();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已匯入譜面: ${file.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('匯入失敗: $e')),
        );
      }
    }
  }

  Future<void> _deleteSheet(AnnotatedSheet sheet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除「${sheet.fileName}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 刪除檔案
      final file = File(sheet.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      setState(() {
        _sheets.removeWhere((s) => s.sheetId == sheet.sheetId);
      });

      await _saveSheets();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已刪除譜面')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刪除失敗: $e')),
        );
      }
    }
  }

  void _openSheet(AnnotatedSheet sheet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SheetViewerPage(
          sheet: sheet,
          onSave: (updatedSheet) async {
            final index = _sheets.indexWhere((s) => s.sheetId == sheet.sheetId);
            if (index != -1) {
              setState(() {
                _sheets[index] = updatedSheet;
              });
              await _saveSheets();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('sheet_annotation_page'),
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: Text(
          _isEditMode ? '選擇要刪除的譜面' : '電子譜',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.dynamicTextDark,
          ),
        ),
        backgroundColor: AppColors.dynamicBackground,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // 不顯示返回鍵
        actions: [
          // 樂曲目錄按鈕 (對應電子譜頁面的電子譜按鈕)
          if (!_isEditMode)
            IconButton(
              onPressed: () => context.go('/notes'),
              icon: const Icon(Icons.library_music),
              tooltip: '樂曲目錄',
              color: AppColors.dynamicPrimary,
            ),
          if (_sheets.isNotEmpty)
            TextButton(
              onPressed: _toggleEditMode,
              child: Text(
                _isEditMode ? '取消' : '編輯',
                style: TextStyle(
                  fontSize: 16,
                  color: _isEditMode ? Colors.red : AppColors.dynamicPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_isEditMode && _selectedIndices.isNotEmpty)
            IconButton(
              onPressed: _deleteSelectedSheets,
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: '刪除選中項',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sheets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '尚無譜面',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '點擊右下角 + 按鈕匯入譜面',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sheets.length,
                  itemBuilder: (context, index) {
                    final sheet = _sheets[index];
                    final isPdf = sheet.filePath.endsWith('.pdf');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (_isEditMode) {
                              _toggleSelection(index);
                            } else {
                              _openSheet(sheet);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // 編輯模式下的選擇框
                                if (_isEditMode) ...[
                                  Checkbox(
                                    value: _selectedIndices.contains(index),
                                    onChanged: (value) =>
                                        _toggleSelection(index),
                                    activeColor: AppColors.dynamicPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                // 檔案預覽縮圖或圖標
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.dynamicPrimary
                                            .withOpacity(0.9),
                                        AppColors.dynamicAccent
                                            .withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.dynamicPrimary
                                          .withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: !isPdf &&
                                            File(sheet.filePath).existsSync()
                                        ? Image.file(
                                            File(sheet.filePath),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(
                                                Icons.image,
                                                color: Colors.white,
                                                size: 36,
                                              );
                                            },
                                          )
                                        : Icon(
                                            isPdf
                                                ? Icons.picture_as_pdf
                                                : Icons.image,
                                            color: Colors.white,
                                            size: 36,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // 檔案資訊
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sheet.fileName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.dynamicTextDark,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.dynamicPrimary
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.bookmark,
                                                  size: 14,
                                                  color:
                                                      AppColors.dynamicPrimary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${sheet.markers.length} 個標記',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors
                                                        .dynamicPrimary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            isPdf
                                                ? Icons.picture_as_pdf
                                                : Icons.image,
                                            size: 14,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isPdf ? 'PDF' : '圖片',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '更新於 ${_formatDateTime(sheet.updatedAt)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 刪除按鈕 (非編輯模式下顯示)
                                if (!_isEditMode)
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red[400],
                                    ),
                                    onPressed: () => _deleteSheet(sheet),
                                    tooltip: '刪除',
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _isEditMode
          ? null
          : FloatingActionButton(
              onPressed: _pickAndAddSheet,
              backgroundColor: AppColors.dynamicPrimary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}

class SheetViewerPage extends StatefulWidget {
  final AnnotatedSheet sheet;
  final Function(AnnotatedSheet) onSave;

  const SheetViewerPage({
    super.key,
    required this.sheet,
    required this.onSave,
  });

  @override
  State<SheetViewerPage> createState() => _SheetViewerPageState();
}

class _SheetViewerPageState extends State<SheetViewerPage> {
  late AnnotatedSheet _currentSheet;

  @override
  void initState() {
    super.initState();
    _currentSheet = widget.sheet;
  }

  void _onMarkersChanged(List<AnnotationMarker> markers) {
    setState(() {
      _currentSheet = _currentSheet.copyWith(
        markers: markers,
        updatedAt: DateTime.now(),
      );
    });
    widget.onSave(_currentSheet);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // 柔和的淺灰色背景
      appBar: AppBar(
        title: Text(
          widget.sheet.fileName,
          style: TextStyle(
            color: AppColors.dynamicTextDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        iconTheme: IconThemeData(color: AppColors.dynamicPrimary),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.dynamicPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bookmark,
                  size: 16,
                  color: AppColors.dynamicPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_currentSheet.markers.length}',
                  style: TextStyle(
                    color: AppColors.dynamicPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: widget.sheet.filePath.endsWith('.pdf')
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PDF 檢視功能開發中',
                    style: TextStyle(
                      color: AppColors.dynamicTextDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '請先使用圖片格式',
                    style: TextStyle(
                      color: AppColors.dynamicTextLight,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : AnnotatableImageViewer(
              sheet: _currentSheet,
              onMarkersChanged: _onMarkersChanged,
            ),
    );
  }
}

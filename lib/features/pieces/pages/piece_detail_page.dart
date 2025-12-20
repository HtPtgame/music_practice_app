import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:music_practice_app/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:music_practice_app/utils/lru_cache.dart';
import 'package:music_practice_app/models/drawing_data.dart';
import 'package:music_practice_app/widgets/drawing_canvas.dart';
import 'package:music_practice_app/models/sheet_annotation.dart';
import 'sheet_viewer_page.dart';

/// 以緩存與逾時保護取得圖片尺寸，避免重複解析造成卡頓
Future<Size?> _resolveImageSizeWithCache(
  File file,
  LruCache<String, Size> cache,
) async {
  if (!file.existsSync()) return null;

  final cacheKey = file.path;
  if (cache.containsKey(cacheKey)) {
    return cache.get(cacheKey);
  }

  try {
    final completer = Completer<Size?>();
    final timer = Timer(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        debugPrint('圖片尺寸解析逾時: ${file.path}');
        completer.complete(null);
      }
    });

    final image = Image.file(
      file,
      cacheWidth: 1024, // 降低解碼尺寸減少主執行緒負載
    ).image;

    image.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener(
            (info, _) {
              if (!completer.isCompleted) {
                final size = Size(
                  info.image.width.toDouble(),
                  info.image.height.toDouble(),
                );
                cache.put(cacheKey, size);
                completer.complete(size);
              }
            },
            onError: (exception, stackTrace) {
              if (!completer.isCompleted) {
                debugPrint('圖片載入錯誤: $exception');
                completer.complete(null);
              }
            },
          ),
        );

    final result = await completer.future;
    timer.cancel();
    return result;
  } catch (e) {
    debugPrint('獲取圖片尺寸失敗: $e');
    return null;
  }
}

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
  final List<AnnotatedSheet> initialSheets;
  final Function(List<String>) onNotesChanged;
  final Function(List<AnnotatedSheet>) onSheetsChanged;

  const MusicSheetDetailPage({
    super.key,
    required this.sheetName,
    required this.initialNotes,
    required this.initialSheets,
    required this.onNotesChanged,
    required this.onSheetsChanged,
  });

  @override
  State<MusicSheetDetailPage> createState() => _MusicSheetDetailPageState();
}

class _MusicSheetDetailPageState extends State<MusicSheetDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<PracticeNote> _notes;
  late List<AnnotatedSheet> _sheets;

  // 電子譜相關狀態
  bool _isSheetEditMode = false;
  final Set<int> _selectedSheetIndices = {};
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  // 練習筆記編輯模式
  bool _isNoteEditMode = false;
  final Set<int> _selectedNoteIndices = {};

  // 圖片尺寸緩存，避免重複解析 (LRU 快取，最多 30 張)
  final LruCache<String, Size> _imageSizeCache = LruCache(maxSize: 30);

  final TextEditingController _measureController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // 更新 AppBar 標題和按鈕
    });

    // 初始化筆記
    _notes = widget.initialNotes.map((noteString) {
      return PracticeNote.fromString(noteString);
    }).toList();

    // 初始化電子譜
    _sheets = List.from(widget.initialSheets);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
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
          content: SingleChildScrollView(
            child: Column(
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
                    hintText: l10n?.sheetDetailContentHint ??
                        '記錄需要注意的地方、技巧要點或練習重點...',
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
          content: SingleChildScrollView(
            child: Column(
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
                    hintText: l10n?.sheetDetailContentHint ??
                        '記錄需要注意的地方、技巧要點或練習重點...',
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
    final isSheetTab = _tabController.index == 0;

    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.dynamicTextDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.sheetName,
          style: TextStyle(
            color: AppColors.dynamicTextDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.dynamicBackground,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.dynamicPrimary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.dynamicPrimary,
          tabs: const [
            Tab(text: '電子譜'),
            Tab(text: '練習筆記'),
          ],
        ),
        actions: [
          if (isSheetTab && _sheets.isNotEmpty)
            TextButton(
              onPressed: _toggleSheetEditMode,
              child: Text(
                _isSheetEditMode
                    ? (l10n?.notePageCancel ?? '取消')
                    : (l10n?.notePageEdit ?? '編輯'),
                style: TextStyle(
                  color:
                      _isSheetEditMode ? Colors.red : AppColors.dynamicPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (isSheetTab &&
              _isSheetEditMode &&
              _selectedSheetIndices.isNotEmpty)
            IconButton(
              onPressed: _deleteSelectedAnnotatedSheets,
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          if (!isSheetTab && _notes.isNotEmpty)
            TextButton(
              onPressed: _toggleNoteEditMode,
              child: Text(
                _isNoteEditMode
                    ? (l10n?.notePageCancel ?? '取消')
                    : (l10n?.notePageEdit ?? '編輯'),
                style: TextStyle(
                  color:
                      _isNoteEditMode ? Colors.red : AppColors.dynamicPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (!isSheetTab &&
              _isNoteEditMode &&
              _selectedNoteIndices.isNotEmpty)
            IconButton(
              onPressed: _deleteSelectedNotes,
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
        ],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSheetsTab(l10n),
            _buildNotesTab(l10n),
          ],
        ),
      ),
      floatingActionButton: (_isSheetEditMode || _isNoteEditMode)
          ? null
          : FloatingActionButton(
              onPressed: isSheetTab ? _pickAndAddSheet : _addNote,
              backgroundColor: AppColors.dynamicPrimary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildNotesTab(AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_notes.isEmpty)
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
                  ],
                ),
              ),
            ),
          if (_notes.isEmpty) const SizedBox(height: 20),
          Expanded(
            child: _notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note_outlined,
                          size: 80,
                          color:
                              AppColors.dynamicTextLight.withValues(alpha: 0.5),
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
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      return _PracticeNoteItem(
                        note: _notes[index],
                        onEdit: () => _editNote(index),
                        onDrawing: () => _showDrawingDialog(index),
                        isEditMode: _isNoteEditMode,
                        isSelected: _selectedNoteIndices.contains(index),
                        onToggleSelection: () => _toggleNoteSelection(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetsTab(AppLocalizations? l10n) {
    if (_sheets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.sheetAnnotationEmpty ?? '尚無電子譜',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.sheetAnnotationEmptyHint ?? '點擊右下角 + 按鈕匯入照片',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // 直接顯示照片的畫廊視圖
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPageIndex = index;
            });
          },
          itemCount: _sheets.length,
          itemBuilder: (context, index) {
            final sheet = _sheets[index];

            return _SheetImageViewer(
              key: ValueKey(sheet.sheetId),
              sheet: sheet,
              isEditMode: _isSheetEditMode,
              isSelected: _selectedSheetIndices.contains(index),
              imageSizeCache: _imageSizeCache,
              onTap: () => _openSheet(sheet),
              onToggleSelection: () => _toggleSheetSelection(index),
            );
          },
        ),
        // 頁碼指示器
        if (_sheets.length > 1)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentPageIndex + 1} / ${_sheets.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- 電子譜相關方法 ---

  Future<void> _pickAndAddSheet() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: true, // 支援多張照片匯入
      );

      if (result == null || result.files.isEmpty) return;

      // 複製檔案到應用目錄
      final appDir = await getApplicationDocumentsDirectory();
      final sheetsDir = Directory('${appDir.path}/sheets');
      if (!await sheetsDir.exists()) {
        await sheetsDir.create(recursive: true);
      }

      int importedCount = 0;
      for (final file in result.files) {
        if (file.path == null) continue;

        final timestamp = DateTime.now().millisecondsSinceEpoch + importedCount;
        final extension = file.extension ?? 'png';
        final newFileName = 'sheet_$timestamp.$extension';
        final newPath = '${sheetsDir.path}/$newFileName';

        await File(file.path!).copy(newPath);

        // 創建新的標註譜面
        final sheet = AnnotatedSheet(
          sheetId: timestamp.toString(),
          filePath: newPath,
          fileName: file.name,
        );

        _sheets.add(sheet);
        importedCount++;
      }

      setState(() {});
      widget.onSheetsChanged(_sheets);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已匯入 $importedCount 張照片')),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${l10n?.sheetAnnotationImportFailed ?? '匯入失敗'}: $e')),
        );
      }
    }
  }

  void _toggleSheetEditMode() {
    setState(() {
      _isSheetEditMode = !_isSheetEditMode;
      if (!_isSheetEditMode) {
        _selectedSheetIndices.clear();
      }
    });
  }

  void _toggleNoteEditMode() {
    setState(() {
      _isNoteEditMode = !_isNoteEditMode;
      if (!_isNoteEditMode) {
        _selectedNoteIndices.clear();
      }
    });
  }

  void _toggleNoteSelection(int index) {
    setState(() {
      if (_selectedNoteIndices.contains(index)) {
        _selectedNoteIndices.remove(index);
      } else {
        _selectedNoteIndices.add(index);
      }
    });
  }

  void _deleteSelectedNotes() {
    setState(() {
      final sortedIndices = _selectedNoteIndices.toList()..sort((a, b) => b.compareTo(a));
      for (final index in sortedIndices) {
        _notes.removeAt(index);
      }
      _selectedNoteIndices.clear();
      _isNoteEditMode = false;
    });
    widget.onNotesChanged(_notes.map((note) => note.toString()).toList());
  }

  void _toggleSheetSelection(int index) {
    setState(() {
      if (_selectedSheetIndices.contains(index)) {
        _selectedSheetIndices.remove(index);
      } else {
        _selectedSheetIndices.add(index);
      }
    });
  }

  Future<void> _deleteSelectedAnnotatedSheets() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.sheetAnnotationConfirmDelete ?? '確認刪除'),
        content: Text(
            '${l10n?.sheetAnnotationConfirmDeleteMultiple ?? '確定要刪除選中的'} ${_selectedSheetIndices.length} ${l10n?.sheetAnnotationDeletedSuffix ?? '個譜面'}？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.sheetAnnotationCancel ?? '取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n?.sheetAnnotationDelete ?? '刪除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 刪除選中的檔案
      final indicesToDelete = _selectedSheetIndices.toList()
        ..sort((a, b) => b.compareTo(a));
      for (final index in indicesToDelete) {
        final sheet = _sheets[index];
        final file = File(sheet.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        _sheets.removeAt(index);
      }

      widget.onSheetsChanged(_sheets);

      setState(() {
        _selectedSheetIndices.clear();
        _isSheetEditMode = false;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${l10n?.sheetAnnotationDeletedMultiple ?? '已刪除'} ${indicesToDelete.length} ${l10n?.sheetAnnotationDeletedSuffix ?? '個譜面'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${l10n?.sheetAnnotationDeleteFailed ?? '刪除失敗'}: $e')),
        );
      }
    }
  }

  void _openSheet(AnnotatedSheet sheet) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => SheetViewerPage(
          sheet: sheet,
          onSave: (updatedSheet) async {
            final index = _sheets.indexWhere((s) => s.sheetId == sheet.sheetId);
            if (index != -1) {
              setState(() {
                _sheets[index] = updatedSheet;
              });
              widget.onSheetsChanged(_sheets);

              // 將有小節數的標記統整到練習筆記
              _syncMarkersToNotes(updatedSheet);
            }
          },
        ),
      ),
    );
  }

  /// 將電子譜標記統整到練習筆記
  void _syncMarkersToNotes(AnnotatedSheet sheet) {
    bool hasNewNotes = false;

    for (final marker in sheet.markers) {
      if (marker.measure != null && marker.note.isNotEmpty) {
        // 檢查是否已經有相同小節+內容的筆記
        final existingIndex = _notes.indexWhere(
          (note) =>
              note.measure == marker.measure && note.content == marker.note,
        );

        if (existingIndex == -1) {
          // 不存在相同的筆記，新增
          _notes.add(PracticeNote(
            measure: marker.measure!,
            content: marker.note,
          ));
          hasNewNotes = true;
        }
      }
    }

    if (hasNewNotes) {
      // 按小節數排序
      _notes.sort((a, b) => a.measure.compareTo(b.measure));

      setState(() {});
      widget.onNotesChanged(_notes.map((note) => note.toString()).toList());
    }
  }
}

/// 優化的圖片查看器 Widget，避免重複構建和圖片解析
class _SheetImageViewer extends StatefulWidget {
  final AnnotatedSheet sheet;
  final bool isEditMode;
  final bool isSelected;
  final LruCache<String, Size> imageSizeCache;
  final VoidCallback onTap;
  final VoidCallback onToggleSelection;

  const _SheetImageViewer({
    super.key,
    required this.sheet,
    required this.isEditMode,
    required this.isSelected,
    required this.imageSizeCache,
    required this.onTap,
    required this.onToggleSelection,
  });

  @override
  State<_SheetImageViewer> createState() => _SheetImageViewerState();
}

class _SheetImageViewerState extends State<_SheetImageViewer>
    with AutomaticKeepAliveClientMixin {
  Size? _imageSize;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final file = File(widget.sheet.filePath);

    if (!file.existsSync()) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    final size = await _resolveImageSizeWithCache(
      file,
      widget.imageSizeCache,
    );
    if (!mounted) return;

    setState(() {
      _imageSize = size;
      _isLoading = false;
      _hasError = size == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必須調用以支持 AutomaticKeepAliveClientMixin

    final file = File(widget.sheet.filePath);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.dynamicPrimary,
                  ),
                )
              : _hasError || !file.existsSync()
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('無法載入圖片',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final containerWidth = constraints.maxWidth;
                        final containerHeight = constraints.maxHeight;

                        double imageDisplayWidth = containerWidth;
                        double imageDisplayHeight = containerHeight;
                        double offsetX = 0;
                        double offsetY = 0;

                        if (_imageSize != null) {
                          final widthRatio = containerWidth / _imageSize!.width;
                          final heightRatio =
                              containerHeight / _imageSize!.height;
                          final scale = widthRatio < heightRatio
                              ? widthRatio
                              : heightRatio;

                          imageDisplayWidth = _imageSize!.width * scale;
                          imageDisplayHeight = _imageSize!.height * scale;

                          offsetX = (containerWidth - imageDisplayWidth) / 2;
                          offsetY = (containerHeight - imageDisplayHeight) / 2;
                        }

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              file,
                              fit: BoxFit.contain,
                              cacheWidth: 1024, // 限制緩存大小以節省記憶體
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image,
                                          size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text('圖片載入失敗',
                                          style: TextStyle(
                                              color: Colors.grey[600])),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // 顯示標記 - 使用 RepaintBoundary 隔離重繪
                            if (_imageSize != null)
                              ...widget.sheet.markers.map((marker) {
                                return Positioned(
                                  left: offsetX +
                                      marker.position.dx * imageDisplayWidth -
                                      10,
                                  top: offsetY +
                                      marker.position.dy * imageDisplayHeight -
                                      10,
                                  child: RepaintBoundary(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: SvgPicture.asset(
                                        marker.iconPath,
                                        fit: BoxFit.contain,
                                        placeholderBuilder: (_) =>
                                            const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            // 編輯模式勾選框
                            if (widget.isEditMode)
                              Positioned(
                                top: 16,
                                right: 16,
                                child: GestureDetector(
                                  onTap: widget.onToggleSelection,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: widget.isSelected
                                          ? AppColors.dynamicPrimary
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: widget.isSelected
                                            ? AppColors.dynamicPrimary
                                            : Colors.grey,
                                        width: 2,
                                      ),
                                    ),
                                    child: widget.isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 18,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

/// 練習要點項目元件 - 支援展開/收起多行顯示
class _PracticeNoteItem extends StatefulWidget {
  final PracticeNote note;
  final VoidCallback onEdit;
  final VoidCallback onDrawing;
  final bool isEditMode;
  final bool isSelected;
  final VoidCallback onToggleSelection;

  const _PracticeNoteItem({
    required this.note,
    required this.onEdit,
    required this.onDrawing,
    required this.isEditMode,
    required this.isSelected,
    required this.onToggleSelection,
  });

  @override
  State<_PracticeNoteItem> createState() => _PracticeNoteItemState();
}

class _PracticeNoteItemState extends State<_PracticeNoteItem> {

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      color: AppColors.dynamicCard,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: widget.isEditMode ? widget.onToggleSelection : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading - 小節數或勾選框
              if (widget.isEditMode)
                GestureDetector(
                  onTap: widget.onToggleSelection,
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? AppColors.dynamicPrimary
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isSelected
                            ? AppColors.dynamicPrimary
                            : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: widget.isSelected
                        ? const Icon(
                            Icons.check,
                            size: 18,
                            color: Colors.white,
                          )
                        : null,
                  ),
                )
              else
                CircleAvatar(
                  backgroundColor: AppColors.dynamicPrimary.withValues(alpha: 0.1),
                  radius: 20,
                  child: Text(
                    '${widget.note.measure}',
                    style: TextStyle(
                      color: AppColors.dynamicPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              
              // Content - 練習內容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.note.content,
                      style: TextStyle(
                        color: AppColors.dynamicTextDark,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    
                    // 畫面指示器
                    if (widget.note.drawing?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.brush, size: 14, color: AppColors.dynamicPrimary),
                            const SizedBox(width: 4),
                            Text(
                              l10n?.sheetDetailDrawingIncluded ?? '包含音樂畫面',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.dynamicPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 操作按鈕 (水平排列在文字下方)
                    if (!widget.isEditMode)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.edit, size: 18),
                                label: Text(l10n?.sheetDetailEditNote ?? '編輯'),
                                onPressed: widget.onEdit,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.dynamicPrimary,
                                  side: BorderSide(color: AppColors.dynamicPrimary),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(
                                  Icons.brush,
                                  size: 18,
                                  color: widget.note.drawing?.isNotEmpty == true
                                      ? AppColors.dynamicPrimary
                                      : Colors.grey,
                                ),
                                label: Text(l10n?.sheetDetailDrawing ?? '畫面'),
                                onPressed: widget.onDrawing,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: widget.note.drawing?.isNotEmpty == true
                                      ? AppColors.dynamicPrimary
                                      : Colors.grey,
                                  side: BorderSide(
                                    color: widget.note.drawing?.isNotEmpty == true
                                        ? AppColors.dynamicPrimary
                                        : Colors.grey,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:music_practice_app/features/pieces/pages/piece_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:music_practice_app/l10n/app_localizations.dart';
import 'package:music_practice_app/models/sheet_annotation.dart';

// 樂譜目錄數據模型
class MusicSheet {
  final String name;
  final List<String> notes;
  final List<AnnotatedSheet> annotatedSheets;
  final DateTime createdAt;

  MusicSheet({
    required this.name,
    required this.notes,
    List<AnnotatedSheet>? annotatedSheets,
    required this.createdAt,
  }) : annotatedSheets = annotatedSheets ?? [];

  // 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'notes': notes,
      'annotatedSheets': annotatedSheets.map((s) => s.toJsonString()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // 從 JSON 創建 MusicSheet
  factory MusicSheet.fromJson(Map<String, dynamic> json) {
    return MusicSheet(
      name: json['name'] as String,
      notes: List<String>.from(json['notes'] as List),
      annotatedSheets: (json['annotatedSheets'] as List<dynamic>?)
              ?.map((e) => AnnotatedSheet.fromJsonString(e as String))
              .toList() ??
          [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }
}

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  // 樂譜目錄數據
  final List<MusicSheet> _musicSheets = [];
  bool _isNoteLoading = true;
  bool _isNoteEditMode = false;
  final Set<int> _selectedNoteIndices = {};

  @override
  void initState() {
    super.initState();
    _loadMusicSheets();
  }

  // --- 樂譜目錄相關方法 ---


  // 載入樂譜目錄
  Future<void> _loadMusicSheets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? musicSheetsJson = prefs.getString('music_sheets');

      if (musicSheetsJson != null && musicSheetsJson.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(musicSheetsJson);
        setState(() {
          _musicSheets.clear();
          _musicSheets.addAll(
            jsonList.map((json) => MusicSheet.fromJson(json)).toList(),
          );
          _isNoteLoading = false;
        });
        print('成功載入 ${_musicSheets.length} 個樂譜目錄');
      } else {
        print('沒有找到已儲存的樂譜目錄');
        setState(() {
          _isNoteLoading = false;
        });
      }
    } catch (e) {
      print('載入樂譜目錄時發生錯誤: $e');
      setState(() {
        _musicSheets.clear();
        _isNoteLoading = false;
      });
    }
  }

  // 儲存樂譜目錄
  Future<void> _saveMusicSheets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(
        _musicSheets.map((sheet) => sheet.toJson()).toList(),
      );
      await prefs.setString('music_sheets', jsonString);
      print('成功儲存 ${_musicSheets.length} 個樂譜目錄');
    } catch (e) {
      print('儲存樂譜目錄時發生錯誤: $e');
    }
  }

  void _showAddMusicSheetDialog() {
    final l10n = AppLocalizations.of(context);
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              l10n?.notePageAddSheet ?? '新增樂譜目錄',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.dynamicTextDark,
              ),
            ),
          ),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: l10n?.notePageSheetName ?? '樂譜名稱',
              labelStyle: TextStyle(color: AppColors.dynamicTextLight),
              hintText: l10n?.notePageSheetNameHint ?? '例如：Beethoven op.53、Mozart K.545',
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l10n?.notePageCancel ?? '取消',
                  style: TextStyle(color: AppColors.dynamicTextLight),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _musicSheets.add(MusicSheet(
                      name: nameController.text,
                      notes: [],
                      createdAt: DateTime.now(),
                    ));
                  });
                  await _saveMusicSheets();
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dynamicPrimary,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l10n?.notePageAdd ?? '新增',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleNoteEditMode() {
    setState(() {
      _isNoteEditMode = !_isNoteEditMode;
      if (!_isNoteEditMode) {
        _selectedNoteIndices.clear();
      }
    });
  }

  void _deleteSelectedNoteSheets() {
    if (_selectedNoteIndices.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(l10n?.notePageConfirmDelete ?? '確認刪除'),
          ),
          content: Text('${l10n?.notePageConfirmDeleteMessage ?? '確定要刪除'} ${_selectedNoteIndices.length} ${l10n?.notePageConfirmDeleteSuffix ?? '個樂譜及其所有筆記嗎?'}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(l10n?.notePageCancel ?? '取消'),
              ),
            ),
            TextButton(
              onPressed: () async {
                // 從大到小排序索引,避免刪除時索引錯亂
                final sortedIndices = _selectedNoteIndices.toList()
                  ..sort((a, b) => b.compareTo(a));
                setState(() {
                  for (final index in sortedIndices) {
                    _musicSheets.removeAt(index);
                  }
                  _selectedNoteIndices.clear();
                  _isNoteEditMode = false;
                });
                await _saveMusicSheets();
                Navigator.of(context).pop();
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l10n?.notePageDelete ?? '刪除',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openMusicSheetDetail(int index) {
    // 使用 rootNavigator: true 完全脫離 ShellRoute，隱藏底部導覽欄
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true, // 全螢幕對話框模式
        builder: (context) => MusicSheetDetailPage(
          sheetName: _musicSheets[index].name,
          initialNotes: _musicSheets[index].notes,
          initialSheets: _musicSheets[index].annotatedSheets,
          onNotesChanged: (updatedNotes) async {
            setState(() {
              _musicSheets[index].notes.clear();
              _musicSheets[index].notes.addAll(updatedNotes);
            });
            await _saveMusicSheets();
          },
          onSheetsChanged: (updatedSheets) async {
            setState(() {
              _musicSheets[index].annotatedSheets.clear();
              _musicSheets[index].annotatedSheets.addAll(updatedSheets);
            });
            await _saveMusicSheets();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasItems = _musicSheets.isNotEmpty;
    final hasSelection = _selectedNoteIndices.isNotEmpty;
    
    return Scaffold(
      key: const ValueKey('note_page'),
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _isNoteEditMode 
              ? (l10n?.notePageSelectToDelete ?? '選擇要刪除的樂譜')
              : (l10n?.notePageTitle ?? '樂譜筆記'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.dynamicTextDark,
            ),
          ),
        ),
        backgroundColor: AppColors.dynamicBackground,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (hasItems)
            TextButton(
              onPressed: _toggleNoteEditMode,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _isNoteEditMode ? (l10n?.notePageCancel ?? '取消') : (l10n?.notePageEdit ?? '編輯'),
                  style: TextStyle(
                    fontSize: 16,
                    color: _isNoteEditMode ? Colors.red : AppColors.dynamicPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_isNoteEditMode && hasSelection)
            IconButton(
              onPressed: _deleteSelectedNoteSheets,
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: l10n?.notePageDeleteSelected ?? '刪除選中項',
            ),
        ],
      ),
      body: SafeArea(
        child: _buildMusicSheetsList(l10n),
      ),
      floatingActionButton: _isNoteEditMode
          ? null
          : FloatingActionButton(
              onPressed: _showAddMusicSheetDialog,
              backgroundColor: AppColors.dynamicPrimary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildMusicSheetsList(AppLocalizations? l10n) {
    // 如果正在載入，顯示加載指示器
    if (_isNoteLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.dynamicPrimary,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _musicSheets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 64,
                    color: AppColors.dynamicTextLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.notePageEmpty ?? '還沒有任何樂譜目錄',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.dynamicTextLight.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.notePageEmptyHint ?? '點擊右下角的 + 按鈕新增樂譜',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.dynamicTextLight.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _musicSheets.length,
              itemBuilder: (context, index) {
                final sheet = _musicSheets[index];
                final isSelected = _selectedNoteIndices.contains(index);

                return Card(
                  color: AppColors.dynamicCard,
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      if (_isNoteEditMode) {
                        setState(() {
                          if (isSelected) {
                            _selectedNoteIndices.remove(index);
                          } else {
                            _selectedNoteIndices.add(index);
                          }
                        });
                      } else {
                        _openMusicSheetDetail(index);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 標題行: 音符符號 + 樂曲名稱
                              Row(
                                children: [
                                  Icon(
                                    Icons.music_note,
                                    color: AppColors.dynamicPrimary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      sheet.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.dynamicTextDark,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 筆記數量
                              Padding(
                                padding: const EdgeInsets.only(left: 32),
                                child: Text(
                                  '${sheet.notes.length} ${l10n?.notePageNotesCount ?? '條筆記'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.dynamicTextLight
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 編輯模式: 顯示勾選框
                        if (_isNoteEditMode)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.dynamicPrimary
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.dynamicPrimary
                                      : AppColors.dynamicTextLight,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}


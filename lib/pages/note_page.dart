import 'package:flutter/material.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';

// 樂譜目錄數據模型
class MusicSheet {
  final String name;
  final List<String> notes;
  final DateTime createdAt;

  MusicSheet({
    required this.name,
    required this.notes,
    required this.createdAt,
  });

  // 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // 從 JSON 創建 MusicSheet
  factory MusicSheet.fromJson(Map<String, dynamic> json) {
    return MusicSheet(
      name: json['name'] as String,
      notes: List<String>.from(json['notes'] as List),
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
  final List<MusicSheet> _musicSheets = [];
  bool _isLoading = true; // 新增載入狀態

  @override
  void initState() {
    super.initState();
    _loadMusicSheets();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 載入樂譜目錄
  Future<void> _loadMusicSheets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? musicSheetsJson = prefs.getString('music_sheets');
      
      if (musicSheetsJson != null && musicSheetsJson.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(musicSheetsJson);
        if (mounted) {
          setState(() {
            _musicSheets.clear();
            _musicSheets.addAll(
              jsonList.map((json) => MusicSheet.fromJson(json)).toList(),
            );
            _isLoading = false; // 載入完成
          });
        }
        print('成功載入 ${_musicSheets.length} 個樂譜目錄');
      } else {
        print('沒有找到已儲存的樂譜目錄');
        if (mounted) {
          setState(() {
            _isLoading = false; // 載入完成(無資料)
          });
        }
      }
    } catch (e) {
      print('載入樂譜目錄時發生錯誤: $e');
      // 如果載入失敗，確保列表是空的
      if (mounted) {
        setState(() {
          _musicSheets.clear();
          _isLoading = false; // 載入完成(失敗)
        });
      }
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
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '新增樂譜目錄',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.dynamicTextDark,
            ),
          ),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: '樂譜名稱',
              labelStyle: TextStyle(color: AppColors.dynamicTextLight),
              hintText: '例如：Beethoven op.53、Mozart K.545',
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
              child: Text(
                '取消',
                style: TextStyle(color: AppColors.dynamicTextLight),
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

  void _deleteMusicSheet(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認刪除'),
          content: Text('確定要刪除「${_musicSheets[index].name}」及其所有筆記嗎？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _musicSheets.removeAt(index);
                });
                await _saveMusicSheets();
                Navigator.of(context).pop();
              },
              child: const Text(
                '刪除',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openMusicSheetDetail(int index) {
    context.go('/notes/detail/$index', extra: {
      'sheetName': _musicSheets[index].name,
      'initialNotes': _musicSheets[index].notes,
      'onNotesChanged': (List<String> updatedNotes) async {
        setState(() {
          _musicSheets[index].notes.clear();
          _musicSheets[index].notes.addAll(updatedNotes);
        });
        await _saveMusicSheets();
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: Text(
          '樂譜目錄',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.dynamicTextDark,
          ),
        ),
        backgroundColor: AppColors.dynamicBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildMusicSheetsTab(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMusicSheetDialog,
        backgroundColor: AppColors.dynamicPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMusicSheetsTab() {
    // 載入中顯示進度指示器
    if (_isLoading) {
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
                    '還沒有任何樂譜目錄',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.dynamicTextLight.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '點擊右下角的 + 按鈕新增樂譜',
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
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.35,
              ),
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _musicSheets.length,
              itemBuilder: (context, index) {
                final sheet = _musicSheets[index];
                return Card(
                  color: AppColors.dynamicCard,
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _openMusicSheetDetail(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                Icons.music_note,
                                color: AppColors.dynamicPrimary,
                                size: 22,
                              ),
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                iconSize: 20,
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deleteMusicSheet(index);
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red, size: 18),
                                        SizedBox(width: 8),
                                        Text('刪除', style: TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    sheet.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.dynamicTextDark,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${sheet.notes.length} 條筆記',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.dynamicTextLight.withValues(alpha: 0.8),
                                  ),
                                ),
                                Text(
                                  '${sheet.createdAt.month}/${sheet.createdAt.day}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.dynamicTextLight.withValues(alpha: 0.6),
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
              },
            ),
    );
  }
}
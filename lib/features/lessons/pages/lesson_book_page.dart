import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:music_practice_app/features/lessons/models/lesson_note.dart';
import 'package:music_practice_app/features/lessons/services/lesson_service.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:music_practice_app/l10n/app_localizations.dart';

/// 獲取分類的本地化名稱
String getCategoryDisplayName(LessonNoteCategory category, AppLocalizations? l10n) {
  switch (category.id) {
    case 'slow_practice':
      return l10n?.lessonBookCategorySlowPractice ?? category.displayName;
    case 'technique':
      return l10n?.lessonBookCategoryTechnique ?? category.displayName;
    case 'tone':
      return l10n?.lessonBookCategoryTone ?? category.displayName;
    case 'other':
      return l10n?.lessonBookCategoryOther ?? category.displayName;
    default:
      return category.displayName;
  }
}

class LessonBookPage extends StatefulWidget {
  const LessonBookPage({super.key});

  @override
  State<LessonBookPage> createState() => _LessonBookPageState();
}

class _LessonBookPageState extends State<LessonBookPage> {
  final LessonService _lessonService = LessonService();
  List<_PieceOption> _pieceOptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _lessonService.loadRecords();
    await _loadPieceOptions();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPieceOptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('music_sheets');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _pieceOptions = jsonList.asMap().entries.map((entry) {
          final json = entry.value as Map<String, dynamic>;
          return _PieceOption(
            id: 'piece_${entry.key}',
            name: json['name'] as String,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('載入樂譜列表失敗: $e');
    }
  }

  void _showAddRecordDialog([LessonRecord? existingRecord]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddLessonRecordSheet(
        existingRecord: existingRecord,
        pieceOptions: _pieceOptions,
        onSave: (record) async {
          if (existingRecord != null) {
            await _lessonService.updateRecord(record);
          } else {
            await _lessonService.addRecord(record);
            // 同步到樂譜筆記
            await _syncToMusicSheets(record);
          }
          if (mounted) setState(() {});
        },
      ),
    );
  }

  Future<void> _syncToMusicSheets(LessonRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('music_sheets');
      if (jsonString == null) return;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final l10n = mounted ? AppLocalizations.of(context) : null;
      
      for (final point in record.points) {
        if (point.relatedPieceId == null) continue;
        
        final pieceIndex = int.tryParse(point.relatedPieceId!.replaceFirst('piece_', ''));
        if (pieceIndex == null || pieceIndex >= jsonList.length) continue;

        final pieceJson = jsonList[pieceIndex] as Map<String, dynamic>;
        final notes = List<String>.from(pieceJson['notes'] as List? ?? []);

        final categoryName = getCategoryDisplayName(point.category, l10n);
        final practiceNote = {
          'measure': _extractMeasure(point.measureRange),
          'content': '[$categoryName] ${point.content}',
        };
        notes.add(jsonEncode(practiceNote));

        pieceJson['notes'] = notes;
        jsonList[pieceIndex] = pieceJson;
      }

      await prefs.setString('music_sheets', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('同步到樂譜筆記失敗: $e');
    }
  }

  int _extractMeasure(String? measureRange) {
    if (measureRange == null) return 1;
    final match = RegExp(r'(\d+)').firstMatch(measureRange);
    return match != null ? int.parse(match.group(1)!) : 1;
  }

  Future<void> _deleteRecord(LessonRecord record) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.lessonBookConfirmDelete ?? '確認刪除'),
        content: Text(l10n?.lessonBookConfirmDeleteMessage ?? '確定要刪除這筆上課紀錄嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? '取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n?.delete ?? '刪除', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _lessonService.deleteRecord(record.id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.lessonBookTitle ?? '家庭聯絡簿'),
        backgroundColor: AppColors.dynamicBackground,
        foregroundColor: AppColors.dynamicTextDark,
        elevation: 0,
      ),
      backgroundColor: AppColors.dynamicBackground,
      body: SafeArea(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: _lessonService,
              builder: (context, _) {
                final records = _lessonService.records;
                if (records.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildRecordsList(records);
              },
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordDialog(),
        backgroundColor: AppColors.dynamicPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: AppColors.dynamicTextLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.lessonBookEmpty ?? '還沒有上課紀錄',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.dynamicTextLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.lessonBookEmptyHint ?? '點擊右下角 + 新增老師上課內容',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.dynamicTextLight.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(List<LessonRecord> records) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _LessonRecordCard(
          record: record,
          dateLabel: _formatDate(record.lessonDate),
          onTap: () => _showAddRecordDialog(record),
          onDelete: () => _deleteRecord(record),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return l10n?.lessonBookToday ?? '今天';
    } else if (dateOnly == yesterday) {
      return l10n?.lessonBookYesterday ?? '昨天';
    } else {
      return '${date.month}/${date.day} (${_weekdayName(date.weekday)})';
    }
  }

  String _weekdayName(int weekday) {
    final l10n = AppLocalizations.of(context);
    final names = l10n?.lessonBookWeekdays ?? ['一', '二', '三', '四', '五', '六', '日'];
    return l10n?.lessonBookWeekdayLabel(weekday) ?? '週${names[weekday - 1]}';
  }
}

class _LessonRecordCard extends StatelessWidget {
  final LessonRecord record;
  final String dateLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _LessonRecordCard({
    required this.record,
    required this.dateLabel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.dynamicCard,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                dateLabel,
                style: TextStyle(
                  color: AppColors.dynamicTextDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              // 顯示重點數量
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.dynamicPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${record.points.length} ${AppLocalizations.of(context)?.lessonBookPointsCount ?? '則'}',
                  style: TextStyle(
                    color: AppColors.dynamicPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.delete_outline, 
                    color: AppColors.dynamicTextLight, size: 20),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PieceOption {
  final String id;
  final String name;
  const _PieceOption({required this.id, required this.name});
}

/// 編輯中的重點（可變動）
class _EditablePoint {
  String id;
  LessonNoteCategory category;
  String content;
  _PieceOption? relatedPiece;
  String measureRange;

  _EditablePoint({
    required this.id,
    required this.category,
    this.content = '',
    this.relatedPiece,
    this.measureRange = '',
  });

  LessonPoint toPoint() {
    return LessonPoint(
      id: id,
      category: category,
      content: content,
      relatedPieceId: relatedPiece?.id,
      relatedPieceName: relatedPiece?.name,
      measureRange: measureRange.isEmpty ? null : measureRange,
    );
  }

  static _EditablePoint fromPoint(LessonPoint point, List<_PieceOption> pieceOptions) {
    return _EditablePoint(
      id: point.id,
      category: point.category,
      content: point.content,
      relatedPiece: point.relatedPieceId != null 
          ? pieceOptions.where((p) => p.id == point.relatedPieceId).firstOrNull
          : null,
      measureRange: point.measureRange ?? '',
    );
  }
}

class _AddLessonRecordSheet extends StatefulWidget {
  final LessonRecord? existingRecord;
  final List<_PieceOption> pieceOptions;
  final Future<void> Function(LessonRecord) onSave;

  const _AddLessonRecordSheet({
    this.existingRecord,
    required this.pieceOptions,
    required this.onSave,
  });

  @override
  State<_AddLessonRecordSheet> createState() => _AddLessonRecordSheetState();
}

class _AddLessonRecordSheetState extends State<_AddLessonRecordSheet> {
  late DateTime _lessonDate;
  late List<_EditablePoint> _points;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final record = widget.existingRecord;
    _lessonDate = record?.lessonDate ?? DateTime.now();
    
    if (record != null && record.points.isNotEmpty) {
      _points = record.points
          .map((p) => _EditablePoint.fromPoint(p, widget.pieceOptions))
          .toList();
    } else {
      // 預設新增一則空白重點
      _points = [
        _EditablePoint(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          category: LessonCategories.slowPractice,
        ),
      ];
    }
  }

  void _addPoint() {
    setState(() {
      _points.add(_EditablePoint(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        category: LessonCategories.slowPractice,
      ));
    });
  }

  void _removePoint(int index) {
    if (_points.length > 1) {
      setState(() {
        _points.removeAt(index);
      });
    }
  }

  Future<void> _save() async {
    // 過濾掉內容為空的重點
    final validPoints = _points.where((p) => p.content.trim().isNotEmpty).toList();
    
    if (validPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請至少輸入一則上課內容')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final record = LessonRecord(
      id: widget.existingRecord?.id ?? 
          DateTime.now().millisecondsSinceEpoch.toString(),
      lessonDate: _lessonDate,
      points: validPoints.map((p) => p.toPoint()).toList(),
      createdAt: widget.existingRecord?.createdAt ?? DateTime.now(),
    );

    await widget.onSave(record);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lessonDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _lessonDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    // ignore: unused_local_variable
    final safeBottom = MediaQuery.of(context).padding.bottom;
    
    return Container(
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: AppColors.dynamicBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // 標題列
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Text(
                    widget.existingRecord == null 
                        ? (l10n?.lessonBookAddRecord ?? '新增上課紀錄')
                        : (l10n?.lessonBookEditRecord ?? '編輯上課紀錄'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dynamicTextDark,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // 日期選擇
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.dynamicPrimary),
                      const SizedBox(width: 12),
                      Text(
                        '${_lessonDate.year}/${_lessonDate.month}/${_lessonDate.day}',
                        style: TextStyle(
                          color: AppColors.dynamicTextDark,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: AppColors.dynamicTextLight),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 重點列表（可捲動）
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset > 0 ? bottomInset : 16),
                itemCount: _points.length + 1, // +1 for the add button
                itemBuilder: (context, index) {
                  if (index < _points.length) {
                    return _PointEditor(
                      point: _points[index],
                      index: index,
                      pieceOptions: widget.pieceOptions,
                      canDelete: _points.length > 1,
                      onChanged: () => setState(() {}),
                      onDelete: () => _removePoint(index),
                    );
                  } else {
                    // 新增重點按鈕放在列表最後，這樣可以捲動到它
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: OutlinedButton.icon(
                        onPressed: _addPoint,
                        icon: const Icon(Icons.add),
                        label: Text(l10n?.lessonBookAddPoint ?? '新增重點'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.dynamicPrimary,
                          side: BorderSide(color: AppColors.dynamicPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          
            // 儲存按鈕（固定在底部）
            Container(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              decoration: BoxDecoration(
                color: AppColors.dynamicBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dynamicPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n?.lessonBookSave ?? '儲存',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 單則重點編輯器
class _PointEditor extends StatelessWidget {
  final _EditablePoint point;
  final int index;
  final List<_PieceOption> pieceOptions;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _PointEditor({
    required this.point,
    required this.index,
    required this.pieceOptions,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dynamicCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dynamicPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題與刪除按鈕
          Row(
            children: [
              Text(
                '${l10n?.lessonBookPointLabel ?? '重點'} ${index + 1}',
                style: TextStyle(
                  color: AppColors.dynamicPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (canDelete)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.close, 
                      color: AppColors.dynamicTextLight, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 類別選擇
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LessonCategories.all.map((cat) {
              final isSelected = point.category == cat;
              final l10n = AppLocalizations.of(context);
              return ChoiceChip(
                label: Text(getCategoryDisplayName(cat, l10n)),
                selected: isSelected,
                onSelected: (_) {
                  point.category = cat;
                  onChanged();
                },
                selectedColor: AppColors.dynamicPrimary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected 
                      ? AppColors.dynamicPrimary 
                      : AppColors.dynamicTextDark,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          
          // 內容輸入
          TextField(
            controller: TextEditingController(text: point.content)
              ..selection = TextSelection.collapsed(offset: point.content.length),
            onChanged: (value) {
              point.content = value;
            },
            maxLines: 2,
            decoration: InputDecoration(
              hintText: l10n?.lessonBookInputHint ?? '輸入上課內容...',
              filled: true,
              fillColor: AppColors.dynamicBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          
          // 樂譜與小節（放在同一行）
          Row(
            children: [
              // 關聯樂譜
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<_PieceOption?>(
                  value: point.relatedPiece,
                  decoration: InputDecoration(
                    hintText: l10n?.lessonBookSheetHint ?? '樂譜',
                    filled: true,
                    fillColor: AppColors.dynamicBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n?.lessonBookNoAssociate ?? '不關聯')),
                    ...pieceOptions.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (value) {
                    point.relatedPiece = value;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // 小節
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: point.measureRange)
                    ..selection = TextSelection.collapsed(offset: point.measureRange.length),
                  onChanged: (value) {
                    point.measureRange = value;
                  },
                  decoration: InputDecoration(
                    hintText: l10n?.lessonBookMeasureHint ?? '小節',
                    filled: true,
                    fillColor: AppColors.dynamicBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

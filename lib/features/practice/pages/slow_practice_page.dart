import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:veloria/utils/app_colors.dart';
import 'package:veloria/features/practice/models/slow_practice_task.dart';
import 'package:veloria/features/practice/services/slow_practice_service.dart';
import 'package:veloria/features/lessons/models/lesson_note.dart';
import 'package:veloria/services/metronome_service.dart';
import 'package:veloria/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// For FontFeature

class SlowPracticePage extends StatefulWidget {
  const SlowPracticePage({super.key});

  @override
  State<SlowPracticePage> createState() => _SlowPracticePageState();
}

class _SlowPracticePageState extends State<SlowPracticePage> {
  final SlowPracticeService _service = SlowPracticeService();
  List<LessonPoint> _slowPracticePoints = [];
  List<_PieceOption> _pieceOptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _service.loadTasks();
    _slowPracticePoints = await _service.getSlowPracticePointsFromLessons();
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

  void _startPracticeFromPoint(LessonPoint point) async {
    final task = await _service.createTaskFromLessonPoint(point);
    if (mounted) {
      setState(() {});
      _openPracticeSession(task);
    }
  }

  void _startPracticeManual(String? pieceId, String? pieceName,
      String measureRange, String? content) async {
    final task = await _service.createTask(
      pieceId: pieceId,
      pieceName: pieceName,
      measureRange: measureRange,
      content: content,
    );
    if (mounted) {
      setState(() {});
      _openPracticeSession(task);
    }
  }

  void _openPracticeSession(SlowPracticeTask task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _SlowPracticeSessionPage(
          task: task,
          onUpdate: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground, // 使用 App 主題背景色
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏰', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l10n?.slowPracticeTitle ?? '慢練魔法屋',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppColors.dynamicTextDark,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.dynamicBackground,
        foregroundColor: AppColors.dynamicTextDark,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_service.tasks.isNotEmpty)
            IconButton(
              onPressed: _showHistorySheet,
              icon: Icon(Icons.history_rounded, color: AppColors.dynamicTextDark),
              tooltip: l10n?.slowPracticeHistory ?? '練習紀錄',
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations? l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        _buildHeroCard(),
        const SizedBox(height: 28),
        // 選擇練習標題
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.dynamicAccent, // 使用 App 主題強調色
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dynamicAccent.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text('✨', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Text(
              l10n?.slowPracticeSelectPoint ?? '選擇要練的重點',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.dynamicTextDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_slowPracticePoints.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Icon(Icons.book_rounded, size: 18, color: AppColors.dynamicTextLight),
                const SizedBox(width: 6),
                Text(
                  l10n?.lessonBookFromLessonBook ?? '來自家庭聯絡簿',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.dynamicTextLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ..._slowPracticePoints.map((point) => _buildLessonPointCard(point)),
          const SizedBox(height: 24),
        ],
        _buildManualInputCard(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeroCard() {
    final stepColors = [
      const Color(0xFFFF8A80), // 鮮豔紅
      const Color(0xFF4FC3F7), // 鮮豔藍
      const Color(0xFF66BB6A), // 鮮豔綠
    ];
    
    final stepIcons = ['🎯', '🕵️', '🏆'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.dynamicCard, // 使用卡片背景色，不再是漸層
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.dynamicAccent, width: 2), // 加個邊框像佈告欄
        boxShadow: [
          BoxShadow(
            color: AppColors.dynamicPrimary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 標題區域
                Row(
                  children: [
                    // 烏龜圖示
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.dynamicAccent, width: 2),
                      ),
                      child: const Text('🐢', style: TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.slowPracticeTip ?? '慢練小秘訣',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.dynamicTextDark,
                                ),
                              ),
                              Text(
                                l10n?.slowFollowSteps ?? '跟著步驟一起練習吧！',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.dynamicTextLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    // 詳細說明按鈕 (改成小圖示)
                    IconButton(
                      onPressed: _showFullSopDialog,
                      icon: Icon(Icons.info_outline_rounded, color: AppColors.dynamicPrimary),
                      tooltip: '查看詳細說明',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 三個步驟的可愛卡片
                Builder(
                  builder: (innerContext) {
                    final l10n = AppLocalizations.of(innerContext);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < 3; i++) ...[
                          if (i > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.dynamicPrimary.withValues(alpha: 0.6),
                                size: 24,
                              ),
                            ),
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: stepColors[i].withValues(alpha: 0.3), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: stepColors[i].withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(stepIcons[i], style: const TextStyle(fontSize: 24)),
                                ),
                                const SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    i == 0 ? (l10n?.slowPracticeStep1Title ?? '設定目標') : (i == 1 ? (l10n?.slowPracticeStep2Title ?? '慢練偵探') : (l10n?.slowPracticeStep3Title ?? '最終挑戰')),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.dynamicTextDark,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonPointCard(LessonPoint point) {
    // 隨機選擇一個可愛的音樂相關圖示
    final icons = ['🎹', '🎻', '🎺', '🎸', '🥁', '🎷', '🎼', '🎵'];
    final iconIndex = (point.hashCode) % icons.length;
    final icon = icons[iconIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.dynamicCard.withValues(alpha: 0.3), // 淺色卡片背景
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.dynamicCard, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.dynamicPrimary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startPracticeFromPoint(point),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 可愛的鋼琴圖示
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.dynamicCard, AppColors.dynamicAccent],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dynamicAccent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 30)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (point.relatedPieceName != null)
                        Text(
                          point.relatedPieceName!,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: AppColors.dynamicTextDark,
                          ),
                        ),
                      const SizedBox(height: 6),
                      if (point.measureRange != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context);
                              return Text(
                                l10n?.slowPracticeMeasure.replaceAll(
                                        '{range}', point.measureRange!) ??
                                    '第 ${point.measureRange} 小節',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.dynamicPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                      if (point.content.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            point.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.dynamicTextLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // 開始按鈕
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.dynamicPrimary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.dynamicPrimary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        l10n?.slowPracticeStart ?? '開始',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.dynamicAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.dynamicAccent.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showManualInputDialog,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 可愛的鉛筆圖示
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.dynamicCard, AppColors.dynamicAccent],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dynamicAccent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('✏️', style: TextStyle(fontSize: 30)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.slowPracticeCustomRange ?? '自己選要練哪裡',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: AppColors.dynamicTextDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n?.slowPracticeCustomRangeHint ?? '輸入小節範圍開始練習！',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.dynamicPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.dynamicPrimary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showManualInputDialog() {
    _PieceOption? selectedPiece;
    final measureController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final l10n = AppLocalizations.of(context);
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          final screenHeight = MediaQuery.of(context).size.height;
          final maxHeight = screenHeight * 0.85; // 最大高度為螢幕的 85%

          return Container(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
            ),
            decoration: BoxDecoration(
              color: AppColors.dynamicBackground,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 標題欄（固定）
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                    child: Row(
                      children: [
                        Text(
                          l10n?.slowPracticeCustomRangeTitle ?? '自訂練習範圍',
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
                  const SizedBox(height: 16),
                  // 可滾動內容
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n?.slowPracticeSheetOptional ?? '樂譜（可選）',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.dynamicTextDark,
                              )),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<_PieceOption?>(
                            initialValue: selectedPiece,
                            decoration: InputDecoration(
                              hintText: l10n?.slowPracticeSelectSheet ?? '選擇樂譜',
                              filled: true,
                              fillColor: AppColors.dynamicCard,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                      l10n?.slowPracticeNoSelect ?? '不選擇')),
                              ..._pieceOptions.map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p.name),
                                  )),
                            ],
                            onChanged: (value) =>
                                setSheetState(() => selectedPiece = value),
                          ),
                          const SizedBox(height: 16),
                          Text(l10n?.slowPracticeMeasureRequired ?? '練習小節 *',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.dynamicTextDark,
                              )),
                          const SizedBox(height: 8),
                          TextField(
                            controller: measureController,
                            decoration: InputDecoration(
                              hintText: l10n?.slowPracticeMeasureExample ??
                                  '例如：12-16',
                              filled: true,
                              fillColor: AppColors.dynamicCard,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            autofocus: true,
                          ),
                          const SizedBox(height: 16),
                          Text(l10n?.slowPracticeNote ?? '備註',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.dynamicTextDark,
                              )),
                          const SizedBox(height: 8),
                          TextField(
                            controller: contentController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText:
                                  l10n?.slowPracticeNoteHint ?? '需要注意的地方...',
                              filled: true,
                              fillColor: AppColors.dynamicCard,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (measureController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            l10n?.slowPracticePleaseInputMeasure ??
                                                '請輸入練習小節')),
                                  );
                                  return;
                                }
                                Navigator.pop(context);
                                _startPracticeManual(
                                  selectedPiece?.id,
                                  selectedPiece?.name,
                                  measureController.text.trim(),
                                  contentController.text.trim().isEmpty
                                      ? null
                                      : contentController.text.trim(),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.dynamicPrimary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                  l10n?.slowPracticeStartPractice ?? '開始練習',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
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

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: AppColors.dynamicBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      l10n?.slowPracticeHistory ?? '練習紀錄',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dynamicTextDark,
                      ),
                    ),
                    const Spacer(),
                    // 清除按鈕
                    if (_service.tasks.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _confirmClearAllHistory(context),
                        icon: Icon(
                          Icons.delete_sweep_rounded,
                          size: 18,
                          color: Colors.red.shade400,
                        ),
                        label: Text(
                          l10n?.slowPracticeClearAll ?? '清除全部',
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (_service.inProgressTasks.isNotEmpty) ...[
                      _buildHistorySection(
                          l10n?.slowPracticeInProgress ?? '🎹 進行中',
                          _service.inProgressTasks),
                      const SizedBox(height: 16),
                    ],
                    if (_service.completedTasks.isNotEmpty) ...[
                      _buildHistorySection(
                          l10n?.slowPracticeCompleted ?? '✅ 已完成',
                          _service.completedTasks),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 確認清除所有練習記錄
  void _confirmClearAllHistory(BuildContext sheetContext) {
    showDialog(
      context: sheetContext,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.orange.shade400),
              const SizedBox(width: 8),
              const Text('確認清除'),
            ],
          ),
          content: const Text(
            '確定要清除所有練習紀錄嗎？\n此操作無法復原。',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                '取消',
                style: TextStyle(color: AppColors.dynamicTextLight),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // 關閉對話框
                Navigator.pop(sheetContext);  // 關閉 bottom sheet
                await _service.clearAllTasks();
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('已清除所有練習紀錄'),
                        ],
                      ),
                      backgroundColor: Colors.green.shade400,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('清除'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistorySection(String title, List<SlowPracticeTask> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: AppColors.dynamicTextDark,
            ),
          ),
        ),
        ...tasks.map((task) {
          return Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              final dateToShow = task.completedAt ?? task.createdAt;
              final dateStr = '${dateToShow.year}/${dateToShow.month}/${dateToShow.day}';
              final isCompleted = task.status == SlowPracticeStatus.completed;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.dynamicPrimary.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _openPracticeSession(task);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            // 左側色條
                            Container(
                              width: 6,
                              color: isCompleted ? const Color(0xFF66BB6A) : const Color(0xFF42A5F5),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            task.pieceName ?? (l10n?.slowPracticePractice ?? '練習'),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppColors.dynamicTextDark,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.dynamicBackground,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            dateStr,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.dynamicTextLight,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.music_note_rounded, size: 14, color: AppColors.dynamicPrimary),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n?.slowPracticeMeasure.replaceAll('{range}', task.measureRange ?? '?') ??
                                          '第 ${task.measureRange ?? "?"} 小節',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.dynamicTextLight,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${(task.overallProgress * 100).toInt()}%',
                                          style: TextStyle(
                                            color: isCompleted ? const Color(0xFF66BB6A) : const Color(0xFF42A5F5),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  void _showFullSopDialog() {
    final l10n = AppLocalizations.of(context);
    
    final steps = [
      {
        'icon': '🎯', 
        'title': '1. 設定 & 拆解',
        'desc': '想一想自己現在要練什麼，設定小目標',
        'color': const Color(0xFFFF8A80),
      },
      {
        'icon': '🕵️',
        'title': '2. 慢練小偵探',
        'desc': '每次練習時，心中自己檢查一下：\n• 有沒有彈錯音？\n• 有用對指法嗎？\n• 耳朵有沒有在聽節拍器？\n\n不要讓自己養成錯誤的壞習慣，讓自己全神貫注！',
        'color': const Color(0xFF4FC3F7),
      },
      {
        'icon': '🏆',
        'title': '3. 最終挑戰',
        'desc': '到了最後一步不要鬆懈，繼續保持！',
        'color': const Color(0xFF66BB6A),
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.all(24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.all(24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.dynamicPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('✨', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                l10n?.slowPracticeSopTitle ?? '慢練小秘訣',
                style: TextStyle(
                  color: AppColors.dynamicTextDark, 
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              for (int i = 0; i < steps.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Icon(Icons.arrow_downward_rounded, 
                      color: AppColors.dynamicPrimary.withValues(alpha: 0.3), 
                      size: 28
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (steps[i]['color'] as Color).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (steps[i]['color'] as Color).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            steps[i]['icon'] as String,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              steps[i]['title'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: AppColors.dynamicTextDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        steps[i]['desc'] as String,
                        style: TextStyle(
                          color: AppColors.dynamicTextDark,
                          fontSize: 15,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.dynamicAccent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.dynamicAccent.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('💪', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '練習從來不輕鬆，但只要每天堅持，就會變得很厲害！',
                        style: TextStyle(
                          color: AppColors.dynamicTextDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        actions: [
          Center(
            child: SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dynamicPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n?.slowPracticeUnderstand ?? '我知道了！', 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PieceOption {
  final String id;
  final String name;
  const _PieceOption({required this.id, required this.name});
}

// ==================== 慢練練習頁面（新版 5 步驟） ====================

class _SlowPracticeSessionPage extends StatefulWidget {
  final SlowPracticeTask task;
  final VoidCallback onUpdate;

  const _SlowPracticeSessionPage({
    required this.task,
    required this.onUpdate,
  });

  @override
  State<_SlowPracticeSessionPage> createState() =>
      _SlowPracticeSessionPageState();
}

class _SlowPracticeSessionPageState extends State<_SlowPracticeSessionPage>
    with SingleTickerProviderStateMixin {
  final SlowPracticeService _service = SlowPracticeService();
  final MetronomeService _metronomeService = MetronomeService();
  late SlowPracticeTask _task;
  int _currentStepIndex = 0;

  // Animation Controller for Step 3 buttons
  late AnimationController _buttonShakeController;

  // Metronome State
  bool _metronomeEnabled = false;
  bool _metronomeInitialized = false;
  bool _isDisposed = false; // 追蹤 dispose 狀態
  final ValueNotifier<bool> _beatFlashNotifier = ValueNotifier<bool>(false);

  // Step 1 State
  final TextEditingController _bpmController = TextEditingController();

  // Step 2 State - 練習選項清單 (保留供未來擴展)
  // ignore: unused_field
  final List<String> _checklistOptions = [
    '左手單獨',
    '右手單獨',
    '節奏拆解',
    '只彈重拍',
    '唱譜',
    '不踩踏板'
  ];

  // Step 2 State - 動態速度級距生成
  List<int> _getSpeedSteps() {
    // 從初始速度到 100% 的級距,每次增加 5%
    final initial = _task.initialSpeedPercent;
    final steps = <int>[];

    for (int speed = initial; speed <= 100; speed += 5) {
      steps.add(speed);
    }

    // 確保最後一個級距是 100
    if (steps.isEmpty || steps.last != 100) {
      steps.add(100);
    }

    return steps;
  }

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _currentStepIndex = _task.currentStep;

    // Safety check for legacy data
    if (_currentStepIndex >= SlowPracticeSteps.all.length) {
      _currentStepIndex = SlowPracticeSteps.all.length - 1;
    }

    _bpmController.text = _task.targetBpm.toString();

    if (_task.status == SlowPracticeStatus.pending) {
      _task.status = SlowPracticeStatus.inProgress;
      _service.updateTask(_task);
    }

    _buttonShakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _toggleMetronome() async {
    if (_metronomeEnabled) {
      _stopMetronome();
    } else {
      // 延遲初始化節拍器服務
      if (!_metronomeInitialized) {
        await _metronomeService.initialize();
        _metronomeInitialized = true;
      }
      _startMetronome();
    }
  }

  void _startMetronome() {
    if (_metronomeEnabled) return;

    setState(() {
      _metronomeEnabled = true;
    });

    int bpm = _currentStepIndex == 0 ? _task.targetBpm : _task.currentBpm;
    
    // 使用 Isolate 版本的節拍器，不受 UI 線程阻塞影響
    _metronomeService.startMetronome(bpm, onBeat: () {
      if (!_isDisposed && mounted) {
        // 視覺效果
        _beatFlashNotifier.value = true;
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!_isDisposed && mounted) {
            _beatFlashNotifier.value = false;
          }
        });
      }
    });
  }

  void _stopMetronome() {
    _metronomeService.stopMetronome();

    if (mounted && !_isDisposed) {
      setState(() {
        _metronomeEnabled = false;
      });
      _beatFlashNotifier.value = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true; // 標記為已 dispose
    _stopMetronome();
    if (_metronomeInitialized) {
      _metronomeService.release();
    }
    _beatFlashNotifier.dispose();
    _bpmController.dispose();
    _buttonShakeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStepIndex >= 2) {
      _service.completeTask(_task.id);
      widget.onUpdate();
      _showCompletionDialog();
      return;
    }

    setState(() {
      _currentStepIndex++;
      _task.currentStep = _currentStepIndex;

      // 初始化下一步驟的狀態
      if (_currentStepIndex == 1) {
        // 進入 Step 2 (Slow Iteration - 從初始速度到 100%)
        _task.currentBpm =
            (_task.targetBpm * _task.initialSpeedPercent / 100).round();
        _task.consecutiveSuccessCount = 0;
      } else if (_currentStepIndex == 2) {
        // 進入 Step 3 (Full Rehearsal)
        _task.finalChallengeSuccessCount = 0;
      }
    });
    _service.updateTask(_task);
  }

  // Step 1 Logic
  void _saveStep1() {
    final bpm = int.tryParse(_bpmController.text);
    if (bpm == null || bpm < 30 || bpm > 300) {
      return;
    }
    _task.targetBpm = bpm;
    _nextStep();
  }

  // Step 2 Logic
  void _toggleChecklist(String item) {
    setState(() {
      if (_task.checklistSelected.contains(item)) {
        _task.checklistSelected.remove(item);
      } else {
        _task.checklistSelected.add(item);
      }
    });
    _service.updateTask(_task);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Step 3 & 4 Logic
  void _recordIteration(bool success) {
    setState(() {
      if (success) {
        _task.consecutiveSuccessCount++;
        if (_task.consecutiveSuccessCount >= 3) {
          // 讓第三個燈亮一下再晉級
          _service.updateTask(_task);
          Future.delayed(const Duration(milliseconds: 500), () {
            _increaseSpeed();
          });
        }
      } else {
        // 嚴格模式：歸零
        _task.consecutiveSuccessCount = 0;
      }
    });
    if (_task.consecutiveSuccessCount < 3) {
      _service.updateTask(_task);
    }
  }

  void _increaseSpeed() {
    final steps = _getSpeedSteps();
    final currentPercent = (_task.currentBpm / _task.targetBpm * 100).round();

    // 找下一個級距
    int? nextPercent;
    for (final p in steps) {
      if (p > currentPercent) {
        nextPercent = p;
        break;
      }
    }

    // Step 2 (Index 1) 只練到 95%
    if (_currentStepIndex == 1 && nextPercent != null && nextPercent > 95) {
      nextPercent = null; // 強制結束
    } else if (_currentStepIndex == 1 && currentPercent >= 95) {
      nextPercent = null;
    }

    if (nextPercent != null) {
      setState(() {
        _task.currentBpm = (_task.targetBpm * nextPercent! / 100).round();
        _task.consecutiveSuccessCount = 0;
      });

      // 更新節拍器速度
      if (_metronomeEnabled) {
        _stopMetronome();
        Future.delayed(const Duration(milliseconds: 100), () {
          _startMetronome();
        });
      }
    } else {
      // 該階段完成
      _nextStep();
    }
  }

  // Step 5 Logic
  void _recordFinalChallenge(bool success) {
    setState(() {
      if (success) {
        _task.finalChallengeSuccessCount++;
        _buttonShakeController.forward(from: 0.0); // 觸發震動動畫
        if (_task.finalChallengeSuccessCount >= 5) {
          _showCompletionDialog(); // 顯示大功告成動畫
        }
      } else {
        _task.finalChallengeSuccessCount = 0;
      }
    });
    _service.updateTask(_task);
  }

  void _showCompletionDialog() {
    // 停止節拍器
    if (_metronomeEnabled) {
      _stopMetronome();
    }

    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFFFCA28), width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded,
                  size: 80, color: Color(0xFFFFCA28)),
              const SizedBox(height: 16),
              Text(
                l10n?.slowPracticeChallengeSuccess ?? '太棒了！挑戰成功！',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF455A64),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.slowPracticeAllComplete ?? '你已經完成了所有的練習！',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 關閉 Dialog
                    Navigator.pop(context); // 關閉頁面
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: Text(l10n?.slowPracticeComplete ?? '完成',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentStep = SlowPracticeSteps.all[_currentStepIndex];
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.dynamicBackground, // 使用 App 主題背景色
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _currentStepIndex == 0
                  ? Icons.tune_rounded
                  : (_currentStepIndex == 1 ? Icons.search_rounded : Icons.emoji_events_rounded),
              color: AppColors.dynamicTextDark,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              _currentStepIndex == 0
                  ? '設定 & 拆解'
                  : (_currentStepIndex == 1 ? '慢練小偵探' : '最終挑戰'),
              style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.dynamicTextDark),
            ),
          ],
        ),
        backgroundColor: AppColors.dynamicBackground,
        foregroundColor: AppColors.dynamicTextDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          // 節拍器按鈕
          if (_currentStepIndex > 0)
            ValueListenableBuilder<bool>(
              valueListenable: _beatFlashNotifier,
              builder: (context, isFlashing, child) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFlashing
                        ? AppColors.dynamicAccent.withValues(alpha: 0.3)
                        : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dynamicPrimary.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _metronomeEnabled
                          ? Icons.music_note_rounded
                          : Icons.music_note_outlined,
                      color: _metronomeEnabled ? AppColors.dynamicPrimary : AppColors.dynamicTextLight,
                    ),
                    onPressed: _toggleMetronome,
                    tooltip: _metronomeEnabled
                        ? (l10n?.slowPracticeToggleMetronomeOff ?? '關閉節拍器')
                        : (l10n?.slowPracticeToggleMetronome ?? '開啟節拍器'),
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildStepContent(currentStep),
            ),
            const SizedBox(height: 4),
            _buildStepIndicator(),
            SizedBox(height: bottomPadding > 0 ? 8 : 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const SizedBox.shrink();
  }

  Widget _buildStepIndicator() {
    final l10n = AppLocalizations.of(context);
    const stepIcons = [
      Icons.settings_rounded,
      Icons.speed_rounded,
      Icons.emoji_events_rounded,
    ];
    final stepLabels = l10n?.slowPracticeStepLabels ?? ['設定', '慢練', '挑戰'];

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < SlowPracticeSteps.all.length; i++) ...[
            _buildStepItem(
              icon: stepIcons[i],
              label: stepLabels[i],
              isActive: i == _currentStepIndex,
            ),
            if (i < SlowPracticeSteps.all.length - 1)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: AppColors.dynamicTextLight.withValues(alpha: 0.3),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.dynamicPrimary
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.dynamicPrimary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: AppColors.dynamicPrimary.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
            border: isActive ? null : Border.all(color: AppColors.dynamicPrimary.withValues(alpha: 0.1), width: 2),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : AppColors.dynamicPrimary.withValues(alpha: 0.5),
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? AppColors.dynamicTextDark : AppColors.dynamicTextLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(SlowPracticeStepInfo step) {
    // Step 1 使用固定底部的按鈕佈局
    if (_currentStepIndex == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(child: _buildStep1Setup()),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          if (_currentStepIndex == 1) _buildStep2Iteration(),
          if (_currentStepIndex == 2) _buildStep3FullRehearsal(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStep1Setup() {
    final l10n = AppLocalizations.of(context);
    final canProceed =
        _bpmController.text.isNotEmpty && _task.checklistSelected.isNotEmpty;

    // 童趣配色：鮮明但不刺眼的三原色變體
    const colorSpeed = Color(0xFF42A5F5); // 活力藍 (Blue 400)
    const colorCheck = Color(0xFFFFCA28); // 暖陽黃 (Amber 400)
    const colorStart = Color(0xFFEC407A); // 糖果粉 (Pink 400)

    // 獲取翻譯後的拆解選項
    final decompositions = l10n?.slowPracticeDecompositions ??
        ['左手單獨', '右手單獨', '節奏拆解', '只彈重拍', '唱譜', '不踩踏板'];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. 設定目標原速 (藍色系)
                _buildCuteSectionTitle(
                    '1',
                    l10n?.slowPracticeSetTargetBpm ?? '設定目標原速',
                    Icons.speed_rounded,
                    colorSpeed),
                const SizedBox(height: 12),
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: colorSpeed.withValues(alpha: 0.3),
                        width: 3), // 加粗的彩色邊框
                    boxShadow: [
                      BoxShadow(
                        color: colorSpeed.withValues(alpha: 0.1),
                        blurRadius: 0, // 移除模糊，改為硬邊陰影 (Pop Art 風格)
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRoundIconButton(Icons.remove, () {
                        int current = int.tryParse(_bpmController.text) ?? 100;
                        int newValue = (current - 5).clamp(40, 240);
                        _bpmController.text = newValue.toString();
                        setState(() {});
                      }, colorSpeed),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _bpmController.text.isEmpty
                                ? '100'
                                : _bpmController.text,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: colorSpeed, // 數字跟著主題色
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(l10n?.slowPracticeSpeed ?? '速度',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorSpeed.withValues(alpha: 0.6))),
                        ],
                      ),
                      _buildRoundIconButton(Icons.add, () {
                        int current = int.tryParse(_bpmController.text) ?? 100;
                        int newValue = (current + 5).clamp(40, 240);
                        _bpmController.text = newValue.toString();
                        setState(() {});
                      }, colorSpeed),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. 選擇拆解方式 (黃色系)
                _buildCuteSectionTitle(
                    '2',
                    l10n?.slowPracticeSelectDecomposition ?? '選擇拆解方式',
                    Icons.checklist_rounded,
                    colorCheck),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: decompositions.map((item) {
                    final isSelected = _task.checklistSelected.contains(item);
                    return GestureDetector(
                      onTap: () => _toggleChecklist(item),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFF8E1)
                              : Colors.white, // 選中:淡黃背景
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected
                                ? colorCheck
                                : const Color(0xFFEEEEEE),
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  const BoxShadow(
                                      color: colorCheck,
                                      blurRadius: 0,
                                      offset: Offset(0, 4))
                                ] // 硬邊陰影
                              : [
                                  BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      blurRadius: 0,
                                      offset: const Offset(0, 2))
                                ],
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected
                                ? const Color(0xFFFF6F00)
                                : const Color(0xFF9E9E9E), // 選中:深橘
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // 3. 初始練習速度 (粉色系)
                _buildCuteSectionTitle(
                    '3',
                    l10n?.slowPracticeInitialSpeed ?? '初始練習速度',
                    Icons.rocket_launch_rounded,
                    colorStart),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: colorStart.withValues(alpha: 0.3), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: colorStart.withValues(alpha: 0.1),
                        blurRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCE4EC), // 淡粉紅
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_task.initialSpeedPercent}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: colorStart,
                              ),
                            ),
                          ),
                          Text(
                            l10n?.slowPracticeSpeedValue.replaceAll('{bpm}',
                                    '${(_task.targetBpm * _task.initialSpeedPercent / 100).round()}') ??
                                '= ${(_task.targetBpm * _task.initialSpeedPercent / 100).round()} 速度',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: colorStart,
                          inactiveTrackColor: const Color(0xFFF5F5F5),
                          thumbColor: colorStart,
                          overlayColor: colorStart.withValues(alpha: 0.1),
                          trackHeight: 12, // 很粗的軌道
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 14),
                        ),
                        child: Slider(
                          value: _task.initialSpeedPercent.toDouble(),
                          min: 30,
                          max: 80,
                          divisions: 10,
                          onChanged: (value) {
                            setState(() {
                              _task.initialSpeedPercent = value.round();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n?.slowPracticeSpeedSuggestion ?? '建議從 40-60% 開始',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Next Button (Fixed at bottom)
        Container(
          width: double.infinity,
          height: 64,
          margin: const EdgeInsets.only(bottom: 20, top: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: canProceed
                    ? const Color(0xFF66BB6A).withValues(alpha: 1.0)
                    : Colors.grey.withValues(alpha: 0.2),
                blurRadius: 0, // 硬邊陰影，像按鈕實體
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: canProceed ? _saveStep1 : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canProceed
                  ? const Color(0xFF81C784)
                  : const Color(0xFFEEEEEE), // Light Green 300
              foregroundColor:
                  canProceed ? Colors.white : const Color(0xFFBDBDBD),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              elevation: 0, // 移除自帶陰影，使用 Container 的硬陰影
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(l10n?.slowPracticeReady ?? '準備好了，出發！',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCuteSectionTitle(
      String number, String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF455A64),
          ),
        ),
      ],
    );
  }

  Widget _buildRoundIconButton(IconData icon, VoidCallback onPressed,
      [Color? color]) {
    final iconColor = color ?? const Color(0xFF0277BD);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
            color: iconColor.withValues(alpha: 0.2), width: 2), // 增加彩色邊框
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.2), // 彩色陰影
            blurRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor),
        splashRadius: 24,
      ),
    );
  }

  Widget _buildStep2Iteration() {
    final l10n = AppLocalizations.of(context);
    final currentPercent = (_task.currentBpm / _task.targetBpm * 100).round();
    // 確保進度條在 95% 時看起來是滿的 (如果需要) 或者就顯示真實比例
    // 這裡我們顯示真實比例，但最大值是 95%

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        // 儀表板顯示 (Pop Art 風格)
        Stack(
          alignment: Alignment.center,
          children: [
            // 外圈裝飾
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                    color: const Color(0xFF80CBC4), width: 4), // Teal 200
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF26A69A).withValues(alpha: 0.1),
                    blurRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
            // 進度圓環
            SizedBox(
              width: 220,
              height: 220,
              child: CircularProgressIndicator(
                value: currentPercent / 100,
                strokeWidth: 24,
                backgroundColor: const Color(0xFFE0F2F1), // 淡薄荷綠
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF26A69A)), // 深薄荷綠
                strokeCap: StrokeCap.round,
              ),
            ),
            // 中間資訊
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n?.slowPracticeCurrentSpeed ?? '目前速度',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF90A4AE),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_task.currentBpm}',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00695C),
                    height: 1.0,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB2DFDB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n?.slowPracticeTarget
                            .replaceAll('{bpm}', '${_task.targetBpm}') ??
                        '目標: ${_task.targetBpm}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 40),

        // 連續成功指示燈
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isActive = index < _task.consecutiveSuccessCount;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFFFCA28)
                    : const Color(0xFFEEEEEE), // 亮燈:黃 / 滅燈:灰
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? const Color(0xFFFFB300)
                      : const Color(0xFFE0E0E0),
                  width: 2,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          l10n?.slowPracticeConsecutiveSuccess ?? '連續成功 3 次就加速！',
          style: const TextStyle(
              color: Color(0xFF90A4AE), fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 40),

        // 按鈕區
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.close_rounded,
                label: l10n?.slowPracticeFail ?? '失誤 (歸零)',
                color: const Color(0xFFE57373), // 柔和紅
                bgColor: const Color(0xFFFFEBEE), // 淡紅背景
                onTap: () => _recordIteration(false),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildActionButton(
                icon: Icons.check_rounded,
                label: l10n?.slowPracticeSuccess ?? '成功 (+1)',
                color: const Color(0xFF81C784), // 柔和綠
                bgColor: const Color(0xFFE8F5E9), // 淡綠背景
                onTap: () => _recordIteration(true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3FullRehearsal() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        // 1. 挑戰圖示與標題 - 去除光暈，改為乾淨的圓形背景
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white, // 純白背景，乾淨清爽
                border: Border.all(
                    color: const Color(0xFFFFF59D), width: 4), // 淡黃色邊框
              ),
            ),
            const Icon(
              Icons.emoji_events_rounded,
              size: 140,
              color: Color(0xFFFFCA28), // 柔和的暖黃色
            ),
          ],
        ),
        const SizedBox(height: 24),

        Text(
          l10n?.slowPracticeFinalChallenge ?? '最終挑戰！',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Color(0xFF546E7A), // 藍灰色
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: 40),

        // 2. 進度指示器
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final isCompleted = index < _task.finalChallengeSuccessCount;
            final isCurrentTarget = index == _task.finalChallengeSuccessCount;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: isCurrentTarget ? 56 : 44,
              height: isCurrentTarget ? 56 : 44,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFFFFCA28) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFFFFCA28)
                      : const Color(0xFFFFE082),
                  width: isCurrentTarget ? 4 : 3,
                ),
              ),
              child: Icon(
                Icons.star_rounded,
                color: isCompleted ? Colors.white : const Color(0xFFFFE082),
                size: isCurrentTarget ? 32 : 24,
              ),
            );
          }),
        ),

        const SizedBox(height: 50),

        // 3. 按鈕區 (改為 櫻花粉 vs 湖水綠)
        AnimatedBuilder(
          animation: _buttonShakeController,
          builder: (context, child) {
            // 簡單的垂直震動 (Sine wave)
            final double offset = sin(_buttonShakeController.value * pi * 6) *
                6 *
                (1 - _buttonShakeController.value);
            return Transform.translate(
              offset: Offset(0, offset),
              child: child,
            );
          },
          child: Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.refresh_rounded,
                  label: l10n?.slowPracticeOops ?? '哎呀 (重來)',
                  color: const Color(0xFFF06292), // 櫻花粉 (Pink 300)
                  bgColor: const Color(0xFFFCE4EC), // 淡粉紅背景
                  onTap: () => _recordFinalChallenge(false),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.check_circle_rounded,
                  label: l10n?.slowPracticePerfect ?? '完美 (+1)',

                  color: const Color(0xFF26A69A), // 湖水綠 (Teal 400)
                  bgColor: const Color(0xFFE0F2F1), // 淡湖水綠背景
                  onTap: () => _recordFinalChallenge(true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

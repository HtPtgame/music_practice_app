import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:music_practice_app/features/practice/models/slow_practice_task.dart';
import 'package:music_practice_app/features/practice/services/slow_practice_service.dart';
import 'package:music_practice_app/features/lessons/models/lesson_note.dart';
import 'package:music_practice_app/services/metronome_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui'; // For FontFeature

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

  void _startPracticeManual(String? pieceId, String? pieceName, String measureRange, String? content) async {
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // 溫暖的米黃色背景
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐢', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            const Text(
              '慢練魔法屋',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: Color(0xFF5D4037),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFFF8E1),
        foregroundColor: const Color(0xFF5D4037),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_service.tasks.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFCC80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _showHistorySheet,
                icon: const Icon(Icons.history, color: Color(0xFF5D4037)),
                tooltip: '練習紀錄',
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeroCard(),
        const SizedBox(height: 24),
        // 選擇練習標題
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFAB91),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFF7043), width: 3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('🎯', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text(
                '選擇要練的重點',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_slowPracticePoints.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFB2DFDB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📚', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Text(
                  '來自家庭聯絡簿',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF00695C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._slowPracticePoints.map((point) => _buildLessonPointCard(point)),
          const SizedBox(height: 16),
        ],
        _buildManualInputCard(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeroCard() {
    final stepColors = [
      const Color(0xFFFFCDD2), // 粉紅
      const Color(0xFFB3E5FC), // 淺藍
      const Color(0xFFC8E6C9), // 淺綠
    ];
    
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE1F5FE), Color(0xFFFCE4EC)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF81D4FA), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 標題區域
            Row(
              children: [
                // 可愛的烏龜動畫容器
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF81C784),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4CAF50), width: 3),
                  ),
                  child: const Center(
                    child: Text('🐢', style: TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '慢練小秘訣',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF37474F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '「慢慢來，比較快！」',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.brown.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                // 詳細按鈕
                GestureDetector(
                  onTap: _showFullSopDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFC107), width: 2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb, color: Color(0xFF5D4037), size: 18),
                        SizedBox(width: 4),
                        Text(
                          '看詳細',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 三個步驟的可愛卡片
            Row(
              children: List.generate(3, (index) {
                final step = SlowPracticeSteps.all[index];
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: stepColors[index],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: stepColors[index].withValues(alpha: 0.8),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(step.icon, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(
                          step.title.split(' ')[0],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF37474F),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonPointCard(LessonPoint point) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCE93D8), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startPracticeFromPoint(point),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 可愛的鋼琴圖示
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE1BEE7), Color(0xFFCE93D8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFAB47BC), width: 2),
                  ),
                  child: const Center(
                    child: Text('🎹', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (point.relatedPieceName != null)
                        Text(
                          point.relatedPieceName!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF37474F),
                          ),
                        ),
                      if (point.measureRange != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9C4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '第 ${point.measureRange} 小節',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFFF8F00),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (point.content.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            point.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF78909C),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 開始按鈕
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2E7D32), width: 2),
                  ),
                  child: const Text(
                    '開始',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB74D), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showManualInputDialog,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 可愛的鉛筆圖示
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFE082), Color(0xFFFFB74D)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFF9800), width: 2),
                  ),
                  child: const Center(
                    child: Text('✏️', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '自己選要練哪裡',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF37474F),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '輸入小節範圍開始練習！',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFFF8F00),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFFF9800),
                    size: 20,
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
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.dynamicBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '自訂練習範圍',
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
                const SizedBox(height: 20),
                Text('樂譜（可選）', style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dynamicTextDark,
                )),
                const SizedBox(height: 8),
                DropdownButtonFormField<_PieceOption?>(
                  value: selectedPiece,
                  decoration: InputDecoration(
                    hintText: '選擇樂譜',
                    filled: true,
                    fillColor: AppColors.dynamicCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('不選擇')),
                    ..._pieceOptions.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name),
                    )),
                  ],
                  onChanged: (value) => setSheetState(() => selectedPiece = value),
                ),
                const SizedBox(height: 16),
                Text('練習小節 *', style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dynamicTextDark,
                )),
                const SizedBox(height: 8),
                TextField(
                  controller: measureController,
                  decoration: InputDecoration(
                    hintText: '例如：12-16',
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
                Text('備註', style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dynamicTextDark,
                )),
                const SizedBox(height: 8),
                TextField(
                  controller: contentController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: '需要注意的地方...',
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
                          const SnackBar(content: Text('請輸入練習小節')),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('開始練習',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                    '練習紀錄',
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (_service.inProgressTasks.isNotEmpty) ...[
                    _buildHistorySection('🎹 進行中', _service.inProgressTasks),
                    const SizedBox(height: 16),
                  ],
                  if (_service.completedTasks.isNotEmpty) ...[
                    _buildHistorySection('✅ 已完成', _service.completedTasks),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(String title, List<SlowPracticeTask> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.dynamicTextDark,
          ),
        ),
        const SizedBox(height: 8),
        ...tasks.map((task) => Card(
          color: AppColors.dynamicCard,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () {
              Navigator.pop(context);
              _openPracticeSession(task);
            },
            title: Text(task.pieceName ?? '練習'),
            subtitle: Text('第 ${task.measureRange ?? "?"} 小節'),
            trailing: Text(
              '${(task.overallProgress * 100).toInt()}%',
              style: TextStyle(
                color: AppColors.dynamicPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )),
      ],
    );
  }

  void _showFullSopDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('🐢 ', style: TextStyle(fontSize: 24)),
            Text('慢練 SOP', style: TextStyle(color: AppColors.dynamicTextDark)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: SlowPracticeSteps.all.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${step.step + 1}. ${step.title}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          step.shortDesc,
                          style: TextStyle(
                            color: AppColors.dynamicPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('了解'),
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
  State<_SlowPracticeSessionPage> createState() => _SlowPracticeSessionPageState();
}

class _SlowPracticeSessionPageState extends State<_SlowPracticeSessionPage> with SingleTickerProviderStateMixin {
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
  Timer? _metronomeTimer;
  DateTime? _metronomeStartTime; // 記錄節拍器開始時間
  int _beatCount = 0; // 記錄拍數
  final ValueNotifier<bool> _beatFlashNotifier = ValueNotifier<bool>(false);

  // Step 1 State
  final TextEditingController _bpmController = TextEditingController();

  // Step 2 State
  final List<String> _checklistOptions = [
    '左手單獨', '右手單獨', '節奏拆解', '只彈重拍', '唱譜', '不踩踏板'
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
    final double intervalMs = 60000.0 / bpm;
    
    // 記錄起始時間和拍數
    _metronomeStartTime = DateTime.now();
    _beatCount = 0;
    
    // 立即播放第一拍
    _playMetronomeBeat();
    
    // 使用精確的時間計算來避免累積誤差
    _scheduleNextBeat(intervalMs);
  }

  void _scheduleNextBeat(double intervalMs) {
    if (!_metronomeEnabled || _metronomeStartTime == null || _isDisposed) return;
    
    _beatCount++;
    
    // 計算理論上下一拍應該發生的時間
    final targetTime = _metronomeStartTime!.add(
      Duration(milliseconds: (_beatCount * intervalMs).round())
    );
    
    // 計算實際需要等待的時間(補償累積誤差)
    final now = DateTime.now();
    final delay = targetTime.difference(now);
    
    // 如果延遲為負數(已經遲到),立即播放;否則按計算的延遲時間播放
    final actualDelay = delay.isNegative 
        ? Duration.zero 
        : delay;
    
    _metronomeTimer = Timer(actualDelay, () {
      if (_metronomeEnabled && !_isDisposed && mounted) {
        _playMetronomeBeat();
        _scheduleNextBeat(intervalMs);
      }
    });
  }

  void _stopMetronome() {
    _metronomeTimer?.cancel();
    _metronomeTimer = null;
    _metronomeStartTime = null;
    _beatCount = 0;
    
    if (mounted && !_isDisposed) {
      setState(() {
        _metronomeEnabled = false;
      });
      _beatFlashNotifier.value = false;
    }
  }

  void _playMetronomeBeat() {
    if (!mounted || _isDisposed) return;
    
    // 播放聲音
    if (_metronomeInitialized) {
      _metronomeService.playBeat();
    }
    
    // 視覺效果 - 使用 mounted 檢查避免 disposed 後更新
    _beatFlashNotifier.value = true;
    Future.delayed(const Duration(milliseconds: 100), () {
      // 雙重檢查狀態
      if (!_isDisposed && mounted) {
        _beatFlashNotifier.value = false;
      }
    });
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
      if (_currentStepIndex == 1) { // 進入 Step 2 (Slow Iteration - 從初始速度到 100%)
        _task.currentBpm = (_task.targetBpm * _task.initialSpeedPercent / 100).round();
        _task.consecutiveSuccessCount = 0;
      } else if (_currentStepIndex == 2) { // 進入 Step 3 (Full Rehearsal)
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
              style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold),
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
              const Icon(Icons.emoji_events_rounded, size: 80, color: Color(0xFFFFCA28)),
              const SizedBox(height: 16),
              const Text(
                '太棒了！挑戰成功！',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF455A64),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '你已經完成了所有的練習！',
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: const Text('完成', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
    final currentStep = SlowPracticeSteps.all[_currentStepIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFBDE0E6),
      appBar: AppBar(
        title: Text(_task.pieceName ?? '慢練練習'),
        backgroundColor: const Color(0xFFBDE0E6),
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
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
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFlashing 
                        ? Colors.amber.withOpacity(0.3) 
                        : Colors.transparent,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _metronomeEnabled ? Icons.music_note : Icons.music_note_outlined,
                      color: _metronomeEnabled ? Colors.amber : Colors.black54,
                    ),
                    onPressed: _toggleMetronome,
                    tooltip: _metronomeEnabled ? '關閉節拍器' : '開啟節拍器',
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildStepContent(currentStep),
          ),
          const SizedBox(height: 4),
          _buildStepIndicator(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const SizedBox.shrink();
  }

  Widget _buildStepIndicator() {
    const stepIcons = [
      Icons.settings,
      Icons.speed,
      Icons.emoji_events,
    ];
    const stepLabels = ['設定', '慢練', '挑戰'];

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < SlowPracticeSteps.all.length; i++) ...[
            _buildStepItem(
              icon: stepIcons[i],
              label: stepLabels[i],
              isActive: i == _currentStepIndex,
            ),
            if (i < SlowPracticeSteps.all.length - 1)
              const Icon(Icons.arrow_forward, size: 16, color: Colors.black26),
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
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF81C7D4)
                : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.black26,
            size: 26,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black45,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(SlowPracticeStepInfo step) {
    // 移除英文 Step X，改為純圖示與標題
    final titleWidget = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _currentStepIndex == 0 ? Icons.settings_rounded :
            _currentStepIndex == 1 ? Icons.speed_rounded : Icons.emoji_events_rounded,
            size: 32,
            color: const Color(0xFF455A64),
          ),
          const SizedBox(width: 12),
          Text(
            step.title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Color(0xFF455A64),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );

    // Step 1 使用固定底部的按鈕佈局
    if (_currentStepIndex == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            titleWidget,
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
          titleWidget,
          const SizedBox(height: 12),
          if (_currentStepIndex == 1) _buildStep2Iteration(),
          if (_currentStepIndex == 2) _buildStep3FullRehearsal(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStep1Setup() {
    final canProceed = _bpmController.text.isNotEmpty && _task.checklistSelected.isNotEmpty;
    
    // 童趣配色：鮮明但不刺眼的三原色變體
    const colorSpeed = Color(0xFF42A5F5);   // 活力藍 (Blue 400)
    const colorCheck = Color(0xFFFFCA28);   // 暖陽黃 (Amber 400)
    const colorStart = Color(0xFFEC407A);   // 糖果粉 (Pink 400)

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. 設定目標原速 (藍色系)
                _buildCuteSectionTitle('1', '設定目標原速', Icons.speed_rounded, colorSpeed),
                const SizedBox(height: 12),
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colorSpeed.withValues(alpha: 0.3), width: 3), // 加粗的彩色邊框
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
                            _bpmController.text.isEmpty ? '100' : _bpmController.text,
                            style: TextStyle(
                              fontSize: 48, 
                              fontWeight: FontWeight.w900,
                              color: colorSpeed, // 數字跟著主題色
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('速度', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorSpeed.withValues(alpha: 0.6))),
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
                _buildCuteSectionTitle('2', '選擇拆解方式', Icons.checklist_rounded, colorCheck),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: _checklistOptions.map((item) {
                    final isSelected = _task.checklistSelected.contains(item);
                    return GestureDetector(
                      onTap: () => _toggleChecklist(item),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFF8E1) : Colors.white, // 選中:淡黃背景
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? colorCheck : const Color(0xFFEEEEEE),
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: colorCheck, blurRadius: 0, offset: const Offset(0, 4))] // 硬邊陰影
                              : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 0, offset: const Offset(0, 2))],
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected ? const Color(0xFFFF6F00) : const Color(0xFF9E9E9E), // 選中:深橘
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // 3. 初始練習速度 (粉色系)
                _buildCuteSectionTitle('3', '初始練習速度', Icons.rocket_launch_rounded, colorStart),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colorStart.withValues(alpha: 0.3), width: 3),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCE4EC), // 淡粉紅
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_task.initialSpeedPercent}%',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: colorStart,
                              ),
                            ),
                          ),
                          Text(
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
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
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
                      const Text(
                        '建議從 40-60% 開始',
                        style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
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
                color: canProceed ? const Color(0xFF66BB6A).withValues(alpha: 1.0) : Colors.grey.withValues(alpha: 0.2),
                blurRadius: 0, // 硬邊陰影，像按鈕實體
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: canProceed ? _saveStep1 : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canProceed ? const Color(0xFF81C784) : const Color(0xFFEEEEEE), // Light Green 300
              foregroundColor: canProceed ? Colors.white : const Color(0xFFBDBDBD),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              elevation: 0, // 移除自帶陰影，使用 Container 的硬陰影
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('準備好了，出發！', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCuteSectionTitle(String number, String title, IconData icon, Color color) {
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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: const Color(0xFF455A64),
          ),
        ),
      ],
    );
  }

  Widget _buildRoundIconButton(IconData icon, VoidCallback onPressed, [Color? color]) {
    final iconColor = color ?? const Color(0xFF0277BD);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 2), // 增加彩色邊框
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
                border: Border.all(color: const Color(0xFF80CBC4), width: 4), // Teal 200
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
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF26A69A)), // 深薄荷綠
                strokeCap: StrokeCap.round,
              ),
            ),
            // 中間資訊
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '目前速度',
                  style: TextStyle(
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB2DFDB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
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
                color: isActive ? const Color(0xFFFFCA28) : const Color(0xFFEEEEEE), // 亮燈:黃 / 滅燈:灰
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? const Color(0xFFFFB300) : const Color(0xFFE0E0E0),
                  width: 2,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        const Text(
          '連續成功 3 次就加速！',
          style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 40),

        // 按鈕區
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.close_rounded,
                label: '失誤 (歸零)',
                color: const Color(0xFFE57373), // 柔和紅
                bgColor: const Color(0xFFFFEBEE), // 淡紅背景
                onTap: () => _recordIteration(false),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildActionButton(
                icon: Icons.check_rounded,
                label: '成功 (+1)',
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
                border: Border.all(color: const Color(0xFFFFF59D), width: 4), // 淡黃色邊框
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
        
        const Text(
          '最終挑戰！',
          style: TextStyle(
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
                  color: isCompleted ? const Color(0xFFFFCA28) : const Color(0xFFFFE082),
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
            final double offset = sin(_buttonShakeController.value * pi * 6) * 6 * (1 - _buttonShakeController.value);
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
                  label: '哎呀 (重來)',
                  color: const Color(0xFFF06292), // 櫻花粉 (Pink 300)
                  bgColor: const Color(0xFFFCE4EC), // 淡粉紅背景
                  onTap: () => _recordFinalChallenge(false),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.check_circle_rounded,
                  label: '完美 (+1)',
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

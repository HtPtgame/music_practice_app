import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_practice_app/features/practice/models/slow_practice_task.dart';
import 'package:music_practice_app/features/lessons/models/lesson_note.dart';
import 'package:music_practice_app/features/lessons/services/lesson_service.dart';

class SlowPracticeService extends ChangeNotifier {
  static final SlowPracticeService _instance = SlowPracticeService._internal();
  factory SlowPracticeService() => _instance;
  SlowPracticeService._internal();

  static const String _storageKey = 'slow_practice_tasks';

  List<SlowPracticeTask> _tasks = [];
  List<SlowPracticeTask> get tasks => List.unmodifiable(_tasks);
  
  List<SlowPracticeTask> get pendingTasks => 
      _tasks.where((t) => t.status == SlowPracticeStatus.pending).toList();
  
  List<SlowPracticeTask> get inProgressTasks => 
      _tasks.where((t) => t.status == SlowPracticeStatus.inProgress).toList();
  
  List<SlowPracticeTask> get completedTasks => 
      _tasks.where((t) => t.status == SlowPracticeStatus.completed).toList();

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// 載入所有慢練任務
  Future<void> loadTasks() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];
      _tasks = jsonList
          .map((jsonStr) => SlowPracticeTask.fromJsonString(jsonStr))
          .toList();
      _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('SlowPracticeService: 載入失敗 $e');
      _tasks = [];
      _isLoaded = true;
    }
  }

  /// 儲存所有任務
  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _tasks.map((t) => t.toJsonString()).toList();
      await prefs.setStringList(_storageKey, jsonList);
    } catch (e) {
      debugPrint('SlowPracticeService: 儲存失敗 $e');
    }
  }

  /// 從家庭聯絡簿的「慢練」重點建立任務
  Future<SlowPracticeTask> createTaskFromLessonPoint(LessonPoint point) async {
    final task = SlowPracticeTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pieceId: point.relatedPieceId,
      pieceName: point.relatedPieceName,
      measureRange: point.measureRange,
      lessonContent: point.content,
      createdAt: DateTime.now(),
    );
    
    // 自動分割段落
    task.autoSplitSegments();
    
    _tasks.insert(0, task);
    await _saveTasks();
    notifyListeners();
    
    return task;
  }

  /// 手動建立任務
  Future<SlowPracticeTask> createTask({
    String? pieceId,
    String? pieceName,
    String? measureRange,
    String? content,
  }) async {
    final task = SlowPracticeTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pieceId: pieceId,
      pieceName: pieceName,
      measureRange: measureRange,
      lessonContent: content,
      createdAt: DateTime.now(),
    );
    
    task.autoSplitSegments();
    
    _tasks.insert(0, task);
    await _saveTasks();
    notifyListeners();
    
    return task;
  }

  /// 開始練習任務
  Future<void> startTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].status = SlowPracticeStatus.inProgress;
      await _saveTasks();
      notifyListeners();
    }
  }

  /// 更新任務
  Future<void> updateTask(SlowPracticeTask task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      await _saveTasks();
      notifyListeners();
    }
  }

  /// 記錄段落練習結果
  Future<void> recordSegmentAttempt({
    required String taskId,
    required String segmentId,
    required bool isPerfect,
  }) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;
    
    final task = _tasks[taskIndex];
    final segmentIndex = task.segments.indexWhere((s) => s.id == segmentId);
    if (segmentIndex == -1) return;
    
    final segment = task.segments[segmentIndex];
    segment.totalAttempts++;
    
    if (isPerfect) {
      segment.perfectCount++;
      if (segment.perfectCount >= 3) {
        segment.isCompleted = true;
      }
    } else {
      // 不是完美，重置連續計數
      segment.perfectCount = 0;
    }
    
    await _saveTasks();
    notifyListeners();
  }

  /// 調整段落速度
  Future<void> adjustSegmentSpeed({
    required String taskId,
    required String segmentId,
    required int speedPercent,
  }) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;
    
    final task = _tasks[taskIndex];
    final segmentIndex = task.segments.indexWhere((s) => s.id == segmentId);
    if (segmentIndex == -1) return;
    
    task.segments[segmentIndex].currentSpeedPercent = speedPercent.clamp(20, 100);
    
    await _saveTasks();
    notifyListeners();
  }

  /// 完成任務
  Future<void> completeTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].status = SlowPracticeStatus.completed;
      await _saveTasks();
      notifyListeners();
    }
  }

  /// 刪除任務
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    await _saveTasks();
    notifyListeners();
  }

  /// 清除所有練習記錄
  Future<void> clearAllTasks() async {
    _tasks.clear();
    await _saveTasks();
    notifyListeners();
  }

  /// 增加練習時間
  Future<void> addPracticeTime(String taskId, int seconds) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].totalPracticeSeconds += seconds;
      await _saveTasks();
      notifyListeners();
    }
  }

  /// 從家庭聯絡簿獲取所有「慢練」類別的重點
  Future<List<LessonPoint>> getSlowPracticePointsFromLessons() async {
    final lessonService = LessonService();
    await lessonService.loadRecords();
    
    final slowPracticePoints = <LessonPoint>[];
    for (final record in lessonService.records) {
      slowPracticePoints.addAll(
        record.points.where((p) => p.category.id == 'slow_practice')
      );
    }
    
    return slowPracticePoints;
  }
}

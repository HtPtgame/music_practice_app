import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloria/features/lessons/models/lesson_note.dart';

class LessonService extends ChangeNotifier {
  static final LessonService _instance = LessonService._internal();
  factory LessonService() => _instance;
  LessonService._internal();

  static const String _storageKey = 'lesson_records';
  
  List<LessonRecord> _records = [];
  List<LessonRecord> get records => List.unmodifiable(_records);
  
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// 載入所有上課紀錄
  Future<void> loadRecords() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];
      _records = jsonList
          .map((jsonStr) => LessonRecord.fromJsonString(jsonStr))
          .toList();
      _records.sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('LessonService: 載入失敗 $e');
      _records = [];
      _isLoaded = true;
    }
  }

  /// 儲存所有上課紀錄
  Future<void> _saveRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _records.map((r) => r.toJsonString()).toList();
      await prefs.setStringList(_storageKey, jsonList);
    } catch (e) {
      debugPrint('LessonService: 儲存失敗 $e');
    }
  }

  /// 新增上課紀錄
  Future<void> addRecord(LessonRecord record) async {
    _records.insert(0, record);
    _records.sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
    await _saveRecords();
    notifyListeners();
  }

  /// 更新上課紀錄
  Future<void> updateRecord(LessonRecord record) async {
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _records[index] = record;
      _records.sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
      await _saveRecords();
      notifyListeners();
    }
  }

  /// 刪除上課紀錄
  Future<void> deleteRecord(String recordId) async {
    _records.removeWhere((r) => r.id == recordId);
    await _saveRecords();
    notifyListeners();
  }

  /// 取得某樂譜的所有相關重點
  List<LessonPoint> getPointsForPiece(String pieceId) {
    final points = <LessonPoint>[];
    for (final record in _records) {
      points.addAll(record.points.where((p) => p.relatedPieceId == pieceId));
    }
    return points;
  }
}

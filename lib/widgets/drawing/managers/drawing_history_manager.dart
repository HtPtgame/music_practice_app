import 'dart:ui' as ui;
import '../../../models/drawing_data.dart';

/// 📜 繪圖歷史記錄管理器
/// 
/// Phase 3 重構: 從 DrawingCanvas 提取
/// 負責 Undo/Redo 歷史記錄管理和快取保存
class DrawingHistoryManager {
  // ===== 歷史記錄 =====
  final List<List<DrawingStroke>> _history = [];
  final List<ui.Image?> _cacheHistory = [];
  int _historyIndex = -1;

  // ===== 配置 =====
  static const int maxHistorySize = 50;

  // ===== Getters =====
  int get historyIndex => _historyIndex;
  List<ui.Image?> get cacheHistory => _cacheHistory;
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  /// 保存當前狀態到歷史記錄
  void saveToHistory({
    required List<DrawingStroke> strokes,
    required ui.Image? currentCache,
  }) {
    // 如果不在最新狀態，刪除後面的歷史
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
      // 同時清理快取歷史（需要先 dispose 不再使用的 Image）
      for (int i = _historyIndex + 1; i < _cacheHistory.length; i++) {
        final imageToDispose = _cacheHistory[i];
        // 只 dispose 不是當前快取的 Image
        if (imageToDispose != null && imageToDispose != currentCache) {
          imageToDispose.dispose();
        }
      }
      _cacheHistory.removeRange(_historyIndex + 1, _cacheHistory.length);
    }

    // 保存當前狀態（筆劃）
    _history.add(List.from(strokes));
    // 保存當前快取（避免 Undo 時重新運算）
    _cacheHistory.add(currentCache);
    _historyIndex = _history.length - 1;

    // 限制歷史記錄數量
    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
      final oldImage = _cacheHistory[0];
      // 只在確定不會再使用時才 dispose
      if (oldImage != null && oldImage != currentCache) {
        oldImage.dispose();
      }
      _cacheHistory.removeAt(0);
      _historyIndex--;
    }
  }

  /// 執行 Undo 操作
  /// 返回要還原的筆劃列表，如果無法 undo 則返回 null
  UndoResult? undo() {
    if (!canUndo) return null;

    _historyIndex--;
    return UndoResult(
      strokes: List.from(_history[_historyIndex]),
      cachedImage: _cacheHistory[_historyIndex],
    );
  }

  /// 執行 Redo 操作
  /// 返回要還原的筆劃列表，如果無法 redo 則返回 null
  UndoResult? redo() {
    if (!canRedo) return null;

    _historyIndex++;
    return UndoResult(
      strokes: List.from(_history[_historyIndex]),
      cachedImage: _cacheHistory[_historyIndex],
    );
  }

  /// 清空歷史記錄
  void clear() {
    for (var cache in _cacheHistory) {
      cache?.dispose();
    }
    _history.clear();
    _cacheHistory.clear();
    _historyIndex = -1;
  }

  /// 釋放資源
  void dispose() {
    for (var cache in _cacheHistory) {
      cache?.dispose();
    }
    _history.clear();
    _cacheHistory.clear();
  }
}

/// Undo/Redo 操作的結果
class UndoResult {
  final List<DrawingStroke> strokes;
  final ui.Image? cachedImage;

  UndoResult({
    required this.strokes,
    required this.cachedImage,
  });
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../painters/drawing_painter.dart';
import '../../../models/drawing_data.dart';

/// 🚀 繪圖快取管理器
/// 
/// Phase 3 重構: 從 DrawingCanvas 提取
/// 負責背景快取和當前筆劃快取的管理
class DrawingCacheManager {
  // ===== 背景快取（已完成的筆劃）=====
  ui.Image? _cachedBackground;
  int _cachedStrokeCount = 0;
  bool _isCacheBuilding = false;

  // ===== 當前筆劃的增量快取 =====
  ui.Image? _currentStrokeCache;
  int _currentStrokeCachedPoints = 0;
  bool _isCurrentStrokeCacheBuilding = false;

  // ===== Getters =====
  ui.Image? get cachedBackground => _cachedBackground;
  int get cachedStrokeCount => _cachedStrokeCount;
  ui.Image? get currentStrokeCache => _currentStrokeCache;
  int get currentStrokeCachedPoints => _currentStrokeCachedPoints;
  bool get isCacheBuilding => _isCacheBuilding;

  /// 設置背景快取（用於 undo 還原）
  void setBackgroundCache(ui.Image? image, int strokeCount) {
    _cachedBackground = image;
    _cachedStrokeCount = strokeCount;
  }

  /// 🚀 更新 Canvas 快取（增量更新）
  Future<void> updateCache({
    required List<DrawingStroke> strokes,
    required Size size,
    required List<ui.Image?> cacheHistory,
    DrawingPainter? painterForNewStrokes,
  }) async {
    if (_isCacheBuilding) return;
    _isCacheBuilding = true;

    try {
      final newStrokeCount = strokes.length;

      // 如果沒有新筆劃，不需要更新
      if (newStrokeCount == _cachedStrokeCount) {
        _isCacheBuilding = false;
        return;
      }

      final width = size.width.toInt();
      final height = size.height.toInt();

      // 建立新的 recorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 🎨 先繪製舊的背景快取（如果有）
      if (_cachedBackground != null) {
        canvas.drawImage(_cachedBackground!, Offset.zero, Paint());
      }

      // 🚀 優化：如果有當前筆劃快取，直接使用它（避免重新渲染）
      if (_currentStrokeCache != null &&
          newStrokeCount - _cachedStrokeCount == 1) {
        // 只有一條新筆劃，且有當前筆劃快取，直接使用
        canvas.drawImage(_currentStrokeCache!, Offset.zero, Paint());
      } else if (painterForNewStrokes != null) {
        // 🎨 渲染新增的筆劃
        for (int i = _cachedStrokeCount; i < newStrokeCount; i++) {
          final stroke = strokes[i];
          painterForNewStrokes.drawStrokeToCanvas(canvas, stroke);
        }
      }

      // 轉換為 Image
      final picture = recorder.endRecording();
      final newImage = await picture.toImage(width, height);

      // 釋放舊快取（但不要 dispose 歷史中的 Image）
      final oldCache = _cachedBackground;
      final isInHistory = cacheHistory.contains(oldCache);
      if (oldCache != null && !isInHistory) {
        oldCache.dispose();
      }

      // 更新快取
      _cachedBackground = newImage;
      _cachedStrokeCount = newStrokeCount;
    } catch (e) {
      debugPrint('❌ 快取更新失敗: $e');
    } finally {
      _isCacheBuilding = false;
    }
  }

  /// 🎯 更新快取並清理當前筆劃快取
  Future<void> updateCacheAndCleanup({
    required List<DrawingStroke> strokes,
    required Size size,
    required List<ui.Image?> cacheHistory,
    DrawingPainter? painterForNewStrokes,
  }) async {
    await updateCache(
      strokes: strokes,
      size: size,
      cacheHistory: cacheHistory,
      painterForNewStrokes: painterForNewStrokes,
    );

    // 更新完成後，清除當前筆劃快取
    _currentStrokeCache?.dispose();
    _currentStrokeCache = null;
    _currentStrokeCachedPoints = 0;
  }

  /// 🔄 重建整個快取（橡皮擦專用：快速重建）
  Future<void> rebuildCache({
    required List<DrawingStroke> strokes,
    required Size size,
    required List<ui.Image?> cacheHistory,
    required DrawingPainter painter,
  }) async {
    if (_isCacheBuilding) return;
    _isCacheBuilding = true;

    try {
      if (strokes.isEmpty) {
        // 沒有筆劃時，清除快取（但不要 dispose 歷史中的 Image）
        final oldCache = _cachedBackground;
        final isInHistory = cacheHistory.contains(oldCache);
        if (oldCache != null && !isInHistory) {
          oldCache.dispose();
        }
        _cachedBackground = null;
        _cachedStrokeCount = 0;
        _isCacheBuilding = false;
        return;
      }

      final width = size.width.toInt();
      final height = size.height.toInt();

      // 建立新的 recorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 繪製所有剩餘筆劃（橡皮擦後只執行一次）
      for (final stroke in strokes) {
        painter.drawStrokeToCanvas(canvas, stroke);
      }

      // 轉換為 Image
      final picture = recorder.endRecording();
      final newImage = await picture.toImage(width, height);

      _cachedBackground = newImage;
      _cachedStrokeCount = strokes.length;
    } catch (e) {
      debugPrint('❌ 快取重建失敗: $e');
    } finally {
      _isCacheBuilding = false;
    }
  }

  /// 🎯 增量更新當前筆劃快取
  Future<void> updateCurrentStrokeCache({
    required List<Offset> currentStroke,
    required Color color,
    required double strokeWidth,
    required Size size,
    required DrawingPainter painter,
  }) async {
    // 防止重複建立
    if (_isCurrentStrokeCacheBuilding) return;

    // 如果沒有新點，不需要更新
    if (currentStroke.length <= _currentStrokeCachedPoints) return;

    // 如果點數太少（<3個），直接渲染不快取
    if (currentStroke.length < 3) return;

    _isCurrentStrokeCacheBuilding = true;

    try {
      final width = size.width.toInt();
      final height = size.height.toInt();

      // 建立新的 recorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 🎨 先繪製舊的快取（如果有）
      if (_currentStrokeCache != null) {
        canvas.drawImage(_currentStrokeCache!, Offset.zero, Paint());
      }

      // 🎨 只繪製新增的點
      painter.drawTextureBrush(
        canvas,
        currentStroke.sublist(_currentStrokeCachedPoints),
        color,
        strokeWidth,
        useSkipping: false,
      );

      // 轉換為 Image
      final picture = recorder.endRecording();
      final newImage = await picture.toImage(width, height);

      // 釋放舊快取
      _currentStrokeCache?.dispose();

      // 更新快取
      _currentStrokeCache = newImage;
      _currentStrokeCachedPoints = currentStroke.length;
    } catch (e) {
      debugPrint('❌ 當前筆劃快取更新失敗: $e');
    } finally {
      _isCurrentStrokeCacheBuilding = false;
    }
  }

  /// 清除當前筆劃快取（開始新筆劃時）
  void clearCurrentStrokeCache() {
    _currentStrokeCache?.dispose();
    _currentStrokeCache = null;
    _currentStrokeCachedPoints = 0;
  }

  /// 釋放資源
  void dispose({required List<ui.Image?> cacheHistory}) {
    _currentStrokeCache?.dispose();
    
    // 如果當前快取不在歷史中，才需要 dispose
    if (_cachedBackground != null && !cacheHistory.contains(_cachedBackground)) {
      _cachedBackground!.dispose();
    }
    
    _cachedBackground = null;
    _currentStrokeCache = null;
  }
}

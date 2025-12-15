import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';
import '../models/drawing_data.dart';
import '../l10n/app_localizations.dart';

class DrawingCanvas extends StatefulWidget {
  final DrawingData initialDrawing;
  final Function(DrawingData) onDrawingChanged;
  final bool isReadOnly;
  final double? width;
  final double? height;

  const DrawingCanvas({
    super.key,
    required this.initialDrawing,
    required this.onDrawingChanged,
    this.isReadOnly = false,
    this.width,
    this.height,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  late DrawingData _drawingData;
  List<Offset> _currentStroke = [];
  Color _selectedColor = const Color(0xFF1E88E5);
  double _strokeWidth = 8.0; // 預設最細的筆刷
  bool _isEraser = false;
  BrushType _brushType = BrushType.texture;

  // 🎨 筆刷紋理快取池
  BrushTexturePool? _texturePool;
  bool _isPoolReady = false;

  // 🚀 Canvas 快取 - 避免重複渲染已完成的筆劃
  ui.Image? _cachedBackground;
  int _cachedStrokeCount = 0;
  bool _isCacheBuilding = false;

  // 🎯 當前筆劃的增量快取
  ui.Image? _currentStrokeCache;
  int _currentStrokeCachedPoints = 0;
  bool _isCurrentStrokeCacheBuilding = false;

  // 📜 Undo 歷史記錄（筆劃數據 + 快取圖片）
  final List<List<DrawingStroke>> _history = [];
  final List<ui.Image?> _cacheHistory = [];
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    _drawingData = widget.initialDrawing;
    _initializeTexturePool();

    // 如果有舊紀錄，建立背景快取並保存到歷史
    if (_drawingData.strokes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rebuildCache().then((_) {
          if (mounted) _saveToHistory();
        });
      });
    } else {
      // 空畫布也要保存初始狀態
      _saveToHistory();
    }
  }

  @override
  void dispose() {
    _texturePool?.dispose();
    _currentStrokeCache?.dispose();
    
    // 清理快取歷史
    for (var cache in _cacheHistory) {
      cache?.dispose();
    }
    
    // 如果當前快取不在歷史中，才需要 dispose
    if (_cachedBackground != null && !_cacheHistory.contains(_cachedBackground)) {
      _cachedBackground!.dispose();
    }
    
    super.dispose();
  }

  /// 初始化紋理快取池
  Future<void> _initializeTexturePool() async {
    _texturePool = BrushTexturePool();
    try {
      await _texturePool!.buildPool(_selectedColor, _strokeWidth);
      if (mounted) {
        setState(() {
          _isPoolReady = true;
        });
        print('✅ 紋理池初始化完成');
      }
    } catch (e) {
      print('❌ 紋理池初始化失敗: $e');
      if (mounted) {
        setState(() {
          _isPoolReady = false;
        });
      }
    }
  }

  /// 重建紋理池（當顏色或筆刷大小改變時）
  Future<void> _rebuildTexturePool() async {
    await _texturePool?.buildPool(_selectedColor, _strokeWidth);
    if (mounted) {
      setState(() {
        _isPoolReady = true;
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.isReadOnly) return;
    setState(() {
      _currentStroke = [details.localPosition];
      // 🎯 清除當前筆劃快取，開始新筆劃
      _currentStrokeCache?.dispose();
      _currentStrokeCache = null;
      _currentStrokeCachedPoints = 0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.isReadOnly) return;

    // 🎯 智能點採樣 - 避免點過密導致性能問題
    if (_currentStroke.isNotEmpty) {
      final lastPoint = _currentStroke.last;
      final distance = (details.localPosition - lastPoint).distance;

      // 只有當移動距離大於 2 像素時才添加新點（更密集的採樣）
      if (distance < 2.0) {
        return; // 跳過太近的點
      }
    }

    setState(() {
      // 🚀 關鍵修復：創建新的 List，而不是修改舊的
      // 這樣 CustomPaint 才會偵測到變化並重繪！
      _currentStroke = [..._currentStroke, details.localPosition];
    });

    // 🎯 增量更新當前筆劃快取（非同步，不阻塞 UI）
    _updateCurrentStrokeCache();
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.isReadOnly) return;

    if (_currentStroke.isNotEmpty) {
      if (_isEraser) {
        // 橡皮擦：固定大小25.0，碰到整條刪除
        const eraserRadius = 25.0;
        
        // 先找出要刪除的筆劃（但不立即刪除）
        final toDelete = <DrawingStroke>[];
        for (final stroke in _drawingData.strokes) {
          final shouldDelete = _currentStroke.any((eraserPoint) {
            return stroke.points.any((strokePoint) {
              final distance = (eraserPoint - strokePoint).distance;
              final threshold = eraserRadius + (stroke.strokeWidth / 2);
              return distance < threshold;
            });
          });
          if (shouldDelete) {
            toDelete.add(stroke);
          }
        }
        
        // 如果沒有要刪除的筆劃，直接返回
        if (toDelete.isEmpty) {
          setState(() {
            _currentStroke = [];
          });
          return;
        }
        
        // 先刪除筆劃（不觸發重繪）
        for (final stroke in toDelete) {
          _drawingData.strokes.remove(stroke);
        }
        _currentStroke = [];
        
        // 立即重建快取，完成後一次性更新畫面
        _rebuildCache().then((_) {
          if (mounted) {
            setState(() {
              // 快取已更新，觸發重繪
            });
            _saveToHistory();
          }
        });
      } else {
        final stroke = DrawingStroke(
          points: List.from(_currentStroke),
          color: _selectedColor,
          strokeWidth: _strokeWidth,
          brushType: _brushType,
        );
        setState(() {
          _drawingData.strokes.add(stroke);
          _currentStroke = [];
          // 🎯 注意：不立即清除當前筆劃快取
          // 讓 _updateCache() 先使用它合併到背景
        });
        // 先更新背景快取，再保存到歷史（確保快取包含新筆劃）
        _updateCacheAndCleanup().then((_) {
          if (mounted) {
            _saveToHistory();
          }
        });
      }
      widget.onDrawingChanged(_drawingData);
    }
  }

  void _undoLastStroke() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        _drawingData.strokes.clear();
        _drawingData.strokes.addAll(List.from(_history[_historyIndex]));
        
        // 直接使用歷史快取，零運算！
        _cachedBackground = _cacheHistory[_historyIndex];
        _cachedStrokeCount = _drawingData.strokes.length;
      });
      widget.onDrawingChanged(_drawingData);
    }
  }

  /// 保存當前狀態到歷史記錄
  void _saveToHistory() {
    // 如果不在最新狀態，刪除後面的歷史
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
      // 同時清理快取歷史（需要先 dispose 不再使用的 Image）
      for (int i = _historyIndex + 1; i < _cacheHistory.length; i++) {
        final imageToDispose = _cacheHistory[i];
        // 只 dispose 不是當前快取的 Image
        if (imageToDispose != null && imageToDispose != _cachedBackground) {
          imageToDispose.dispose();
        }
      }
      _cacheHistory.removeRange(_historyIndex + 1, _cacheHistory.length);
    }

    // 保存當前狀態（筆劃）
    _history.add(List.from(_drawingData.strokes));
    // 保存當前快取（避免 Undo 時重新運算）
    _cacheHistory.add(_cachedBackground);
    _historyIndex = _history.length - 1;

    // 限制歷史記錄數量（最多 50 步）
    if (_history.length > 50) {
      _history.removeAt(0);
      final oldImage = _cacheHistory[0];
      // 只在確定不會再使用時才 dispose
      if (oldImage != null && oldImage != _cachedBackground) {
        oldImage.dispose();
      }
      _cacheHistory.removeAt(0);
      _historyIndex--;
    }
  }

  /// 🚀 更新 Canvas 快取（增量更新）
  Future<void> _updateCache() async {
    if (_isCacheBuilding) return;
    _isCacheBuilding = true;

    try {
      final newStrokeCount = _drawingData.strokes.length;

      // 如果沒有新筆劃，不需要更新
      if (newStrokeCount == _cachedStrokeCount) {
        _isCacheBuilding = false;
        return;
      }

      // 取得畫布尺寸
      final size = MediaQuery.of(context).size;
      final width = (widget.width ?? size.width).toInt();
      final height = (widget.height ?? size.height).toInt();

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
      } else {
        // 🎨 渲染新增的筆劃
        for (int i = _cachedStrokeCount; i < newStrokeCount; i++) {
          final stroke = _drawingData.strokes[i];
          _drawStrokeToCanvas(canvas, stroke);
        }
      }

      // 轉換為 Image
      final picture = recorder.endRecording();
      final newImage = await picture.toImage(width, height);

      // 釋放舊快取（但不要 dispose 歷史中的 Image）
      final oldCache = _cachedBackground;
      final isInHistory = _cacheHistory.contains(oldCache);
      if (oldCache != null && !isInHistory) {
        oldCache.dispose();
      }

      // 更新快取
      if (mounted) {
        setState(() {
          _cachedBackground = newImage;
          _cachedStrokeCount = newStrokeCount;
        });
      }
    } catch (e) {
      print('❌ 快取更新失敗: $e');
    } finally {
      _isCacheBuilding = false;
    }
  }

  /// 🎯 更新快取並清理當前筆劃快取
  Future<void> _updateCacheAndCleanup() async {
    // 先更新背景快取（會使用當前筆劃快取）
    await _updateCache();

    // 更新完成後，清除當前筆劃快取
    if (mounted) {
      setState(() {
        _currentStrokeCache?.dispose();
        _currentStrokeCache = null;
        _currentStrokeCachedPoints = 0;
      });
    }
  }

  ///  重建整個快取（橡皮擦專用：快速重建）
  Future<void> _rebuildCache() async {
    if (_isCacheBuilding) return;
    _isCacheBuilding = true;

    try {
      if (_drawingData.strokes.isEmpty) {
        // 沒有筆劃時，清除快取（但不要 dispose 歷史中的 Image）
        final oldCache = _cachedBackground;
        final isInHistory = _cacheHistory.contains(oldCache);
        if (oldCache != null && !isInHistory) {
          oldCache.dispose();
        }
        if (mounted) {
          setState(() {
            _cachedBackground = null;
            _cachedStrokeCount = 0;
          });
        }
        _isCacheBuilding = false;
        return;
      }

      // 取得畫布尺寸
      final size = MediaQuery.of(context).size;
      final width = (widget.width ?? size.width).toInt();
      final height = (widget.height ?? size.height).toInt();

      // 建立新的 recorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 繪製所有剩餘筆劃（橡皮擦後只執行一次）
      for (final stroke in _drawingData.strokes) {
        _drawStrokeToCanvas(canvas, stroke);
      }

      // 轉換為 Image
      final picture = recorder.endRecording();
      final newImage = await picture.toImage(width, height);

      if (mounted) {
        setState(() {
          _cachedBackground = newImage;
          _cachedStrokeCount = _drawingData.strokes.length;
        });
      }
    } catch (e) {
      print('❌ 快取重建失敗: $e');
    } finally {
      _isCacheBuilding = false;
    }
  }

  /// � 增量更新當前筆劃快取
  Future<void> _updateCurrentStrokeCache() async {
    // 防止重複建立
    if (_isCurrentStrokeCacheBuilding) return;

    // 如果沒有新點，不需要更新
    if (_currentStroke.length <= _currentStrokeCachedPoints) return;

    // 如果點數太少（<3個），直接渲染不快取
    if (_currentStroke.length < 3) return;

    _isCurrentStrokeCacheBuilding = true;

    try {
      // 取得畫布尺寸
      final size = MediaQuery.of(context).size;
      final width = (widget.width ?? size.width).toInt();
      final height = (widget.height ?? size.height).toInt();

      // 建立新的 recorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 🎨 先繪製舊的快取（如果有）
      if (_currentStrokeCache != null) {
        canvas.drawImage(_currentStrokeCache!, Offset.zero, Paint());
      }

      // 🎨 只繪製新增的點
      final painter = _DrawingPainter(
        strokes: [],
        currentStroke: _currentStroke.sublist(_currentStrokeCachedPoints),
        currentColor: _selectedColor,
        currentStrokeWidth: _strokeWidth,
        isErasing: false,
        texturePool: _texturePool,
        isPoolReady: _isPoolReady,
        cachedBackground: null,
      );
      painter.paint(canvas, Size(width.toDouble(), height.toDouble()));

      // 轉換為 Image
      final picture = recorder.endRecording();
      final newImage = await picture.toImage(width, height);

      // 釋放舊快取
      _currentStrokeCache?.dispose();

      // 更新快取
      if (mounted) {
        setState(() {
          _currentStrokeCache = newImage;
          _currentStrokeCachedPoints = _currentStroke.length;
        });
      }
    } catch (e) {
      print('❌ 當前筆劃快取更新失敗: $e');
    } finally {
      _isCurrentStrokeCacheBuilding = false;
    }
  }

  /// �🎨 將單一筆劃繪製到 Canvas
  void _drawStrokeToCanvas(Canvas canvas, DrawingStroke stroke) {
    // ✨ 使用和即時繪製完全相同的渲染路徑
    // 關鍵：創建臨時 Painter，但不使用紋理池（確保顏色正確）
    final painter = _DrawingPainter(
      strokes: [],
      currentStroke: [],
      currentColor: stroke.color,
      currentStrokeWidth: stroke.strokeWidth,
      isErasing: false,
      texturePool: null,           // 🔥 不使用紋理池，確保顏色正確
      isPoolReady: false,          // 🔥 強制使用即時渲染
      cachedBackground: null,
    );
    
    // 使用 Painter 的渲染方法，會調用 _drawFullStampAtPoint（確定性8層渲染）
    painter._drawFullTextureBrush(
      canvas,
      stroke.points,
      stroke.color,
      stroke.strokeWidth,
      useSkipping: true,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: Container(
            width: widget.width ?? double.infinity,
            constraints: BoxConstraints(
              minHeight: 200,
              maxHeight: widget.height ?? 300,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: widget.isReadOnly
                  ? BorderRadius.circular(12)
                  : const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
            ),
            child: ClipRRect(
              borderRadius: widget.isReadOnly
                  ? BorderRadius.circular(12)
                  : const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: _DrawingPainter(
                    strokes: _drawingData.strokes,
                    currentStroke: _currentStroke,
                    currentColor: _isEraser
                        ? Colors.grey.withOpacity(0.3)
                        : _selectedColor,
                    currentStrokeWidth: _strokeWidth, // 橡皮擦粗細跟隨畫筆
                    isErasing: _isEraser,
                    texturePool: _texturePool,
                    isPoolReady: _isPoolReady,
                    cachedBackground: _cachedBackground, // 🚀 傳入已完成筆劃快取
                    currentStrokeCache: _currentStrokeCache, // 🎯 傳入當前筆劃快取
                    currentStrokeCachedPoints:
                        _currentStrokeCachedPoints, // 🎯 已快取的點數
                  ),
                  child: Container(),
                ),
              ),
            ),
          ),
        ),
        if (!widget.isReadOnly)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(AppLocalizations.of(context)!.errorDrawingColorLabel,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: _buildColorButtons()),
                        )),
                  ],
                ),
                const Divider(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(AppLocalizations.of(context)!.errorDrawingSizeLabel,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: _buildSizeButtons()),
                        )),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _buildColorButtons() {
    final colors = [
      const Color(0xFF1E88E5),
      const Color(0xFF26C6DA),
      const Color(0xFFFFFFFF),
      const Color(0xFFD7CCC8),
      const Color(0xFF8D6E63),
      const Color(0xFF4CAF50),
    ];

    return colors.map((color) {
      final isSelected = _selectedColor == color && !_isEraser;
      return GestureDetector(
        onTap: () async {
          setState(() {
            _selectedColor = color;
            _isEraser = false;
            _isPoolReady = false; // 標記為未準備
          });
          await _rebuildTexturePool(); // 重建紋理池
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.blue[700]! : Colors.grey[400]!,
              width: isSelected ? 3 : 2,
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildSizeButtons() {
    final sizes = [8.0, 12.0, 18.0, 25.0];
    final buttons = sizes.map((width) {
      final isSelected = _strokeWidth == width && !_isEraser;
      return GestureDetector(
        onTap: () async {
          setState(() {
            _strokeWidth = width;
            _isEraser = false;
            _isPoolReady = false; // 標記為未準備
          });
          await _rebuildTexturePool(); // 重建紋理池
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[50] : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
                color: isSelected ? Colors.blue[400]! : Colors.grey[300]!,
                width: 2),
          ),
          child: Center(
            child: Container(
              width: (width / 25 * 14).clamp(4.0, 14.0),
              height: (width / 25 * 14).clamp(4.0, 14.0),
              decoration: BoxDecoration(
                  color: Colors.grey[800], shape: BoxShape.circle),
            ),
          ),
        ),
      );
    }).toList();

    buttons.add(GestureDetector(
      onTap: () => setState(() => _isEraser = !_isEraser),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _isEraser ? Colors.pink[50] : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
              color: _isEraser ? Colors.pink[400]! : Colors.grey[300]!,
              width: 2),
        ),
        child: Icon(Icons.auto_fix_high,
            size: 20, color: _isEraser ? Colors.pink[700] : Colors.grey[600]),
      ),
    ));

    buttons.add(GestureDetector(
      onTap: _drawingData.strokes.isEmpty ? null : _undoLastStroke,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: Icon(Icons.undo,
            size: 20,
            color: _drawingData.strokes.isEmpty
                ? Colors.grey[300]
                : Colors.grey[700]),
      ),
    ));

    return buttons;
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isErasing;
  final BrushTexturePool? texturePool;
  final bool isPoolReady;
  final ui.Image? cachedBackground; // 🚀 已完成筆劃的快取
  final ui.Image? currentStrokeCache; // 🎯 當前筆劃的快取
  final int currentStrokeCachedPoints; // 🎯 當前筆劃已快取的點數

  // Paint 緩存
  final Paint _paintCache = Paint()..style = PaintingStyle.fill;

  _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentStrokeWidth,
    this.isErasing = false,
    this.texturePool,
    this.isPoolReady = false,
    this.cachedBackground, // 🚀 傳入已完成筆劃快取
    this.currentStrokeCache, // 🎯 傳入當前筆劃快取
    this.currentStrokeCachedPoints = 0, // 🎯 傳入已快取的點數
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 🚀 優先使用快取背景（已完成的筆劃）
    if (cachedBackground != null) {
      // 直接繪製快取的背景圖片
      canvas.drawImage(cachedBackground!, Offset.zero, Paint());
    } else {
      // 沒有快取時，渲染所有已完成的筆劃
      for (final stroke in strokes) {
        _drawFullTextureBrush(
            canvas, stroke.points, stroke.color, stroke.strokeWidth,
            useSkipping: true);
      }
    }

    // � 渲染當前正在繪製的筆劃（使用增量快取）
    if (currentStroke.isNotEmpty) {
      if (isErasing) {
        // 🧹 橡皮擦：使用簡單原始筆刷
        _drawSimpleBrush(
            canvas, currentStroke, currentColor, currentStrokeWidth);
      } else {
        // 🎨 一般繪圖：使用增量快取
        if (currentStrokeCache != null && currentStrokeCachedPoints > 0) {
          canvas.drawImage(currentStrokeCache!, Offset.zero, Paint());

          // 只渲染新增的點（從快取點數開始）
          if (currentStroke.length > currentStrokeCachedPoints) {
            final newPoints = currentStroke.sublist(currentStrokeCachedPoints);
            _drawFullTextureBrush(
                canvas, newPoints, currentColor, currentStrokeWidth,
                useSkipping: false);
          }
        } else {
          // 沒有快取時，渲染所有點
          _drawFullTextureBrush(
              canvas, currentStroke, currentColor, currentStrokeWidth,
              useSkipping: false);
        }
      }
    }
  }

  void _drawFullStampAtPoint(Canvas canvas, Offset point, Color color,
      double strokeWidth, int pointIndex) {
    // 🎯 完整8層肌理渲染 - 確定性算法（無隨機數）
    
    // ✨ 確定性偽隨機數生成器 - 基於座標和索引
    double deterministicRandom(int seed) {
      // 使用數學函數生成 [0,1) 的確定性值
      final hash = ((seed * 2654435761) ^ (seed >> 16)) & 0x7FFFFFFF;
      return (hash % 10000) / 10000.0;
    }
    
    int seedCounter = 0;
    double nextRandom() {
      final seed = point.dx.toInt() * 73856093 ^ 
                   point.dy.toInt() * 19349663 ^ 
                   pointIndex * 83492791 ^ 
                   seedCounter;
      seedCounter++;
      return deterministicRandom(seed);
    }
    
    int nextInt(int max) {
      return (nextRandom() * max).floor();
    }

    Color getHueVariation(Color baseColor, double variation) {
      final hslColor = HSLColor.fromColor(baseColor);
      final hueShift = (nextRandom() - 0.5) * variation;
      return hslColor.withHue((hslColor.hue + hueShift) % 360).toColor();
    }

    // 第0層: 紙張纖維紋理 (8-12條)
    final fiberCount = 8 + nextInt(5);
    for (int j = 0; j < fiberCount; j++) {
      final baseAngle = nextRandom() * 2 * math.pi;
      final angleVariation = (nextRandom() - 0.5) * 0.4;
      final fiberAngle = baseAngle + angleVariation;
      final fiberLength = strokeWidth * (0.6 + nextRandom() * 0.9);
      final fiberThickness = strokeWidth * 0.05 * (0.5 + nextRandom());
      final startOffsetX = (nextRandom() - 0.5) * strokeWidth * 1.2;
      final startOffsetY = (nextRandom() - 0.5) * strokeWidth * 1.2;
      final startPoint =
          Offset(point.dx + startOffsetX, point.dy + startOffsetY);
      final endPoint = Offset(
        startPoint.dx + math.cos(fiberAngle) * fiberLength,
        startPoint.dy + math.sin(fiberAngle) * fiberLength,
      );
      final fiberColor = getHueVariation(color, 15);
      _paintCache
        ..color = fiberColor.withOpacity(0.02 + nextRandom() * 0.04)
        ..strokeWidth = fiberThickness
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(startPoint, endPoint, _paintCache);
    }

    // 第1層: 底層擴散 (12-20個點)
    final spreadCount = 12 + nextInt(9);
    for (int i = 0; i < spreadCount; i++) {
      final angleBase = nextRandom() * 2 * math.pi;
      final angleNoise = (nextRandom() - 0.5) * 0.8;
      final angle = angleBase + angleNoise;
      final distFactor1 = math.pow(nextRandom(), 0.4).toDouble();
      final distFactor2 = nextRandom();
      final distFactor = (distFactor1 * 0.7 + distFactor2 * 0.3);
      final maxDistance = strokeWidth * (2.2 + nextRandom() * 1.4);
      final distance = distFactor * maxDistance;
      final offsetX = math.cos(angle) * distance;
      final offsetY = math.sin(angle) * distance;
      final opacity = 0.03 + (1 - distFactor) * 0.12;
      final dotSize = strokeWidth * (0.25 + nextRandom() * 0.45);
      final dotColor = getHueVariation(color, 10);
      _paintCache.color = dotColor.withOpacity(opacity);
      _paintCache.style = PaintingStyle.fill;
      canvas.drawCircle(
          Offset(point.dx + offsetX, point.dy + offsetY), dotSize, _paintCache);
    }

    // 第2層: 顆粒層 (8-16個點)
    final particleCount = 8 + nextInt(9);
    for (int i = 0; i < particleCount; i++) {
      final offsetX =
          (math.pow(nextRandom(), 0.6) - 0.5) * 2 * strokeWidth * 1.6;
      final offsetY =
          (math.pow(nextRandom(), 0.6) - 0.5) * 2 * strokeWidth * 1.6;
      final opacity = 0.12 + nextRandom() * 0.32;
      final sizeVariation = nextRandom();
      final particleSize =
          strokeWidth * (0.2 + math.pow(sizeVariation, 0.7) * 0.6);
      final particleColor = getHueVariation(color, 12);
      _paintCache.color = particleColor.withOpacity(opacity);
      canvas.drawCircle(Offset(point.dx + offsetX, point.dy + offsetY),
          particleSize, _paintCache);
    }

    // 第3層: 刮擦紋理 (2-4條刮痕) - 只在有方向的地方添加
    if (pointIndex > 0) {
      final scratchCount = 2 + nextInt(3);
      for (int j = 0; j < scratchCount; j++) {
        final angle = nextRandom() * 2 * math.pi;
        final offset = (j - scratchCount / 2) * strokeWidth * 0.3;
        final perpAngle = angle + math.pi / 2;
        final offsetX = math.cos(perpAngle) * offset;
        final offsetY = math.sin(perpAngle) * offset;
        final scratchLength = strokeWidth * (0.5 + nextRandom() * 0.5);
        final scratchOpacity = 0.08 + nextRandom() * 0.15;
        final scratchWidth = strokeWidth * (0.1 + nextRandom() * 0.15);
        final scratchColor = getHueVariation(color, 8);
        final p1 = Offset(point.dx + offsetX, point.dy + offsetY);
        final p2 = Offset(p1.dx + math.cos(angle) * scratchLength,
            p1.dy + math.sin(angle) * scratchLength);
        _paintCache
          ..color = scratchColor.withOpacity(scratchOpacity)
          ..strokeWidth = scratchWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(p1, p2, _paintCache);
      }
    }

    // 第4層: 厚塗堆積 (5-10個層)
    final layerCount = 5 + nextInt(6);
    for (int j = 0; j < layerCount; j++) {
      final clusterFactor = math.pow(nextRandom(), 0.5).toDouble();
      final offsetX =
          (nextRandom() - 0.5) * strokeWidth * 1.1 * clusterFactor;
      final offsetY =
          (nextRandom() - 0.5) * strokeWidth * 1.1 * clusterFactor;
      final opacity = 0.15 + nextRandom() * 0.35;
      final layerSize =
          strokeWidth * (0.3 + math.pow(nextRandom(), 0.6) * 0.5);
      final layerColor = getHueVariation(color, 10);
      _paintCache.color = layerColor.withOpacity(opacity);
      _paintCache.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(point.dx + offsetX, point.dy + offsetY),
          layerSize, _paintCache);
    }

    // 第5層: 主體核心
    _paintCache.color = getHueVariation(color, 6).withOpacity(0.55);
    canvas.drawCircle(point, strokeWidth * 0.5, _paintCache);

    // 第6層: 高光 (2-4個)
    final highlightCount = 2 + nextInt(3);
    for (int i = 0; i < highlightCount; i++) {
      final offsetX = (nextRandom() - 0.75) * strokeWidth * 0.5;
      final offsetY = (nextRandom() - 0.75) * strokeWidth * 0.5;
      final highlightSize = strokeWidth * (0.2 + nextRandom() * 0.2);
      final highlightColor = getHueVariation(color, 8);
      _paintCache.color =
          highlightColor.withOpacity(0.35 + nextRandom() * 0.25);
      canvas.drawCircle(Offset(point.dx + offsetX, point.dy + offsetY),
          highlightSize, _paintCache);
    }

    // 第7層: 陰影 (1-3個)
    final shadowCount = 1 + nextInt(3);
    for (int j = 0; j < shadowCount; j++) {
      final shadowX = (nextRandom() + 0.15) * strokeWidth * 0.4;
      final shadowY = (nextRandom() + 0.15) * strokeWidth * 0.4;
      final shadowSize = strokeWidth * (0.15 + nextRandom() * 0.15);
      final shadowColor = getHueVariation(color, 8);
      _paintCache.color =
          shadowColor.withOpacity(0.15 + nextRandom() * 0.12);
      canvas.drawCircle(Offset(point.dx + shadowX, point.dy + shadowY),
          shadowSize, _paintCache);
    }

    // 第8層: 邊緣毛邊 (3-6個點)
    final edgeCount = 3 + nextInt(4);
    for (int i = 0; i < edgeCount; i++) {
      final angleBase = (i / edgeCount) * 2 * math.pi;
      final angleNoise = (nextRandom() - 0.5) * 0.6;
      final angle = angleBase + angleNoise;
      final distanceVariation = 0.6 + nextRandom() * 1.2;
      final distance = strokeWidth * distanceVariation;
      final offsetX = math.cos(angle) * distance;
      final offsetY = math.sin(angle) * distance;
      final edgeSize =
          strokeWidth * (0.08 + math.pow(nextRandom(), 0.7) * 0.25);
      final edgeOpacity = 0.08 + nextRandom() * 0.22;
      final edgeColor = getHueVariation(color, 12);
      _paintCache.color = edgeColor.withOpacity(edgeOpacity);
      canvas.drawCircle(Offset(point.dx + offsetX, point.dy + offsetY),
          edgeSize, _paintCache);
    }
  }

  // 完整筆劃渲染 (用於已完成的筆劃)
  void _drawFullTextureBrush(
      Canvas canvas, List<Offset> points, Color color, double strokeWidth,
      {bool useSkipping = true}) {
    if (points.isEmpty) return;

    // 🎯 智能跳點策略 - 平衡質量與性能
    int pointStep = 1; // 預設不跳點

    if (useSkipping) {
      // 只有已完成的筆劃才使用跳點優化
      if (points.length <= 20) {
        pointStep = 1; // 短筆劃：全部渲染
      } else if (points.length <= 80) {
        pointStep = 2; // 中等筆劃：跳1點
      } else {
        pointStep = 3; // 長筆劃：跳2點
      }
    }

    for (int i = 0; i < points.length; i += pointStep) {
      // 🚀 使用紋理池優化渲染
      if (isPoolReady && texturePool != null) {
        _drawStampFromPool(canvas, points[i], strokeWidth, i);
      } else {
        // 降級方案：使用簡化渲染（當前筆劃）或完整渲染（已完成筆劃）
        if (!useSkipping) {
          // 當前筆劃：使用快速簡化版本
          _drawQuickStamp(canvas, points[i], color, strokeWidth);
        } else {
          // 已完成筆劃：使用完整8層渲染
          _drawFullStampAtPoint(canvas, points[i], color, strokeWidth, i);
        }
      }
    }
  }

  /// ⚡ 快速簡化版 stamp - 用於即時顯示當前筆劃
  void _drawQuickStamp(
      Canvas canvas, Offset point, Color color, double strokeWidth) {
    // 只渲染核心 3 層，保證速度
    // 確定性偽隨機數
    double deterministicRandom(int seed) {
      final hash = ((seed * 2654435761) ^ (seed >> 16)) & 0x7FFFFFFF;
      return (hash % 10000) / 10000.0;
    }
    
    int seedCounter = 0;
    double nextRandom() {
      final seed = point.dx.toInt() * 73856093 ^ 
                   point.dy.toInt() * 19349663 ^ 
                   seedCounter;
      seedCounter++;
      return deterministicRandom(seed);
    }

    // 第1層: 底層擴散（簡化）
    const diffusionCount = 6; // 減少數量
    for (int i = 0; i < diffusionCount; i++) {
      final angle = (i / diffusionCount) * 2 * math.pi;
      final distance = strokeWidth * (0.3 + nextRandom() * 0.5);
      final offsetX = math.cos(angle) * distance;
      final offsetY = math.sin(angle) * distance;
      final size = strokeWidth * 0.2;
      _paintCache.color = color.withOpacity(0.1);
      canvas.drawCircle(
          Offset(point.dx + offsetX, point.dy + offsetY), size, _paintCache);
    }

    // 第2層: 主體核心
    _paintCache.color = color.withOpacity(0.7);
    canvas.drawCircle(point, strokeWidth * 0.5, _paintCache);

    // 第3層: 高光
    _paintCache.color = color.withOpacity(0.4);
    canvas.drawCircle(
        Offset(point.dx - strokeWidth * 0.15, point.dy - strokeWidth * 0.15),
        strokeWidth * 0.25,
        _paintCache);
  }

  /// 🧹 簡單原始筆刷 - 用於橡皮擦，不經過任何運算
  void _drawSimpleBrush(
      Canvas canvas, List<Offset> points, Color color, double strokeWidth) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (points.length == 1) {
      // 單點：畫圓
      canvas.drawCircle(
          points[0], strokeWidth / 2, paint..style = PaintingStyle.fill);
    } else {
      // 多點：連線
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    }
  }

  /// 🚀 從紋理池繪製 stamp (O(1) 複雜度)
  void _drawStampFromPool(
      Canvas canvas, Offset point, double strokeWidth, int pointIndex) {
    // ✨ 確定性紋理選擇 - 基於座標和索引
    if (texturePool!._textures.isEmpty) return;
    
    final textureIndex = (point.dx.toInt() * 73856093 ^ 
                         point.dy.toInt() * 19349663 ^ 
                         pointIndex * 83492791).abs() % texturePool!._textures.length;
    final texture = texturePool!._textures[textureIndex];

    // 確定性偽隨機數
    double deterministicRandom(int seed) {
      final hash = ((seed * 2654435761) ^ (seed >> 16)) & 0x7FFFFFFF;
      return (hash % 10000) / 10000.0;
    }
    
    int seedCounter = 0;
    double nextRandom() {
      final seed = point.dx.toInt() * 73856093 ^ 
                   point.dy.toInt() * 19349663 ^ 
                   pointIndex * 83492791 ^ 
                   seedCounter;
      seedCounter++;
      return deterministicRandom(seed);
    }

    // 計算 stamp 實際大小
    final stampDisplaySize = strokeWidth * 4;

    canvas.save();

    // 移動到繪製點
    canvas.translate(point.dx, point.dy);

    // 🎨 輕微旋轉 (±8°)
    final rotation = (nextRandom() - 0.5) * 0.28; // ±8° ≈ 0.14 rad
    canvas.rotate(rotation);

    // 🎨 微縮放 (95%~105%)
    final scale = 0.95 + nextRandom() * 0.1;
    canvas.scale(scale);

    // 居中 stamp
    canvas.translate(-stampDisplaySize / 2, -stampDisplaySize / 2);

    // 繪製紋理
    final srcRect = Rect.fromLTWH(
        0, 0, texture.width.toDouble(), texture.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, stampDisplaySize, stampDisplaySize);

    canvas.drawImageRect(texture, srcRect, dstRect, _paintCache);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) {
    // 🎯 關鍵：只要有任何變化就重繪
    // ✅ 現在 currentStroke 每次都是新的 List，可以正確比較
    return oldDelegate.strokes.length != strokes.length ||
        oldDelegate.currentStroke.length != currentStroke.length ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.currentStrokeWidth != currentStrokeWidth ||
        oldDelegate.cachedBackground != cachedBackground ||
        oldDelegate.currentStrokeCache != currentStrokeCache || // 🎯 當前筆劃快取變化
        oldDelegate.currentStrokeCachedPoints !=
            currentStrokeCachedPoints; // 🎯 快取點數變化
  }
}

/// 🎨 筆刷紋理快取池
class BrushTexturePool {
  static const int _poolSize = 16; // 16 張紋理足夠隨機
  static const int _stampSize = 128; // 紋理圖片尺寸

  List<ui.Image> _textures = [];

  bool get isReady => _textures.length == _poolSize;

  /// 建立紋理池
  Future<void> buildPool(Color color, double strokeWidth) async {
    // 清除舊紋理
    _disposeTextures();
    _textures = [];

    // 建立 16 張不同的紋理
    final List<Future<ui.Image>> futures = [];
    for (int i = 0; i < _poolSize; i++) {
      futures.add(_createStamp(color, strokeWidth, i * 1000));
    }

    _textures = await Future.wait(futures);
  }

  /// 建立單一紋理 stamp
  Future<ui.Image> _createStamp(
      Color color, double strokeWidth, int seed) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..style = PaintingStyle.fill;

    final center = Offset(_stampSize / 2, _stampSize / 2);
    final scale = _stampSize / (strokeWidth * 4); // 縮放到合適大小

    // ✨ 確定性偽隨機數生成器
    double deterministicRandom(int s) {
      final hash = ((s * 2654435761) ^ (s >> 16)) & 0x7FFFFFFF;
      return (hash % 10000) / 10000.0;
    }
    
    int seedCounter = 0;
    double nextRandom() {
      final s = seed * 73856093 ^ seedCounter * 19349663;
      seedCounter++;
      return deterministicRandom(s);
    }
    
    int nextInt(int max) {
      return (nextRandom() * max).floor();
    }

    Color getHueVariation(Color baseColor, double variation) {
      final hslColor = HSLColor.fromColor(baseColor);
      final hueShift = (nextRandom() - 0.5) * variation;
      return hslColor.withHue((hslColor.hue + hueShift) % 360).toColor();
    }

    // 🎨 繪製 8 層肌理（整合到單一 stamp）

    // 第0層: 紙張纖維紋理
    final fiberCount = 8 + nextInt(5);
    for (int j = 0; j < fiberCount; j++) {
      final baseAngle = nextRandom() * 2 * math.pi;
      final angleVariation = (nextRandom() - 0.5) * 0.4;
      final fiberAngle = baseAngle + angleVariation;
      final fiberLength =
          strokeWidth * scale * (0.6 + nextRandom() * 0.9);
      final fiberThickness =
          strokeWidth * scale * 0.05 * (0.5 + nextRandom());
      final startOffsetX =
          (nextRandom() - 0.5) * strokeWidth * scale * 1.2;
      final startOffsetY =
          (nextRandom() - 0.5) * strokeWidth * scale * 1.2;
      final startPoint =
          Offset(center.dx + startOffsetX, center.dy + startOffsetY);
      final endPoint = Offset(
        startPoint.dx + math.cos(fiberAngle) * fiberLength,
        startPoint.dy + math.sin(fiberAngle) * fiberLength,
      );
      final fiberColor = getHueVariation(color, 15);
      paint
        ..color = fiberColor.withOpacity(0.02 + nextRandom() * 0.04)
        ..strokeWidth = fiberThickness
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(startPoint, endPoint, paint);
    }

    // 第1層: 底層擴散
    final spreadCount = 12 + nextInt(9);
    for (int i = 0; i < spreadCount; i++) {
      final angle = nextRandom() * 2 * math.pi;
      final distFactor = math.pow(nextRandom(), 0.4).toDouble();
      final maxDistance =
          strokeWidth * scale * (2.2 + nextRandom() * 1.4);
      final distance = distFactor * maxDistance;
      final offsetX = math.cos(angle) * distance;
      final offsetY = math.sin(angle) * distance;
      final opacity = 0.03 + (1 - distFactor) * 0.12;
      final dotSize = strokeWidth * scale * (0.25 + nextRandom() * 0.45);
      final dotColor = getHueVariation(color, 10);
      paint.color = dotColor.withOpacity(opacity);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(
          Offset(center.dx + offsetX, center.dy + offsetY), dotSize, paint);
    }

    // 第2層: 顆粒層
    final particleCount = 8 + nextInt(9);
    for (int i = 0; i < particleCount; i++) {
      final offsetX =
          (nextRandom() - 0.5) * 2 * strokeWidth * scale * 1.6;
      final offsetY =
          (nextRandom() - 0.5) * 2 * strokeWidth * scale * 1.6;
      final opacity = 0.12 + nextRandom() * 0.32;
      final particleSize = strokeWidth *
          scale *
          (0.2 + math.pow(nextRandom(), 0.7) * 0.6);
      final particleColor = getHueVariation(color, 12);
      paint.color = particleColor.withOpacity(opacity);
      canvas.drawCircle(Offset(center.dx + offsetX, center.dy + offsetY),
          particleSize, paint);
    }

    // 第3層: 刮擦紋理
    final scratchCount = 2 + nextInt(3);
    for (int j = 0; j < scratchCount; j++) {
      final angle = nextRandom() * 2 * math.pi;
      final offset = (j - scratchCount / 2) * strokeWidth * scale * 0.3;
      final perpAngle = angle + math.pi / 2;
      final offsetX = math.cos(perpAngle) * offset;
      final offsetY = math.sin(perpAngle) * offset;
      final scratchLength =
          strokeWidth * scale * (0.5 + nextRandom() * 0.5);
      final scratchOpacity = 0.08 + nextRandom() * 0.15;
      final scratchWidth =
          strokeWidth * scale * (0.1 + nextRandom() * 0.15);
      final scratchColor = getHueVariation(color, 8);
      final p1 = Offset(center.dx + offsetX, center.dy + offsetY);
      final p2 = Offset(p1.dx + math.cos(angle) * scratchLength,
          p1.dy + math.sin(angle) * scratchLength);
      paint
        ..color = scratchColor.withOpacity(scratchOpacity)
        ..strokeWidth = scratchWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(p1, p2, paint);
    }

    // 第4層: 厚塗堆積
    final layerCount = 5 + nextInt(6);
    for (int j = 0; j < layerCount; j++) {
      final offsetX = (nextRandom() - 0.5) * strokeWidth * scale * 1.1;
      final offsetY = (nextRandom() - 0.5) * strokeWidth * scale * 1.1;
      final opacity = 0.15 + nextRandom() * 0.35;
      final layerSize = strokeWidth *
          scale *
          (0.3 + math.pow(nextRandom(), 0.6) * 0.5);
      final layerColor = getHueVariation(color, 10);
      paint.color = layerColor.withOpacity(opacity);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(
          Offset(center.dx + offsetX, center.dy + offsetY), layerSize, paint);
    }

    // 第5層: 主體核心
    paint.color = getHueVariation(color, 6).withOpacity(0.55);
    canvas.drawCircle(center, strokeWidth * scale * 0.5, paint);

    // 第6層: 高光
    final highlightCount = 2 + nextInt(3);
    for (int i = 0; i < highlightCount; i++) {
      final offsetX = (nextRandom() - 0.75) * strokeWidth * scale * 0.5;
      final offsetY = (nextRandom() - 0.75) * strokeWidth * scale * 0.5;
      final highlightSize =
          strokeWidth * scale * (0.2 + nextRandom() * 0.2);
      final highlightColor = getHueVariation(color, 8);
      paint.color =
          highlightColor.withOpacity(0.35 + nextRandom() * 0.25);
      canvas.drawCircle(Offset(center.dx + offsetX, center.dy + offsetY),
          highlightSize, paint);
    }

    // 第7層: 陰影
    final shadowCount = 1 + nextInt(3);
    for (int j = 0; j < shadowCount; j++) {
      final shadowX = (nextRandom() + 0.15) * strokeWidth * scale * 0.4;
      final shadowY = (nextRandom() + 0.15) * strokeWidth * scale * 0.4;
      final shadowSize =
          strokeWidth * scale * (0.15 + nextRandom() * 0.15);
      final shadowColor = getHueVariation(color, 8);
      paint.color = shadowColor.withOpacity(0.15 + nextRandom() * 0.12);
      canvas.drawCircle(
          Offset(center.dx + shadowX, center.dy + shadowY), shadowSize, paint);
    }

    // 第8層: 邊緣毛邊
    final edgeCount = 3 + nextInt(4);
    for (int i = 0; i < edgeCount; i++) {
      final angleBase = (i / edgeCount) * 2 * math.pi;
      final angleNoise = (nextRandom() - 0.5) * 0.6;
      final angle = angleBase + angleNoise;
      final distanceVariation = 0.6 + nextRandom() * 1.2;
      final distance = strokeWidth * scale * distanceVariation;
      final offsetX = math.cos(angle) * distance;
      final offsetY = math.sin(angle) * distance;
      final edgeSize = strokeWidth *
          scale *
          (0.08 + math.pow(nextRandom(), 0.7) * 0.25);
      final edgeOpacity = 0.08 + nextRandom() * 0.22;
      final edgeColor = getHueVariation(color, 12);
      paint.color = edgeColor.withOpacity(edgeOpacity);
      canvas.drawCircle(
          Offset(center.dx + offsetX, center.dy + offsetY), edgeSize, paint);
    }

    // 轉換為圖片
    final picture = recorder.endRecording();
    return await picture.toImage(_stampSize, _stampSize);
  }

  /// 清理紋理
  void _disposeTextures() {
    for (var texture in _textures) {
      texture.dispose();
    }
  }

  /// 釋放資源
  void dispose() {
    _disposeTextures();
    _textures = [];
  }
}

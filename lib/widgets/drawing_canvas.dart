import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';
import '../models/drawing_data.dart';

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
  double _strokeWidth = 8.0; // 預設最細筆刷
  bool _isEraser = false;
  BrushType _brushType = BrushType.texture;
  
  // 快取系統相關變數
  BrushTexturePool? _texturePool;
  bool _isPoolReady = false;
  ui.Image? _cachedBackground;
  ui.Image? _currentStrokeCache;
  int _cachedStrokeCount = 0;
  int _currentStrokeCachedPoints = 0;
  bool _isCacheBuilding = false;
  
  // 歷史記錄系統（筆劃 + 快取）
  final List<List<DrawingStroke>> _history = [];
  final List<ui.Image?> _cacheHistory = [];
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    _drawingData = widget.initialDrawing;
    
    // 初始化紋理池
    _initializeTexturePool();
    
    // 如果有舊紀錄，建立初始快取
    if (_drawingData.strokes.isNotEmpty) {
      Future.microtask(() => _rebuildCache().then((_) {
        if (mounted) _saveToHistory();
      }));
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

  void _onPanStart(DragStartDetails details) {
    if (widget.isReadOnly) return;
    setState(() {
      _currentStroke = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.isReadOnly) return;
    setState(() {
      _currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.isReadOnly) return;

    if (_currentStroke.isNotEmpty) {
      if (_isEraser) {
        // 橡皮擦：固定大小25.0，碰到整條刪除
        const eraserRadius = 25.0;
        final beforeCount = _drawingData.strokes.length;
        
        setState(() {
          _drawingData.strokes.removeWhere((stroke) {
            return _currentStroke.any((eraserPoint) {
              return stroke.points.any((strokePoint) {
                final distance = (eraserPoint - strokePoint).distance;
                final threshold = eraserRadius + (stroke.strokeWidth / 2);
                return distance < threshold;
              });
            });
          });
          _currentStroke = [];
        });
        
        // 如果有刪除筆劃，重建快取並保存到歷史
        if (_drawingData.strokes.length < beforeCount) {
          _cachedStrokeCount = _drawingData.strokes.length;
          _rebuildCache().then((_) {
            if (mounted) {
              _saveToHistory();
            }
          });
        }
      } else {
        // 正常繪圖
        final stroke = DrawingStroke(
          points: List.from(_currentStroke),
          color: _selectedColor,
          strokeWidth: _strokeWidth,
          brushType: _brushType,
        );
        setState(() {
          _drawingData.strokes.add(stroke);
          _currentStroke = [];
        });
        
        // 先更新背景快取，再保存到歷史
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
  
  /// 增量更新背景快取
  Future<void> _updateCache() async {
    if (_isCacheBuilding) return;
    _isCacheBuilding = true;

    try {
      final newStrokeCount = _drawingData.strokes.length;
      if (newStrokeCount == _cachedStrokeCount) {
        _isCacheBuilding = false;
        return;
      }

      final size = MediaQuery.of(context).size;
      final width = (widget.width ?? size.width).toInt();
      final height = (widget.height ?? size.height).toInt();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 繪製已快取的背景
      if (_cachedBackground != null) {
        canvas.drawImage(_cachedBackground!, Offset.zero, Paint());
      }

      // 只繪製新增的筆劃
      for (int i = _cachedStrokeCount; i < newStrokeCount; i++) {
        _drawStrokeToCanvas(canvas, _drawingData.strokes[i]);
      }
      
      // 繪製當前筆劃快取
      if (_currentStrokeCache != null) {
        canvas.drawImage(_currentStrokeCache!, Offset.zero, Paint());
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
  
  /// 更新快取並清理當前筆劃快取
  Future<void> _updateCacheAndCleanup() async {
    await _updateCache();
    
    if (mounted) {
      setState(() {
        _currentStrokeCache?.dispose();
        _currentStrokeCache = null;
        _currentStrokeCachedPoints = 0;
      });
    }
  }
  
  /// 重建整個快取
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
      
      final size = MediaQuery.of(context).size;
      final width = (widget.width ?? size.width).toInt();
      final height = (widget.height ?? size.height).toInt();
      
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // 繪製所有筆劃
      for (final stroke in _drawingData.strokes) {
        _drawStrokeToCanvas(canvas, stroke);
      }
      
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
  
  /// 繪製筆劃到畫布
  void _drawStrokeToCanvas(Canvas canvas, DrawingStroke stroke) {
    if (stroke.brushType == BrushType.texture && _texturePool != null && _isPoolReady) {
      _drawTextureBrush(canvas, stroke.points, stroke.color, stroke.strokeWidth);
    } else {
      _drawSimpleBrush(canvas, stroke.points, stroke.color, stroke.strokeWidth);
    }
  }
  
  /// 繪製紋理筆刷
  void _drawTextureBrush(Canvas canvas, List<Offset> points, Color color, double strokeWidth) {
    if (points.isEmpty || _texturePool == null) return;

    final paint = Paint()
      ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn)
      ..isAntiAlias = true;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final texture = _texturePool!.getTexture(i);
      if (texture != null) {
        final size = strokeWidth * 1.2;
        final rect = Rect.fromCenter(
          center: point,
          width: size,
          height: size,
        );
        canvas.drawImageRect(
          texture,
          Rect.fromLTWH(0, 0, texture.width.toDouble(), texture.height.toDouble()),
          rect,
          paint,
        );
      }
    }
  }
  
  /// 繪製簡單筆刷
  void _drawSimpleBrush(Canvas canvas, List<Offset> points, Color color, double strokeWidth) {
    if (points.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    if (points.length == 1) {
      canvas.drawCircle(points[0], strokeWidth / 2, paint..style = PaintingStyle.fill);
    } else {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    }
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
                    cachedBackground: _cachedBackground,
                    currentStroke: _currentStroke,
                    currentColor: _isEraser ? Colors.grey.withOpacity(0.3) : _selectedColor,
                    currentStrokeWidth: _isEraser ? 25.0 : _strokeWidth,
                    isErasing: _isEraser,
                    texturePool: _texturePool,
                    isPoolReady: _isPoolReady,
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
                    Text('顏色 ',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    Expanded(
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _buildColorButtons())),
                  ],
                ),
                Divider(height: 12),
                Row(
                  children: [
                    Text('大小 ',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    Expanded(
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _buildSizeButtons())),
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
      Color(0xFF1E88E5),
      Color(0xFF26C6DA),
      Color(0xFFFFFFFF),
      Color(0xFFD7CCC8),
      Color(0xFF8D6E63),
      Color(0xFF4CAF50),
    ];

    return colors.map((color) {
      final isSelected = _selectedColor == color && !_isEraser;
      return GestureDetector(
        onTap: () => setState(() {
          _selectedColor = color;
          _isEraser = false;
        }),
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
        onTap: () => setState(() {
          _strokeWidth = width;
          _isEraser = false;
        }),
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
              decoration:
                  BoxDecoration(color: Colors.grey[800], shape: BoxShape.circle),
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
          border:
              Border.all(color: _isEraser ? Colors.pink[400]! : Colors.grey[300]!, width: 2),
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
            color: _drawingData.strokes.isEmpty ? Colors.grey[300] : Colors.grey[700]),
      ),
    ));

    return buttons;
  }
}

class _DrawingPainter extends CustomPainter {
  final ui.Image? cachedBackground;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isErasing;
  final BrushTexturePool? texturePool;
  final bool isPoolReady;

  _DrawingPainter({
    this.cachedBackground,
    required this.currentStroke,
    required this.currentColor,
    required this.currentStrokeWidth,
    this.isErasing = false,
    this.texturePool,
    this.isPoolReady = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 繪製快取的背景
    if (cachedBackground != null) {
      canvas.drawImage(cachedBackground!, Offset.zero, Paint());
    }
    
    // 繪製當前正在繪製的筆劃（橡皮擦用簡單筆刷）
    if (currentStroke.isNotEmpty) {
      _drawSimpleBrush(canvas, currentStroke, currentColor, currentStrokeWidth);
    }
  }
  
  /// 繪製簡單筆刷
  void _drawSimpleBrush(Canvas canvas, List<Offset> points, Color color, double strokeWidth) {
    if (points.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    if (points.length == 1) {
      canvas.drawCircle(points[0], strokeWidth / 2, paint..style = PaintingStyle.fill);
    } else {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) {
    return oldDelegate.cachedBackground != cachedBackground ||
        oldDelegate.currentStroke.length != currentStroke.length ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.currentStrokeWidth != currentStrokeWidth;
  }
}

// 舊的複雜紋理畫家（暫時保留但不使用）
class _LegacyDrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isErasing;

  // Paint 緩存
  final Paint _paintCache = Paint()..style = PaintingStyle.fill;

  _LegacyDrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentStrokeWidth,
    this.isErasing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 渲染所有已完成的筆劃
    for (final stroke in strokes) {
      _drawFullTextureBrush(canvas, stroke.points, stroke.color, stroke.strokeWidth);
    }
    
    // 渲染當前正在繪製的筆劃
    if (currentStroke.isNotEmpty) {
      _drawFullTextureBrush(canvas, currentStroke, currentColor, currentStrokeWidth);
    }
  }

  void _drawFullStampAtPoint(
      Canvas canvas, Offset point, Color color, double strokeWidth, int pointIndex) {
    // 🎯 完整8層肌理渲染 - 最佳視覺效果
    final random = math.Random(point.hashCode + pointIndex);

    Color getHueVariation(Color baseColor, double variation) {
      final hslColor = HSLColor.fromColor(baseColor);
      final hueShift = (random.nextDouble() - 0.5) * variation;
      return hslColor.withHue((hslColor.hue + hueShift) % 360).toColor();
    }

    // 第0層: 紙張纖維紋理 (8-12條)
    final fiberCount = 8 + random.nextInt(5);
    for (int j = 0; j < fiberCount; j++) {
      final baseAngle = random.nextDouble() * 2 * math.pi;
      final angleVariation = (random.nextDouble() - 0.5) * 0.4;
      final fiberAngle = baseAngle + angleVariation;
      final fiberLength = strokeWidth * (0.6 + random.nextDouble() * 0.9);
      final fiberThickness = strokeWidth * 0.05 * (0.5 + random.nextDouble());
      final startOffsetX = (random.nextDouble() - 0.5) * strokeWidth * 1.2;
      final startOffsetY = (random.nextDouble() - 0.5) * strokeWidth * 1.2;
      final startPoint = Offset(point.dx + startOffsetX, point.dy + startOffsetY);
      final endPoint = Offset(
        startPoint.dx + math.cos(fiberAngle) * fiberLength,
        startPoint.dy + math.sin(fiberAngle) * fiberLength,
      );
      final fiberColor = getHueVariation(color, 15);
      _paintCache
        ..color = fiberColor.withOpacity(0.02 + random.nextDouble() * 0.04)
        ..strokeWidth = fiberThickness
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(startPoint, endPoint, _paintCache);
    }
    
    // 第1層: 底層擴散 (12-20個點)
    final spreadCount = 12 + random.nextInt(9);
    for (int i = 0; i < spreadCount; i++) {
      final angleBase = random.nextDouble() * 2 * math.pi;
      final angleNoise = (random.nextDouble() - 0.5) * 0.8;
      final angle = angleBase + angleNoise;
      final distFactor1 = math.pow(random.nextDouble(), 0.4).toDouble();
      final distFactor2 = random.nextDouble();
      final distFactor = (distFactor1 * 0.7 + distFactor2 * 0.3);
      final maxDistance = strokeWidth * (2.2 + random.nextDouble() * 1.4);
      final distance = distFactor * maxDistance;
      final offsetX = math.cos(angle) * distance;
      final offsetY = math.sin(angle) * distance;
      final opacity = 0.03 + (1 - distFactor) * 0.12;
      final dotSize = strokeWidth * (0.25 + random.nextDouble() * 0.45);
      final dotColor = getHueVariation(color, 10);
      _paintCache.color = dotColor.withOpacity(opacity);
      _paintCache.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(point.dx + offsetX, point.dy + offsetY), dotSize, _paintCache);
    }
    
    // 第2層: 顆粒層 (8-16個點)
    final particleCount = 8 + random.nextInt(9);
    for (int i = 0; i < particleCount; i++) {
      final offsetX = (math.pow(random.nextDouble(), 0.6) - 0.5) * 2 * strokeWidth * 1.6;
      final offsetY = (math.pow(random.nextDouble(), 0.6) - 0.5) * 2 * strokeWidth * 1.6;
      final opacity = 0.12 + random.nextDouble() * 0.32;
      final sizeVariation = random.nextDouble();
      final particleSize = strokeWidth * (0.2 + math.pow(sizeVariation, 0.7) * 0.6);
      final particleColor = getHueVariation(color, 12);
      _paintCache.color = particleColor.withOpacity(opacity);
      canvas.drawCircle(Offset(point.dx + offsetX, point.dy + offsetY), particleSize, _paintCache);
    }
    
    // 第3層: 刮擦紋理 (2-4條刮痕) - 只在有方向的地方添加
    if (pointIndex > 0) {
      final scratchCount = 2 + random.nextInt(3);
      for (int j = 0; j < scratchCount; j++) {
        final angle = random.nextDouble() * 2 * math.pi;
        final offset = (j - scratchCount / 2) * strokeWidth * 0.3;
        final perpAngle = angle + math.pi / 2;
        final offsetX = math.cos(perpAngle) * offset;
        final offsetY = math.sin(perpAngle) * offset;
        final scratchLength = strokeWidth * (0.5 + random.nextDouble() * 0.5);
        final scratchOpacity = 0.08 + random.nextDouble() * 0.15;
        final scratchWidth = strokeWidth * (0.1 + random.nextDouble() * 0.15);
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
    final layerCount = 5 + random.nextInt(6);
    for (int j = 0; j < layerCount; j++) {
      final clusterFactor = math.pow(random.nextDouble(), 0.5).toDouble();
      final offsetX = (random.nextDouble() - 0.5) * strokeWidth * 1.1 * clusterFactor;
      final offsetY = (random.nextDouble() - 0.5) * strokeWidth * 1.1 * clusterFactor;
      final opacity = 0.15 + random.nextDouble() * 0.35;
      final layerSize = strokeWidth * (0.3 + math.pow(random.nextDouble(), 0.6) * 0.5);
      final layerColor = getHueVariation(color, 10);
      _paintCache.color = layerColor.withOpacity(opacity);
      _paintCache.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(point.dx + offsetX, point.dy + offsetY), layerSize, _paintCache);
    }
    
    // 第5層: 主體核心
    _paintCache.color = getHueVariation(color, 6).withOpacity(0.55);
    canvas.drawCircle(point, strokeWidth * 0.5, _paintCache);
    
    // 第6層: 高光 (2-4個)
    final highlightCount = 2 + random.nextInt(3);
    for (int i = 0; i < highlightCount; i++) {
      final offsetX = (random.nextDouble() - 0.75) * strokeWidth * 0.5;
      final offsetY = (random.nextDouble() - 0.75) * strokeWidth * 0.5;
      final highlightSize = strokeWidth * (0.2 + random.nextDouble() * 0.2);
      final highlightColor = getHueVariation(color, 8);
      _paintCache.color = highlightColor.withOpacity(0.35 + random.nextDouble() * 0.25);
      canvas.drawCircle(Offset(point.dx + offsetX, point.dy + offsetY), highlightSize, _paintCache);
    }
    
    // 第7層: 陰影 (1-3個)
    final shadowCount = 1 + random.nextInt(3);
    for (int j = 0; j < shadowCount; j++) {
      final shadowX = (random.nextDouble() + 0.15) * strokeWidth * 0.4;
      final shadowY = (random.nextDouble() + 0.15) * strokeWidth * 0.4;
      final shadowSize = strokeWidth * (0.15 + random.nextDouble() * 0.15);
      final shadowColor = getHueVariation(color, 8);
      _paintCache.color = shadowColor.withOpacity(0.15 + random.nextDouble() * 0.12);
      canvas.drawCircle(Offset(point.dx + shadowX, point.dy + shadowY), shadowSize, _paintCache);
    }
    
    // 第8層: 邊緣毛邊 (3-6個點)
    final edgeCount = 3 + random.nextInt(4);
    for (int i = 0; i < edgeCount; i++) {
      final angleBase = (i / edgeCount) * 2 * math.pi;
      final angleNoise = (random.nextDouble() - 0.5) * 0.6;
      final angle = angleBase + angleNoise;
      final distanceVariation = 0.6 + random.nextDouble() * 1.2;
      final distance = strokeWidth * distanceVariation;
      final offsetX = math.cos(angle) * distance;
      final offsetY = math.sin(angle) * distance;
      final edgeSize = strokeWidth * (0.08 + math.pow(random.nextDouble(), 0.7) * 0.25);
      final edgeOpacity = 0.08 + random.nextDouble() * 0.22;
      final edgeColor = getHueVariation(color, 12);
      _paintCache.color = edgeColor.withOpacity(edgeOpacity);
      canvas.drawCircle(Offset(point.dx + offsetX, point.dy + offsetY), edgeSize, _paintCache);
    }
  }

  // 完整筆劃渲染 (用於已完成的筆劃)
  void _drawFullTextureBrush(Canvas canvas, List<Offset> points, Color color, double strokeWidth) {
    if (points.isEmpty) return;

    // 🎯 智能跳點策略 - 平衡質量與性能
    int pointStep;
    if (points.length <= 20) {
      pointStep = 1; // 短筆劃：全部渲染
    } else if (points.length <= 80) {
      pointStep = 2; // 中等筆劃：跳1點
    } else {
      pointStep = 3; // 長筆劃：跳2點
    }
    
    for (int i = 0; i < points.length; i += pointStep) {
      _drawFullStampAtPoint(canvas, points[i], color, strokeWidth, i);
    }
  }

  @override
  bool shouldRepaint(_LegacyDrawingPainter oldDelegate) {
    return oldDelegate.strokes.length != strokes.length ||
        oldDelegate.currentStroke.length != currentStroke.length ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.currentStrokeWidth != currentStrokeWidth;
  }
}

/// 筆刷紋理快取池
class BrushTexturePool {
  static const int poolSize = 16;
  static const int textureSize = 128;
  
  final List<ui.Image?> _textures = List.filled(poolSize, null);
  bool _isBuilt = false;
  
  Future<void> buildPool(Color color, double strokeWidth) async {
    if (_isBuilt) return;
    
    for (int i = 0; i < poolSize; i++) {
      _textures[i] = await _generateTexture(i, color, strokeWidth);
    }
    _isBuilt = true;
  }
  
  Future<ui.Image> _generateTexture(int seed, Color color, double strokeWidth) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final random = math.Random(seed);
    
    final paint = Paint()
      ..color = color.withOpacity(0.6 + random.nextDouble() * 0.3)
      ..style = PaintingStyle.fill;
    
    final center = Offset(textureSize / 2, textureSize / 2);
    final radius = (textureSize / 4) + random.nextDouble() * (textureSize / 8);
    
    canvas.drawCircle(center, radius, paint);
    
    final picture = recorder.endRecording();
    return await picture.toImage(textureSize, textureSize);
  }
  
  ui.Image? getTexture(int index) {
    return _textures[index % poolSize];
  }
  
  void dispose() {
    for (var texture in _textures) {
      texture?.dispose();
    }
  }
}

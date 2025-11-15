import 'package:flutter/material.dart';
import 'dart:math' as math;
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
  double _strokeWidth = 15.0;
  bool _isEraser = false;
  BrushType _brushType = BrushType.texture;

  @override
  void initState() {
    super.initState();
    _drawingData = widget.initialDrawing;
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
        setState(() {
          _drawingData.strokes.removeWhere((stroke) {
            return _currentStroke.any((point) {
              return stroke.points.any((strokePoint) {
                final distance = (point - strokePoint).distance;
                return distance < 15.0;
              });
            });
          });
          _currentStroke = [];
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
        });
      }
      widget.onDrawingChanged(_drawingData);
    }
  }

  void _undoLastStroke() {
    if (_drawingData.strokes.isNotEmpty) {
      setState(() {
        _drawingData.strokes.removeLast();
      });
      widget.onDrawingChanged(_drawingData);
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
                    strokes: _drawingData.strokes,
                    currentStroke: _currentStroke,
                    currentColor:
                        _isEraser ? Colors.pink.withOpacity(0.3) : _selectedColor,
                    currentStrokeWidth:
                        _isEraser ? 25.0 : _strokeWidth,
                    isErasing: _isEraser,
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
  final List<DrawingStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isErasing;

  // Paint 緩存
  final Paint _paintCache = Paint()..style = PaintingStyle.fill;

  _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentStrokeWidth,
    this.isErasing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 🎨 渲染所有已完成的筆劃
    for (final stroke in strokes) {
      _drawFullTextureBrush(canvas, stroke.points, stroke.color, stroke.strokeWidth);
    }
    
    // 🎨 渲染當前正在繪製的筆劃
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
  bool shouldRepaint(_DrawingPainter oldDelegate) {
    // 🎯 關鍵：只要有任何變化就重繪
    return oldDelegate.strokes.length != strokes.length ||
        oldDelegate.currentStroke.length != currentStroke.length ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.currentStrokeWidth != currentStrokeWidth;
  }
}

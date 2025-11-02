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
                    currentColor: _isEraser ? Colors.pink.withOpacity(0.3) : _selectedColor,
                    currentStrokeWidth: _isEraser ? 25.0 : _strokeWidth,
                    isErasing: _isEraser,
                  ),
                  child: Container(),
                ),
              ),
            ),
          ),
        ),
        if (!widget.isReadOnly) Container(
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
                  Text('顏色 ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: _buildColorButtons())),
                ],
              ),
              Divider(height: 12),
              Row(
                children: [
                  Text('大小 ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: _buildSizeButtons())),
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
            border: Border.all(color: isSelected ? Colors.blue[400]! : Colors.grey[300]!, width: 2),
          ),
          child: Center(
            child: Container(
              width: (width / 25 * 14).clamp(4.0, 14.0),
              height: (width / 25 * 14).clamp(4.0, 14.0),
              decoration: BoxDecoration(color: Colors.grey[800], shape: BoxShape.circle),
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
          border: Border.all(color: _isEraser ? Colors.pink[400]! : Colors.grey[300]!, width: 2),
        ),
        child: Icon(Icons.auto_fix_high, size: 20, color: _isEraser ? Colors.pink[700] : Colors.grey[600]),
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
        child: Icon(Icons.undo, size: 20, color: _drawingData.strokes.isEmpty ? Colors.grey[300] : Colors.grey[700]),
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

  _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentStrokeWidth,
    this.isErasing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawTextureBrush(canvas, stroke.points, stroke.color, stroke.strokeWidth);
    }
    if (currentStroke.isNotEmpty) {
      _drawTextureBrush(canvas, currentStroke, currentColor, currentStrokeWidth);
    }
  }

  void _drawTextureBrush(Canvas canvas, List<Offset> points, Color color, double strokeWidth) {
    if (points.isEmpty) return;
    final random = math.Random(points.hashCode);
    
    // 🎨 色相微調輔助函數 - 讓顏色帶有自然的色彩動態
    Color getHueVariation(Color baseColor, double variation) {
      final hslColor = HSLColor.fromColor(baseColor);
      final hueShift = (random.nextDouble() - 0.5) * variation; // -variation/2 到 +variation/2
      return hslColor.withHue((hslColor.hue + hueShift) % 360).toColor();
    }
    
    // 第零層:紙張纖維紋理 - 模擬畫布底紋
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final fiberCount = 12 + random.nextInt(8); // 12-19條纖維
      
      for (int j = 0; j < fiberCount; j++) {
        // 紙張纖維大致有方向性,但不完全平行
        final baseAngle = random.nextDouble() * 2 * math.pi;
        final angleVariation = (random.nextDouble() - 0.5) * 0.4; // ±0.2弧度的變化
        final fiberAngle = baseAngle + angleVariation;
        
        // 纖維長度隨機
        final fiberLength = strokeWidth * (0.6 + random.nextDouble() * 0.9);
        final fiberThickness = strokeWidth * 0.05 * (0.5 + random.nextDouble());
        
        // 起點稍微偏移
        final startOffsetX = (random.nextDouble() - 0.5) * strokeWidth * 1.2;
        final startOffsetY = (random.nextDouble() - 0.5) * strokeWidth * 1.2;
        
        final startPoint = Offset(
          point.dx + startOffsetX,
          point.dy + startOffsetY,
        );
        final endPoint = Offset(
          startPoint.dx + math.cos(fiberAngle) * fiberLength,
          startPoint.dy + math.sin(fiberAngle) * fiberLength,
        );
        
        // 纖維顏色非常淡,接近透明
        final fiberColor = getHueVariation(color, 15); // 色相偏移±7.5度
        
        canvas.drawLine(
          startPoint,
          endPoint,
          Paint()
            ..color = fiberColor.withOpacity(0.02 + random.nextDouble() * 0.04)
            ..strokeWidth = fiberThickness
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
      }
    }
    
    // 第一層:底層紋理擴散 - 模擬畫布纖維吸收顏料(增強隨機性)
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      // 🎯 增強散布隨機性:點數量也隨機化
      final spreadCount = 20 + random.nextInt(18); // 從25-35改為20-38,範圍更大
      
      for (int j = 0; j < spreadCount; j++) {
        // 🎯 使用柏林噪聲式的角度分布,避免完全均勻
        final angleBase = random.nextDouble() * 2 * math.pi;
        final angleNoise = (random.nextDouble() - 0.5) * 0.8; // 額外的角度噪聲
        final angle = angleBase + angleNoise;
        
        // 使用不均勻擴散,模擬真實顏料流動
        // 🎯 增強隨機性:混合兩種分布
        final distFactor1 = math.pow(random.nextDouble(), 0.4).toDouble();
        final distFactor2 = random.nextDouble();
        final distFactor = (distFactor1 * 0.7 + distFactor2 * 0.3); // 混合分布
        
        // 🎯 距離範圍也隨機化
        final maxDistance = strokeWidth * (2.2 + random.nextDouble() * 1.4); // 2.2-3.6倍
        final distance = distFactor * maxDistance;
        
        final offsetX = math.cos(angle) * distance;
        final offsetY = math.sin(angle) * distance;
        
        // 外圍越淡,中心越濃
        final opacity = 0.03 + (1 - distFactor) * 0.12;
        // 🎯 點大小也更隨機
        final dotSize = strokeWidth * (0.25 + random.nextDouble() * 0.45);
        
        // 🎨 加入色相變化
        final dotColor = getHueVariation(color, 10); // 色相偏移±5度
        
        canvas.drawCircle(
          Offset(point.dx + offsetX, point.dy + offsetY),
          dotSize,
          Paint()
            ..color = dotColor.withOpacity(opacity)
            ..style = PaintingStyle.fill,
        );
      }
    }
    
    // 第二層:肌理顆粒層 - 模擬顏料顆粒和畫布質感(增強隨機性)
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      // 🎯 顆粒數量隨機化
      final particleCount = 12 + random.nextInt(15); // 從15-23改為12-27
      
      for (int j = 0; j < particleCount; j++) {
        // 🎯 不規則分布 - 使用非均勻分布
        final offsetX = (math.pow(random.nextDouble(), 0.6) - 0.5) * 2 * strokeWidth * 1.6;
        final offsetY = (math.pow(random.nextDouble(), 0.6) - 0.5) * 2 * strokeWidth * 1.6;
        
        // 🎯 透明度範圍擴大
        final opacity = 0.12 + random.nextDouble() * 0.32;
        
        // 🎯 顆粒大小差異更大
        final sizeVariation = random.nextDouble();
        final particleSize = strokeWidth * (0.2 + math.pow(sizeVariation, 0.7) * 0.6);
        
        // 🎨 加入色相變化
        final particleColor = getHueVariation(color, 12); // 色相偏移±6度
        
        canvas.drawCircle(
          Offset(point.dx + offsetX, point.dy + offsetY),
          particleSize,
          Paint()
            ..color = particleColor.withOpacity(opacity)
            ..style = PaintingStyle.fill,
        );
      }
    }
    
    // 第三層:刮擦紋理 - 模擬畫刀刮過的痕跡(增強變化)
    if (points.length > 1) {
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        
        // 計算筆劃方向並創建垂直刮痕
        final dx = p2.dx - p1.dx;
        final dy = p2.dy - p1.dy;
        final distance = math.sqrt(dx * dx + dy * dy);
        
        if (distance > 0) {
          final angle = math.atan2(dy, dx);
          // 🎯 刮痕數量隨機化
          final scratchCount = 2 + random.nextInt(5); // 從3-5改為2-7
          
          for (int j = 0; j < scratchCount; j++) {
            // 🎯 刮痕位置更不規則
            final offset = (j - scratchCount / 2 + (random.nextDouble() - 0.5) * 0.6) * strokeWidth * 0.28;
            final perpAngle = angle + math.pi / 2 + (random.nextDouble() - 0.5) * 0.3; // 角度微調
            final offsetX = math.cos(perpAngle) * offset;
            final offsetY = math.sin(perpAngle) * offset;
            
            // 🎯 刮痕透明度隨機變化範圍更大
            final scratchOpacity = 0.08 + random.nextDouble() * 0.20;
            
            // 🎯 刮痕寬度變化更大
            final scratchWidth = strokeWidth * (0.1 + math.pow(random.nextDouble(), 0.8) * 0.25);
            
            // 🎨 加入色相變化
            final scratchColor = getHueVariation(color, 8); // 色相偏移±4度
            
            canvas.drawLine(
              Offset(p1.dx + offsetX, p1.dy + offsetY),
              Offset(p2.dx + offsetX, p2.dy + offsetY),
              Paint()
                ..color = scratchColor.withOpacity(scratchOpacity)
                ..strokeWidth = scratchWidth
                ..strokeCap = StrokeCap.round
                ..style = PaintingStyle.stroke,
            );
          }
        }
      }
    }
    
    // 第四層:厚塗堆積 - 模擬顏料厚塗的立體感(增強隨機性)
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      // 🎯 圖層數量隨機化
      final layerCount = 8 + random.nextInt(10); // 從10-15改為8-18
      
      for (int j = 0; j < layerCount; j++) {
        // 🎯 使用簇狀分布 - 有些區域堆積更厚
        final clusterFactor = math.pow(random.nextDouble(), 0.5).toDouble();
        final offsetX = (random.nextDouble() - 0.5) * strokeWidth * 1.1 * clusterFactor;
        final offsetY = (random.nextDouble() - 0.5) * strokeWidth * 1.1 * clusterFactor;
        
        // 🎯 透明度變化更大
        final opacity = 0.15 + random.nextDouble() * 0.35;
        
        // 🎯 圖層大小隨機化
        final layerSize = strokeWidth * (0.3 + math.pow(random.nextDouble(), 0.6) * 0.5);
        
        // 🎨 加入色相變化
        final layerColor = getHueVariation(color, 10); // 色相偏移±5度
        
        canvas.drawCircle(
          Offset(point.dx + offsetX, point.dy + offsetY),
          layerSize,
          Paint()
            ..color = layerColor.withOpacity(opacity)
            ..style = PaintingStyle.fill,
        );
      }
    }
    
    // 第五層:主體輪廓 - 清晰但保持手繪感(加入色彩動態)
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      
      // 使用稍微不規則的路徑模擬手繪
      for (int i = 1; i < points.length; i++) {
        // 🎯 抖動幅度隨機化
        final jitterAmount = 0.06 + random.nextDouble() * 0.06; // 6%-12%
        final jitterX = (random.nextDouble() - 0.5) * strokeWidth * jitterAmount;
        final jitterY = (random.nextDouble() - 0.5) * strokeWidth * jitterAmount;
        path.lineTo(
          points[i].dx + jitterX,
          points[i].dy + jitterY,
        );
      }
      
      // 🎨 主輪廓使用微妙的色相變化
      final outlineColor = getHueVariation(color, 6); // 色相偏移±3度
      
      canvas.drawPath(
        path,
        Paint()
          ..color = outlineColor.withOpacity(0.55)
          ..strokeWidth = strokeWidth * 1.05
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }
    
    // 第六層:高光與陰影 - 模擬光線照射在厚顏料上的效果(增強立體感)
    for (int i = 0; i < points.length; i += 2) {
      final point = points[i];
      
      // 🎯 高光區(偏向左上) - 數量隨機化
      final highlightCount = 3 + random.nextInt(3); // 3-6個高光
      for (int j = 0; j < highlightCount; j++) {
        final highlightX = point.dx + (random.nextDouble() - 0.75) * strokeWidth * 0.5;
        final highlightY = point.dy + (random.nextDouble() - 0.75) * strokeWidth * 0.5;
        
        // 🎯 高光大小隨機
        final highlightSize = strokeWidth * (0.2 + random.nextDouble() * 0.2);
        
        // 🎨 高光帶有微妙的色相偏移(偏向暖色)
        final highlightColor = getHueVariation(color, 8); // 色相偏移±4度
        
        canvas.drawCircle(
          Offset(highlightX, highlightY),
          highlightSize,
          Paint()
            ..color = highlightColor.withOpacity(0.35 + random.nextDouble() * 0.25)
            ..style = PaintingStyle.fill,
        );
      }
      
      // 🎯 陰影區(偏向右下) - 數量隨機化
      final shadowCount = 2 + random.nextInt(3); // 2-5個陰影
      for (int j = 0; j < shadowCount; j++) {
        final shadowX = point.dx + (random.nextDouble() + 0.15) * strokeWidth * 0.4;
        final shadowY = point.dy + (random.nextDouble() + 0.15) * strokeWidth * 0.4;
        
        // 🎯 陰影大小隨機
        final shadowSize = strokeWidth * (0.15 + random.nextDouble() * 0.15);
        
        // 🎨 陰影帶有微妙的色相偏移(偏向冷色)
        final shadowColor = getHueVariation(color, 8); // 色相偏移±4度
        
        canvas.drawCircle(
          Offset(shadowX, shadowY),
          shadowSize,
          Paint()
            ..color = shadowColor.withOpacity(0.15 + random.nextDouble() * 0.12)
            ..style = PaintingStyle.fill,
        );
      }
    }
    
    // 第七層:邊緣毛邊 - 模擬顏料邊緣的自然不規則(增強真實感)
    for (int i = 0; i < points.length; i += 2) {
      final point = points[i];
      // 🎯 邊緣點數量隨機化
      final edgeCount = 5 + random.nextInt(7); // 從6-10改為5-12
      
      for (int j = 0; j < edgeCount; j++) {
        // 🎯 角度分布不完全均勻
        final angleBase = (j / edgeCount) * 2 * math.pi;
        final angleNoise = (random.nextDouble() - 0.5) * 0.6;
        final angle = angleBase + angleNoise;
        
        // 🎯 距離變化更大
        final distanceVariation = 0.6 + random.nextDouble() * 1.2; // 從0.7-1.6改為0.6-1.8
        final distance = strokeWidth * distanceVariation;
        
        final offsetX = math.cos(angle) * distance;
        final offsetY = math.sin(angle) * distance;
        
        // 🎯 邊緣點大小變化更大
        final edgeSize = strokeWidth * (0.08 + math.pow(random.nextDouble(), 0.7) * 0.25);
        
        // 🎯 透明度範圍擴大
        final edgeOpacity = 0.08 + random.nextDouble() * 0.22;
        
        // 🎨 加入色相變化
        final edgeColor = getHueVariation(color, 12); // 色相偏移±6度
        
        canvas.drawCircle(
          Offset(point.dx + offsetX, point.dy + offsetY),
          edgeSize,
          Paint()
            ..color = edgeColor.withOpacity(edgeOpacity)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) => true;
}

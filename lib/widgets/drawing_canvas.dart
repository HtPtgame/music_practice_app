import 'package:flutter/material.dart';
import '../models/drawing_data.dart';

/// 繪圖畫布 Widget
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
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isEraser = false; // 橡皮擦模式

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
    
    // 立即更新當前筆劃並強制重繪
    setState(() {
      _currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.isReadOnly) return;
    
    if (_currentStroke.isNotEmpty) {
      if (_isEraser) {
        // 橡皮擦模式:移除與當前筆劃相交的筆劃
        setState(() {
          _drawingData.strokes.removeWhere((stroke) {
            return _currentStroke.any((point) {
              return stroke.points.any((strokePoint) {
                final distance = (point - strokePoint).distance;
                return distance < 10.0; // 橡皮擦範圍
              });
            });
          });
          _currentStroke = [];
        });
      } else {
        // 繪圖模式:新增筆劃
        final stroke = DrawingStroke(
          points: List.from(_currentStroke),
          color: _selectedColor,
          strokeWidth: _strokeWidth,
        );
        
        setState(() {
          _drawingData.strokes.add(stroke);
          _currentStroke = [];
        });
      }
      
      widget.onDrawingChanged(_drawingData);
    }
  }

  void _clearDrawing() {
    setState(() {
      _drawingData = DrawingData();
      _currentStroke = [];
    });
    widget.onDrawingChanged(_drawingData);
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
        // 繪圖區域 (使用 Flexible 自動調整高度)
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
                    currentStrokeWidth: _isEraser ? 20.0 : _strokeWidth,
                    isErasing: _isEraser,
                  ),
                  child: Container(),
                ),
              ),
            ),
          ),
        ),
        
        // 工具列(僅在非只讀模式顯示,移到下方)
        if (!widget.isReadOnly) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 第一行:顏色選擇 (放大並佔滿整行)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Text('顏色:', style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Colors.black,
                            Colors.red,
                            Colors.blue,
                            Colors.green,
                            Colors.orange,
                            Colors.purple,
                          ].map((color) {
                            final isSelected = _selectedColor == color && !_isEraser;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedColor = color;
                                _isEraser = false;
                              }),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.grey[300]!,
                                    width: isSelected ? 3 : 2,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ] : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                // 第二行:粗細選擇和橡皮擦 (比照顏色的排版)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Text('粗細:', style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ...[2.0, 3.0, 5.0, 8.0].map((width) {
                              final isSelected = _strokeWidth == width && !_isEraser;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _strokeWidth = width;
                                  _isEraser = false;
                                }),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue[50] : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: width * 1.5,
                                      height: width * 1.5,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            // 橡皮擦按鈕
                            GestureDetector(
                              onTap: () => setState(() => _isEraser = !_isEraser),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _isEraser ? Colors.pink[50] : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _isEraser ? Colors.pink[300]! : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.auto_fix_high,
                                  size: 18,
                                  color: _isEraser ? Colors.pink[700] : Colors.grey[600],
                                ),
                              ),
                            ),
                            // 復原按鈕
                            GestureDetector(
                              onTap: _drawingData.strokes.isEmpty ? null : _undoLastStroke,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.undo,
                                  size: 18,
                                  color: _drawingData.strokes.isEmpty ? Colors.grey[300] : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 繪圖畫家
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
    // 繪製已完成的筆劃
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length > 1) {
        final path = Path();
        path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        canvas.drawPath(path, paint);
      } else if (stroke.points.length == 1) {
        // 單點繪製為小圓點
        canvas.drawCircle(stroke.points[0], stroke.strokeWidth / 2, paint..style = PaintingStyle.fill);
      }
    }

    // 繪製當前正在畫的筆劃 (即時顯示)
    if (currentStroke.isNotEmpty) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (currentStroke.length > 1) {
        // 使用 Path 繪製連續的線條,效能更好且更流暢
        final path = Path();
        path.moveTo(currentStroke[0].dx, currentStroke[0].dy);
        for (int i = 1; i < currentStroke.length; i++) {
          path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
        }
        canvas.drawPath(path, paint);
      } else if (currentStroke.length == 1) {
        // 單點顯示為圓點
        canvas.drawCircle(currentStroke[0], currentStrokeWidth / 2, paint..style = PaintingStyle.fill);
      }
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) {
    // 總是重繪以確保即時顯示
    return true;
  }
}

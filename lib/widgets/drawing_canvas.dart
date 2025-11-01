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
        // 繪圖區域
        Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 300,
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
                  currentColor: _isEraser ? Colors.white : _selectedColor,
                  currentStrokeWidth: _isEraser ? 20.0 : _strokeWidth,
                ),
                child: Container(),
              ),
            ),
          ),
        ),
        
        // 工具列(僅在非只讀模式顯示,移到下方)
        if (!widget.isReadOnly) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                // 第一行:顏色選擇
                Row(
                  children: [
                    Text('顏色:', style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Wrap(
                        spacing: 2,
                        runSpacing: 1,
                        children: [
                          Colors.black,
                          Colors.red,
                          Colors.blue,
                          Colors.green,
                          Colors.orange,
                          Colors.purple,
                        ].map((color) {
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedColor = color;
                              _isEraser = false; // 選擇顏色時退出橡皮擦模式
                            }),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedColor == color && !_isEraser ? Colors.white : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: _selectedColor == color && !_isEraser
                                    ? [BoxShadow(color: Colors.black26, blurRadius: 2)]
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 第二行:粗細選擇、橡皮擦和操作按鈕
                Row(
                  children: [
                    Text('粗細:', style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                    const SizedBox(width: 4),
                    ...[2.0, 3.0, 5.0, 8.0].map((width) {
                      return GestureDetector(
                        onTap: () => setState(() {
                          _strokeWidth = width;
                          _isEraser = false; // 選擇粗細時退出橡皮擦模式
                        }),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: _strokeWidth == width && !_isEraser ? Colors.blue[100] : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Container(
                            width: width * 1.2,
                            height: width * 1.2,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(width: 3),
                    // 橡皮擦按鈕
                    GestureDetector(
                      onTap: () => setState(() => _isEraser = !_isEraser),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: _isEraser ? Colors.pink[100] : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Icon(
                          Icons.auto_fix_high,
                          size: 16,
                          color: _isEraser ? Colors.pink[700] : Colors.grey[600],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 操作按鈕
                    IconButton(
                      icon: const Icon(Icons.undo, size: 14),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 14,
                      onPressed: _drawingData.strokes.isEmpty ? null : _undoLastStroke,
                      tooltip: '復原',
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 14),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 14,
                      onPressed: _drawingData.strokes.isEmpty ? null : _clearDrawing,
                      tooltip: '清除',
                    ),
                  ],
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

  _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentStrokeWidth,
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

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    // 繪製當前正在畫的筆劃
    if (currentStroke.isNotEmpty) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < currentStroke.length - 1; i++) {
        canvas.drawLine(currentStroke[i], currentStroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes || 
           oldDelegate.currentStroke != currentStroke;
  }
}

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
  
  // 用於強制 CustomPaint 重繪的通知器
  final ValueNotifier<int> _repaintNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _drawingData = widget.initialDrawing;
  }
  
  @override
  void dispose() {
    _repaintNotifier.dispose();
    super.dispose();
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
    _currentStroke.add(details.localPosition);
    _repaintNotifier.value++; // 觸發重繪
    setState(() {});
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
                child: ValueListenableBuilder<int>(
                  valueListenable: _repaintNotifier,
                  builder: (context, value, child) {
                    return CustomPaint(
                      painter: _DrawingPainter(
                        strokes: _drawingData.strokes,
                        currentStroke: _currentStroke,
                        currentColor: _isEraser ? Colors.pink.withOpacity(0.3) : _selectedColor,
                        currentStrokeWidth: _isEraser ? 20.0 : _strokeWidth,
                        isErasing: _isEraser,
                      ),
                      child: Container(),
                    );
                  },
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
                // 第一行:顏色選擇
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('顏色:', style: TextStyle(fontSize: 8, color: Colors.grey[700])),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Wrap(
                        spacing: 1.5,
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
                              _isEraser = false;
                            }),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedColor == color && !_isEraser ? Colors.white : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // 第二行:粗細選擇、橡皮擦和操作按鈕
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('粗細:', style: TextStyle(fontSize: 8, color: Colors.grey[700])),
                    const SizedBox(width: 2),
                    ...[2.0, 3.0, 5.0, 8.0].map((width) {
                      return GestureDetector(
                        onTap: () => setState(() {
                          _strokeWidth = width;
                          _isEraser = false;
                        }),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            color: _strokeWidth == width && !_isEraser ? Colors.blue[100] : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Container(
                            width: width,
                            height: width,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(width: 2),
                    // 橡皮擦按鈕
                    GestureDetector(
                      onTap: () => setState(() => _isEraser = !_isEraser),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _isEraser ? Colors.pink[100] : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Icon(
                          Icons.auto_fix_high,
                          size: 12,
                          color: _isEraser ? Colors.pink[700] : Colors.grey[600],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 操作按鈕
                    IconButton(
                      icon: const Icon(Icons.undo, size: 12),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      iconSize: 12,
                      onPressed: _drawingData.strokes.isEmpty ? null : _undoLastStroke,
                      tooltip: '復原',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 12),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      iconSize: 12,
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
    // 只要 currentStroke 有變化就重繪
    return oldDelegate.strokes.length != strokes.length || 
           oldDelegate.currentStroke.length != currentStroke.length ||
           oldDelegate.currentColor != currentColor ||
           oldDelegate.currentStrokeWidth != currentStrokeWidth;
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/drawing_data.dart';
import '../../l10n/app_localizations.dart';
import '../custom_color_picker_dialog.dart';
import 'managers/brush_texture_pool.dart';
import 'managers/drawing_cache_manager.dart';
import 'managers/drawing_history_manager.dart';
import 'painters/drawing_painter.dart';

/// 🎨 重構後的繪圖畫布
/// 
/// Phase 3 重構: 從 1518 行精簡至 ~320 行
/// 使用提取的管理器類別處理複雜邏輯
class DrawingCanvasRefactored extends StatefulWidget {
  final DrawingData initialDrawing;
  final Function(DrawingData) onDrawingChanged;
  final bool isReadOnly;
  final double? width;
  final double? height;

  const DrawingCanvasRefactored({
    super.key,
    required this.initialDrawing,
    required this.onDrawingChanged,
    this.isReadOnly = false,
    this.width,
    this.height,
  });

  @override
  State<DrawingCanvasRefactored> createState() => _DrawingCanvasRefactoredState();
}

class _DrawingCanvasRefactoredState extends State<DrawingCanvasRefactored> {
  // ===== 繪圖數據 =====
  late DrawingData _drawingData;
  List<Offset> _currentStroke = [];
  
  // ===== 工具狀態 =====
  Color _selectedColor = const Color(0xFF1E88E5);
  double _strokeWidth = 4.0;
  bool _isEraser = false;
  List<Color> _customColors = [];

  // ===== 管理器 =====
  late BrushTexturePool _texturePool;
  late DrawingCacheManager _cacheManager;
  late DrawingHistoryManager _historyManager;
  bool _isPoolReady = false;

  @override
  void initState() {
    super.initState();
    _drawingData = widget.initialDrawing;
    _texturePool = BrushTexturePool();
    _cacheManager = DrawingCacheManager();
    _historyManager = DrawingHistoryManager();
    
    _initializeTexturePool();
    _loadCustomColors();

    // 如果有舊紀錄，建立背景快取並保存到歷史
    if (_drawingData.strokes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rebuildCache().then((_) {
          if (mounted) _saveToHistory();
        });
      });
    } else {
      _saveToHistory();
    }
  }

  @override
  void dispose() {
    _texturePool.dispose();
    _cacheManager.dispose(cacheHistory: _historyManager.cacheHistory);
    _historyManager.dispose();
    super.dispose();
  }

  // ===== 初始化方法 =====

  Future<void> _initializeTexturePool() async {
    try {
      await _texturePool.buildPool(_selectedColor, _strokeWidth);
      if (mounted) {
        setState(() => _isPoolReady = true);
      }
    } catch (e) {
      debugPrint('❌ 紋理池初始化失敗: $e');
    }
  }

  Future<void> _rebuildTexturePool() async {
    setState(() => _isPoolReady = false);
    await _texturePool.buildPool(_selectedColor, _strokeWidth);
    if (mounted) {
      setState(() => _isPoolReady = true);
    }
  }

  Future<void> _loadCustomColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hexList = prefs.getStringList('custom_drawing_colors');
      if (hexList != null && mounted) {
        setState(() {
          _customColors = hexList
              .map((hex) => Color(int.parse(hex.replaceFirst('#', '0xFF'))))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading custom colors: $e');
    }
  }

  Future<void> _saveCustomColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hexList = _customColors
          .map((color) => '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}')
          .toList();
      await prefs.setStringList('custom_drawing_colors', hexList);
    } catch (e) {
      debugPrint('Error saving custom colors: $e');
    }
  }

  // ===== 手勢處理 =====

  void _onPanStart(DragStartDetails details) {
    if (widget.isReadOnly) return;
    setState(() {
      _currentStroke = [details.localPosition];
      _cacheManager.clearCurrentStrokeCache();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.isReadOnly) return;

    // 智能點採樣 - 避免點過密
    if (_currentStroke.isNotEmpty) {
      final lastPoint = _currentStroke.last;
      final distance = (details.localPosition - lastPoint).distance;
      if (distance < 2.0) return;
    }

    setState(() {
      _currentStroke = [..._currentStroke, details.localPosition];
    });

    // 增量更新當前筆劃快取
    _updateCurrentStrokeCache();
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.isReadOnly) return;
    if (_currentStroke.isEmpty) return;

    if (_isEraser) {
      _handleEraserEnd();
    } else {
      _handleDrawEnd();
    }
  }

  void _handleEraserEnd() {
    const eraserRadius = 25.0;
    final toDelete = <DrawingStroke>[];
    
    for (final stroke in _drawingData.strokes) {
      final shouldDelete = _currentStroke.any((eraserPoint) {
        return stroke.points.any((strokePoint) {
          final distance = (eraserPoint - strokePoint).distance;
          final threshold = eraserRadius + (stroke.strokeWidth / 2);
          return distance < threshold;
        });
      });
      if (shouldDelete) toDelete.add(stroke);
    }

    if (toDelete.isEmpty) {
      setState(() => _currentStroke = []);
      return;
    }

    for (final stroke in toDelete) {
      _drawingData.strokes.remove(stroke);
    }
    _currentStroke = [];

    _rebuildCache().then((_) {
      if (mounted) {
        setState(() {});
        _saveToHistory();
      }
    });
    
    widget.onDrawingChanged(_drawingData);
  }

  void _handleDrawEnd() {
    final stroke = DrawingStroke(
      points: List.from(_currentStroke),
      color: _selectedColor,
      strokeWidth: _strokeWidth,
      brushType: BrushType.texture,
    );
    
    setState(() {
      _drawingData.strokes.add(stroke);
      _currentStroke = [];
    });

    _updateCacheAndCleanup().then((_) {
      if (mounted) _saveToHistory();
    });
    
    widget.onDrawingChanged(_drawingData);
  }

  // ===== 快取操作 =====

  Future<void> _rebuildCache() async {
    final size = MediaQuery.of(context).size;
    final painter = _createPainter();
    await _cacheManager.rebuildCache(
      strokes: _drawingData.strokes,
      size: Size(widget.width ?? size.width, widget.height ?? size.height),
      cacheHistory: _historyManager.cacheHistory,
      painter: painter,
    );
  }

  Future<void> _updateCacheAndCleanup() async {
    final size = MediaQuery.of(context).size;
    final painter = _createPainter();
    await _cacheManager.updateCacheAndCleanup(
      strokes: _drawingData.strokes,
      size: Size(widget.width ?? size.width, widget.height ?? size.height),
      cacheHistory: _historyManager.cacheHistory,
      painterForNewStrokes: painter,
    );
  }

  Future<void> _updateCurrentStrokeCache() async {
    final size = MediaQuery.of(context).size;
    final painter = _createPainter();
    await _cacheManager.updateCurrentStrokeCache(
      currentStroke: _currentStroke,
      color: _selectedColor,
      strokeWidth: _strokeWidth,
      size: Size(widget.width ?? size.width, widget.height ?? size.height),
      painter: painter,
    );
    if (mounted) setState(() {});
  }

  DrawingPainter _createPainter() {
    return DrawingPainter(
      strokes: [],
      currentStroke: [],
      currentColor: _selectedColor,
      currentStrokeWidth: _strokeWidth,
      texturePool: _texturePool,
      isPoolReady: _isPoolReady,
    );
  }

  // ===== 歷史記錄操作 =====

  void _saveToHistory() {
    _historyManager.saveToHistory(
      strokes: _drawingData.strokes,
      currentCache: _cacheManager.cachedBackground,
    );
  }

  void _undoLastStroke() {
    final result = _historyManager.undo();
    if (result == null) return;

    setState(() {
      _drawingData.strokes.clear();
      _drawingData.strokes.addAll(result.strokes);
      _cacheManager.setBackgroundCache(
        result.cachedImage,
        _drawingData.strokes.length,
      );
    });
    
    widget.onDrawingChanged(_drawingData);
  }

  // ===== 自訂顏色對話框 =====

  void _showCustomColorPicker() {
    showDialog(
      context: context,
      builder: (context) => CustomColorPickerDialog(
        initialColor: _selectedColor,
        savedColors: _customColors,
        onColorsSaved: (List<Color> newColors) async {
          setState(() => _customColors = newColors);
          await _saveCustomColors();
        },
        onColorSelected: (Color color) async {
          setState(() {
            _selectedColor = color;
            _isEraser = false;
          });
          await _rebuildTexturePool();
        },
      ),
    );
  }

  // ===== 建構 UI =====

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCanvas(),
        if (!widget.isReadOnly) _buildToolbar(),
      ],
    );
  }

  Widget _buildCanvas() {
    return Flexible(
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
              painter: DrawingPainter(
                strokes: _drawingData.strokes,
                currentStroke: _currentStroke,
                currentColor: _isEraser
                    ? Colors.grey.withValues(alpha: 0.3)
                    : _selectedColor,
                currentStrokeWidth: _strokeWidth,
                isErasing: _isEraser,
                texturePool: _texturePool,
                isPoolReady: _isPoolReady,
                cachedBackground: _cacheManager.cachedBackground,
                currentStrokeCache: _cacheManager.currentStrokeCache,
                currentStrokeCachedPoints: _cacheManager.currentStrokeCachedPoints,
              ),
              child: Container(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
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
          _buildToolRow(l10n.errorDrawingColorLabel, _buildColorButtons()),
          const Divider(height: 12),
          _buildToolRow(l10n.errorDrawingSizeLabel, _buildSizeButtons()),
        ],
      ),
    );
  }

  Widget _buildToolRow(String label, List<Widget> buttons) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: buttons,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildColorButtons() {
    final List<Widget> buttons = [];

    if (_customColors.isNotEmpty) {
      for (int i = 0; i < _customColors.length && i < 5; i++) {
        buttons.add(_buildColorButton(_customColors[i]));
      }
    } else {
      const defaultColors = [
        Color(0xFF000000), Color(0xFFFF0000), Color(0xFF0000FF),
        Color(0xFF00FF00), Color(0xFFFFFF00),
      ];
      for (final color in defaultColors) {
        buttons.add(_buildColorButton(color));
      }
    }

    buttons.add(_buildRainbowButton());
    return buttons;
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _selectedColor == color && !_isEraser;
    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedColor = color;
          _isEraser = false;
        });
        await _rebuildTexturePool();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue[700]! : Colors.grey[400]!,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))
          ] : null,
        ),
      ),
    );
  }

  Widget _buildRainbowButton() {
    return GestureDetector(
      onTap: _showCustomColorPicker,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 36, height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(colors: [
            Colors.red, Colors.orange, Colors.yellow, Colors.green,
            Colors.blue, Color(0xFF4B0082), Color(0xFF9400D3), Colors.red
          ]),
          border: Border.all(color: Colors.grey[400]!, width: 2),
        ),
        child: const Icon(Icons.palette, color: Colors.white, size: 20),
      ),
    );
  }

  List<Widget> _buildSizeButtons() {
    final sizes = [4.0, 8.0, 12.0, 16.0];
    final buttons = sizes.map((width) {
      final isSelected = _strokeWidth == width && !_isEraser;
      return GestureDetector(
        onTap: () async {
          setState(() {
            _strokeWidth = width;
            _isEraser = false;
          });
          await _rebuildTexturePool();
        },
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[50] : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.blue[400]! : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: (width / 16 * 12).clamp(3.0, 12.0),
              height: (width / 16 * 12).clamp(3.0, 12.0),
              decoration: BoxDecoration(color: Colors.grey[800], shape: BoxShape.circle),
            ),
          ),
        ),
      );
    }).toList();

    // 橡皮擦按鈕
    buttons.add(GestureDetector(
      onTap: () => setState(() => _isEraser = !_isEraser),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: _isEraser ? Colors.pink[50] : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: _isEraser ? Colors.pink[400]! : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Icon(Icons.auto_fix_high, size: 20,
            color: _isEraser ? Colors.pink[700] : Colors.grey[600]),
      ),
    ));

    // Undo 按鈕
    buttons.add(GestureDetector(
      onTap: _drawingData.strokes.isEmpty ? null : _undoLastStroke,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: Icon(Icons.undo, size: 20,
            color: _drawingData.strokes.isEmpty ? Colors.grey[300] : Colors.grey[700]),
      ),
    ));

    return buttons;
  }
}

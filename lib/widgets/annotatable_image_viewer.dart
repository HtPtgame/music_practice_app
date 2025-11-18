import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/sheet_annotation.dart';
import '../utils/app_colors.dart';

/// 可標註的圖片檢視器
class AnnotatableImageViewer extends StatefulWidget {
  final AnnotatedSheet sheet;
  final Function(List<AnnotationMarker>) onMarkersChanged;
  final bool isEditable;

  const AnnotatableImageViewer({
    super.key,
    required this.sheet,
    required this.onMarkersChanged,
    this.isEditable = true,
  });

  @override
  State<AnnotatableImageViewer> createState() => _AnnotatableImageViewerState();
}

class _AnnotatableImageViewerState extends State<AnnotatableImageViewer> {
  List<AnnotationMarker> _markers = [];
  final TransformationController _transformationController =
      TransformationController();
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _markers = List.from(widget.sheet.markers);
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  void _addMarker(Offset position, Size imageSize) {
    if (!widget.isEditable) return;

    // 轉換為相對座標 (0.0 ~ 1.0)
    final relativePosition = Offset(
      position.dx / imageSize.width,
      position.dy / imageSize.height,
    );

    _showNoteDialog(relativePosition);
  }

  void _showNoteDialog(Offset relativePosition,
      [AnnotationMarker? existingMarker]) {
    final TextEditingController noteController = TextEditingController(
      text: existingMarker?.note ?? '',
    );
    Color selectedColor = existingMarker?.color ?? Colors.red;
    String selectedIcon = existingMarker?.iconPath ?? 'assets/star1.svg'; // 預設為星星1

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingMarker == null ? '新增標記' : '編輯標記'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: '筆記內容',
                    hintText: '輸入您的筆記...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('選擇星星圖標:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    'assets/star1.svg',
                    'assets/star2.svg',
                    'assets/star3.svg',
                  ].map((iconPath) {
                    final isSelected = selectedIcon == iconPath;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = iconPath),
                      child: Container(
                        width: 70,
                        height: 70,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.dynamicPrimary.withOpacity(0.1)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.dynamicPrimary
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SvgPicture.asset(
                          iconPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('標記顏色:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Colors.amber,        // 金色（適合星星）
                    Colors.yellow,       // 黃色
                    Colors.orange,       // 橙色
                    Colors.red,          // 紅色
                    Colors.blue,         // 藍色
                    Colors.purple,       // 紫色
                  ].map((color) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color
                                ? Colors.black
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            if (existingMarker != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _markers.removeWhere((m) => m.id == existingMarker.id);
                  });
                  widget.onMarkersChanged(_markers);
                  Navigator.pop(context);
                },
                child: const Text('刪除', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final note = noteController.text.trim();
                if (note.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('請輸入筆記內容')),
                  );
                  return;
                }

                setState(() {
                  if (existingMarker != null) {
                    // 更新現有標記
                    final index =
                        _markers.indexWhere((m) => m.id == existingMarker.id);
                    if (index != -1) {
                      _markers[index] = AnnotationMarker(
                        id: existingMarker.id,
                        position: existingMarker.position,
                        note: note,
                        createdAt: existingMarker.createdAt,
                        color: selectedColor,
                        iconPath: selectedIcon,
                      );
                    }
                  } else {
                    // 新增標記
                    _markers.add(AnnotationMarker(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      position: relativePosition,
                      note: note,
                      createdAt: DateTime.now(),
                      color: selectedColor,
                      iconPath: selectedIcon,
                    ));
                  }
                });
                widget.onMarkersChanged(_markers);
                Navigator.pop(context);
              },
              child: const Text('確定'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 計算圖片的實際尺寸
        return FutureBuilder<Size>(
          future: _getImageSize(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final imageSize = snapshot.data!;
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            // 計算縮放比例以適應螢幕
            final widthRatio = screenWidth / imageSize.width;
            final heightRatio = screenHeight / imageSize.height;
            final scale = widthRatio < heightRatio ? widthRatio : heightRatio;

            // 計算實際顯示尺寸
            final displayWidth = imageSize.width * scale;
            final displayHeight = imageSize.height * scale;

            // 全螢幕模式時的 padding 和樣式
            final outerPadding = _isFullScreen ? 0.0 : 16.0;
            final cardPadding = _isFullScreen ? 0.0 : 12.0; // Card 內部 padding
            final borderRadius = _isFullScreen ? 0.0 : 20.0;
            final showShadow = !_isFullScreen;

            return Container(
              padding: EdgeInsets.all(outerPadding),
              child: Center(
                child: Container(
                  width: _isFullScreen
                      ? screenWidth
                      : displayWidth + cardPadding * 2,
                  height: _isFullScreen
                      ? screenHeight
                      : displayHeight + cardPadding * 2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: showShadow
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: AppColors.dynamicPrimary.withOpacity(0.1),
                              blurRadius: 40,
                              offset: const Offset(0, 4),
                              spreadRadius: -10,
                            ),
                          ]
                        : null,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          _isFullScreen ? 0 : borderRadius - 8),
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: GestureDetector(
                          // 雙擊切換全螢幕
                          onDoubleTap: _toggleFullScreen,
                          onTapDown: widget.isEditable
                              ? (details) {
                                  final RenderBox box =
                                      context.findRenderObject() as RenderBox;
                                  final localPosition =
                                      box.globalToLocal(details.globalPosition);

                                  // 調整位置以考慮所有 padding
                                  final totalPadding =
                                      outerPadding + cardPadding;
                                  final adjustedPosition = Offset(
                                    localPosition.dx - totalPadding,
                                    localPosition.dy - totalPadding,
                                  );

                                  final contentWidth = _isFullScreen
                                      ? screenWidth
                                      : displayWidth;
                                  final contentHeight = _isFullScreen
                                      ? screenHeight
                                      : displayHeight;

                                  // 檢查是否點擊到現有標記
                                  for (final marker in _markers) {
                                    final markerPos = Offset(
                                      marker.position.dx * contentWidth,
                                      marker.position.dy * contentHeight,
                                    );
                                    final distance =
                                        (adjustedPosition - markerPos).distance;
                                    if (distance < 20) {
                                      _showNoteDialog(marker.position, marker);
                                      return;
                                    }
                                  }

                                  // 新增標記
                                  _addMarker(adjustedPosition,
                                      Size(contentWidth, contentHeight));
                                }
                              : null,
                          child: Stack(
                            children: [
                              // 背景圖片 - 帶邊框
                              Container(
                                width:
                                    _isFullScreen ? screenWidth : displayWidth,
                                height: _isFullScreen
                                    ? screenHeight
                                    : displayHeight,
                                decoration: BoxDecoration(
                                  border: _isFullScreen
                                      ? null
                                      : Border.all(
                                          color: AppColors.dynamicPrimary
                                              .withOpacity(0.2),
                                          width: 3,
                                        ),
                                  borderRadius: _isFullScreen
                                      ? null
                                      : BorderRadius.circular(
                                          borderRadius - 10),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      _isFullScreen ? 0 : borderRadius - 12),
                                  child: Image.file(
                                    File(widget.sheet.filePath),
                                    fit: BoxFit.contain,
                                    width: _isFullScreen
                                        ? screenWidth
                                        : displayWidth,
                                    height: _isFullScreen
                                        ? screenHeight
                                        : displayHeight,
                                  ),
                                ),
                              ),

                              // 標記圖標
                              ..._markers.map((marker) {
                                final contentWidth =
                                    _isFullScreen ? screenWidth : displayWidth;
                                final contentHeight = _isFullScreen
                                    ? screenHeight
                                    : displayHeight;

                                return Positioned(
                                  left: marker.position.dx * contentWidth - 20,
                                  top: marker.position.dy * contentHeight - 20,
                                  child: GestureDetector(
                                    onTap: () => _showNoteDialog(
                                        marker.position, marker),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: SvgPicture.asset(
                                        marker.iconPath,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Size> _getImageSize() async {
    final image = Image.file(File(widget.sheet.filePath));
    final completer = Completer<Size>();
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );
    return completer.future;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}

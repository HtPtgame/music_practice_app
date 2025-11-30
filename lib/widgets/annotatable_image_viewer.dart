import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/sheet_annotation.dart';
import '../utils/app_colors.dart';
import '../l10n/app_localizations.dart';

/// 可標註的圖片檢視器
class AnnotatableImageViewer extends StatefulWidget {
  final AnnotatedSheet sheet;
  final Function(List<AnnotationMarker>) onMarkersChanged;
  final bool isEditable;
  final bool isFullScreen;

  const AnnotatableImageViewer({
    super.key,
    required this.sheet,
    required this.onMarkersChanged,
    this.isEditable = true,
    this.isFullScreen = false,
  });

  @override
  State<AnnotatableImageViewer> createState() => _AnnotatableImageViewerState();
}

class _AnnotatableImageViewerState extends State<AnnotatableImageViewer> {
  List<AnnotationMarker> _markers = [];
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _markers = List.from(widget.sheet.markers);
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
    final TextEditingController measureController = TextEditingController(
      text: existingMarker?.measure?.toString() ?? '',
    );
    Color selectedColor = existingMarker?.color ?? Colors.red;
    String selectedIcon = existingMarker?.iconPath ?? 'assets/star1.svg'; // 預設為星星1

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingMarker == null 
              ? AppLocalizations.of(context)!.annotationAddMarker 
              : AppLocalizations.of(context)!.annotationEditMarker),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: measureController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.annotationMeasureLabel,
                    hintText: AppLocalizations.of(context)!.annotationMeasureHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.annotationNoteLabel,
                    hintText: AppLocalizations.of(context)!.annotationNoteHint,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.annotationSelectStar, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                child: Text(AppLocalizations.of(context)!.annotationDelete, style: const TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.annotationCancel),
            ),
            ElevatedButton(
              onPressed: () {
                final note = noteController.text.trim();
                if (note.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.annotationInputRequired)),
                  );
                  return;
                }
                
                // 解析小節數
                final measureText = measureController.text.trim();
                final int? measureNum = measureText.isEmpty ? null : int.tryParse(measureText);

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
                        measure: measureNum,
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
                      measure: measureNum,
                    ));
                  }
                });
                widget.onMarkersChanged(_markers);
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.annotationConfirm),
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
            final isFullScreen = widget.isFullScreen;
            final outerPadding = isFullScreen ? 0.0 : 16.0;
            final cardPadding = isFullScreen ? 0.0 : 12.0; // Card 內部 padding
            final borderRadius = isFullScreen ? 0.0 : 20.0;
            final showShadow = !isFullScreen;

            return Container(
              padding: EdgeInsets.all(outerPadding),
              child: Center(
                child: Container(
                  width: isFullScreen
                      ? screenWidth
                      : displayWidth + cardPadding * 2,
                  height: isFullScreen
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
                          isFullScreen ? 0 : borderRadius - 8),
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: GestureDetector(
                          // 雙擊加入標記
                          onDoubleTapDown: widget.isEditable
                              ? (details) {
                                  final RenderBox box =
                                      context.findRenderObject() as RenderBox;
                                  final localPosition =
                                      box.globalToLocal(details.globalPosition);

                                  // 調整位置以考慮所有 padding 和圖片居中偏移
                                  final totalPadding =
                                      outerPadding + cardPadding;
                                  final offsetX = isFullScreen
                                      ? (screenWidth - displayWidth) / 2
                                      : 0.0;
                                  final offsetY = isFullScreen
                                      ? (screenHeight - displayHeight) / 2
                                      : 0.0;
                                  final adjustedPosition = Offset(
                                    localPosition.dx - totalPadding - offsetX,
                                    localPosition.dy - totalPadding - offsetY,
                                  );

                                  // 新增標記 (使用實際顯示尺寸)
                                  _addMarker(adjustedPosition,
                                      Size(displayWidth, displayHeight));
                                }
                              : null,
                          child: Stack(
                            children: [
                              // 背景圖片 - 帶邊框
                              Container(
                                width:
                                    isFullScreen ? screenWidth : displayWidth,
                                height: isFullScreen
                                    ? screenHeight
                                    : displayHeight,
                                decoration: BoxDecoration(
                                  border: isFullScreen
                                      ? null
                                      : Border.all(
                                          color: AppColors.dynamicPrimary
                                              .withOpacity(0.2),
                                          width: 3,
                                        ),
                                  borderRadius: isFullScreen
                                      ? null
                                      : BorderRadius.circular(
                                          borderRadius - 10),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      isFullScreen ? 0 : borderRadius - 12),
                                  child: Image.file(
                                    File(widget.sheet.filePath),
                                    fit: BoxFit.contain,
                                    width: isFullScreen
                                        ? screenWidth
                                        : displayWidth,
                                    height: isFullScreen
                                        ? screenHeight
                                        : displayHeight,
                                  ),
                                ),
                              ),

                              // 標記圖標 (縮小: 24x24)
                              ..._markers.map((marker) {
                                // 計算圖片居中後的偏移量
                                final offsetX = isFullScreen
                                    ? (screenWidth - displayWidth) / 2
                                    : 0.0;
                                final offsetY = isFullScreen
                                    ? (screenHeight - displayHeight) / 2
                                    : 0.0;

                                return Positioned(
                                  left: offsetX + marker.position.dx * displayWidth - 12,
                                  top: offsetY + marker.position.dy * displayHeight - 12,
                                  child: GestureDetector(
                                    onTap: () => _showNoteDialog(
                                        marker.position, marker),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                            spreadRadius: 0,
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

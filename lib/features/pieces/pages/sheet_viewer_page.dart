import 'package:flutter/material.dart';
import 'package:music_practice_app/models/sheet_annotation.dart';
import 'package:music_practice_app/widgets/annotatable_image_viewer.dart';

class SheetViewerPage extends StatefulWidget {
  final AnnotatedSheet sheet;
  final Function(AnnotatedSheet) onSave;

  const SheetViewerPage({
    super.key,
    required this.sheet,
    required this.onSave,
  });

  @override
  State<SheetViewerPage> createState() => _SheetViewerPageState();
}

class _SheetViewerPageState extends State<SheetViewerPage> {
  late AnnotatedSheet _currentSheet;

  @override
  void initState() {
    super.initState();
    _currentSheet = widget.sheet;
  }

  void _onMarkersChanged(List<AnnotationMarker> markers) {
    setState(() {
      _currentSheet = _currentSheet.copyWith(
        markers: markers,
        updatedAt: DateTime.now(),
      );
    });
    widget.onSave(_currentSheet);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 全螢幕圖片檢視器
          AnnotatableImageViewer(
            sheet: _currentSheet,
            onMarkersChanged: _onMarkersChanged,
            isFullScreen: true,
          ),
          // 左上角關閉按鈕
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
            ),
          ),
          // 右上角標記數量
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bookmark,
                    size: 16,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentSheet.markers.length}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

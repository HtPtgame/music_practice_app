import 'dart:convert';
import 'package:flutter/material.dart';

/// 譜面標記點
class AnnotationMarker {
  final String id;
  final Offset position; // 相對位置 (0.0 ~ 1.0)
  final String note;
  final int? measure; // 小節數
  final DateTime createdAt;
  final Color color;
  final String iconPath; // 星星圖標路徑

  AnnotationMarker({
    required this.id,
    required this.position,
    required this.note,
    this.measure,
    required this.createdAt,
    this.color = Colors.red,
    this.iconPath = 'assets/icon/star1.svg', // 預設為星星1
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': position.dx,
      'y': position.dy,
      'note': note,
      'measure': measure,
      'createdAt': createdAt.toIso8601String(),
      'color': color.value,
      'iconPath': iconPath,
    };
  }

  factory AnnotationMarker.fromJson(Map<String, dynamic> json) {
    // 修正舊路徑 (assets/star*.svg → assets/icon/star*.svg)
    String iconPath = json['iconPath'] as String? ?? 'assets/icon/star1.svg';
    if (iconPath.startsWith('assets/star') &&
        !iconPath.startsWith('assets/icon/')) {
      iconPath = iconPath.replaceFirst('assets/', 'assets/icon/');
    }

    return AnnotationMarker(
      id: json['id'] as String,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      note: json['note'] as String,
      measure: json['measure'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      color: Color(json['color'] as int),
      iconPath: iconPath,
    );
  }
}

/// 帶註解的譜面
class AnnotatedSheet {
  final String sheetId;
  final String filePath; // PDF 或圖片路徑
  final String fileName;
  final List<AnnotationMarker> markers;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnnotatedSheet({
    required this.sheetId,
    required this.filePath,
    required this.fileName,
    List<AnnotationMarker>? markers,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : markers = markers ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  AnnotatedSheet copyWith({
    String? sheetId,
    String? filePath,
    String? fileName,
    List<AnnotationMarker>? markers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnnotatedSheet(
      sheetId: sheetId ?? this.sheetId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      markers: markers ?? this.markers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sheetId': sheetId,
      'filePath': filePath,
      'fileName': fileName,
      'markers': markers.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AnnotatedSheet.fromJson(Map<String, dynamic> json) {
    return AnnotatedSheet(
      sheetId: json['sheetId'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      markers: (json['markers'] as List?)
              ?.map((m) => AnnotationMarker.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory AnnotatedSheet.fromJsonString(String str) =>
      AnnotatedSheet.fromJson(jsonDecode(str) as Map<String, dynamic>);
}

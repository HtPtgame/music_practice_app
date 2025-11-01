import 'dart:ui';

/// 繪圖筆劃數據模型
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
    };
  }

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      points: (json['points'] as List)
          .map((p) => Offset(p['x'] as double, p['y'] as double))
          .toList(),
      color: Color(json['color'] as int),
      strokeWidth: json['strokeWidth'] as double,
    );
  }
}

/// 繪圖數據模型
class DrawingData {
  final List<DrawingStroke> strokes;

  DrawingData({List<DrawingStroke>? strokes}) : strokes = strokes ?? [];

  bool get isEmpty => strokes.isEmpty;
  bool get isNotEmpty => strokes.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'strokes': strokes.map((s) => s.toJson()).toList(),
    };
  }

  factory DrawingData.fromJson(Map<String, dynamic> json) {
    return DrawingData(
      strokes: (json['strokes'] as List)
          .map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  DrawingData copyWith({List<DrawingStroke>? strokes}) {
    return DrawingData(
      strokes: strokes ?? this.strokes,
    );
  }
}

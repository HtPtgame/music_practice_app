import 'dart:convert';

/// 單則上課重點
class LessonPoint {
  final String id;
  final LessonNoteCategory category;
  final String content;
  final String? relatedPieceId;
  final String? relatedPieceName;
  final String? measureRange;

  const LessonPoint({
    required this.id,
    required this.category,
    required this.content,
    this.relatedPieceId,
    this.relatedPieceName,
    this.measureRange,
  });

  LessonPoint copyWith({
    String? id,
    LessonNoteCategory? category,
    String? content,
    String? relatedPieceId,
    String? relatedPieceName,
    String? measureRange,
  }) {
    return LessonPoint(
      id: id ?? this.id,
      category: category ?? this.category,
      content: content ?? this.content,
      relatedPieceId: relatedPieceId ?? this.relatedPieceId,
      relatedPieceName: relatedPieceName ?? this.relatedPieceName,
      measureRange: measureRange ?? this.measureRange,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': category.id,
      'categoryName': category.displayName,
      'content': content,
      'relatedPieceId': relatedPieceId,
      'relatedPieceName': relatedPieceName,
      'measureRange': measureRange,
    };
  }

  factory LessonPoint.fromJson(Map<String, dynamic> json) {
    return LessonPoint(
      id: json['id'] as String,
      category: LessonNoteCategory(
        id: json['categoryId'] as String,
        displayName: json['categoryName'] as String,
      ),
      content: json['content'] as String,
      relatedPieceId: json['relatedPieceId'] as String?,
      relatedPieceName: json['relatedPieceName'] as String?,
      measureRange: json['measureRange'] as String?,
    );
  }
}

/// 一次上課紀錄（包含多則重點）
class LessonRecord {
  final String id;
  final DateTime lessonDate;
  final List<LessonPoint> points;
  final DateTime createdAt;

  const LessonRecord({
    required this.id,
    required this.lessonDate,
    required this.points,
    required this.createdAt,
  });

  LessonRecord copyWith({
    String? id,
    DateTime? lessonDate,
    List<LessonPoint>? points,
    DateTime? createdAt,
  }) {
    return LessonRecord(
      id: id ?? this.id,
      lessonDate: lessonDate ?? this.lessonDate,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonDate': lessonDate.toIso8601String(),
      'points': points.map((p) => p.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LessonRecord.fromJson(Map<String, dynamic> json) {
    return LessonRecord(
      id: json['id'] as String,
      lessonDate: DateTime.parse(json['lessonDate'] as String),
      points: (json['points'] as List<dynamic>)
          .map((p) => LessonPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory LessonRecord.fromJsonString(String jsonStr) {
    return LessonRecord.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }
}

class LessonNoteCategory {
  final String id;
  final String displayName;

  const LessonNoteCategory({
    required this.id,
    required this.displayName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonNoteCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class LessonCategories {
  static const slowPractice = LessonNoteCategory(
    id: 'slow_practice',
    displayName: '慢練',
  );
  static const technique = LessonNoteCategory(
    id: 'technique',
    displayName: '技巧',
  );
  static const tone = LessonNoteCategory(
    id: 'tone',
    displayName: '音色',
  );
  static const other = LessonNoteCategory(
    id: 'other',
    displayName: '其他',
  );

  static List<LessonNoteCategory> all = [
    slowPractice,
    technique,
    tone,
    other,
  ];

  static LessonNoteCategory fromId(String id) {
    return all.firstWhere(
      (c) => c.id == id,
      orElse: () => other,
    );
  }
}

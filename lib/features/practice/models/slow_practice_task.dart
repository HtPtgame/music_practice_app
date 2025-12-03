import 'dart:convert';

/// 慢練任務狀態
enum SlowPracticeStatus {
  pending,    // 待練習
  inProgress, // 進行中
  completed,  // 已完成
}

/// 單個練習段落
class PracticeSegment {
  final String id;
  final int startMeasure;
  final int endMeasure;
  int perfectCount;       // 連續完美次數 (用於 Step 3, 4)
  int totalAttempts;      // 總嘗試次數
  bool isCompleted;       // 是否完成
  int currentSpeedPercent; // 當前速度百分比

  PracticeSegment({
    required this.id,
    required this.startMeasure,
    required this.endMeasure,
    this.perfectCount = 0,
    this.totalAttempts = 0,
    this.isCompleted = false,
    this.currentSpeedPercent = 40,
  });

  String get displayRange => '$startMeasure-$endMeasure 小節';

  Map<String, dynamic> toJson() => {
    'id': id,
    'startMeasure': startMeasure,
    'endMeasure': endMeasure,
    'perfectCount': perfectCount,
    'totalAttempts': totalAttempts,
    'isCompleted': isCompleted,
    'currentSpeedPercent': currentSpeedPercent,
  };

  factory PracticeSegment.fromJson(Map<String, dynamic> json) {
    return PracticeSegment(
      id: json['id'] as String,
      startMeasure: json['startMeasure'] as int,
      endMeasure: json['endMeasure'] as int,
      perfectCount: json['perfectCount'] as int? ?? 0,
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      currentSpeedPercent: json['currentSpeedPercent'] as int? ?? 40,
    );
  }
}

/// 慢練 SOP 任務
class SlowPracticeTask {
  final String id;
  final String? pieceId;
  final String? pieceName;
  final String? measureRange;      // 從家庭聯絡簿帶入的小節範圍
  final String? lessonContent;     // 從家庭聯絡簿帶入的內容
  final DateTime createdAt;
  final DateTime? completedAt;
  SlowPracticeStatus status;
  List<PracticeSegment> segments;  // 細分的練習段落
  int currentStep;                 // 當前步驟 (0-4)
  
  // 新增欄位
  int targetBpm;                   // 目標原速 (Step 1)
  int initialSpeedPercent;         // 初始練習速度百分比 (Step 1)
  List<String> checklistSelected;  // 已選的拆解項目 (Step 2)
  int currentBpm;                  // 當前練習速度 (Step 3, 4)
  int consecutiveSuccessCount;     // 當前速度的連續成功次數 (Step 3, 4)
  int finalChallengeSuccessCount;  // 最終挑戰連續成功次數 (Step 5)
  
  // 練習紀錄
  int totalPracticeSeconds;        // 總練習時間

  SlowPracticeTask({
    required this.id,
    this.pieceId,
    this.pieceName,
    this.measureRange,
    this.lessonContent,
    required this.createdAt,
    this.completedAt,
    this.status = SlowPracticeStatus.pending,
    List<PracticeSegment>? segments,
    this.currentStep = 0,
    this.totalPracticeSeconds = 0,
    this.targetBpm = 100,
    this.initialSpeedPercent = 40,
    List<String>? checklistSelected,
    this.currentBpm = 40,
    this.consecutiveSuccessCount = 0,
    this.finalChallengeSuccessCount = 0,
  }) : segments = segments ?? [],
       checklistSelected = checklistSelected ?? [];

  /// 從小節範圍解析出開始和結束小節
  (int?, int?) get parsedMeasureRange {
    if (measureRange == null) return (null, null);
    final match = RegExp(r'(\d+)[-~](\d+)').firstMatch(measureRange!);
    if (match != null) {
      return (int.parse(match.group(1)!), int.parse(match.group(2)!));
    }
    final single = RegExp(r'(\d+)').firstMatch(measureRange!);
    if (single != null) {
      final m = int.parse(single.group(1)!);
      return (m, m);
    }
    return (null, null);
  }

  /// 自動分割段落（每 2-4 小節為一段）
  void autoSplitSegments() {
    final (start, end) = parsedMeasureRange;
    if (start == null || end == null) return;
    
    segments.clear();
    int current = start;
    int segmentId = 0;
    
    while (current <= end) {
      final segmentEnd = (current + 3).clamp(current, end);
      segments.add(PracticeSegment(
        id: '${id}_seg_$segmentId',
        startMeasure: current,
        endMeasure: segmentEnd,
      ));
      current = segmentEnd + 1;
      segmentId++;
    }
  }

  /// 計算整體進度 (0.0 - 1.0)
  double get overallProgress {
    // 簡單計算：步驟進度 / 總步驟數
    return currentStep / 3.0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pieceId': pieceId,
    'pieceName': pieceName,
    'measureRange': measureRange,
    'lessonContent': lessonContent,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'status': status.index,
    'segments': segments.map((s) => s.toJson()).toList(),
    'currentStep': currentStep,
    'totalPracticeSeconds': totalPracticeSeconds,
    'targetBpm': targetBpm,
    'initialSpeedPercent': initialSpeedPercent,
    'checklistSelected': checklistSelected,
    'currentBpm': currentBpm,
    'consecutiveSuccessCount': consecutiveSuccessCount,
    'finalChallengeSuccessCount': finalChallengeSuccessCount,
  };

  factory SlowPracticeTask.fromJson(Map<String, dynamic> json) {
    return SlowPracticeTask(
      id: json['id'] as String,
      pieceId: json['pieceId'] as String?,
      pieceName: json['pieceName'] as String?,
      measureRange: json['measureRange'] as String?,
      lessonContent: json['lessonContent'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      status: SlowPracticeStatus.values[json['status'] as int? ?? 0],
      segments: (json['segments'] as List<dynamic>?)
          ?.map((s) => PracticeSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
      currentStep: json['currentStep'] as int? ?? 0,
      totalPracticeSeconds: json['totalPracticeSeconds'] as int? ?? 0,
      targetBpm: json['targetBpm'] as int? ?? 100,
      initialSpeedPercent: json['initialSpeedPercent'] as int? ?? 40,
      checklistSelected: (json['checklistSelected'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      currentBpm: json['currentBpm'] as int? ?? 40,
      consecutiveSuccessCount: json['consecutiveSuccessCount'] as int? ?? 0,
      finalChallengeSuccessCount: json['finalChallengeSuccessCount'] as int? ?? 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SlowPracticeTask.fromJsonString(String jsonStr) {
    return SlowPracticeTask.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }
}

/// 慢練 SOP 步驟定義 (新版 3 步驟)
class SlowPracticeSteps {
  static const List<SlowPracticeStepInfo> all = [
    SlowPracticeStepInfo(
      step: 0,
      title: '設定 & 拆解',
      shortDesc: '設定速度 & 拆解方式',
      fullDesc: '設定目標原速，並選擇拆解方式（例如「左手單獨」或「節奏拆解」），強迫大腦先處理簡單的資訊。',
      icon: '⚙️',
    ),
    SlowPracticeStepInfo(
      step: 1,
      title: '慢速迭代 (Slow Iteration)',
      shortDesc: '從初始速度到 100%',
      fullDesc: '從初始速度開始練習到 100% 原速。必須按下綠色的「成功」按鈕 3 次，速度條才會往右跳一格。按紅色「失誤」則當前級距歸零。',
      icon: '🐢',
    ),
    SlowPracticeStepInfo(
      step: 2,
      title: '完整演練 (Full Rehearsal)',
      shortDesc: '連續 5 次全對',
      fullDesc: '最後的考驗。每次成功點亮一個綠燈，只要按一次「中斷/失敗」，所有綠燈歸零。確保肌肉記憶穩固。',
      icon: '🏆',
    ),
  ];
}

class SlowPracticeStepInfo {
  final int step;
  final String title;
  final String shortDesc;
  final String fullDesc;
  final String icon;

  const SlowPracticeStepInfo({
    required this.step,
    required this.title,
    required this.shortDesc,
    required this.fullDesc,
    required this.icon,
  });
}

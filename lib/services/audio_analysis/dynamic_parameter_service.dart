/// 動態參數配置服務 (Round 9 - 2025/10/26)
/// 
/// 根據樂曲特性自動調整檢測參數：
/// 1. energyThreshold: 根據樂曲難度 (0.30~0.40)
/// 2. timingTolerance: 根據樂曲速度 (0.08~0.20秒)
library;

import 'dart:math';
import 'models/note_event.dart';

/// 樂曲難度等級
enum DifficultyLevel {
  beginner,     // 初學者
  intermediate, // 中級
  advanced,     // 進階
  expert,       // 專家
}

/// 動態參數配置
class DynamicParameters {
  /// 能量閾值 (0.30~0.40)
  final double energyThreshold;
  
  /// 時間容錯窗口 (秒, 0.08~0.20)
  final double timingTolerance;
  
  /// 難度等級
  final DifficultyLevel difficulty;
  
  /// 平均速度 (音符/秒)
  final double averageSpeed;
  
  /// 音符總數
  final int noteCount;
  
  /// 曲目時長 (秒)
  final double duration;
  
  /// 平均 BPM (從 tempo 計算)
  final double? averageBpm;

  const DynamicParameters({
    required this.energyThreshold,
    required this.timingTolerance,
    required this.difficulty,
    required this.averageSpeed,
    required this.noteCount,
    required this.duration,
    this.averageBpm,
  });

  @override
  String toString() {
    return '''
DynamicParameters {
  難度: $difficulty
  音符數: $noteCount
  時長: ${duration.toStringAsFixed(1)}秒
  平均速度: ${averageSpeed.toStringAsFixed(2)} 音符/秒
  ${averageBpm != null ? 'BPM: ${averageBpm!.toStringAsFixed(0)}' : ''}
  
  → energyThreshold: ${energyThreshold.toStringAsFixed(2)}
  → timingTolerance: ±${(timingTolerance * 1000).toStringAsFixed(0)}ms
}''';
  }
}

/// 動態參數配置服務
class DynamicParameterService {
  // ═══════════════════════════════════════════════════════════
  // 參數範圍定義
  // ═══════════════════════════════════════════════════════════
  
  /// energyThreshold 範圍 (根據 Round 8 測試結果)
  static const double minEnergyThreshold = 0.30; // 複雜曲目，高靈敏度
  static const double maxEnergyThreshold = 0.40; // 簡單曲目，高穩定性
  
  /// timingTolerance 範圍
  static const double minTimingTolerance = 0.08; // 快速曲目，±80ms
  static const double maxTimingTolerance = 0.20; // 慢速曲目，±200ms
  
  // ═══════════════════════════════════════════════════════════
  // 難度評估參數閾值
  // ═══════════════════════════════════════════════════════════
  
  /// 音符數閾值
  static const int beginnerNoteThreshold = 100;     // ≤100: 初學者
  static const int intermediateNoteThreshold = 500; // ≤500: 中級
  static const int advancedNoteThreshold = 1000;    // ≤1000: 進階
  
  /// 音符密度閾值 (音符/秒)
  static const double beginnerSpeedThreshold = 3.0;    // ≤3: 初學者
  static const double intermediateSpeedThreshold = 6.0; // ≤6: 中級
  static const double advancedSpeedThreshold = 10.0;   // ≤10: 進階
  
  /// 曲目時長閾值 (秒)
  static const double longPieceDuration = 120.0; // ≥2分鐘視為長曲目
  
  // ═══════════════════════════════════════════════════════════
  // 主要功能：計算動態參數
  // ═══════════════════════════════════════════════════════════
  
  /// 根據 MIDI Timeline 計算動態參數
  DynamicParameters calculateParameters(MidiTimeline timeline, {double? averageBpm}) {
    final noteCount = timeline.events.length;
    final duration = timeline.duration;
    
    // 計算平均速度 (音符/秒)
    final averageSpeed = noteCount / max(duration, 1.0);
    
    // 評估難度等級
    final difficulty = _assessDifficulty(
      noteCount: noteCount,
      duration: duration,
      averageSpeed: averageSpeed,
    );
    
    // 計算 energyThreshold (根據難度)
    final energyThreshold = _calculateEnergyThreshold(
      difficulty: difficulty,
      noteCount: noteCount,
      duration: duration,
    );
    
    // 計算 timingTolerance (根據速度)
    final timingTolerance = _calculateTimingTolerance(
      averageSpeed: averageSpeed,
      averageBpm: averageBpm,
    );
    
    return DynamicParameters(
      energyThreshold: energyThreshold,
      timingTolerance: timingTolerance,
      difficulty: difficulty,
      averageSpeed: averageSpeed,
      noteCount: noteCount,
      duration: duration,
      averageBpm: averageBpm,
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // 難度評估
  // ═══════════════════════════════════════════════════════════
  
  /// 評估樂曲難度
  /// 
  /// 綜合考慮：
  /// 1. 音符總數
  /// 2. 音符密度 (速度)
  /// 3. 曲目時長
  DifficultyLevel _assessDifficulty({
    required int noteCount,
    required double duration,
    required double averageSpeed,
  }) {
    // 計算難度分數 (0-100)
    int score = 0;
    
    // 1. 音符數評分 (0-40分)
    if (noteCount <= beginnerNoteThreshold) {
      score += 0; // 0-10分
    } else if (noteCount <= intermediateNoteThreshold) {
      score += 10 + ((noteCount - beginnerNoteThreshold) / 
               (intermediateNoteThreshold - beginnerNoteThreshold) * 10).toInt();
    } else if (noteCount <= advancedNoteThreshold) {
      score += 20 + ((noteCount - intermediateNoteThreshold) / 
               (advancedNoteThreshold - intermediateNoteThreshold) * 10).toInt();
    } else {
      score += 30 + min(((noteCount - advancedNoteThreshold) / 500 * 10).toInt(), 10);
    }
    
    // 2. 音符速度評分 (0-40分)
    if (averageSpeed <= beginnerSpeedThreshold) {
      score += 0;
    } else if (averageSpeed <= intermediateSpeedThreshold) {
      score += 10 + ((averageSpeed - beginnerSpeedThreshold) / 
               (intermediateSpeedThreshold - beginnerSpeedThreshold) * 10).toInt();
    } else if (averageSpeed <= advancedSpeedThreshold) {
      score += 20 + ((averageSpeed - intermediateSpeedThreshold) / 
               (advancedSpeedThreshold - intermediateSpeedThreshold) * 10).toInt();
    } else {
      score += 30 + min(((averageSpeed - advancedSpeedThreshold) / 5 * 10).toInt(), 10);
    }
    
    // 3. 時長評分 (0-20分)
    if (duration >= longPieceDuration) {
      score += 10; // 長曲目增加難度
      if (averageSpeed > intermediateSpeedThreshold) {
        score += 10; // 又快又長，難度更高
      }
    }
    
    // 根據總分判定難度
    if (score < 20) {
      return DifficultyLevel.beginner;
    } else if (score < 50) {
      return DifficultyLevel.intermediate;
    } else if (score < 75) {
      return DifficultyLevel.advanced;
    } else {
      return DifficultyLevel.expert;
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // energyThreshold 計算
  // ═══════════════════════════════════════════════════════════
  
  /// 計算動態 energyThreshold
  /// 
  /// 策略 (基於 Round 8 測試結果):
  /// - 簡單曲目 (初學者): 0.38-0.40 (高閾值，減少噪音誤報)
  /// - 中等曲目: 0.35-0.38 (平衡值)
  /// - 複雜曲目 (進階/專家): 0.30-0.35 (低閾值，提高召回率)
  /// 
  /// 特殊調整:
  /// - 長曲目 (>120秒): -0.02 (避免能量衰減導致漏音)
  /// - 極快速度 (>10音符/秒): -0.02 (提高靈敏度)
  double _calculateEnergyThreshold({
    required DifficultyLevel difficulty,
    required int noteCount,
    required double duration,
  }) {
    double threshold;
    
    // 基礎閾值 (根據難度)
    switch (difficulty) {
      case DifficultyLevel.beginner:
        threshold = 0.39; // 簡單曲目，高穩定性
        break;
      case DifficultyLevel.intermediate:
        threshold = 0.36; // 中等曲目，平衡
        break;
      case DifficultyLevel.advanced:
        threshold = 0.33; // 進階曲目，提高靈敏度
        break;
      case DifficultyLevel.expert:
        threshold = 0.30; // 專家曲目，最高靈敏度
        break;
    }
    
    // 調整 1: 長曲目補償 (避免能量衰減)
    if (duration > longPieceDuration) {
      threshold -= 0.02;
    }
    
    // 調整 2: 極高音符密度補償
    final averageSpeed = noteCount / max(duration, 1.0);
    if (averageSpeed > advancedSpeedThreshold) {
      threshold -= 0.02;
    }
    
    // 限制在有效範圍內
    return threshold.clamp(minEnergyThreshold, maxEnergyThreshold);
  }
  
  // ═══════════════════════════════════════════════════════════
  // timingTolerance 計算
  // ═══════════════════════════════════════════════════════════
  
  /// 計算動態 timingTolerance
  /// 
  /// 策略:
  /// - 慢速曲目 (≤3音符/秒): ±200ms (寬容錯)
  /// - 中速曲目 (3-6音符/秒): ±150ms (中等)
  /// - 快速曲目 (6-10音符/秒): ±100ms (嚴格)
  /// - 極快曲目 (>10音符/秒): ±80ms (極嚴格)
  /// 
  /// BPM 輔助計算:
  /// - 若有 BPM 資訊，可更精確計算
  /// - 慢速 (<90 BPM): ±200ms
  /// - 中速 (90-140 BPM): ±150ms
  /// - 快速 (>140 BPM): ±100ms
  double _calculateTimingTolerance({
    required double averageSpeed,
    double? averageBpm,
  }) {
    double tolerance;
    
    // 優先使用 BPM 計算 (更準確)
    if (averageBpm != null && averageBpm > 0) {
      if (averageBpm < 90) {
        tolerance = 0.20; // 慢速，寬容錯
      } else if (averageBpm < 140) {
        tolerance = 0.15; // 中速
      } else if (averageBpm < 180) {
        tolerance = 0.10; // 快速
      } else {
        tolerance = 0.08; // 極快
      }
    } else {
      // 使用音符密度計算
      if (averageSpeed <= beginnerSpeedThreshold) {
        tolerance = 0.20; // 慢速，≤3音符/秒
      } else if (averageSpeed <= intermediateSpeedThreshold) {
        tolerance = 0.15; // 中速，≤6音符/秒
      } else if (averageSpeed <= advancedSpeedThreshold) {
        tolerance = 0.10; // 快速，≤10音符/秒
      } else {
        tolerance = 0.08; // 極快，>10音符/秒
      }
    }
    
    // 限制在有效範圍內
    return tolerance.clamp(minTimingTolerance, maxTimingTolerance);
  }
  
  // ═══════════════════════════════════════════════════════════
  // 輔助功能：從 Tempo 事件計算平均 BPM
  // ═══════════════════════════════════════════════════════════
  
  /// 從 MIDI Tempo 事件計算平均 BPM
  /// 
  /// 參數:
  /// - tempoEvents: Tempo 變化事件列表
  /// - duration: 曲目總時長 (秒)
  /// 
  /// 返回: 平均 BPM，若無 tempo 事件則返回 null
  static double? calculateAverageBpm({
    required List<dynamic> tempoEvents, // List<TempoChange>
    required double duration,
  }) {
    if (tempoEvents.isEmpty || duration <= 0) {
      return null;
    }
    
    // 簡單情況：只有一個 tempo
    if (tempoEvents.length == 1) {
      final microsecondsPerQuarter = tempoEvents[0].microsecondsPerQuarter;
      return 60000000.0 / microsecondsPerQuarter; // 60秒 * 1,000,000微秒 / 微秒每四分音符
    }
    
    // 複雜情況：加權平均 (按時間段權重)
    // 注：這需要知道每段 tempo 的持續時間
    // 簡化實作：取第一個 tempo (通常是主要速度)
    final firstTempo = tempoEvents[0].microsecondsPerQuarter;
    return 60000000.0 / firstTempo;
  }
}

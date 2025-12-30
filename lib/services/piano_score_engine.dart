/// 鋼琴樂譜比對引擎
///
/// 核心功能: 將即時輸入的音符與樂譜進行智能比對
/// 四層過濾機制: 視窗搜尋 → 精確命中 → 雜訊過濾 → 錯音判定
library;

import 'dart:math';
import 'package:veloria/services/detected_note.dart';

/// 判定結果類型
enum JudgmentResult {
  correct,  // 正確命中
  miss,     // 跳過音符 (檢測到使用者跳過了某些音)
  wrong,    // 彈錯音
  noise,    // 雜訊 (忽略)
}

/// 樂譜音符: 目標音符
class Note {
  final int midiNote;     // 音高
  final double timestamp; // 時間戳記 (秒)

  Note({
    required this.midiNote,
    required this.timestamp,
  });

  String get noteName => _midiToNoteName(midiNote);

  @override
  String toString() => '$noteName @ ${timestamp.toStringAsFixed(1)}s';
}

/// 判定結果物件
class JudgmentOutput {
  final JudgmentResult result;      // 判定類型
  final int? matchedIndex;           // 如果命中,回傳命中的索引
  final List<int> skippedIndices;   // 如果有跳過,回傳跳過的索引列表
  final String message;              // 詳細訊息

  JudgmentOutput({
    required this.result,
    this.matchedIndex,
    this.skippedIndices = const [],
    required this.message,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[$result] $message');
    if (matchedIndex != null) {
      buffer.write(' (matched: #$matchedIndex)');
    }
    if (skippedIndices.isNotEmpty) {
      buffer.write(' (skipped: ${skippedIndices.join(', ')})');
    }
    return buffer.toString();
  }
}

/// 鋼琴樂譜比對引擎
///
/// 實現四層過濾機制,智能判定使用者的輸入
class PianoScoreEngine {
  // ==================== 配置參數 ====================
  
  /// 視窗搜尋範圍 (往後偷看幾個音符)
  /// 例如: searchWindow = 2, 則會檢查 [currentIndex, currentIndex+1, currentIndex+2]
  final int searchWindow;
  
  /// 雜訊過濾閾值
  final int minDurationFrames;     // 最短持續幀數
  final double minEnergy;          // 最低能量
  final double minHarmonicRatio;   // 最低諧波比
  
  /// 音高匹配容差 (允許幾個半音的差異)
  final int pitchTolerance;
  
  // ==================== 狀態變數 ====================
  
  /// 目標樂譜
  final List<Note> targetSong;
  
  /// 當前游標 (指向下一個要匹配的音符)
  int currentIndex = 0;
  
  /// 統計資料
  int correctCount = 0;
  int wrongCount = 0;
  int missCount = 0;
  int noiseCount = 0;

  // ==================== 建構子 ====================
  
  PianoScoreEngine({
    required this.targetSong,
    this.searchWindow = 2,
    this.minDurationFrames = 3,
    this.minEnergy = 0.2,
    this.minHarmonicRatio = 0.4,
    this.pitchTolerance = 1,
  });

  // ==================== 核心邏輯 ====================
  
  /// 處理輸入音符 (四層過濾機制)
  ///
  /// 層級零: 雜訊過濾 (Noise Gate) - 最優先檢查
  /// 層級一: 視窗搜尋 (Look-Ahead & Skip)
  /// 層級二: 精確命中 (Direct Match)
  /// 層級三: 錯音判定 (Wrong Note)
  JudgmentOutput processInput(DetectedNote input) {
    // 檢查是否已完成所有音符
    if (currentIndex >= targetSong.length) {
      return JudgmentOutput(
        result: JudgmentResult.noise,
        message: '樂曲已完成,忽略額外輸入',
      );
    }

    print('\n🎵 處理輸入: $input');
    print('📍 當前游標: currentIndex = $currentIndex / ${targetSong.length}');
    print('🎯 期望音符: ${targetSong[currentIndex]}');

    // ========================================
    // 層級零: 雜訊過濾 (Noise Gate) - 最優先
    // ========================================
    //
    // 在匹配之前先過濾雜訊,避免誤判
    // 條件: 持續時間太短 OR 能量太低 OR 諧波比太低
    
    final isNoise = input.durationFrames < minDurationFrames ||
                    input.peakEnergy < minEnergy ||
                    input.harmonicRatio < minHarmonicRatio;
    
    if (isNoise) {
      print('🔇 雜訊過濾: Dur=${input.durationFrames}, E=${input.peakEnergy.toStringAsFixed(2)}, HR=${input.harmonicRatio.toStringAsFixed(2)}');
      
      noiseCount++;
      
      return JudgmentOutput(
        result: JudgmentResult.noise,
        message: '雜訊 (忽略)',
      );
    }

    // ========================================
    // 層級一: 視窗搜尋 (Look-Ahead & Skip)
    // ========================================
    // 
    // 機制說明:
    // 1. 不僅比對當前音符 (currentIndex),還要往後偷看 searchWindow 個音符
    // 2. 如果輸入音符匹配到「未來的某個音符」,說明使用者跳過了中間的音符
    // 3. 將跳過的音符標記為 Miss,並將 currentIndex 跳躍到匹配位置
    //
    // 範例:
    //   樂譜: [C4, D4, E4, F4, G4]
    //   currentIndex = 1 (期望 D4)
    //   searchWindow = 2 (往後看 2 個)
    //   
    //   如果輸入 F4:
    //   - 檢查範圍: [D4(#1), E4(#2), F4(#3)]
    //   - 發現 F4 在 #3 位置
    //   - 判定: 使用者跳過了 D4(#1) 和 E4(#2)
    //   - 回傳: Miss, skippedIndices=[1, 2], matchedIndex=3
    //   - 更新: currentIndex = 4 (下次期望 G4)
    
    final searchEnd = min(currentIndex + searchWindow, targetSong.length - 1);
    
    print('🔍 視窗搜尋範圍: [$currentIndex ~ $searchEnd]');
    for (int i = currentIndex; i <= searchEnd; i++) {
      final target = targetSong[i];
      final pitchDiff = (input.midiNote - target.midiNote).abs();
      
      print('   檢查 #$i: ${target.noteName} (差異 $pitchDiff 半音)');
      
      if (pitchDiff <= pitchTolerance) {
        // 找到匹配!
        if (i == currentIndex) {
          // ========================================
          // 層級二: 精確命中 (Direct Match)
          // ========================================
          print('✅ 精確命中! 當前音符 #$currentIndex');
          
          correctCount++;
          currentIndex++;
          
          return JudgmentOutput(
            result: JudgmentResult.correct,
            matchedIndex: i,
            message: '正確! 命中 ${target.noteName}',
          );
        } else {
          // 匹配到未來的音符 → 判定為 Miss (跳過)
          final skipped = List.generate(i - currentIndex, (idx) => currentIndex + idx);
          
          print('⏭️  跳過檢測! 使用者跳過了 ${skipped.length} 個音符');
          for (final skipIdx in skipped) {
            print('   ❌ Miss: ${targetSong[skipIdx].noteName}');
          }
          print('   ✅ 命中: ${target.noteName} (#$i)');
          
          missCount += skipped.length;
          correctCount++;
          currentIndex = i + 1;
          
          return JudgmentOutput(
            result: JudgmentResult.miss,
            matchedIndex: i,
            skippedIndices: skipped,
            message: '跳過 ${skipped.length} 個音符,命中 ${target.noteName}',
          );
        }
      }
    }

    // ========================================
    // 層級三: 錯音判定 (Wrong Note)
    // ========================================
    //
    // 不是雜訊,但音高不對 → 判定為錯音
    // currentIndex 保持不變,等待使用者修正
    
    final expected = targetSong[currentIndex];
    print('❌ 錯音判定! 期望 ${expected.noteName}, 輸入 ${_midiToNoteName(input.midiNote)}');
    
    wrongCount++;
    
    return JudgmentOutput(
      result: JudgmentResult.wrong,
      message: '錯誤! 期望 ${expected.noteName}, 輸入 ${_midiToNoteName(input.midiNote)}',
    );
  }

  // ==================== 輔助函數 ====================
  
  /// 取得當前進度百分比
  double get progress {
    if (targetSong.isEmpty) return 0.0;
    return (currentIndex / targetSong.length * 100).clamp(0.0, 100.0);
  }

  /// 取得準確率 (不含雜訊)
  double get accuracy {
    final total = correctCount + wrongCount + missCount;
    if (total == 0) return 0.0;
    return (correctCount / total * 100);
  }

  /// 重置引擎狀態
  void reset() {
    currentIndex = 0;
    correctCount = 0;
    wrongCount = 0;
    missCount = 0;
    noiseCount = 0;
  }

  /// 列印統計資料
  void printStats() {
    print('\n📊 統計資料:');
    print('   進度: ${progress.toStringAsFixed(1)}% ($currentIndex / ${targetSong.length})');
    print('   正確: $correctCount');
    print('   錯誤: $wrongCount');
    print('   跳過: $missCount');
    print('   雜訊: $noiseCount (已忽略)');
    print('   準確率: ${accuracy.toStringAsFixed(1)}%');
  }
}

// ==================== 工具函數 ====================

String _midiToNoteName(int midiNote) {
  const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  final octave = (midiNote / 12).floor() - 1;
  final noteName = noteNames[midiNote % 12];
  return '$noteName$octave';
}

// ==================== 測試範例 ====================

void main() {
  print('🎹 鋼琴樂譜比對引擎 - 測試範例\n');
  print('=' * 80);

  // 建立測試樂譜: 小星星前四個音 (C C G G)
  final song = [
    Note(midiNote: 60, timestamp: 0.0),  // C4
    Note(midiNote: 60, timestamp: 0.5),  // C4
    Note(midiNote: 67, timestamp: 1.0),  // G4
    Note(midiNote: 67, timestamp: 1.5),  // G4
  ];

  // 初始化引擎
  final engine = PianoScoreEngine(
    targetSong: song,
    searchWindow: 2,          // 往後偷看 2 個音
    minDurationFrames: 3,     // 至少持續 3 幀
    minEnergy: 0.2,           // 最低能量 0.2
    minHarmonicRatio: 0.4,    // 最低諧波比 0.4
    pitchTolerance: 1,        // 允許 ±1 半音
  );

  print('\n🎼 目標樂譜:');
  for (int i = 0; i < song.length; i++) {
    print('   #$i: ${song[i]}');
  }

  print('\n' + '=' * 80);
  print('開始測試: 彈錯 → 噪音 → 跳過音符 → 命中\n');

  // ========================================
  // 測試 1: 彈錯音 (期望 C4, 彈成 D4)
  // ========================================
  print('\n📍 測試 1: 彈錯音');
  print('-' * 40);
  
  var input = DetectedNote(
    midiNote: 62,           // D4 (錯誤!)
    time: 0.1,
    confidence: 0.9,
    peakEnergy: 0.8,
    durationFrames: 10,
    harmonicRatio: 0.9,
  );
  
  var result = engine.processInput(input);
  print('結果: $result\n');

  // ========================================
  // 測試 2: 雜訊 (能量太低)
  // ========================================
  print('\n📍 測試 2: 雜訊 (能量太低)');
  print('-' * 40);
  
  input = DetectedNote(
    midiNote: 60,           // C4
    time: 0.2,
    confidence: 0.3,
    peakEnergy: 0.1,        // 能量太低!
    durationFrames: 10,
    harmonicRatio: 0.9,
  );
  
  result = engine.processInput(input);
  print('結果: $result\n');

  // ========================================
  // 測試 3: 跳過音符 (直接彈第三個音 G4)
  // ========================================
  print('\n📍 測試 3: 跳過音符 (期望 C4, 直接彈 G4)');
  print('-' * 40);
  
  input = DetectedNote(
    midiNote: 67,           // G4 (跳過了 C4 和 C4)
    time: 0.3,
    confidence: 0.9,
    peakEnergy: 0.8,
    durationFrames: 10,
    harmonicRatio: 0.9,
  );
  
  result = engine.processInput(input);
  print('結果: $result\n');

  // ========================================
  // 測試 4: 精確命中 (期望 G4, 彈 G4)
  // ========================================
  print('\n📍 測試 4: 精確命中');
  print('-' * 40);
  
  input = DetectedNote(
    midiNote: 67,           // G4 (正確!)
    time: 0.4,
    confidence: 0.9,
    peakEnergy: 0.8,
    durationFrames: 10,
    harmonicRatio: 0.9,
  );
  
  result = engine.processInput(input);
  print('結果: $result\n');

  // ========================================
  // 最終統計
  // ========================================
  print('\n' + '=' * 80);
  engine.printStats();
  print('=' * 80);
}

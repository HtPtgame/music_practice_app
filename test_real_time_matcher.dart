/// 真實整合測試 - 音頻檢測 + 樂譜比對
///
/// 這是真正會執行的測試,不是 UI 範例
library;

import 'lib/services/piano_score_engine.dart';
import 'lib/services/audio_analysis/real_time_score_matcher.dart';
import 'lib/services/audio_analysis/sequence_matcher_service.dart';

void main() async {
  print('🎹 真實整合測試: 音頻檢測 + 樂譜比對\n');
  print('=' * 80);
  
  // ==================== 測試 1: 基本整合測試 ====================
  
  print('\n📖 測試 1: 基本音符檢測與比對');
  print('-' * 80);
  
  // 目標樂譜: 小星星前四個音 (C C G G)
  final targetSong = [
    Note(midiNote: 60, timestamp: 0.0),   // C4
    Note(midiNote: 60, timestamp: 0.5),   // C4
    Note(midiNote: 67, timestamp: 1.0),   // G4
    Note(midiNote: 67, timestamp: 1.5),   // G4
  ];
  
  // 建立比對器
  final matcher = RealTimeScoreMatcher(
    targetSong: targetSong,
    searchWindow: 2,
    minDurationFrames: 3,
    minEnergy: 0.2,
    minHarmonicRatio: 0.4,
  );
  
  // 模擬音頻檢測結果 (DetectedNote)
  print('\n🎵 模擬音頻檢測流程:\n');
  
  final detections = [
    // 正確彈奏第一個 C4
    DetectedNote(
      midiNote: 60,
      time: 0.1,
      confidence: 0.95,
      peakEnergy: 0.8,
      harmonicRatio: 0.9,
      onsetStrength: 0.7,
      spectralFlatness: 0.1,
      durationFrames: 5,
    ),
    
    // 正確彈奏第二個 C4
    DetectedNote(
      midiNote: 60,
      time: 0.6,
      confidence: 0.92,
      peakEnergy: 0.75,
      harmonicRatio: 0.88,
      onsetStrength: 0.65,
      spectralFlatness: 0.12,
      durationFrames: 5,
    ),
    
    // 雜訊 (會被過濾)
    DetectedNote(
      midiNote: 55,
      time: 0.8,
      confidence: 0.3,
      peakEnergy: 0.1,
      harmonicRatio: 0.2,
      onsetStrength: 0.05,
      spectralFlatness: 0.8,
      durationFrames: 1,
    ),
    
    // 跳過一個音,直接彈 G4 (#3)
    DetectedNote(
      midiNote: 67,
      time: 1.6,
      confidence: 0.9,
      peakEnergy: 0.85,
      harmonicRatio: 0.92,
      onsetStrength: 0.75,
      spectralFlatness: 0.08,
      durationFrames: 6,
    ),
  ];
  
  // 處理每個檢測到的音符
  for (int i = 0; i < detections.length; i++) {
    final detection = detections[i];
    print('檢測 #${i + 1}: MIDI=${detection.midiNote}, Time=${detection.time.toStringAsFixed(2)}s');
    print('   特徵: E=${detection.peakEnergy.toStringAsFixed(2)}, '
          'HR=${detection.harmonicRatio.toStringAsFixed(2)}, '
          'Dur=${detection.durationFrames}');
    
    final result = matcher.processDetectedNote(detection);
    
    final icon = switch (result.judgment) {
      JudgmentResult.correct => '✅',
      JudgmentResult.miss => '⏭️',
      JudgmentResult.wrong => '❌',
      JudgmentResult.noise => '🔇',
    };
    
    print('   結果: $icon ${result.message}');
    print('   狀態: 進度 ${result.progress.toStringAsFixed(1)}%, '
          '準確率 ${result.accuracy.toStringAsFixed(1)}%\n');
  }
  
  matcher.printStats();
  matcher.dispose();
  
  // ==================== 測試 2: 練習模式控制器 ====================
  
  print('\n\n📖 測試 2: 練習模式控制器 (PracticeModeController)');
  print('-' * 80);
  
  final practiceController = PracticeModeController();
  
  // 目標樂譜: C D E F G
  final scale = [
    Note(midiNote: 60, timestamp: 0.0),   // C
    Note(midiNote: 62, timestamp: 0.5),   // D
    Note(midiNote: 64, timestamp: 1.0),   // E
    Note(midiNote: 65, timestamp: 1.5),   // F
    Note(midiNote: 67, timestamp: 2.0),   // G
  ];
  
  // 啟動練習模式
  practiceController.startPractice(
    targetSong: scale,
    onResult: (result) {
      // UI 更新回調
      final icon = switch (result.judgment) {
        JudgmentResult.correct => '💚',
        JudgmentResult.miss => '💛',
        JudgmentResult.wrong => '❤️',
        JudgmentResult.noise => '🔇',
      };
      print('   UI 更新: $icon ${result.message}');
    },
  );
  
  print('\n🎮 模擬使用者彈奏:\n');
  
  // 模擬音頻檢測結果
  final practiceDetections = [
    // 正確: C
    DetectedNote(
      midiNote: 60,
      time: 0.1,
      confidence: 0.9,
      peakEnergy: 0.8,
      harmonicRatio: 0.9,
      onsetStrength: 0.7,
      spectralFlatness: 0.1,
      durationFrames: 5,
    ),
    
    // 錯誤: 彈了 C,期望 D
    DetectedNote(
      midiNote: 60,
      time: 0.6,
      confidence: 0.88,
      peakEnergy: 0.75,
      harmonicRatio: 0.88,
      onsetStrength: 0.65,
      spectralFlatness: 0.12,
      durationFrames: 5,
    ),
    
    // 修正: D
    DetectedNote(
      midiNote: 62,
      time: 0.8,
      confidence: 0.92,
      peakEnergy: 0.8,
      harmonicRatio: 0.91,
      onsetStrength: 0.7,
      spectralFlatness: 0.1,
      durationFrames: 5,
    ),
    
    // 跳過 E 和 F,直接彈 G
    DetectedNote(
      midiNote: 67,
      time: 2.1,
      confidence: 0.95,
      peakEnergy: 0.85,
      harmonicRatio: 0.93,
      onsetStrength: 0.75,
      spectralFlatness: 0.08,
      durationFrames: 6,
    ),
  ];
  
  // 批次處理
  practiceController.onAudioDetected(practiceDetections);
  
  // 顯示最終狀態
  print('\n📊 最終狀態:');
  final status = practiceController.getStatus();
  print('   進度: ${status['progress'].toStringAsFixed(1)}%');
  print('   準確率: ${status['accuracy'].toStringAsFixed(1)}%');
  print('   當前索引: ${status['currentIndex']} / ${status['totalNotes']}');
  print('   期望音符: ${status['expectedNote']}');
  print('   已完成: ${status['isCompleted']}');
  
  practiceController.stopPractice();
  
  // ==================== 測試 3: 容錯與嚴格模式比較 ====================
  
  print('\n\n📖 測試 3: 容錯模式 vs 嚴格模式');
  print('-' * 80);
  
  final testSong = [
    Note(midiNote: 60, timestamp: 0.0),   // C
    Note(midiNote: 64, timestamp: 0.5),   // E
    Note(midiNote: 67, timestamp: 1.0),   // G
  ];
  
  // 容錯模式
  final tolerantMatcher = RealTimeScoreMatcher(
    targetSong: testSong,
    searchWindow: 5,
    minEnergy: 0.1,
    minDurationFrames: 1,
    pitchTolerance: 2,
  );
  
  // 嚴格模式
  final strictMatcher = RealTimeScoreMatcher(
    targetSong: testSong,
    searchWindow: 0,
    minEnergy: 0.3,
    minDurationFrames: 5,
    pitchTolerance: 0,
  );
  
  // 挑戰性輸入: 低品質的 G 音 (跳過了 C 和 E)
  final challengeNote = DetectedNote(
    midiNote: 67,
    time: 1.1,
    confidence: 0.6,
    peakEnergy: 0.15,
    harmonicRatio: 0.5,
    onsetStrength: 0.3,
    spectralFlatness: 0.4,
    durationFrames: 3,
  );
  
  print('\n相同輸入在不同模式下的結果:');
  print('   輸入: G4 (MIDI=67, Energy=0.15, Duration=3)\n');
  
  print('🟢 容錯模式:');
  final tolerantResult = tolerantMatcher.processDetectedNote(challengeNote);
  print('   判定: ${tolerantResult.judgment}');
  print('   訊息: ${tolerantResult.message}');
  print('   跳過: ${tolerantResult.skippedIndices}\n');
  
  print('🔴 嚴格模式:');
  final strictResult = strictMatcher.processDetectedNote(challengeNote);
  print('   判定: ${strictResult.judgment}');
  print('   訊息: ${strictResult.message}');
  
  tolerantMatcher.dispose();
  strictMatcher.dispose();
  
  // ==================== 測試 4: Stream 監聽測試 ====================
  
  print('\n\n📖 測試 4: Stream 監聽測試 (即時通知)');
  print('-' * 80);
  
  final streamMatcher = RealTimeScoreMatcher(
    targetSong: [
      Note(midiNote: 60, timestamp: 0.0),
      Note(midiNote: 62, timestamp: 0.5),
      Note(midiNote: 64, timestamp: 1.0),
    ],
    searchWindow: 2,
  );
  
  // 監聽 Stream
  print('\n📡 啟動 Stream 監聽...\n');
  streamMatcher.resultStream.listen((result) {
    print('📨 Stream 事件: ${result.judgment} - ${result.message}');
  });
  
  // 發送三個檢測
  final streamDetections = [
    DetectedNote(
      midiNote: 60,
      time: 0.1,
      confidence: 0.9,
      peakEnergy: 0.8,
      harmonicRatio: 0.9,
      onsetStrength: 0.7,
      spectralFlatness: 0.1,
      durationFrames: 5,
    ),
    DetectedNote(
      midiNote: 62,
      time: 0.6,
      confidence: 0.9,
      peakEnergy: 0.8,
      harmonicRatio: 0.9,
      onsetStrength: 0.7,
      spectralFlatness: 0.1,
      durationFrames: 5,
    ),
    DetectedNote(
      midiNote: 64,
      time: 1.1,
      confidence: 0.9,
      peakEnergy: 0.8,
      harmonicRatio: 0.9,
      onsetStrength: 0.7,
      spectralFlatness: 0.1,
      durationFrames: 5,
    ),
  ];
  
  for (final note in streamDetections) {
    streamMatcher.processDetectedNote(note);
    // Stream 會自動觸發上面的 listen 回調
    await Future.delayed(Duration(milliseconds: 100)); // 模擬時間延遲
  }
  
  print('\n✅ Stream 測試完成');
  streamMatcher.dispose();
  
  print('\n' + '=' * 80);
  print('💡 整合說明:');
  print('   1. RealTimeScoreMatcher 處理 OptimizedNoteDetectorService 的輸出');
  print('   2. PracticeModeController 提供完整的練習模式控制');
  print('   3. resultStream 提供即時通知 (UI 可監聽更新)');
  print('   4. 所有計算都是真實執行,不是 UI 範例');
  print('=' * 80);
}

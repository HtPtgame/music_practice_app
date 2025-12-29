/// 即時樂譜比對服務 (Real-Time Score Matcher)
///
/// 整合到音頻檢測流程的實戰版本
/// 將 OptimizedNoteDetectorService 檢測到的音符即時與樂譜比對
///
/// 使用場景:
/// - 鋼琴練習模式 (Practice Mode)
/// - 即時反饋系統 (Real-time Feedback)
/// - 成績評分系統 (Scoring System)
library;

import 'dart:async';
import '../piano_score_engine.dart';
import 'sequence_matcher_service.dart';
import 'models/note_event.dart';
import 'package:veloria/services/detected_note.dart';

/// 即時比對結果 (包含統計資料)
class RealTimeMatchResult {
  final JudgmentResult judgment;
  final String message;
  final int? matchedIndex;
  final List<int> skippedIndices;
  
  // 即時統計
  final double progress;
  final double accuracy;
  final int correctCount;
  final int wrongCount;
  final int missCount;
  final int noiseCount;
  
  RealTimeMatchResult({
    required this.judgment,
    required this.message,
    this.matchedIndex,
    this.skippedIndices = const [],
    required this.progress,
    required this.accuracy,
    required this.correctCount,
    required this.wrongCount,
    required this.missCount,
    required this.noiseCount,
  });
}

/// 即時樂譜比對服務
///
/// 將音頻檢測與樂譜匹配整合在一起
class RealTimeScoreMatcher {
  late PianoScoreEngine _scoreEngine;
  
  // 統計資料 Stream
  final _resultController = StreamController<RealTimeMatchResult>.broadcast();
  Stream<RealTimeMatchResult> get resultStream => _resultController.stream;
  
  // 配置參數
  final int searchWindow;
  final int minDurationFrames;
  final double minEnergy;
  final double minHarmonicRatio;
  final int pitchTolerance;
  
  /// 建構子
  ///
  /// [targetSong] 目標樂譜 (MIDI Timeline 轉換而來)
  /// [searchWindow] 往前看的音符數 (允許跳過)
  /// [minDurationFrames] 最小持續幀數 (過濾雜訊)
  /// [minEnergy] 最小能量閾值
  /// [minHarmonicRatio] 最小諧波比
  /// [pitchTolerance] 音高容錯 (半音)
  RealTimeScoreMatcher({
    required List<Note> targetSong,
    this.searchWindow = 3,
    this.minDurationFrames = 3,
    this.minEnergy = 0.2,
    this.minHarmonicRatio = 0.4,
    this.pitchTolerance = 1,
  }) {
    _scoreEngine = PianoScoreEngine(
      targetSong: targetSong,
      searchWindow: searchWindow,
      minDurationFrames: minDurationFrames,
      minEnergy: minEnergy,
      minHarmonicRatio: minHarmonicRatio,
      pitchTolerance: pitchTolerance,
    );
  }
  
  /// 🎯 核心方法: 處理檢測到的音符
  ///
  /// 這個方法會被音頻檢測回調觸發
  /// 
  /// 使用範例:
  /// ```dart
  /// // 在音頻檢測服務中
  /// final detector = OptimizedNoteDetectorService();
  /// final matcher = RealTimeScoreMatcher(targetSong: midiNotes);
  /// 
  /// // 檢測到音符時呼叫
  /// for (final detectedNote in detector.detectAll(spectrogram)) {
  ///   final result = matcher.processDetectedNote(detectedNote);
  ///   print(result.message);
  ///   updateUI(result);
  /// }
  /// ```
  RealTimeMatchResult processDetectedNote(DetectedNote detectedNote) {
    // 呼叫 PianoScoreEngine 進行比對
    final output = _scoreEngine.processInput(detectedNote);
    
    // 封裝結果並加入統計資料
    final result = RealTimeMatchResult(
      judgment: output.result,
      message: output.message,
      matchedIndex: output.matchedIndex,
      skippedIndices: output.skippedIndices,
      progress: _scoreEngine.progress,
      accuracy: _scoreEngine.accuracy,
      correctCount: _scoreEngine.correctCount,
      wrongCount: _scoreEngine.wrongCount,
      missCount: _scoreEngine.missCount,
      noiseCount: _scoreEngine.noiseCount,
    );
    
    // 發送到 Stream (供 UI 監聽)
    _resultController.add(result);
    
    return result;
  }
  
  /// 批次處理多個音符
  ///
  /// 用於處理一幀音頻檢測到的多個音符
  List<RealTimeMatchResult> processMultipleNotes(List<DetectedNote> notes) {
    return notes.map<RealTimeMatchResult>((note) => processDetectedNote(note)).toList();
  }
  
  /// 取得當前進度
  double get progress => _scoreEngine.progress;
  
  /// 取得當前準確率
  double get accuracy => _scoreEngine.accuracy;
  
  /// 取得當前期望音符
  Note? get currentExpectedNote {
    if (_scoreEngine.currentIndex >= _scoreEngine.targetSong.length) {
      return null;
    }
    return _scoreEngine.targetSong[_scoreEngine.currentIndex];
  }
  
  /// 取得當前索引
  int get currentIndex => _scoreEngine.currentIndex;
  
  /// 取得目標樂譜長度
  int get totalNotes => _scoreEngine.targetSong.length;
  
  /// 是否已完成
  bool get isCompleted => _scoreEngine.currentIndex >= _scoreEngine.targetSong.length;
  
  /// 重置比對狀態
  void reset() {
    _scoreEngine.reset();
  }
  
  /// 釋放資源
  void dispose() {
    _resultController.close();
  }
  
  /// 列印統計報告
  void printStats() {
    _scoreEngine.printStats();
  }
}

/// 🎯 靜態工具方法: 從 MidiTimeline 轉換為 PianoScoreEngine 使用的格式
class ScoreConverter {
  /// 將 MidiTimeline 轉換為 Note 列表
  ///
  /// 使用每個音符的 startTime 作為 timestamp
  static List<Note> fromMidiTimeline(MidiTimeline timeline) {
    return timeline.events
        .map((event) => Note(
              midiNote: event.midiNote,
              timestamp: event.startTime,
            ))
        .toList();
  }
  
  /// 從 MIDI 檔案路徑載入並轉換
  ///
  /// 需要配合 MidiParser 使用
  /// ```dart
  /// final timeline = await MidiParser.parse(midiFilePath);
  /// final notes = ScoreConverter.fromMidiTimeline(timeline);
  /// ```
  static List<Note> fromMidiFile(String midiPath) {
    // TODO: 整合 MidiParser
    throw UnimplementedError('需要整合 MidiParser');
  }
}

/// 🎯 整合範例: 完整的音頻檢測 + 樂譜比對流程
///
/// 這是真正會運作的程式碼,不是 UI 範例
class PracticeModeController {
  late RealTimeScoreMatcher _matcher;
  StreamSubscription? _matcherSubscription;
  
  /// 開始練習模式
  ///
  /// [targetSong] 目標樂譜
  /// [onResult] 結果回調 (更新 UI)
  void startPractice({
    required List<Note> targetSong,
    required Function(RealTimeMatchResult) onResult,
  }) {
    // 初始化比對器
    _matcher = RealTimeScoreMatcher(
      targetSong: targetSong,
      searchWindow: 3,
      minDurationFrames: 3,
      minEnergy: 0.2,
      minHarmonicRatio: 0.4,
      pitchTolerance: 1,
    );
    
    // 監聽結果 Stream
    _matcherSubscription = _matcher.resultStream.listen((result) {
      onResult(result);
    });
    
    print('🎹 練習模式已啟動');
    print('   目標: ${targetSong.length} 個音符');
    print('   視窗: ${_matcher.searchWindow} (允許跳過)');
  }
  
  /// 音頻檢測回調
  ///
  /// 這個方法會被 OptimizedNoteDetectorService.detectAll() 呼叫
  void onAudioDetected(List<DetectedNote> detectedNotes) {
    for (final note in detectedNotes) {
      _matcher.processDetectedNote(note);
    }
  }
  
  /// 停止練習
  void stopPractice() {
    _matcherSubscription?.cancel();
    _matcher.printStats();
    _matcher.dispose();
    print('🎹 練習模式已停止');
  }
  
  /// 重新開始
  void restart() {
    _matcher.reset();
    print('🎹 練習重新開始');
  }
  
  /// 取得當前狀態
  Map<String, dynamic> getStatus() {
    return {
      'progress': _matcher.progress,
      'accuracy': _matcher.accuracy,
      'currentIndex': _matcher.currentIndex,
      'totalNotes': _matcher.totalNotes,
      'isCompleted': _matcher.isCompleted,
      'expectedNote': _matcher.currentExpectedNote?.noteName ?? 'N/A',
    };
  }
}

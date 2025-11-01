/// 動態參數整合示範 (Round 9)
/// 
/// 展示如何在 PerformanceAnalyzer 中使用動態參數系統
/// 這是整合指南，實際整合需要修改 performance_analyzer.dart
library;

import 'lib/services/audio_analysis/dynamic_parameter_service.dart';
import 'lib/services/audio_analysis/models/note_event.dart';

/// 示範：如何使用動態參數系統
/// 
/// 使用步驟：
/// 1. 解析 MIDI 檔案
/// 2. 創建 MidiTimeline
/// 3. 計算動態參數
/// 4. 設定檢測服務
/// 5. 執行分析
void main() {
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║     🎚️ 動態參數整合示範 (Round 9)                          ║');
  print('╚══════════════════════════════════════════════════════════════╝\n');

  // ═══════════════════════════════════════════════════════════
  // 範例 1: 簡單曲目（生日快樂）
  // ═══════════════════════════════════════════════════════════
  
  print('【範例 1: 簡單曲目 - 生日快樂】\n');
  
  // 假設已解析 MIDI
  final timeline1 = _createMockTimeline(
    noteCount: 25,
    duration: 17.4,
    name: '生日快樂',
  );
  
  // 創建動態參數服務
  final paramService = DynamicParameterService();
  
  // 計算動態參數
  final params1 = paramService.calculateParameters(timeline1);
  
  print('📊 樂曲分析:');
  print('   音符數: ${params1.noteCount}');
  print('   時長: ${params1.duration.toStringAsFixed(1)}秒');
  print('   速度: ${params1.averageSpeed.toStringAsFixed(2)} 音符/秒');
  print('   難度: ${_getDifficultyStr(params1.difficulty)}');
  print('');
  print('🎚️ 動態參數:');
  print('   energyThreshold: ${params1.energyThreshold.toStringAsFixed(2)} (高閾值，減少噪音)');
  print('   timingTolerance: ±${(params1.timingTolerance * 1000).toStringAsFixed(0)}ms (寬容錯)');
  print('');
  print('💡 效果預期:');
  print('   ✅ 噪音過濾優秀 (0.39 > 0.38)');
  print('   ✅ 適合初學者演奏');
  print('   ✅ 節奏要求寬鬆');
  print('');
  print('─'.padRight(64, '─'));
  print('');

  // ═══════════════════════════════════════════════════════════
  // 範例 2: 複雜曲目（名偵探柯南）
  // ═══════════════════════════════════════════════════════════
  
  print('【範例 2: 複雜曲目 - 名偵探柯南】\n');
  
  final timeline2 = _createMockTimeline(
    noteCount: 1431,
    duration: 163.8,
    name: '名偵探柯南',
  );
  
  final params2 = paramService.calculateParameters(timeline2);
  
  print('📊 樂曲分析:');
  print('   音符數: ${params2.noteCount}');
  print('   時長: ${params2.duration.toStringAsFixed(1)}秒');
  print('   速度: ${params2.averageSpeed.toStringAsFixed(2)} 音符/秒');
  print('   難度: ${_getDifficultyStr(params2.difficulty)}');
  print('');
  print('🎚️ 動態參數:');
  print('   energyThreshold: ${params2.energyThreshold.toStringAsFixed(2)} (低閾值，高靈敏度)');
  print('   timingTolerance: ±${(params2.timingTolerance * 1000).toStringAsFixed(0)}ms (嚴格)');
  print('');
  print('💡 效果預期:');
  print('   ✅ 召回率提升 (0.30 < 0.38，提升 ~5%)');
  print('   ✅ 檢測更多弱音符');
  print('   ✅ 節奏要求嚴格 (±100ms)');
  print('');
  print('─'.padRight(64, '─'));
  print('');

  // ═══════════════════════════════════════════════════════════
  // 範例 3: 整合代碼示範
  // ═══════════════════════════════════════════════════════════
  
  print('【範例 3: 整合代碼示範】\n');
  print('```dart');
  print('// 在 PerformanceAnalyzer.analyze() 中:');
  print('');
  print('// 步驟 1: 解析 MIDI 並創建 timeline');
  print('final timeline = /* ... */;');
  print('');
  print('// 步驟 2: 計算動態參數');
  print('final paramService = DynamicParameterService();');
  print('final params = paramService.calculateParameters(');
  print('  timeline,');
  print('  averageBpm: _calculateAverageBpm(tempoEvents),');
  print(');');
  print('');
  print('// 步驟 3: 設定檢測服務參數');
  print('_noteDetector.setEnergyThreshold(params.energyThreshold);');
  print('_noteVerifier.setEnergyThreshold(params.energyThreshold);');
  print('_errorClassifier.setTimingTolerance(params.timingTolerance);');
  print('');
  print('// 步驟 4: 正常執行分析');
  print('final spectrogram = await _spectrogramService.create(audioPath);');
  print('final detectedNotes = await _noteDetector.detectAll(spectrogram);');
  print('// ...後續分析流程');
  print('```');
  print('');
  print('─'.padRight(64, '─'));
  print('');

  // ═══════════════════════════════════════════════════════════
  // 參數對比
  // ═══════════════════════════════════════════════════════════
  
  print('【參數對比：固定 vs 動態】\n');
  print('┌────────────────────────────────────────────────────────────┐');
  print('│ 樂曲         │ 固定參數      │ 動態參數      │ 差異      │');
  print('├────────────────────────────────────────────────────────────┤');
  print('│              │ 能量閾值      │               │           │');
  print('├────────────────────────────────────────────────────────────┤');
  print('│ 生日快樂        │ 0.38          │ 0.39          │ +0.01     │');
  print('│ 小星星         │ 0.38          │ 0.36          │ -0.02     │');
  print('│ 名偵探柯南      │ 0.38          │ 0.30          │ -0.08 ⭐  │');
  print('├────────────────────────────────────────────────────────────┤');
  print('│              │ 時間容錯      │               │           │');
  print('├────────────────────────────────────────────────────────────┤');
  print('│ 生日快樂        │ ±100ms        │ ±200ms        │ +100ms    │');
  print('│ 小星星         │ ±100ms        │ ±150ms        │ +50ms     │');
  print('│ 名偵探柯南      │ ±100ms        │ ±100ms        │ 持平      │');
  print('└────────────────────────────────────────────────────────────┘');
  print('');
  print('⭐ 最大改善：柯南的 energyThreshold 從 0.38 降至 0.30');
  print('   預期效果：召回率從 75.1% 提升至 ~80%');
  print('');
  
  print('🎉 示範完成！');
  print('');
  print('📝 下一步：');
  print('   1. 在 PerformanceAnalyzer 中整合動態參數系統');
  print('   2. 執行 Round 10 完整測試（32個案例）');
  print('   3. 對比固定參數 vs 動態參數效果');
}

/// 創建模擬的 MidiTimeline
MidiTimeline _createMockTimeline({
  required int noteCount,
  required double duration,
  required String name,
}) {
  final events = <NoteEvent>[];
  final interval = duration / noteCount;
  
  for (int i = 0; i < noteCount; i++) {
    events.add(NoteEvent(
      midiNote: 60 + (i % 12),
      startTime: i * interval,
      endTime: (i + 0.5) * interval,
    ));
  }
  
  return MidiTimeline(
    events: events,
    duration: duration,
  );
}

/// 取得難度字串
String _getDifficultyStr(DifficultyLevel level) {
  switch (level) {
    case DifficultyLevel.beginner:
      return '初學者';
    case DifficultyLevel.intermediate:
      return '中級';
    case DifficultyLevel.advanced:
      return '進階';
    case DifficultyLevel.expert:
      return '專家';
  }
}

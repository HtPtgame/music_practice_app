/// 動態參數測試腳本 (Round 9)
/// 
/// 測試 DynamicParameterService 對不同樂曲的參數計算
import 'lib/services/audio_analysis/dynamic_parameter_service.dart';
import 'lib/services/audio_analysis/models/note_event.dart';

void main() {
  final service = DynamicParameterService();
  
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║     🎚️ 動態參數測試 (Round 9)                              ║');
  print('╚══════════════════════════════════════════════════════════════╝\n');
  
  // 測試用例 1: 生日快樂 (簡單)
  print('【測試 1: 生日快樂】');
  final happyBirthday = _createMockTimeline(
    noteCount: 25,
    duration: 17.4,
    name: '生日快樂',
  );
  final params1 = service.calculateParameters(happyBirthday);
  print(params1);
  print('');
  
  // 測試用例 2: 測試音檔 (中等)
  print('【測試 2: 測試音檔】');
  final testSong = _createMockTimeline(
    noteCount: 94,
    duration: 34.0,
    name: '測試音檔',
  );
  final params2 = service.calculateParameters(testSong);
  print(params2);
  print('');
  
  // 測試用例 3: 小星星 (中等偏難)
  print('【測試 3: 小星星】');
  final twinkleStar = _createMockTimeline(
    noteCount: 147,
    duration: 26.5,
    name: '小星星',
  );
  final params3 = service.calculateParameters(twinkleStar);
  print(params3);
  print('');
  
  // 測試用例 4: 名偵探柯南 (困難)
  print('【測試 4: 名偵探柯南】');
  final conan = _createMockTimeline(
    noteCount: 1431,
    duration: 163.8,
    name: '名偵探柯南',
  );
  final params4 = service.calculateParameters(conan);
  print(params4);
  print('');
  
  // 測試用例 5: 極快樂曲 (專家級)
  print('【測試 5: 極快樂曲 (假設)】');
  final extremeFast = _createMockTimeline(
    noteCount: 2000,
    duration: 120.0,
    name: '極快樂曲',
  );
  final params5 = service.calculateParameters(extremeFast, averageBpm: 200.0);
  print(params5);
  print('');
  
  // 參數對比表
  print('┌────────────────────────────────────────────────────────────┐');
  print('│                   參數對比總表                             │');
  print('├────────────────────────────────────────────────────────────┤');
  print('│ 樂曲         │ 難度         │ 能量閾值 │ 時間容錯      │');
  print('├────────────────────────────────────────────────────────────┤');
  _printRow('生日快樂', params1);
  _printRow('測試音檔', params2);
  _printRow('小星星', params3);
  _printRow('名偵探柯南', params4);
  _printRow('極快樂曲', params5);
  print('└────────────────────────────────────────────────────────────┘\n');
  
  // 驗證範圍
  print('【驗證結果】');
  final allParams = [params1, params2, params3, params4, params5];
  final energyRange = _getRange(allParams.map((p) => p.energyThreshold));
  final timingRange = _getRange(allParams.map((p) => p.timingTolerance));
  
  print('✅ energyThreshold 範圍: ${energyRange.min.toStringAsFixed(2)} - ${energyRange.max.toStringAsFixed(2)}');
  print('✅ timingTolerance 範圍: ${(timingRange.min * 1000).toStringAsFixed(0)}ms - ${(timingRange.max * 1000).toStringAsFixed(0)}ms');
  
  if (energyRange.min >= 0.30 && energyRange.max <= 0.40) {
    print('✅ energyThreshold 在有效範圍內 (0.30~0.40)');
  } else {
    print('❌ energyThreshold 超出範圍！');
  }
  
  if (timingRange.min >= 0.08 && timingRange.max <= 0.20) {
    print('✅ timingTolerance 在有效範圍內 (0.08~0.20秒)');
  } else {
    print('❌ timingTolerance 超出範圍！');
  }
  
  print('\n🎉 動態參數測試完成！');
}

/// 創建模擬的 MidiTimeline
MidiTimeline _createMockTimeline({
  required int noteCount,
  required double duration,
  required String name,
}) {
  // 生成均勻分布的音符事件
  final events = <NoteEvent>[];
  final interval = duration / noteCount;
  
  for (int i = 0; i < noteCount; i++) {
    events.add(NoteEvent(
      midiNote: 60 + (i % 12), // C4-B4
      startTime: i * interval,
      endTime: (i + 0.5) * interval,
    ));
  }
  
  return MidiTimeline(
    events: events,
    duration: duration,
  );
}

/// 打印參數行
void _printRow(String name, DynamicParameters params) {
  final difficultyStr = _getDifficultyStr(params.difficulty);
  final energyStr = params.energyThreshold.toStringAsFixed(2);
  final timingStr = '±${(params.timingTolerance * 1000).toStringAsFixed(0)}ms';
  
  print('│ ${name.padRight(12)} │ ${difficultyStr.padRight(12)} │ ${energyStr.padLeft(8)} │ ${timingStr.padLeft(13)} │');
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

/// 取得數值範圍
({double min, double max}) _getRange(Iterable<double> values) {
  double min = double.infinity;
  double max = double.negativeInfinity;
  
  for (final value in values) {
    if (value < min) min = value;
    if (value > max) max = value;
  }
  
  return (min: min, max: max);
}

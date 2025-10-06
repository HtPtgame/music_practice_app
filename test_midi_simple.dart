import 'dart:io';
import 'lib/services/audio_analysis/midi_parser_service.dart';

/// 簡化版 MIDI 測試 (純 Dart,不需要 Flutter 環境)
void main() async {
  print('🎹 MIDI 解析測試');
  print('═══════════════════════════════════════════════════════════');
  
  const midiPath = 'assets/測試.mid';
  
  final file = File(midiPath);
  if (!await file.exists()) {
    print('❌ 找不到文件: $midiPath');
    return;
  }
  
  final sizeKB = (await file.length() / 1024).toStringAsFixed(2);
  print('📂 文件: $midiPath');
  print('📊 大小: $sizeKB KB');
  print('');
  
  try {
    final parser = MidiParserService();
    final stopwatch = Stopwatch()..start();
    
    final timeline = await parser.parseFile(midiPath);
    
    stopwatch.stop();
    
    print('✅ 解析成功! (${stopwatch.elapsedMilliseconds}ms)');
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 統計信息');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    print('   總音符數: ${timeline.events.length}');
    print('   音樂時長: ${timeline.duration.toStringAsFixed(2)} 秒');
    print('');
    
    if (timeline.events.isEmpty) {
      print('⚠️  警告: 沒有找到任何音符!');
      return;
    }
    
    // 音域分析
    int minMidi = 127;
    int maxMidi = 0;
    
    for (final note in timeline.events) {
      if (note.midiNote < minMidi) minMidi = note.midiNote;
      if (note.midiNote > maxMidi) maxMidi = note.midiNote;
    }
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎼 音域分析');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    print('   最低音: MIDI $minMidi (${_midiToNote(minMidi)})');
    print('   最高音: MIDI $maxMidi (${_midiToNote(maxMidi)})');
    print('   音域跨度: ${maxMidi - minMidi + 1} 個半音');
    print('');
    
    // 音符列表 (前 30 個)
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎵 音符列表 (前 30 個)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    print('   序號 │ 音符   │ 開始時間 │ 持續時間 │ MIDI │ 頻率');
    print('   ────┼────────┼──────────┼──────────┼──────┼─────────');
    
    for (int i = 0; i < timeline.events.length && i < 30; i++) {
      final note = timeline.events[i];
      final num = (i + 1).toString().padLeft(4);
      final name = note.noteName.padRight(6);
      final start = note.startTime.toStringAsFixed(2).padLeft(8);
      final duration = note.duration.toStringAsFixed(2).padLeft(8);
      final midi = note.midiNote.toString().padLeft(4);
      final freq = note.frequency.toStringAsFixed(1).padLeft(7);
      
      print('   $num │ $name │ $start秒 │ $duration秒 │ $midi │ ${freq}Hz');
    }
    
    if (timeline.events.length > 30) {
      print('   ... 還有 ${timeline.events.length - 30} 個音符');
    }
    
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('✅ 測試完成!');
    print('═══════════════════════════════════════════════════════════');
    
  } catch (e, stackTrace) {
    print('');
    print('❌ 解析失敗: $e');
    print('');
    print('錯誤堆疊:');
    print(stackTrace);
  }
}

String _midiToNote(int midiNumber) {
  const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  final octave = (midiNumber ~/ 12) - 1;
  final noteName = notes[midiNumber % 12];
  return '$noteName$octave';
}

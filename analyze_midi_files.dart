/// MIDI 檔案分析工具 - 找出延遲原因
import 'dart:io';
import 'package:music_practice_app/utils/midi_parser.dart';

void main() async {
  print('🔍 MIDI 檔案延遲分析工具\n');
  print('=' * 70);
  
  final midiFiles = [
    'assets/test_voice/測試音檔.mid',
    'assets/test_voice/小星星.mid',
    'assets/test_voice/名偵探柯南.mid',
  ];
  
  for (final path in midiFiles) {
    await analyzeMidiFile(path);
    print('=' * 70);
  }
}

Future<void> analyzeMidiFile(String path) async {
  print('\n📁 檔案: $path');
  
  final file = File(path);
  if (!await file.exists()) {
    print('❌ 檔案不存在');
    return;
  }
  
  final fileSize = await file.length();
  print('📊 檔案大小: ${(fileSize / 1024).toStringAsFixed(2)} KB');
  
  try {
    final bytes = await file.readAsBytes();
    final parser = MidiParser();
    final events = parser.parse(bytes);
    final tpq = parser.ticksPerQuarterNote;
    final tempoEvents = parser.tempoEvents;
    
    print('🎵 音符總數: ${events.length}');
    print('⏱️  TPQ (Ticks Per Quarter): $tpq');
    print('🎼 Tempo 事件數: ${tempoEvents.length}');
    
    if (tempoEvents.isNotEmpty) {
      print('\n📌 Tempo 事件詳情:');
      for (int i = 0; i < tempoEvents.length && i < 5; i++) {
        final tempo = tempoEvents[i];
        final bpm = 60000000 / tempo.microsecondsPerQuarter;
        print('   $i. Tick ${tempo.tick}: ${bpm.toStringAsFixed(1)} BPM (${tempo.microsecondsPerQuarter} μs/quarter)');
      }
      if (tempoEvents.length > 5) {
        print('   ... 還有 ${tempoEvents.length - 5} 個 tempo 事件');
      }
    }
    
    // 分析第一個音符出現的時間
    if (events.isNotEmpty) {
      final firstEvent = events.first;
      final firstEventTick = firstEvent.tick;
      
      // 找到第一個 Note On 事件
      final firstNoteOn = events.firstWhere(
        (e) => e.isNoteOn, 
        orElse: () => events.first
      );
      final firstNoteOnTick = firstNoteOn.tick;
      
      final msPerTick = tempoEvents.isNotEmpty 
          ? tempoEvents.first.msPerTick(tpq)
          : (500000 / 1000.0 / tpq); // 預設 120 BPM
      
      final firstEventTimeMs = firstEventTick * msPerTick;
      final firstNoteOnTimeMs = firstNoteOnTick * msPerTick;
      
      print('\n🎹 第一個事件:');
      print('   Tick: $firstEventTick');
      print('   延遲時間: ${firstEventTimeMs.toStringAsFixed(0)} ms (${(firstEventTimeMs / 1000).toStringAsFixed(2)} 秒)');
      print('   音符: ${_noteNumberToName(firstEvent.noteNumber)}');
      print('   類型: ${firstEvent.isNoteOn ? "Note On ✅" : "Note Off ⚠️"}');
      
      if (!firstEvent.isNoteOn) {
        print('\n🎹 第一個 Note On 事件:');
        print('   Tick: $firstNoteOnTick');
        print('   延遲時間: ${firstNoteOnTimeMs.toStringAsFixed(0)} ms (${(firstNoteOnTimeMs / 1000).toStringAsFixed(2)} 秒)');
        print('   音符: ${_noteNumberToName(firstNoteOn.noteNumber)}');
      }
      
      // 檢查前面是否有大量空白時間
      if (firstNoteOnTimeMs > 1000) {
        print('   🚨 警告: 第一個 Note On 前有 ${(firstNoteOnTimeMs / 1000).toStringAsFixed(2)} 秒的空白!');
        print('   💡 這會導致播放時看起來「卡住」${(firstNoteOnTimeMs / 1000).toStringAsFixed(1)} 秒');
      }
    }
    
    // 分析音符分布
    final noteOnEvents = events.where((e) => e.isNoteOn).toList();
    if (noteOnEvents.length >= 2) {
      final lastNote = noteOnEvents.last;
      final lastTick = lastNote.tick;
      final msPerTick = tempoEvents.isNotEmpty 
          ? tempoEvents.first.msPerTick(tpq)
          : (500000 / 1000.0 / tpq);
      
      final totalDurationMs = lastTick * msPerTick;
      
      print('\n📐 時長分析:');
      print('   最後音符 Tick: $lastTick');
      print('   總時長: ${(totalDurationMs / 1000).toStringAsFixed(2)} 秒');
      print('   音符密度: ${(noteOnEvents.length / (totalDurationMs / 1000)).toStringAsFixed(2)} 音符/秒');
    }
    
    // 分析鋼琴音域
    final pianoNotes = events.where((e) => e.noteNumber >= 21 && e.noteNumber <= 108).toList();
    final nonPianoNotes = events.where((e) => e.noteNumber < 21 || e.noteNumber > 108).toList();
    
    print('\n🎹 音域分析:');
    print('   鋼琴音域 (A0-C8): ${pianoNotes.length} 事件');
    print('   非鋼琴音域: ${nonPianoNotes.length} 事件');
    
    if (nonPianoNotes.isNotEmpty) {
      print('   ⚠️  包含非鋼琴音符，可能被過濾');
    }
    
  } catch (e, s) {
    print('❌ 解析錯誤: $e');
    print('Stack: $s');
  }
}

String _noteNumberToName(int noteNumber) {
  const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  final octave = (noteNumber / 12).floor() - 1;
  final noteName = noteNames[noteNumber % 12];
  return '$noteName$octave';
}

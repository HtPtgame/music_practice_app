// ignore_for_file: avoid_print

import 'dart:io';
import 'package:veloria/utils/midi_parser.dart';

/// 測試 MIDI 檔案解析器
/// 用法: dart run tools/test_midi_parser.dart <midi_file_path>
void main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ 請提供 MIDI 檔案路徑');
    print('用法: dart run tools/test_midi_parser.dart <midi_file_path>');
    exit(1);
  }

  final midiPath = args[0];
  final file = File(midiPath);

  if (!await file.exists()) {
    print('❌ 檔案不存在: $midiPath');
    exit(1);
  }

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📁 MIDI 檔案測試');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  try {
    // 讀取檔案
    final fileSize = await file.length();
    print('📋 基本資訊:');
    print('  • 檔案: ${file.path.split(Platform.pathSeparator).last}');
    print('  • 大小: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)\n');

    // 解析 MIDI
    final bytes = await file.readAsBytes();
    final parser = MidiParser();
    
    print('⚙️  開始解析...');
    final stopwatch = Stopwatch()..start();
    final events = parser.parse(bytes);
    stopwatch.stop();
    
    print('✅ 解析完成 (${stopwatch.elapsedMilliseconds}ms)\n');

    // 顯示解析結果
    print('📊 解析結果:');
    print('  • TPQ (Ticks Per Quarter): ${parser.ticksPerQuarterNote}');
    print('  • 總音符數: ${events.length}');
    print('  • Tempo 事件數: ${parser.tempoEvents.length}\n');

    // 音符範圍
    if (events.isNotEmpty) {
      final noteNumbers = events.map((e) => e.noteNumber).toList();
      final minNote = noteNumbers.reduce((a, b) => a < b ? a : b);
      final maxNote = noteNumbers.reduce((a, b) => a > b ? a : b);
      
      print('🎹 音符範圍:');
      print('  • 最低音: $minNote (${_noteNumberToName(minNote)})');
      print('  • 最高音: $maxNote (${_noteNumberToName(maxNote)})\n');
    }

    // Tempo 資訊
    if (parser.tempoEvents.isNotEmpty) {
      print('🎵 Tempo 事件:');
      for (var i = 0; i < parser.tempoEvents.length && i < 10; i++) {
        final tempo = parser.tempoEvents[i];
        final bpm = (60000000 / tempo.microsecondsPerQuarter).round();
        print('  ${i + 1}. Tick ${tempo.tick}: $bpm BPM (${tempo.microsecondsPerQuarter} μs/quarter)');
      }
      if (parser.tempoEvents.length > 10) {
        print('  ... (還有 ${parser.tempoEvents.length - 10} 個 tempo 事件)');
      }
      print('');
    }

    // Tick 範圍
    if (events.isNotEmpty) {
      final firstTick = events.first.tick;
      final lastTick = events.last.tick;
      
      print('⏱️  Tick 範圍:');
      print('  • 第一個音符: $firstTick');
      print('  • 最後一個音符: $lastTick');
      print('  • 跨度: ${lastTick - firstTick}\n');
    }

    // 估算時長
    if (events.isNotEmpty && parser.tempoEvents.isNotEmpty) {
      final estimatedDuration = _estimateDuration(
        events,
        parser.tempoEvents,
        parser.ticksPerQuarterNote,
      );
      
      print('⏰ 估算時長:');
      print('  • ${estimatedDuration.toStringAsFixed(1)} 秒');
      print('  • ${_formatTime(estimatedDuration)}\n');
    }

    // 檢查問題
    print('🔍 問題檢查:');
    var issueFound = false;

    // 檢查 1: 超大 tick 值
    if (events.isNotEmpty) {
      final largeTicks = events.where((e) => e.tick > 10000000).toList();
      if (largeTicks.isNotEmpty) {
        print('  ⚠️  發現 ${largeTicks.length} 個超大 tick 值 (> 10,000,000)');
        issueFound = true;
      }
    }

    // 檢查 2: 音符超出鋼琴範圍
    if (events.isNotEmpty) {
      final outOfRange = events.where((e) => e.noteNumber < 21 || e.noteNumber > 108).toList();
      if (outOfRange.isNotEmpty) {
        print('  ⚠️  發現 ${outOfRange.length} 個超出鋼琴範圍的音符 (A0-C8)');
        issueFound = true;
      }
    }

    // 檢查 3: 異常 tempo 值
    if (parser.tempoEvents.isNotEmpty) {
      final abnormalTempos = parser.tempoEvents.where((t) => 
        t.microsecondsPerQuarter <= 0 || t.microsecondsPerQuarter > 10000000
      ).toList();
      
      if (abnormalTempos.isNotEmpty) {
        print('  ⚠️  發現 ${abnormalTempos.length} 個異常 tempo 值');
        issueFound = true;
      }

      // 檢查 tempo tick 是否遠超音符範圍
      if (events.isNotEmpty) {
        final lastNoteTick = events.last.tick;
        final farTempos = parser.tempoEvents.where((t) => 
          t.tick > lastNoteTick + (parser.ticksPerQuarterNote * 4)
        ).toList();
        
        if (farTempos.isNotEmpty) {
          print('  ⚠️  發現 ${farTempos.length} 個遠超音符範圍的 tempo 事件');
          for (var tempo in farTempos.take(3)) {
            print('     - Tick ${tempo.tick} (最後音符: $lastNoteTick)');
          }
          issueFound = true;
        }
      }
    }

    if (!issueFound) {
      print('  ✅ 未發現明顯問題');
    }

    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ 測試完成');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  } catch (e, stackTrace) {
    print('\n❌ 解析失敗:');
    print('  錯誤: $e');
    print('\n堆疊追蹤:');
    print(stackTrace);
    exit(1);
  }
}

String _noteNumberToName(int noteNumber) {
  const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  final octave = (noteNumber ~/ 12) - 1;
  final noteName = noteNames[noteNumber % 12];
  return '$noteName$octave';
}

String _formatTime(double seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = (seconds % 60).round();
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
}

double _estimateDuration(
  List<dynamic> events,
  List<dynamic> tempoEvents,
  int tpq,
) {
  if (events.isEmpty || tempoEvents.isEmpty) return 0.0;

  final lastTick = events.last.tick;
  double totalMs = 0.0;
  int currentTick = 0;
  int tempoIndex = 0;
  
  var currentTempo = tempoEvents[0].microsecondsPerQuarter;

  while (currentTick < lastTick) {
    // 檢查是否有新的 tempo
    if (tempoIndex + 1 < tempoEvents.length &&
        currentTick >= tempoEvents[tempoIndex + 1].tick) {
      tempoIndex++;
      currentTempo = tempoEvents[tempoIndex].microsecondsPerQuarter;
    }

    // 計算到下一個 tempo 或結束的時間
    final nextTempoTick = (tempoIndex + 1 < tempoEvents.length)
        ? tempoEvents[tempoIndex + 1].tick
        : lastTick;
    
    final ticksToProcess = nextTempoTick - currentTick;
    final msPerTick = currentTempo / 1000.0 / tpq;
    totalMs += ticksToProcess * msPerTick;
    
    currentTick = nextTempoTick;
  }

  return totalMs / 1000.0;
}

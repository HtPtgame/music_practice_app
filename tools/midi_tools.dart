/// MIDI 分析工具
/// 分析 MIDI 檔案的結構、音符、Tempo 等資訊
/// 
/// 使用方式:
/// ```bash
/// # 分析單個 MIDI 檔案
/// dart tools/midi_tools.dart analyze <檔案路徑>
/// 
/// # 分析目錄中的所有 MIDI 檔案
/// dart tools/midi_tools.dart batch <目錄路徑>
/// ```

import 'dart:io';
import 'dart:typed_data';

void main(List<String> args) {
  if (args.isEmpty) {
    printUsage();
    exit(1);
  }

  final command = args[0].toLowerCase();

  try {
    switch (command) {
      case 'analyze':
        if (args.length < 2) {
          print('❌ 錯誤: analyze 指令需要檔案路徑');
          print('用法: dart tools/midi_tools.dart analyze <檔案路徑>');
          exit(1);
        }
        analyzeMidiFile(args[1]);
        break;

      case 'batch':
        if (args.length < 2) {
          print('❌ 錯誤: batch 指令需要目錄路徑');
          print('用法: dart tools/midi_tools.dart batch <目錄路徑>');
          exit(1);
        }
        batchAnalyzeMidi(args[1]);
        break;

      default:
        print('❌ 未知指令: $command');
        printUsage();
        exit(1);
    }
  } catch (e) {
    print('❌ 錯誤: $e');
    exit(1);
  }
}

void printUsage() {
  print('''
🎼 MIDI 分析工具

使用方式:
  dart tools/midi_tools.dart <指令> [參數]

指令:
  analyze <檔案路徑>  - 分析單個 MIDI 檔案
  batch <目錄路徑>    - 批次分析目錄中的所有 MIDI 檔案

範例:
  dart tools/midi_tools.dart analyze assets/test_voice/生日快樂.mid
  dart tools/midi_tools.dart batch assets/test_voice/
''');
}

void analyzeMidiFile(String filePath) {
  print('🔍 MIDI 檔案分析工具');
  print('=' * 70);
  
  final file = File(filePath);
  if (!file.existsSync()) {
    throw Exception('檔案不存在: $filePath');
  }

  final bytes = file.readAsBytesSync();
  final fileName = filePath.split(Platform.pathSeparator).last;
  
  print('📁 檔案: $fileName');
  print('📊 檔案大小: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
  
  // 解析 MIDI 標頭
  if (bytes.length < 14) {
    throw Exception('檔案太小，不是有效的 MIDI 檔案');
  }

  final header = String.fromCharCodes(bytes.sublist(0, 4));
  if (header != 'MThd') {
    throw Exception('不是有效的 MIDI 檔案（缺少 MThd 標頭）');
  }

  final format = (bytes[8] << 8) | bytes[9];
  final numTracks = (bytes[10] << 8) | bytes[11];
  final division = (bytes[12] << 8) | bytes[13];
  
  print('🎵 格式類型: $format');
  print('📝 軌道數: $numTracks');
  print('⏱️  TPQ (Ticks Per Quarter): $division');
  
  // 解析軌道
  var offset = 14;
  var totalNotes = 0;
  var minNote = 127;
  var maxNote = 0;
  final tempoEvents = <TempoEvent>[];
  final noteTimings = <int>[];
  
  for (var trackNum = 0; trackNum < numTracks && offset < bytes.length; trackNum++) {
    final trackHeader = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    if (trackHeader != 'MTrk') {
      print('⚠️  警告: 軌道 $trackNum 標頭不正確');
      break;
    }
    
    final trackLength = (bytes[offset + 4] << 24) |
                       (bytes[offset + 5] << 16) |
                       (bytes[offset + 6] << 8) |
                       bytes[offset + 7];
    
    offset += 8;
    final trackEnd = offset + trackLength;
    var currentTick = 0;
    
    while (offset < trackEnd && offset < bytes.length) {
      // 讀取 delta time
      final deltaTime = _readVarLength(bytes, offset);
      offset = deltaTime.newOffset;
      currentTick += deltaTime.value;
      
      if (offset >= trackEnd) break;
      
      // 讀取事件
      var eventType = bytes[offset];
      
      // Note On (0x90-0x9F)
      if (eventType >= 0x90 && eventType <= 0x9F) {
        if (offset + 2 < trackEnd) {
          final note = bytes[offset + 1];
          final velocity = bytes[offset + 2];
          
          if (velocity > 0) {
            totalNotes++;
            if (note < minNote) minNote = note;
            if (note > maxNote) maxNote = note;
            noteTimings.add(currentTick);
          }
          offset += 3;
        } else {
          break;
        }
      }
      // Note Off (0x80-0x8F)
      else if (eventType >= 0x80 && eventType <= 0x8F) {
        offset += 3;
      }
      // Meta Event (0xFF)
      else if (eventType == 0xFF) {
        if (offset + 1 >= trackEnd) break;
        
        final metaType = bytes[offset + 1];
        offset += 2;
        
        final length = _readVarLength(bytes, offset);
        offset = length.newOffset;
        
        // Tempo event (0x51)
        if (metaType == 0x51 && length.value == 3 && offset + 3 <= trackEnd) {
          final microsecondsPerQuarter = (bytes[offset] << 16) |
                                         (bytes[offset + 1] << 8) |
                                         bytes[offset + 2];
          final bpm = 60000000 / microsecondsPerQuarter;
          tempoEvents.add(TempoEvent(currentTick, bpm, microsecondsPerQuarter));
        }
        
        offset += length.value;
      }
      // Other events
      else {
        offset++;
        if (eventType >= 0xC0 && eventType <= 0xDF) {
          offset++; // 1 data byte
        } else if (eventType >= 0x80 && eventType <= 0xBF || 
                   eventType >= 0xE0 && eventType <= 0xEF) {
          offset += 2; // 2 data bytes
        }
      }
    }
    
    offset = trackEnd;
  }
  
  print('🎵 音符總數: $totalNotes');
  print('🎼 Tempo 事件數: ${tempoEvents.length}');
  
  if (tempoEvents.isNotEmpty) {
    print('\n📌 Tempo 事件詳情:');
    for (var i = 0; i < tempoEvents.length; i++) {
      final event = tempoEvents[i];
      print('   ${i + 1}. Tick ${event.tick}: ${event.bpm.toStringAsFixed(1)} BPM (${event.microsecondsPerQuarter} μs/quarter)');
    }
  }
  
  if (totalNotes > 0) {
    print('\n📊 音符分布:');
    print('   最低音符: ${_noteToString(minNote)} ($minNote)');
    print('   最高音符: ${_noteToString(maxNote)} ($maxNote)');
    print('   音域跨度: ${maxNote - minNote} 半音 (${((maxNote - minNote) / 12).toStringAsFixed(1)} 個八度)');
    
    // 計算時長
    if (noteTimings.isNotEmpty && tempoEvents.isNotEmpty) {
      final lastTick = noteTimings.reduce((a, b) => a > b ? a : b);
      final tempo = tempoEvents.first;
      final ticksPerSecond = 1000000.0 / tempo.microsecondsPerQuarter * division;
      final duration = lastTick / ticksPerSecond;
      final density = totalNotes / duration;
      
      print('\n⏰ 時長分析:');
      print('   總時長: ${duration.toStringAsFixed(1)} 秒');
      print('   音符密度: ${density.toStringAsFixed(1)} notes/sec');
      
      String rating;
      if (density > 8) {
        rating = '🔥 極快節奏';
      } else if (density > 5) {
        rating = '⚡ 快速';
      } else if (density > 3) {
        rating = '🎵 中等';
      } else if (density > 1) {
        rating = '🎼 慢速';
      } else {
        rating = '🎹 非常慢';
      }
      print('   評級: $rating');
    }
  }
  
  print('=' * 70);
}

void batchAnalyzeMidi(String directoryPath) {
  print('🔍 批次分析 MIDI 檔案');
  print('目錄: $directoryPath\n');
  
  final directory = Directory(directoryPath);
  if (!directory.existsSync()) {
    throw Exception('目錄不存在: $directoryPath');
  }

  final midiFiles = directory
      .listSync()
      .where((f) => f.path.toLowerCase().endsWith('.mid') || 
                    f.path.toLowerCase().endsWith('.midi'))
      .toList();

  if (midiFiles.isEmpty) {
    print('⚠️  目錄中沒有 MIDI 檔案');
    return;
  }

  print('📊 找到 ${midiFiles.length} 個 MIDI 檔案\n');

  for (var i = 0; i < midiFiles.length; i++) {
    print('\n[${ i + 1}/${midiFiles.length}]');
    analyzeMidiFile(midiFiles[i].path);
    if (i < midiFiles.length - 1) {
      print('\n');
    }
  }
}

// ============================================================================
// 輔助類別和函數
// ============================================================================

class TempoEvent {
  final int tick;
  final double bpm;
  final int microsecondsPerQuarter;
  
  TempoEvent(this.tick, this.bpm, this.microsecondsPerQuarter);
}

class VarLengthResult {
  final int value;
  final int newOffset;
  
  VarLengthResult(this.value, this.newOffset);
}

VarLengthResult _readVarLength(Uint8List bytes, int offset) {
  var value = 0;
  var currentOffset = offset;
  
  while (currentOffset < bytes.length) {
    final byte = bytes[currentOffset++];
    value = (value << 7) | (byte & 0x7F);
    
    if ((byte & 0x80) == 0) {
      break;
    }
  }
  
  return VarLengthResult(value, currentOffset);
}

String _noteToString(int note) {
  const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  final octave = (note ~/ 12) - 1;
  final noteName = noteNames[note % 12];
  return '$noteName$octave';
}

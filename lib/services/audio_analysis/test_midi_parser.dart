import 'dart:io';
import 'package:music_practice_app/services/audio_analysis/midi_parser_service.dart';
import 'package:music_practice_app/services/audio_analysis/models/note_event.dart';

/// MIDI 解析測試腳本
///
/// 使用方法:
/// 1. 將 MIDI 文件放在項目根目錄
/// 2. 修改下面的文件路徑
/// 3. 運行: flutter run -d windows lib/services/audio_analysis/test_midi_parser.dart
void main() async {
  print('🎹 MIDI 解析測試工具');
  print('═══════════════════════════════════════');

  // ⚠️ 修改為您的 MIDI 文件路徑
  const midiPath = 'assets/測試.mid'; // 或使用絕對路徑 'd:\\path\\to\\your.mid'

  final file = File(midiPath);
  if (!await file.exists()) {
    print('❌ 錯誤: 找不到文件 "$midiPath"');
    print('');
    print('💡 請執行以下步驟:');
    print('1. 將 MIDI 文件放在項目根目錄');
    print(
        '2. 修改 lib/services/audio_analysis/test_midi_parser.dart 中的 midiPath');
    print('3. 重新運行此腳本');
    return;
  }

  print('📂 文件: $midiPath');
  print('📊 大小: ${(await file.length() / 1024).toStringAsFixed(2)} KB');
  print('');

  try {
    final parser = MidiParserService();

    print('⏳ 開始解析...');
    final timeline = await parser.parseFile(midiPath);

    print('');
    print('✅ 解析成功!');
    print('═══════════════════════════════════════');
    print('📊 統計資訊:');
    print('   總音符數: ${timeline.events.length}');
    print('   總時長: ${timeline.duration.toStringAsFixed(2)} 秒');

    if (timeline.events.isNotEmpty) {
      final firstNote = timeline.events.first;
      final lastNote = timeline.events.last;

      print(
          '   第一個音符: ${firstNote.noteName} (${firstNote.startTime.toStringAsFixed(2)}s)');
      print(
          '   最後一個音符: ${lastNote.noteName} (${lastNote.endTime.toStringAsFixed(2)}s)');

      // 音域分析
      final allNotes = timeline.events.map((e) => e.midiNote).toSet().toList()
        ..sort();
      final lowest = timeline.events
          .map((e) => e.midiNote)
          .reduce((a, b) => a < b ? a : b);
      final highest = timeline.events
          .map((e) => e.midiNote)
          .reduce((a, b) => a > b ? a : b);

      print(
          '   音域: ${NoteEvent(midiNote: lowest, startTime: 0, endTime: 0).noteName} - '
          '${NoteEvent(midiNote: highest, startTime: 0, endTime: 0).noteName}');
      print('   使用的不同音符數: ${allNotes.length}');
    }

    print('');
    print('🎵 前 10 個音符詳情:');
    print('───────────────────────────────────────');

    for (int i = 0; i < 10 && i < timeline.events.length; i++) {
      final note = timeline.events[i];
      final duration = (note.duration * 1000).toStringAsFixed(0);
      print('   ${(i + 1).toString().padLeft(2)}. ${note.noteName.padRight(4)} '
          '│ ${note.startTime.toStringAsFixed(2)}s - ${note.endTime.toStringAsFixed(2)}s '
          '│ 時長: ${duration}ms');
    }

    if (timeline.events.length > 10) {
      print('   ... 還有 ${timeline.events.length - 10} 個音符');
    }

    print('');
    print('═══════════════════════════════════════');
    print('✅ 測試完成!');
  } catch (e) {
    print('');
    print('❌ 解析失敗: $e');
  }
}

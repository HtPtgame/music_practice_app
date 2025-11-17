import 'dart:io';
import 'dart:typed_data';
import 'models/note_event.dart';

/// MIDI 解析服務
///
/// 將 MIDI 文件解析為 MidiTimeline
class MidiParserService {
  /// 從 MIDI 文件解析時間軸
  Future<MidiTimeline> parseFile(String midiFilePath) async {
    try {
      final file = File(midiFilePath);
      if (!await file.exists()) {
        throw Exception('MIDI 文件不存在: $midiFilePath');
      }

      final bytes = await file.readAsBytes();
      return parseBytes(bytes);
    } catch (e) {
      throw Exception('MIDI 解析失敗: $e');
    }
  }

  /// 從字節數據解析 MIDI
  MidiTimeline parseBytes(Uint8List bytes) {
    try {
      // 基本 MIDI 文件格式驗證
      if (bytes.length < 14) {
        throw Exception('MIDI 文件太小');
      }

      // 檢查 "MThd" 標記
      final header = String.fromCharCodes(bytes.sublist(0, 4));
      if (header != 'MThd') {
        throw Exception('不是有效的 MIDI 文件');
      }

      // 讀取格式類型 (bytes 8-9)
      final format = (bytes[8] << 8) | bytes[9];

      // 讀取音軌數量 (bytes 10-11)
      final numTracks = (bytes[10] << 8) | bytes[11];

      // 讀取時間分度 (bytes 12-13)
      final division = (bytes[12] << 8) | bytes[13];

      print('📄 MIDI 格式: $format, 音軌數: $numTracks, 時間分度: $division');

      // 解析所有音軌
      final events = <NoteEvent>[];
      int offset = 14; // 跳過 header

      for (int trackNum = 0; trackNum < numTracks; trackNum++) {
        final trackEvents = _parseTrack(bytes, offset, division);
        events.addAll(trackEvents.events);
        offset = trackEvents.nextOffset;
      }

      // 計算總時長
      double maxEndTime = 0;
      for (final event in events) {
        if (event.endTime > maxEndTime) {
          maxEndTime = event.endTime;
        }
      }

      print(
          '🎵 解析完成: ${events.length} 個音符, 總時長: ${maxEndTime.toStringAsFixed(2)}秒');

      return MidiTimeline(
        events: events,
        duration: maxEndTime,
      );
    } catch (e) {
      throw Exception('MIDI 解析錯誤: $e');
    }
  }

  /// 解析單個音軌
  _TrackParseResult _parseTrack(Uint8List bytes, int offset, int division) {
    // 檢查 "MTrk" 標記
    final trackHeader = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    if (trackHeader != 'MTrk') {
      throw Exception('音軌標記錯誤');
    }

    // 讀取音軌長度
    final trackLength = (bytes[offset + 4] << 24) |
        (bytes[offset + 5] << 16) |
        (bytes[offset + 6] << 8) |
        bytes[offset + 7];

    final trackEnd = offset + 8 + trackLength;
    int pos = offset + 8;

    final events = <NoteEvent>[];
    final activeNotes = <int, _ActiveNote>{}; // MIDI note -> 開始時間

    int currentTick = 0;
    int runningStatus = 0;

    // 假設默認 tempo (120 BPM = 500000 微秒/拍)
    double microsecondsPerQuarterNote = 500000;

    while (pos < trackEnd) {
      // 讀取 delta time (可變長度)
      final deltaResult = _readVariableLength(bytes, pos);
      currentTick += deltaResult.value;
      pos = deltaResult.nextPos;

      if (pos >= trackEnd) break;

      // 讀取事件
      int status = bytes[pos];

      // 處理 running status
      if (status < 0x80) {
        status = runningStatus;
      } else {
        pos++;
        runningStatus = status;
      }

      final eventType = status & 0xF0;
      // final channel = status & 0x0F;  // 保留供未來使用

      // Note On (0x90)
      if (eventType == 0x90) {
        if (pos + 1 >= trackEnd) break;

        final note = bytes[pos];
        final velocity = bytes[pos + 1];
        pos += 2;

        final timeInSeconds =
            _ticksToSeconds(currentTick, division, microsecondsPerQuarterNote);

        if (velocity > 0) {
          // Note On
          activeNotes[note] = _ActiveNote(
            midiNote: note,
            startTime: timeInSeconds,
            velocity: velocity,
          );
        } else {
          // Velocity = 0 視為 Note Off
          final activeNote = activeNotes.remove(note);
          if (activeNote != null) {
            events.add(NoteEvent(
              midiNote: note,
              startTime: activeNote.startTime,
              endTime: timeInSeconds,
              velocity: activeNote.velocity,
            ));
          }
        }
      }
      // Note Off (0x80)
      else if (eventType == 0x80) {
        if (pos + 1 >= trackEnd) break;

        final note = bytes[pos];
        pos += 2; // 跳過 velocity

        final timeInSeconds =
            _ticksToSeconds(currentTick, division, microsecondsPerQuarterNote);
        final activeNote = activeNotes.remove(note);

        if (activeNote != null) {
          events.add(NoteEvent(
            midiNote: note,
            startTime: activeNote.startTime,
            endTime: timeInSeconds,
            velocity: activeNote.velocity,
          ));
        }
      }
      // Meta Event (0xFF)
      else if (status == 0xFF) {
        if (pos >= trackEnd) break;

        final metaType = bytes[pos];
        pos++;

        final lengthResult = _readVariableLength(bytes, pos);
        pos = lengthResult.nextPos;

        // Set Tempo (0x51)
        if (metaType == 0x51 && lengthResult.value == 3) {
          microsecondsPerQuarterNote =
              ((bytes[pos] << 16) | (bytes[pos + 1] << 8) | bytes[pos + 2])
                  .toDouble();
        }

        pos += lengthResult.value;
      }
      // 其他事件 (控制變化, 程序變化等)
      else if (eventType == 0xB0 || eventType == 0xC0 || eventType == 0xE0) {
        final dataBytes = eventType == 0xC0 ? 1 : 2;
        pos += dataBytes;
      }
      // SysEx 事件
      else if (status == 0xF0 || status == 0xF7) {
        final lengthResult = _readVariableLength(bytes, pos);
        pos = lengthResult.nextPos + lengthResult.value;
      }
    }

    return _TrackParseResult(
      events: events,
      nextOffset: trackEnd,
    );
  }

  /// 將 MIDI ticks 轉換為秒
  double _ticksToSeconds(
      int ticks, int division, double microsecondsPerQuarterNote) {
    // division 通常是每四分音符的 ticks 數
    final secondsPerTick = microsecondsPerQuarterNote / (division * 1000000.0);
    return ticks * secondsPerTick;
  }

  /// 讀取可變長度值 (MIDI 標準格式)
  _VariableLengthResult _readVariableLength(Uint8List bytes, int pos) {
    int value = 0;
    int currentPos = pos;

    while (currentPos < bytes.length) {
      final byte = bytes[currentPos];
      value = (value << 7) | (byte & 0x7F);
      currentPos++;

      if ((byte & 0x80) == 0) {
        break; // 最高位為 0,結束
      }
    }

    return _VariableLengthResult(value: value, nextPos: currentPos);
  }
}

/// 活動中的音符 (Note On 但尚未 Note Off)
class _ActiveNote {
  final int midiNote;
  final double startTime;
  final int velocity;

  _ActiveNote({
    required this.midiNote,
    required this.startTime,
    required this.velocity,
  });
}

/// 可變長度讀取結果
class _VariableLengthResult {
  final int value;
  final int nextPos;

  _VariableLengthResult({required this.value, required this.nextPos});
}

/// 音軌解析結果
class _TrackParseResult {
  final List<NoteEvent> events;
  final int nextOffset;

  _TrackParseResult({required this.events, required this.nextOffset});
}

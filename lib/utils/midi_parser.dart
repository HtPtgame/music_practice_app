import 'dart:typed_data';

class MidiNoteEvent {
  final int tick;
  final int noteNumber;
  final int velocity;
  final bool isNoteOn;

  MidiNoteEvent({
    required this.tick,
    required this.noteNumber,
    required this.velocity,
    required this.isNoteOn,
  });
}

class TempoChange {
  final int tick;
  final int microsecondsPerQuarter;

  TempoChange({required this.tick, required this.microsecondsPerQuarter});

  /// 計算每 tick 的毫秒時間
  double msPerTick(int tpq) => microsecondsPerQuarter / 1000.0 / tpq;
}

class MidiParser {
  late ByteData _byteData;
  int _p = 0;
  int ticksPerQuarterNote = 480; // 預設值，會從 MThd 讀取

  List<TempoChange> tempoEvents = [];

  /// 解析 MIDI 檔案
  List<MidiNoteEvent> parse(Uint8List bytes) {
    _byteData = ByteData.view(bytes.buffer);
    _p = 0;
    tempoEvents.clear();

    try {
      // --- Parse Header (MThd) ---
      if (_byteData.lengthInBytes < 14) {
        throw 'MIDI 檔案太小，至少需要 14 bytes';
      }

      final headerId = String.fromCharCodes(_byteData.buffer.asUint8List(_p, 4));
      if (headerId != 'MThd') {
        throw 'Invalid MIDI file: Missing MThd chunk (found: $headerId)';
      }

      final headerLength = _byteData.getUint32(_p + 4);
      if (headerLength < 6) {
        throw 'Invalid MIDI header length: $headerLength';
      }

      // final formatType = _byteData.getUint16(_p + 8); // 0, 1, 2 - unused
      final trackCount = _byteData.getUint16(_p + 10);
      ticksPerQuarterNote = _byteData.getUint16(_p + 12);
      
      if (ticksPerQuarterNote <= 0 || ticksPerQuarterNote > 10000) {
        throw 'Invalid ticks per quarter note: $ticksPerQuarterNote';
      }
      
      if (trackCount <= 0 || trackCount > 1000) {
        throw 'Invalid track count: $trackCount';
      }
      
      _p += 8 + headerLength;

      // --- Parse Tracks (MTrk) ---
      final events = <MidiNoteEvent>[];
      for (int i = 0; i < trackCount; i++) {
        // 安全檢查：確保還有足夠的數據可讀
        if (_p + 8 > _byteData.lengthInBytes) {
          break; // 沒有足夠的數據讀取下一個 chunk
        }
        
        final trackChunk = _readChunk();
        if (trackChunk == null) break; // chunk 讀取失敗
        
        if (String.fromCharCodes(trackChunk.id) == 'MTrk') {
          events.addAll(_parseTrack(trackChunk.data));
        }
      }

      // 排序：先依 tick，再依 tempoEvents
      events.sort((a, b) => a.tick.compareTo(b.tick));
      tempoEvents.sort((a, b) => a.tick.compareTo(b.tick));

      // 如果沒有 tempo 事件，加入預設 120 BPM
      if (tempoEvents.isEmpty) {
        tempoEvents
            .add(TempoChange(tick: 0, microsecondsPerQuarter: 500000)); // 120 BPM
      }

      return events;
    } catch (e) {
      // 重新拋出錯誤，帶有更多上下文
      throw 'MIDI 解析錯誤 (position: $_p/${_byteData.lengthInBytes}): $e';
    }
  }

  /// 解析單一 MTrk
  List<MidiNoteEvent> _parseTrack(ByteData data) {
    final events = <MidiNoteEvent>[];
    int p = 0;
    int tick = 0;
    int lastStatusCode = 0;

    while (p < data.lengthInBytes) {
      // 安全檢查：確保不會超出範圍
      if (p >= data.lengthInBytes) break;
      
      tick += _readVarIntSafe(data, p: () => p, setP: (val) => p = val);
      
      // 安全檢查
      if (p >= data.lengthInBytes) break;

      int statusCode = data.getUint8(p);
      if (statusCode < 0x80) {
        statusCode = lastStatusCode;
        p--; // Running status
      }
      p++;

      // 安全檢查
      if (p > data.lengthInBytes) break;

      final eventType = statusCode & 0xF0;

      if (eventType == 0x90 || eventType == 0x80) {
        // Note On/Off - 需要 2 bytes
        if (p + 2 > data.lengthInBytes) break;
        final note = data.getUint8(p++);
        final velocity = data.getUint8(p++);
        events.add(MidiNoteEvent(
          tick: tick,
          noteNumber: note,
          velocity: velocity,
          isNoteOn: eventType == 0x90 && velocity > 0,
        ));
      } else if (statusCode == 0xFF) {
        // Meta Event
        if (p >= data.lengthInBytes) break;
        final metaType = data.getUint8(p++);
        final len = _readVarIntSafe(data, p: () => p, setP: (val) => p = val);

        if (metaType == 0x51 && len == 3 && p + 3 <= data.lengthInBytes) {
          // Tempo Change
          final microPerQuarter = (data.getUint8(p) << 16) |
              (data.getUint8(p + 1) << 8) |
              data.getUint8(p + 2);
          tempoEvents.add(
              TempoChange(tick: tick, microsecondsPerQuarter: microPerQuarter));
        }
        // 安全跳過：確保不超出範圍
        if (p + len <= data.lengthInBytes) {
          p += len;
        } else {
          break; // 數據不足，停止解析
        }
      } else if (statusCode == 0xF0 || statusCode == 0xF7) {
        // SysEx Event - 讀取長度並跳過
        final len = _readVarIntSafe(data, p: () => p, setP: (val) => p = val);
        if (p + len <= data.lengthInBytes) {
          p += len;
        } else {
          break;
        }
      } else if (eventType == 0xA0 && p + 2 <= data.lengthInBytes) {
        // Polyphonic Key Pressure - 2 bytes
        p += 2;
      } else if (eventType == 0xB0 && p + 2 <= data.lengthInBytes) {
        // Control Change - 2 bytes
        p += 2;
      } else if (eventType == 0xC0 && p + 1 <= data.lengthInBytes) {
        // Program Change - 1 byte
        p += 1;
      } else if (eventType == 0xD0 && p + 1 <= data.lengthInBytes) {
        // Channel Pressure - 1 byte
        p += 1;
      } else if (eventType == 0xE0 && p + 2 <= data.lengthInBytes) {
        // Pitch Bend - 2 bytes
        p += 2;
      } else {
        // 未知事件類型或數據不足，停止解析
        break;
      }

      if (statusCode >= 0x80 && statusCode < 0xF0) {
        lastStatusCode = statusCode;
      }
    }

    return events;
  }
  
  /// 安全版本的可變長度整數讀取
  int _readVarIntSafe(ByteData data,
      {required int Function() p, required void Function(int) setP}) {
    int value = 0;
    int byte;
    int currentP = p();
    int iterations = 0;
    const maxIterations = 4; // VarInt 最多 4 bytes
    
    do {
      if (currentP >= data.lengthInBytes) break;
      byte = data.getUint8(currentP++);
      value = (value << 7) | (byte & 0x7F);
      iterations++;
      if (iterations >= maxIterations) break;
    } while ((byte & 0x80) != 0);
    
    setP(currentP);
    return value;
  }

  /// 讀取一個 Chunk（安全版本）
  ({List<int> id, ByteData data})? _readChunk() {
    // 檢查是否有足夠的空間讀取 chunk header (8 bytes)
    if (_p + 8 > _byteData.lengthInBytes) {
      return null;
    }
    
    final id = _byteData.buffer.asUint8List(_p, 4);
    final length = _byteData.getUint32(_p + 4);
    
    // 檢查是否有足夠的空間讀取 chunk data
    if (_p + 8 + length > _byteData.lengthInBytes) {
      return null;
    }
    
    final data = ByteData.view(_byteData.buffer, _p + 8, length);
    _p += 8 + length;
    return (id: id.toList(), data: data);
  }
}

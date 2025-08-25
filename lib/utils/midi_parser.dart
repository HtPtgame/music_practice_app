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

class MidiParser {
  late ByteData _byteData;
  int _p = 0;
  int ticksPerQuarterNote = 480; // 預設值，會從 MThd 讀取

  List<MidiNoteEvent> parse(Uint8List bytes) {
    _byteData = ByteData.view(bytes.buffer);
    _p = 0;

    // --- Parse Header (MThd) ---
    final headerId = String.fromCharCodes(_byteData.buffer.asUint8List(_p, 4));
    if (headerId != 'MThd') {
      throw 'Invalid MIDI file: Missing MThd chunk.';
    }
    final headerLength = _byteData.getUint32(_p + 4);
    final formatType = _byteData.getUint16(_p + 8);
    final trackCount = _byteData.getUint16(_p + 10);
    ticksPerQuarterNote = _byteData.getUint16(_p + 12);
    _p += 8 + headerLength;

    // --- Parse Tracks (MTrk) ---
    final events = <MidiNoteEvent>[];
    for (int i = 0; i < trackCount; i++) {
      final trackChunk = _readChunk();
      if (String.fromCharCodes(trackChunk.id) == 'MTrk') {
        events.addAll(_parseTrack(trackChunk.data));
      }
    }

    events.sort((a, b) => a.tick.compareTo(b.tick));
    return events;
  }

  List<MidiNoteEvent> _parseTrack(ByteData data) {
    final events = <MidiNoteEvent>[];
    int p = 0;
    int tick = 0;
    int lastStatusCode = 0;

    while (p < data.lengthInBytes) {
      tick += _readVarInt(data, p: () => p, setP: (val) => p = val);

      int statusCode = data.getUint8(p);
      if (statusCode < 0x80) {
        statusCode = lastStatusCode;
        p--;
      }
      p++;

      final eventType = statusCode & 0xF0;

      if (eventType == 0x90 || eventType == 0x80) {
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
        final metaType = data.getUint8(p++);
        final len = _readVarInt(data, p: () => p, setP: (val) => p = val);

        if (metaType == 0x51 && len == 3) {
          // Set Tempo
          final microPerQuarter = (data.getUint8(p) << 16) |
              (data.getUint8(p + 1) << 8) |
              data.getUint8(p + 2);
          // 你可以用 microPerQuarter 換算 BPM: 60_000_000 / microPerQuarter
        }
        p += len;
      } else if (statusCode >= 0xC0 && statusCode <= 0xEF) {
        // Program Change / Control Change
        p += (statusCode >= 0xC0 && statusCode <= 0xDF) ? 1 : 2;
      }

      lastStatusCode = statusCode;
    }
    return events;
  }

  ({List<int> id, ByteData data}) _readChunk() {
    final id = _byteData.buffer.asUint8List(_p, 4);
    final length = _byteData.getUint32(_p + 4);
    final data = ByteData.view(_byteData.buffer, _p + 8, length);
    _p += 8 + length;
    return (id: id.toList(), data: data);
  }

  int _readVarInt(ByteData data,
      {required int Function() p, required void Function(int) setP}) {
    int value = 0;
    int byte;
    int currentP = p();
    do {
      byte = data.getUint8(currentP++);
      value = (value << 7) | (byte & 0x7F);
    } while ((byte & 0x80) != 0);
    setP(currentP);
    return value;
  }
}

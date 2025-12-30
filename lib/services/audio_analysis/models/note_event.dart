import 'dart:math';

/// MIDI 音符事件
///
/// 代表一個音符的開始時間、結束時間和音高
class NoteEvent {
  /// MIDI 音符號 (0-127, 標準鋼琴 21-108)
  final int midiNote;

  /// 開始時間 (秒)
  final double startTime;

  /// 結束時間 (秒)
  final double endTime;

  /// 力度 (0-127)
  final int velocity;

  NoteEvent({
    required this.midiNote,
    required this.startTime,
    required this.endTime,
    this.velocity = 64,
  });

  /// 音符持續時間 (秒)
  double get duration => endTime - startTime;

  /// 音符名稱 (例如: C4, D#5)
  String get noteName {
    const noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B'
    ];
    final octave = (midiNote ~/ 12) - 1;
    final name = noteNames[midiNote % 12];
    return '$name$octave';
  }

  /// 基頻 (Hz) - A4 = 440Hz
  double get frequency {
    return 440 * pow(2, (midiNote - 69) / 12).toDouble();
  }

  /// 計算諧波頻率
  /// [harmonicIndex] 1=基頻, 2=第一泛音, 3=第二泛音...
  double getHarmonic(int harmonicIndex) {
    return frequency * harmonicIndex;
  }

  @override
  String toString() {
    return 'NoteEvent($noteName, ${startTime.toStringAsFixed(3)}s - ${endTime.toStringAsFixed(3)}s, ${(duration * 1000).toStringAsFixed(0)}ms)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteEvent &&
        other.midiNote == midiNote &&
        (other.startTime - startTime).abs() < 0.01; // 10ms 容差
  }

  @override
  int get hashCode => Object.hash(midiNote, (startTime * 100).round());
}

/// MIDI 時間軸
///
/// 包含所有音符事件和預計算的諧波頻率
class MidiTimeline {
  /// 所有音符事件
  final List<NoteEvent> events;

  /// 曲目總時長 (秒)
  final double duration;

  /// 每個音符的諧波頻率緩存 [midiNote -> [f0, 2f0, 3f0]]
  final Map<int, List<double>> _harmonicsCache = {};

  MidiTimeline({
    required this.events,
    required this.duration,
  }) {
    _precomputeHarmonics();
  }

  /// 預計算所有出現過的音符的諧波頻率
  void _precomputeHarmonics() {
    for (final event in events) {
      if (!_harmonicsCache.containsKey(event.midiNote)) {
        _harmonicsCache[event.midiNote] = [
          event.frequency, // f0
          event.getHarmonic(2), // 2f0
          event.getHarmonic(3), // 3f0
        ];
      }
    }
  }

  /// 獲取指定音符的諧波頻率
  List<double> getHarmonics(int midiNote) {
    if (!_harmonicsCache.containsKey(midiNote)) {
      final tempEvent = NoteEvent(
        midiNote: midiNote,
        startTime: 0,
        endTime: 0,
      );
      _harmonicsCache[midiNote] = [
        tempEvent.frequency,
        tempEvent.getHarmonic(2),
        tempEvent.getHarmonic(3),
      ];
    }
    return _harmonicsCache[midiNote]!;
  }

  /// 獲取指定時間範圍內的音符
  List<NoteEvent> getNotesInRange(double startTime, double endTime) {
    return events.where((note) {
      return note.startTime < endTime && note.endTime > startTime;
    }).toList();
  }

  @override
  String toString() {
    return 'MidiTimeline(${events.length} notes, ${duration.toStringAsFixed(2)}s)';
  }
}

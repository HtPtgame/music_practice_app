import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:music_practice_app/utils/midi_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:music_practice_app/services/settings_service.dart';

/// 預排程音符 - 用於 look-ahead scheduling
class _ScheduledNote {
  final MidiNoteEvent event;
  final int scheduledTimeMs;
  bool played;

  _ScheduledNote({
    required this.event,
    required this.scheduledTimeMs,
  }) : played = false;
}

/// Tempo 段快取 - 預計算累積時間
class _CachedTempo {
  final int startTick;
  final int endTick;
  final double msPerTick;
  final double cumulativeMs;

  _CachedTempo({
    required this.startTick,
    required this.endTick,
    required this.msPerTick,
    required this.cumulativeMs,
  });
}

class MidiPlayerService {
  static final MidiPlayerService _instance = MidiPlayerService._internal();
  factory MidiPlayerService() => _instance;
  MidiPlayerService._internal();

  final MidiPro _midiPro = MidiPro();
  final SettingsService _settingsService = SettingsService();

  bool _isInitialized = false;
  int? _soundfontId;

  // 高精度時間追蹤
  Timer? _playbackLoop;
  final Stopwatch _stopwatch = Stopwatch();

  // 播放狀態
  int _currentIndex = 0;
  List<MidiNoteEvent> _events = [];
  List<_ScheduledNote> _scheduledNotes = [];
  String? _currentMidiPath;
  bool _isPaused = false;

  // Tempo 管理
  List<TempoChange> _tempoChanges = [];
  List<_CachedTempo> _cachedTempos = [];
  int _tpq = 480;

  final _playingStateController = StreamController<bool>.broadcast();
  Stream<bool> get playingStateStream => _playingStateController.stream;

  final _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  // 音量快取 (減少重複讀取 SharedPreferences)
  double _cachedMidiVolume = 0.7;
  double _cachedMasterVolume = 0.8;
  bool _cachedSoundEnabled = true;

  // 效能參數
  static const int _playbackIntervalMs = 8; // 125 Hz 更新率
  static const int _lookAheadMs = 50; // 預先排程 50ms
  static const int _maxNotesPerCycle = 10; // 每週期最多處理音符數

  int get totalDurationMs {
    if (_events.isEmpty) return 0;
    if (_cachedTempos.isEmpty) return 0;

    final lastEvent = _events.last;
    return _getEventTimeMs(lastEvent.tick).round();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 嘗試直接從 assets 載入 SoundFont
      try {
        _soundfontId = await _midiPro.loadSoundfont(
            path: 'assets/TimGM6mb.sf2', bank: 0, program: 0);

        if (_soundfontId != null) {
          // 選擇鋼琴音色 (Program 0 = Acoustic Grand Piano)
          await _midiPro.selectInstrument(
            sfId: _soundfontId!,
            channel: 0,
            bank: 0,
            program: 0, // 鋼琴
          );

          _isInitialized = true;
          return;
        }
      } catch (assetsError) {
        // Assets 載入失敗，嘗試其他方法
      }

      // 嘗試複製到設備存儲
      Directory? directory;
      try {
        directory = await getApplicationDocumentsDirectory();
      } catch (e) {
        directory = await getExternalStorageDirectory();
      }

      if (directory == null) {
        throw Exception('Unable to get storage directory');
      }

      final sfPath = '${directory.path}/TimGM6mb.sf2';
      final file = File(sfPath);

      await file.parent.create(recursive: true);

      if (!await file.exists() || await file.length() == 0) {
        final byteData = await rootBundle.load('assets/TimGM6mb.sf2');
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }

      final fileSize = await file.length();
      if (fileSize < 1000) {
        throw Exception('SoundFont file too small');
      }

      // 載入 SoundFont
      _soundfontId =
          await _midiPro.loadSoundfont(path: sfPath, bank: 0, program: 0);

      if (_soundfontId != null) {
        // 設定鋼琴音色
        await _midiPro.selectInstrument(
          sfId: _soundfontId!,
          channel: 0,
          bank: 0,
          program: 0, // Acoustic Grand Piano
        );
      } else {
        throw Exception('Failed to load SoundFont');
      }

      _isInitialized = true;
      await _loadVolumeSettings();
    } catch (e, s) {
      debugPrint('❌ MidiPlayerService: Initialization FAILED: $e\n$s');
      _isInitialized = false;
      _soundfontId = null;

      // 如果 SoundFont 完全失敗，提供視覺模式
      _isInitialized = true; // 允許視覺播放
    }
  }

  /// 載入音量設定到快取
  Future<void> _loadVolumeSettings() async {
    try {
      _cachedMidiVolume = await _settingsService.getMidiVolume();
      _cachedMasterVolume = await _settingsService.getMasterVolume();
      _cachedSoundEnabled = await _settingsService.isSoundEnabled();
    } catch (e) {
      debugPrint('⚠️ Failed to load volume settings: $e');
    }
  }

  Future<void> play(String midiPath) async {
    if (!_isInitialized) await initialize();

    if (_isPaused && _currentMidiPath == midiPath) {
      resume();
      return;
    }

    await stop();

    _currentMidiPath = midiPath;
    _tempoChanges.clear();
    _cachedTempos.clear();
    _scheduledNotes.clear();

    try {
      final file = File(midiPath);
      final bytes = await file.readAsBytes();

      final parser = MidiParser();
      final events = parser.parse(bytes);
      _tpq = parser.ticksPerQuarterNote;

      // 過濾有效事件，只保留鋼琴音域
      final filteredEvents = events.where((e) {
        return e.tick >= 0 &&
            e.tick < 10000000 &&
            e.noteNumber >= 21 && // A0
            e.noteNumber <= 108; // C8
      }).toList();

      if (filteredEvents.isEmpty) {
        debugPrint('⚠️ No valid piano events found');
        return;
      }

      // 移除前導空白時間
      final firstNoteOn = filteredEvents.firstWhere(
        (e) => e.isNoteOn,
        orElse: () => filteredEvents.first,
      );
      final firstNoteTick = firstNoteOn.tick;

      // 調整所有事件
      _events = filteredEvents.map((event) {
        return MidiNoteEvent(
          tick: (event.tick - firstNoteTick).clamp(0, double.infinity).toInt(),
          noteNumber: event.noteNumber,
          velocity: event.velocity,
          isNoteOn: event.isNoteOn,
        );
      }).toList();

      // 調整 tempo 事件
      _tempoChanges = parser.tempoEvents.map((tempo) {
        return TempoChange(
          tick: (tempo.tick - firstNoteTick).clamp(0, double.infinity).toInt(),
          microsecondsPerQuarter: tempo.microsecondsPerQuarter,
        );
      }).toList();

      // 確保至少有一個 tempo
      if (_tempoChanges.isEmpty) {
        _tempoChanges.add(TempoChange(
          tick: 0,
          microsecondsPerQuarter: 500000, // 120 BPM
        ));
      }

      // ⭐ 預計算所有 tempo 段
      _precomputeTempos();

      _currentIndex = 0;
      _isPaused = false;

      // 重新載入音量設定
      await _loadVolumeSettings();

      _playingStateController.add(true);

      // 啟動高精度播放循環
      _stopwatch.reset();
      _stopwatch.start();
      _startPlaybackLoop();
    } catch (e) {
      debugPrint('❌ Error playing MIDI: $e');
      _playingStateController.add(false);
    }
  }

  /// ⭐ 預計算所有 tempo 段的累積時間
  void _precomputeTempos() {
    _cachedTempos.clear();

    double cumulativeMs = 0.0;

    for (int i = 0; i < _tempoChanges.length; i++) {
      final tempo = _tempoChanges[i];
      final msPerTick = tempo.msPerTick(_tpq);
      final endTick = (i + 1 < _tempoChanges.length)
          ? _tempoChanges[i + 1].tick
          : (_events.isNotEmpty ? _events.last.tick + 1 : 999999999);

      _cachedTempos.add(_CachedTempo(
        startTick: tempo.tick,
        endTick: endTick,
        msPerTick: msPerTick,
        cumulativeMs: cumulativeMs,
      ));

      cumulativeMs += (endTick - tempo.tick) * msPerTick;
    }
  }

  /// ⭐ 高效率取得事件時間 (O(1) 查表)
  double _getEventTimeMs(int tick) {
    for (final tempo in _cachedTempos) {
      if (tick >= tempo.startTick && tick < tempo.endTick) {
        return tempo.cumulativeMs + (tick - tempo.startTick) * tempo.msPerTick;
      }
    }

    // Fallback
    if (_cachedTempos.isEmpty) return 0;
    final lastTempo = _cachedTempos.last;
    return lastTempo.cumulativeMs +
        (tick - lastTempo.startTick) * lastTempo.msPerTick;
  }

  void pause() {
    if (!_isPaused && _playbackLoop != null) {
      _isPaused = true;
      _stopwatch.stop();
      _playbackLoop?.cancel();
      _playbackLoop = null;
      _playingStateController.add(false);
    }
  }

  void resume() {
    if (_isPaused) {
      _isPaused = false;
      _stopwatch.start();
      _playingStateController.add(true);
      _startPlaybackLoop();
    }
  }

  /// ⭐ 啟動播放循環 - 使用預測性排程
  void _startPlaybackLoop() {
    _playbackLoop?.cancel();

    _playbackLoop = Timer.periodic(
        const Duration(milliseconds: _playbackIntervalMs), (timer) {
      if (_currentIndex >= _events.length && _scheduledNotes.isEmpty) {
        stop();
        return;
      }

      final elapsedMs = _stopwatch.elapsedMilliseconds;

      // 1️⃣ 播放已排程且時間到的音符
      _playScheduledNotes(elapsedMs);

      // 2️⃣ 預先排程未來的音符 (look-ahead scheduling)
      _scheduleUpcomingNotes(elapsedMs);

      // 3️⃣ 更新進度
      if (_events.isNotEmpty) {
        final progress = (_currentIndex / _events.length).clamp(0.0, 1.0);
        _progressController.add(progress);
      }
    });
  }

  /// 播放已排程的音符
  void _playScheduledNotes(int currentTimeMs) {
    if (_soundfontId == null || !_cachedSoundEnabled) return;

    for (final scheduled in _scheduledNotes) {
      if (!scheduled.played && scheduled.scheduledTimeMs <= currentTimeMs) {
        _playNoteImmediate(scheduled.event);
        scheduled.played = true;
      }
    }

    // 清理已播放的音符
    _scheduledNotes.removeWhere((note) => note.played);
  }

  /// 預先排程即將到來的音符
  void _scheduleUpcomingNotes(int currentTimeMs) {
    final lookAheadTime = currentTimeMs + _lookAheadMs;
    int notesScheduled = 0;

    while (
        _currentIndex < _events.length && notesScheduled < _maxNotesPerCycle) {
      final event = _events[_currentIndex];
      final eventTimeMs = _getEventTimeMs(event.tick).round();

      // 超出 look-ahead 窗口，停止排程
      if (eventTimeMs > lookAheadTime) break;

      // 如果音符已經過期，立即播放
      if (eventTimeMs <= currentTimeMs) {
        if (_soundfontId != null && _cachedSoundEnabled) {
          _playNoteImmediate(event);
        }
      } else {
        // 排程未來音符
        _scheduledNotes.add(_ScheduledNote(
          event: event,
          scheduledTimeMs: eventTimeMs,
        ));
      }

      _currentIndex++;
      notesScheduled++;
    }
  }

  /// ⭐ 立即播放音符 (非阻塞)
  void _playNoteImmediate(MidiNoteEvent event) {
    if (_soundfontId == null) return;

    try {
      final finalVelocity =
          (event.velocity * _cachedMidiVolume * _cachedMasterVolume)
              .round()
              .clamp(0, 127);

      if (event.isNoteOn) {
        _midiPro.playNote(
            sfId: _soundfontId!,
            key: event.noteNumber,
            velocity: finalVelocity);
      } else {
        _midiPro.stopNote(sfId: _soundfontId!, key: event.noteNumber);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Note playback error: $e');
      }
    }
  }

  Future<void> stop() async {
    _playbackLoop?.cancel();
    _playbackLoop = null;
    _stopwatch.stop();
    _stopwatch.reset();

    _currentIndex = 0;
    _isPaused = false;
    _currentMidiPath = null;
    _tempoChanges.clear();
    _cachedTempos.clear();
    _scheduledNotes.clear();

    // 停止所有音符
    if (_soundfontId != null) {
      try {
        for (var i = 21; i <= 108; i++) {
          // 只停止鋼琴音域
          _midiPro.stopNote(sfId: _soundfontId!, key: i);
        }
      } catch (e) {
        debugPrint('❌ Error stopping notes: $e');
      }
    }

    if (!_playingStateController.isClosed) _playingStateController.add(false);
    if (!_progressController.isClosed) _progressController.add(0.0);
  }

  void dispose() {
    _playbackLoop?.cancel();
    _stopwatch.stop();
    _midiPro.dispose();
    _playingStateController.close();
    _progressController.close();
  }

  // 演奏偵錯功能（專注於鋼琴）
  bool get hasAudioSupport => _isInitialized && _soundfontId != null;

  Future<void> playNote(int noteNumber, {int velocity = 64}) async {
    if (!_isInitialized) await initialize();

    if (_soundfontId != null && noteNumber >= 21 && noteNumber <= 108) {
      try {
        await _midiPro.playNote(
          sfId: _soundfontId!,
          key: noteNumber,
          velocity: velocity,
        );
      } catch (e) {
        debugPrint(
            '❌ MidiPlayerService: Error playing piano note $noteNumber: $e');
      }
    }
  }

  Future<void> stopNote(int noteNumber) async {
    if (_soundfontId != null && noteNumber >= 21 && noteNumber <= 108) {
      try {
        await _midiPro.stopNote(sfId: _soundfontId!, key: noteNumber);
      } catch (e) {
        debugPrint(
            '❌ MidiPlayerService: Error stopping piano note $noteNumber: $e');
      }
    }
  }

  Future<void> stopAllNotes() async {
    if (_soundfontId != null) {
      try {
        for (var i = 21; i <= 108; i++) {
          // 鋼琴音域
          await _midiPro.stopNote(sfId: _soundfontId!, key: i);
        }
      } catch (e) {
        debugPrint('❌ MidiPlayerService: Error stopping all piano notes: $e');
      }
    }
  }
}

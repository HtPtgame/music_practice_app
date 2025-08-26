import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:music_practice_app/utils/midi_parser.dart';
import 'package:path_provider/path_provider.dart';

class MidiPlayerService {
  static final MidiPlayerService _instance = MidiPlayerService._internal();
  factory MidiPlayerService() => _instance;
  MidiPlayerService._internal();

  final MidiPro _midiPro = MidiPro();
  bool _isInitialized = false;
  int? _soundfontId;

  Timer? _playbackLoop;
  int _currentIndex = 0;
  List<MidiNoteEvent> _events = [];
  int _startTime = 0; // 毫秒
  double _msPerTick = 0;
  String? _currentMidiPath;

  bool _isPaused = false;
  int _pauseTime = 0;

  List<TempoChange> _tempoChanges = [];
  int _tempoIndex = 0;
  int _tpq = 480; // 從 parser 取得 ticksPerQuarterNote

  final _playingStateController = StreamController<bool>.broadcast();
  Stream<bool> get playingStateStream => _playingStateController.stream;

  final _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  int get totalDurationMs {
    if (_events.isEmpty) return 0;
    final lastTick = _events.last.tick;
    if (_tempoChanges.isEmpty) return (lastTick * _msPerTick).round();

    double totalMs = 0;
    int prevTick = 0;
    double currentMsPerTick = _tempoChanges.first.msPerTick(_tpq);
    int tempoIdx = 0;

    for (final event in _events) {
      while (tempoIdx + 1 < _tempoChanges.length &&
          _tempoChanges[tempoIdx + 1].tick <= event.tick) {
        final nextTempo = _tempoChanges[tempoIdx + 1];
        totalMs += (nextTempo.tick - prevTick) * currentMsPerTick;
        currentMsPerTick = nextTempo.msPerTick(_tpq);
        prevTick = nextTempo.tick;
        tempoIdx++;
      }
    }
    totalMs += (lastTick - prevTick) * currentMsPerTick;
    return totalMs.round();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    debugPrint('MidiPlayerService: Initializing...');
    try {
      final directory = await getApplicationDocumentsDirectory();
      final sfPath = '${directory.path}/TimGM6mb.sf2';
      final file = File(sfPath);

      if (!await file.exists()) {
        final byteData = await rootBundle.load('assets/TimGM6mb.sf2');
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }

      _soundfontId =
          await _midiPro.loadSoundfont(path: sfPath, bank: 0, program: 0);
      _isInitialized = true;
      debugPrint(
          'MidiPlayerService: Initialization complete with SoundFont ID: $_soundfontId');
    } catch (e) {
      debugPrint('MidiPlayerService: Initialization FAILED: $e');
      rethrow;
    }
  }

  Future<void> play(String midiPath) async {
    if (!_isInitialized || _soundfontId == null) await initialize();
    if (!_isInitialized || _soundfontId == null) return;

    if (_isPaused && _currentMidiPath == midiPath) {
      resume();
      return;
    }

    await stop();

    _currentMidiPath = midiPath;
    _tempoChanges.clear();
    _tempoIndex = 0;

    try {
      final file = File(midiPath);
      final bytes = await file.readAsBytes();

      final parser = MidiParser();
      final events = parser.parse(bytes);
      _tpq = parser.ticksPerQuarterNote;

      final filteredEvents = events.where((e) {
        return e.tick >= 0 && e.tick < 10000000 && e.noteNumber >= 0 && e.noteNumber <= 127;
      }).toList();

      if (filteredEvents.isEmpty) {
        debugPrint('MidiPlayerService: No valid events found.');
        return;
      }

      _events = filteredEvents;
      _tempoChanges = parser.tempoEvents;
      _currentIndex = 0;
      _startTime = DateTime.now().millisecondsSinceEpoch;
      _isPaused = false;

      // 設定初始 tempo
      if (_tempoChanges.isNotEmpty) {
        _msPerTick = _tempoChanges.first.msPerTick(_tpq);
      } else {
        _msPerTick = 500000 / 1000.0 / _tpq; // 預設 120 BPM
      }

      _playingStateController.add(true);
      debugPrint(
          'MidiPlayerService: Playing $midiPath with ${_events.length} events, ${_tempoChanges.length} tempo changes, TPQ=$_tpq.');

      _startPlaybackLoop();
    } catch (e) {
      debugPrint('MidiPlayerService: Error playing midi: $e');
      _playingStateController.add(false);
    }
  }

  void pause() {
    if (!_isPaused && _playbackLoop != null) {
      _isPaused = true;
      _pauseTime = DateTime.now().millisecondsSinceEpoch - _startTime;
      _playbackLoop?.cancel();
      _playbackLoop = null;
      _playingStateController.add(false);
    }
  }

  void resume() {
    if (_isPaused) {
      _isPaused = false;
      _startTime = DateTime.now().millisecondsSinceEpoch - _pauseTime;
      _playingStateController.add(true);
      _startPlaybackLoop();
    }
  }

  void _startPlaybackLoop() {
    _playbackLoop?.cancel();
    _playbackLoop = Timer.periodic(const Duration(milliseconds: 5), (timer) {
      if (_currentIndex >= _events.length) {
        stop();
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = now - _startTime;

      // 根據當前事件動態更新 tempo
      while (_tempoIndex + 1 < _tempoChanges.length &&
          _tempoChanges[_tempoIndex + 1].tick <= _events[_currentIndex].tick) {
        _tempoIndex++;
        _msPerTick = _tempoChanges[_tempoIndex].msPerTick(_tpq);
      }

      while (_currentIndex < _events.length) {
        final event = _events[_currentIndex];
        final eventTime = (event.tick * _msPerTick).round();
        if (eventTime > elapsed) break;

        if (event.isNoteOn) {
          _midiPro.playNote(
              sfId: _soundfontId!, key: event.noteNumber, velocity: event.velocity);
        } else {
          _midiPro.stopNote(sfId: _soundfontId!, key: event.noteNumber);
        }
        _currentIndex++;
      }

      if (_events.isNotEmpty) {
        double progress = (_currentIndex / _events.length).clamp(0.0, 1.0);
        _progressController.add(progress);
      }
    });
  }

  Future<void> stop() async {
    _playbackLoop?.cancel();
    _playbackLoop = null;
    _currentIndex = 0;
    _isPaused = false;
    _pauseTime = 0;
    _currentMidiPath = null;
    _tempoChanges.clear();
    _tempoIndex = 0;

    if (_isInitialized && _soundfontId != null) {
      for (var i = 0; i < 128; i++) {
        _midiPro.stopNote(sfId: _soundfontId!, key: i);
      }
    }

    if (!_playingStateController.isClosed) _playingStateController.add(false);
    if (!_progressController.isClosed) _progressController.add(0.0);

    debugPrint('MidiPlayerService: Stopped.');
  }

  void dispose() {
    _playbackLoop?.cancel();
    _midiPro.dispose();
    _playingStateController.close();
    _progressController.close();
    debugPrint('MidiPlayerService: Disposed.');
  }
}

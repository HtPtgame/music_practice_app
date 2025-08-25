// lib/services/midi_player_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:music_practice_app/utils/midi_parser.dart'; // 引入優化版的解析器
import 'package:path_provider/path_provider.dart';

class MidiPlayerService {
  static final MidiPlayerService _instance = MidiPlayerService._internal();
  factory MidiPlayerService() => _instance;
  MidiPlayerService._internal();

  final MidiPro _midiPro = MidiPro();
  bool _isInitialized = false;
  final List<Timer> _playbackTimers = [];
  int? _soundfontId;

  final _playingStateController = StreamController<bool>.broadcast();
  Stream<bool> get playingStateStream => _playingStateController.stream;

  Future<void> initialize() async {
    // ... (這部分的程式碼與之前完全相同，無需修改) ...
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

      _soundfontId = await _midiPro.loadSoundfont(path: sfPath, bank: 0, program: 0);
      _isInitialized = true;
      debugPrint('MidiPlayerService: Initialization complete with SoundFont ID: $_soundfontId');
    } catch (e) {
      debugPrint('MidiPlayerService: Initialization FAILED: $e');
      rethrow;
    }
  }

  Future<void> play(String midiPath) async {
    if (!_isInitialized || _soundfontId == null) {
      await initialize();
      if (!_isInitialized || _soundfontId == null) return;
    }
    await stop();

    try {
      final file = File(midiPath);
      final bytes = await file.readAsBytes();

      // 使用優化版的解析器
      final parser = MidiParser();
      final events = parser.parse(bytes);

      // 【升級】從解析器獲取更精準的 ticksPerQuarterNote
      final int ticksPerQuarterNote = parser.ticksPerQuarterNote;

      _playingStateController.add(true);
      debugPrint('MidiPlayerService: Playing $midiPath with ${events.length} events.');

      // 將 ticksPerQuarterNote 傳遞給排程器
      _scheduleMidiEvents(events, ticksPerQuarterNote);
    } catch (e) {
      debugPrint('MidiPlayerService: Error playing midi: $e');
      _playingStateController.add(false);
    }
  }

  // 【升級】接收 ticksPerQuarterNote 參數
  void _scheduleMidiEvents(List<MidiNoteEvent> events, int ticksPerQuarterNote) {
    const double tempo = 120.0; // 預設速度，未來可由 MIDI 檔案動態讀取
    final double msPerTick = 60000.0 / (tempo * ticksPerQuarterNote);

    for (final event in events) {
      final timeToWait = Duration(milliseconds: (event.tick * msPerTick).round());

      final timer = Timer(timeToWait, () {
        if (_playingStateController.isClosed || !_playingStateController.hasListener) return;

        if (event.isNoteOn) {
          _midiPro.playNote(sfId: _soundfontId!, key: event.noteNumber, velocity: event.velocity);
        } else {
          _midiPro.stopNote(sfId: _soundfontId!, key: event.noteNumber);
        }
      });
      _playbackTimers.add(timer);
    }

    if (events.isNotEmpty) {
      final totalDuration = Duration(milliseconds: (events.last.tick * msPerTick).round() + 1000);
      final endTimer = Timer(totalDuration, () => stop());
      _playbackTimers.add(endTimer);
    } else {
      stop();
    }
  }

  Future<void> stop() async {
    // ... (這部分的程式碼與之前完全相同，無需修改) ...
    for (final timer in _playbackTimers) {
      timer.cancel();
    }
    _playbackTimers.clear();

    if (_isInitialized && _soundfontId != null) {
      for (var i = 0; i < 128; i++) {
        _midiPro.stopNote(sfId: _soundfontId!, key: i);
      }
    }

    if (!_playingStateController.isClosed) {
      _playingStateController.add(false);
    }
    debugPrint('MidiPlayerService: Stopped.');
  }

  void dispose() {
    _midiPro.dispose();
    _playingStateController.close();
    debugPrint('MidiPlayerService: Disposed.');
  }
}
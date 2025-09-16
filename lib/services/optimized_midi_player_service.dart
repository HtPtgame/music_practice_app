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
  int _startTime = 0;
  double _msPerTick = 0;
  String? _currentMidiPath;

  bool _isPaused = false;
  int _pauseTime = 0;

  List<TempoChange> _tempoChanges = [];
  int _tempoIndex = 0;
  int _tpq = 480;

  final _playingStateController = StreamController<bool>.broadcast();
  Stream<bool> get playingStateStream => _playingStateController.stream;

  final _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  // 效能優化：批次處理音符
  final List<MidiNoteEvent> _batchedEvents = [];
  static const int _maxBatchSize = 10;
  
  // 效能優化：減少播放頻率
  static const int _playbackIntervalMs = 10; // 從 5ms 改為 10ms

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
    debugPrint('MidiPlayerService: Initializing for piano...');
    
    try {
      // 嘗試直接從 assets 載入 SoundFont
      try {
        debugPrint('MidiPlayerService: Loading SoundFont from assets...');
        _soundfontId = await _midiPro.loadSoundfont(path: 'assets/TimGM6mb.sf2', bank: 0, program: 0);
        
        if (_soundfontId != null) {
          // 選擇鋼琴音色 (Program 0 = Acoustic Grand Piano)
          await _midiPro.selectInstrument(
            sfId: _soundfontId!,
            channel: 0,
            bank: 0,
            program: 0, // 鋼琴
          );
          
          debugPrint('MidiPlayerService: Piano ready with SoundFont ID: $_soundfontId');
          _isInitialized = true;
          return;
        }
      } catch (assetsError) {
        debugPrint('MidiPlayerService: Assets loading failed: $assetsError');
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
        debugPrint('MidiPlayerService: Copying SoundFont...');
        final byteData = await rootBundle.load('assets/TimGM6mb.sf2');
        await file.writeAsBytes(byteData.buffer.asUint8List());
        debugPrint('MidiPlayerService: SoundFont copied (${byteData.lengthInBytes} bytes)');
      }

      final fileSize = await file.length();
      if (fileSize < 1000) {
        throw Exception('SoundFont file too small');
      }

      // 載入 SoundFont
      _soundfontId = await _midiPro.loadSoundfont(path: sfPath, bank: 0, program: 0);
      
      if (_soundfontId != null) {
        // 設定鋼琴音色
        await _midiPro.selectInstrument(
          sfId: _soundfontId!,
          channel: 0,
          bank: 0,
          program: 0, // Acoustic Grand Piano
        );
        
        debugPrint('MidiPlayerService: Piano ready with device SoundFont ID: $_soundfontId');
      } else {
        throw Exception('Failed to load SoundFont');
      }
      
      _isInitialized = true;
    } catch (e, s) {
      debugPrint('MidiPlayerService: Initialization FAILED: $e\n$s');
      _isInitialized = false;
      _soundfontId = null;
      
      // 如果 SoundFont 完全失敗，提供視覺模式
      _isInitialized = true; // 允許視覺播放
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
    _tempoIndex = 0;
    _batchedEvents.clear();

    try {
      final file = File(midiPath);
      final bytes = await file.readAsBytes();

      final parser = MidiParser();
      final events = parser.parse(bytes);
      _tpq = parser.ticksPerQuarterNote;

      // 過濾有效事件，只保留鋼琴相關音符
      final filteredEvents = events.where((e) {
        return e.tick >= 0 && 
               e.tick < 10000000 && 
               e.noteNumber >= 21 &&  // 鋼琴最低音 A0
               e.noteNumber <= 108;   // 鋼琴最高音 C8
      }).toList();

      if (filteredEvents.isEmpty) {
        debugPrint('MidiPlayerService: No valid piano events found.');
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
      
      final modeText = _soundfontId != null ? "piano audio" : "visual";
      debugPrint('MidiPlayerService: Playing $midiPath with ${_events.length} piano events ($modeText mode)');

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
    _playbackLoop = Timer.periodic(const Duration(milliseconds: _playbackIntervalMs), (timer) {
      if (_currentIndex >= _events.length) {
        stop();
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = now - _startTime;

      // 更新 tempo
      while (_tempoIndex + 1 < _tempoChanges.length &&
          _tempoChanges[_tempoIndex + 1].tick <= _events[_currentIndex].tick) {
        _tempoIndex++;
        _msPerTick = _tempoChanges[_tempoIndex].msPerTick(_tpq);
      }

      // 批次收集當前應該播放的事件
      _batchedEvents.clear();
      while (_currentIndex < _events.length && _batchedEvents.length < _maxBatchSize) {
        final event = _events[_currentIndex];
        final eventTime = (event.tick * _msPerTick).round();
        if (eventTime > elapsed) break;

        _batchedEvents.add(event);
        _currentIndex++;
      }

      // 批次處理音符事件（只有當有 SoundFont 時）
      if (_soundfontId != null && _batchedEvents.isNotEmpty) {
        _processBatchedEvents();
      }

      // 更新進度
      if (_events.isNotEmpty) {
        double progress = (_currentIndex / _events.length).clamp(0.0, 1.0);
        _progressController.add(progress);
      }
    });
  }

  void _processBatchedEvents() {
    if (_soundfontId == null) return;
    
    try {
      for (final event in _batchedEvents) {
        if (event.isNoteOn) {
          _midiPro.playNote(
            sfId: _soundfontId!, 
            key: event.noteNumber, 
            velocity: event.velocity
          );
        } else {
          _midiPro.stopNote(sfId: _soundfontId!, key: event.noteNumber);
        }
      }
    } catch (e) {
      // 如果發生錯誤，記錄但不影響播放
      debugPrint('MidiPlayerService: Batch playback error: $e');
    }
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
    _batchedEvents.clear();

    // 停止所有音符
    if (_soundfontId != null) {
      try {
        for (var i = 21; i <= 108; i++) { // 只停止鋼琴音域
          _midiPro.stopNote(sfId: _soundfontId!, key: i);
        }
      } catch (e) {
        debugPrint('MidiPlayerService: Error stopping notes: $e');
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
        debugPrint('MidiPlayerService: Piano note $noteNumber played (velocity: $velocity)');
      } catch (e) {
        debugPrint('MidiPlayerService: Error playing piano note $noteNumber: $e');
      }
    }
  }

  Future<void> stopNote(int noteNumber) async {
    if (_soundfontId != null && noteNumber >= 21 && noteNumber <= 108) {
      try {
        await _midiPro.stopNote(sfId: _soundfontId!, key: noteNumber);
        debugPrint('MidiPlayerService: Piano note $noteNumber stopped');
      } catch (e) {
        debugPrint('MidiPlayerService: Error stopping piano note $noteNumber: $e');
      }
    }
  }

  Future<void> stopAllNotes() async {
    if (_soundfontId != null) {
      try {
        for (var i = 21; i <= 108; i++) { // 鋼琴音域
          await _midiPro.stopNote(sfId: _soundfontId!, key: i);
        }
        debugPrint('MidiPlayerService: All piano notes stopped');
      } catch (e) {
        debugPrint('MidiPlayerService: Error stopping all piano notes: $e');
      }
    }
  }
}

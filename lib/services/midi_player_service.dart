import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:music_practice_app/utils/midi_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:music_practice_app/core/services/settings_service.dart';

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

    try {
      final lastEvent = _events.last;
      final timeMs = _getEventTimeMs(lastEvent.tick);
      
      if (!timeMs.isFinite || timeMs < 0) return 0;
      
      return timeMs.round().clamp(0, 3600000); // 最多 1 小時
    } catch (e) {
      debugPrint('⚠️ Error calculating total duration: $e');
      return 0;
    }
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
      // ⭐ 檢查檔案是否存在
      final file = File(midiPath);
      if (!await file.exists()) {
        throw Exception('MIDI 檔案不存在: $midiPath');
      }

      final fileSize = await file.length();
      debugPrint('\n📋 MIDI 檔案資訊:');
      debugPrint('  • 檔案: ${file.path.split(Platform.pathSeparator).last}');
      debugPrint('  • 大小: $fileSize bytes');

      // ⭐ 檢查檔案大小
      if (fileSize < 14) {
        throw Exception('MIDI 檔案太小，可能已損壞');
      }
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('MIDI 檔案過大 (>10MB)，可能無法處理');
      }

      // ⭐ 讀取檔案
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('MIDI 檔案空白');
      }

      // ⭐ 解析 MIDI
      final parser = MidiParser();
      List<MidiNoteEvent> events;
      
      try {
        events = parser.parse(bytes);
        _tpq = parser.ticksPerQuarterNote;
        
        debugPrint('  • TPQ: $_tpq');
        debugPrint('  • 原始音符數: ${events.length}');
        debugPrint('  • Tempo 事件數: ${parser.tempoEvents.length}');
      } catch (e, stackTrace) {
        debugPrint('❌ MIDI 解析失敗: $e');
        debugPrint('Stack trace: $stackTrace');
        throw Exception('MIDI 檔案解析失敗：$e');
      }

      // ⭐ 驗證解析結果
      if (_tpq <= 0 || _tpq > 10000) {
        throw Exception('異常的 TPQ 值: $_tpq');
      }

      if (events.isEmpty) {
        throw Exception('檔案中沒有找到任何音符');
      }

      // ⭐ 過濾有效事件，只保留鋼琴音域
      final filteredEvents = events.where((e) {
        return e.tick >= 0 &&
            e.tick < 10000000 && // 防止異常大的 tick 值
            e.noteNumber >= 21 && // A0
            e.noteNumber <= 108; // C8
      }).toList();

      debugPrint('  • 過濾後音符數: ${filteredEvents.length}');

      if (filteredEvents.isEmpty) {
        throw Exception('沒有找到有效的鋼琴音符（A0-C8）');
      }

      // ⭐ 移除前導空白時間
      final firstNoteOn = filteredEvents.firstWhere(
        (e) => e.isNoteOn,
        orElse: () => filteredEvents.first,
      );
      final firstNoteTick = firstNoteOn.tick;

      debugPrint('  • 第一個音符 tick: $firstNoteTick');

      // ⭐ 調整所有事件
      _events = filteredEvents.map((event) {
        return MidiNoteEvent(
          tick: (event.tick - firstNoteTick).clamp(0, double.infinity).toInt(),
          noteNumber: event.noteNumber,
          velocity: event.velocity,
          isNoteOn: event.isNoteOn,
        );
      }).toList();

      // ⭐ 調整並過濾 tempo 事件
      final lastEventTick = _events.isNotEmpty ? _events.last.tick : 0;
      
      _tempoChanges = parser.tempoEvents
          .map((tempo) {
            return TempoChange(
              tick: (tempo.tick - firstNoteTick).clamp(0, double.infinity).toInt(),
              microsecondsPerQuarter: tempo.microsecondsPerQuarter,
            );
          })
          .where((tempo) {
            // 只保留在實際音符範圍內的 tempo 事件
            final isValid = tempo.tick <= lastEventTick + (_tpq * 4) &&
                           tempo.microsecondsPerQuarter > 0 &&
                           tempo.microsecondsPerQuarter < 10000000; // 防止異常值
            return isValid;
          })
          .toList();

      // 確保至少有一個 tempo
      if (_tempoChanges.isEmpty) {
        debugPrint('  ⚠️ 沒有有效 tempo，使用預設 120 BPM');
        _tempoChanges.add(TempoChange(
          tick: 0,
          microsecondsPerQuarter: 500000, // 120 BPM
        ));
      }

      debugPrint('  • 有效 tempo 數: ${_tempoChanges.length}');

      // ⭐ 預計算 tempo 段
      _precomputeTempos();

      if (_cachedTempos.isEmpty) {
        throw Exception('Tempo 預計算失敗');
      }

      // ⭐ 驗證總時長
      final durationMs = totalDurationMs;
      final durationSec = durationMs / 1000.0;
      
      debugPrint('  • 總時長: ${durationSec.toStringAsFixed(1)} 秒');

      if (durationMs <= 0) {
        throw Exception('無效的總時長');
      }

      if (durationMs > 3600000) { // > 1 小時
        throw Exception('檔案時長過長 (>${(durationMs/60000).toStringAsFixed(0)} 分鐘)');
      }

      // ⭐ 開始播放
      debugPrint('✅ MIDI 檔案驗證成功，開始播放\n');
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
      debugPrint('❌ MIDI 播放錯誤: $e');
      if (e.toString().contains('RangeError') || 
          e.toString().contains('Index out of range')) {
        debugPrint('⚠️ 檢測到範圍錯誤，可能是 MIDI 檔案損壞或格式不正確');
      }
      
      // 清理狀態
      await stop();
      rethrow;
    }
  }

  /// ⭐ 預計算所有 tempo 段的累積時間
  void _precomputeTempos() {
    _cachedTempos.clear();

    if (_tempoChanges.isEmpty || _events.isEmpty) {
      debugPrint('⚠️ _precomputeTempos: 沒有 tempo 或事件');
      return;
    }

    double cumulativeMs = 0.0;
    final lastEventTick = _events.last.tick;

    for (int i = 0; i < _tempoChanges.length; i++) {
      final tempo = _tempoChanges[i];
      
      // ⭐ 驗證 tempo 值
      if (tempo.microsecondsPerQuarter <= 0 || tempo.microsecondsPerQuarter > 10000000) {
        debugPrint('⚠️ 跳過異常 tempo: ${tempo.microsecondsPerQuarter}');
        continue;
      }
      
      final msPerTick = tempo.msPerTick(_tpq);
      
      // ⭐ 驗證 msPerTick
      if (!msPerTick.isFinite || msPerTick <= 0 || msPerTick > 1000) {
        debugPrint('⚠️ 跳過異常 msPerTick: $msPerTick');
        continue;
      }
      
      // 計算這個 tempo 段的結束 tick
      int endTick;
      if (i + 1 < _tempoChanges.length) {
        // 下一個 tempo 的開始位置
        endTick = _tempoChanges[i + 1].tick;
      } else {
        // 最後一個 tempo 段，使用實際最後一個音符的 tick + 緩衝
        endTick = lastEventTick + (_tpq * 2); // 加 2 拍的緩衝時間
      }
      
      // 確保 endTick 合理
      endTick = endTick.clamp(tempo.tick, lastEventTick + (_tpq * 4));
      
      // ⭐ 驗證 tick 範圍
      if (endTick <= tempo.tick) {
        debugPrint('⚠️ 跳過無效 tick 範圍: ${tempo.tick} to $endTick');
        continue;
      }

      final tickSpan = endTick - tempo.tick;
      final segmentMs = tickSpan * msPerTick;
      
      // ⭐ 驗證段落時間
      if (!segmentMs.isFinite || segmentMs < 0 || segmentMs > 3600000) {
        debugPrint('⚠️ 跳過異常段落時間: $segmentMs ms');
        continue;
      }

      _cachedTempos.add(_CachedTempo(
        startTick: tempo.tick,
        endTick: endTick,
        msPerTick: msPerTick,
        cumulativeMs: cumulativeMs,
      ));

      cumulativeMs += segmentMs;
    }
    
    // ⭐ 檢查是否成功建立快取
    if (_cachedTempos.isEmpty && _tempoChanges.isNotEmpty) {
      debugPrint('⚠️ 所有 tempo 都無效，嘗試使用預設值');
      
      // 使用預設 120 BPM
      final defaultMsPerTick = 500000.0 / 1000.0 / _tpq;
      _cachedTempos.add(_CachedTempo(
        startTick: 0,
        endTick: lastEventTick + (_tpq * 2),
        msPerTick: defaultMsPerTick,
        cumulativeMs: 0.0,
      ));
    }
  }

  /// ⭐ 高效率取得事件時間 (O(1) 查表)
  double _getEventTimeMs(int tick) {
    if (_cachedTempos.isEmpty) return 0.0;
    if (tick < 0) return 0.0;

    // ⭐ 安全檢查：超出範圏的 tick
    final lastTempo = _cachedTempos.last;
    if (tick > lastTempo.endTick) {
      // 使用最後一個 tempo 段的速度推算
      final extraTicks = tick - lastTempo.endTick;
      final extraMs = extraTicks * lastTempo.msPerTick;
      
      if (!extraMs.isFinite || extraMs < 0) {
        return lastTempo.cumulativeMs;
      }
      
      return lastTempo.cumulativeMs + 
             (lastTempo.endTick - lastTempo.startTick) * lastTempo.msPerTick +
             extraMs;
    }

    // 找到包含該 tick 的 tempo 段
    for (final tempo in _cachedTempos) {
      if (tick >= tempo.startTick && tick < tempo.endTick) {
        final deltaMs = (tick - tempo.startTick) * tempo.msPerTick;
        
        if (!deltaMs.isFinite || deltaMs < 0) {
          return tempo.cumulativeMs;
        }
        
        return tempo.cumulativeMs + deltaMs;
      }
    }

    // 如果沒有找到，返回第一個 tempo 的累積時間
    return _cachedTempos.first.cumulativeMs;
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
          await _midiPro.stopNote(sfId: _soundfontId!, key: i);
        }
      } catch (e) {
        // 忽略停止音符的錯誤
        if (kDebugMode) {
          debugPrint('⚠️ Error stopping notes: $e');
        }
      }
    }

    // 安全更新狀態
    try {
      if (!_playingStateController.isClosed) {
        _playingStateController.add(false);
      }
      if (!_progressController.isClosed) {
        _progressController.add(0.0);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error updating state controllers: $e');
      }
    }
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

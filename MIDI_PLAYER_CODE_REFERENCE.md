# MIDI 播放器相關程式碼整合文件

> **生成日期**: 2025-11-20  
> **目的**: 為外部顧問提供 MIDI 播放介面 (UI) 重構所需的完整程式碼參考

---

## 📋 目錄

1. [UI 畫面層 (View)](#1-ui-畫面層-view)
2. [邏輯控制層 (Logic/Controller)](#2-邏輯控制層-logiccontroller)
3. [主題與顏色配置 (Theme/Colors)](#3-主題與顏色配置-themecolors)
4. [套件依賴 (Dependencies)](#4-套件依賴-dependencies)
5. [補充資訊](#5-補充資訊)

---

## 1. UI 畫面層 (View)

### 檔案路徑：`lib/pages/playback_page.dart`

**說明**: 主要的 MIDI 播放器 UI 頁面，包含專輯封面區域、進度條 Slider、播放/暫停/停止/重播按鈕。

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/services/midi_player_service.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:music_practice_app/l10n/app_localizations.dart';

class PlaybackPage extends StatefulWidget {
  final PlatformFile? file;
  const PlaybackPage({super.key, this.file});

  @override
  State<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  final MidiPlayerService _midiService = MidiPlayerService();
  StreamSubscription? _playingStateSubscription;
  StreamSubscription? _progressSubscription;

  bool _isLoading = true;
  bool _isPlaying = false;

  double _currentPosition = 0.0;
  double get _totalDuration => _midiService.totalDurationMs / 1000.0; // 秒

  @override
  void initState() {
    super.initState();
    _initialize();

    _playingStateSubscription =
        _midiService.playingStateStream.listen((isPlaying) {
      if (mounted) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    });

    _progressSubscription = _midiService.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _currentPosition = progress * _totalDuration;
        });
      }
    });
  }

  Future<void> _initialize() async {
    await _midiService.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _playingStateSubscription?.cancel();
    _progressSubscription?.cancel();
    _midiService.stop();
    super.dispose();
  }

  void _togglePlayPause() {
    if (widget.file?.path == null) return;

    if (_isPlaying) {
      _midiService.pause();
    } else {
      if (_currentPosition > 0) {
        _midiService.resume();
      } else {
        _midiService.play(widget.file!.path!);
      }
    }
  }

  void _restart() async {
    if (widget.file?.path == null) return;
    await _midiService.stop();
    await Future.delayed(const Duration(milliseconds: 200));
    _midiService.play(widget.file!.path!);
  }

  void _stop() {
    _midiService.stop();
  }

  String _formatTime(double seconds) {
    final int minutes = (seconds / 60).floor();
    final int remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            l10n?.playbackTitle ?? '播放 MIDI',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/library'),
        ),
        backgroundColor: AppColors.dynamicBackground,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = MediaQuery.of(context).size.height;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: screenWidth * 0.05,
                      right: screenWidth * 0.05,
                      top: screenHeight * 0.02,
                      bottom: MediaQuery.of(context).padding.bottom + 100,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Card(
                          color: AppColors.dynamicCard,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.06),
                            child: Column(
                              children: [
                                // 🎵 專輯封面區域
                                SizedBox(
                                  width: screenWidth * 0.7,
                                  height: screenWidth * 0.7,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.music_note,
                                        size: screenWidth * 0.2,
                                        color: AppColors.dynamicPrimary,
                                      ),
                                      SizedBox(height: screenHeight * 0.02),
                                      Text(
                                        widget.file?.name ?? (l10n?.playbackUnknownFile ?? '未知檔案'),
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.04,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.dynamicTextDark,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (widget.file != null) ...[
                                        SizedBox(height: screenHeight * 0.01),
                                        Text(
                                          '${l10n?.playbackFileSize ?? '檔案大小'}: ${(widget.file!.size / 1024).toStringAsFixed(1)} KB',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.03,
                                            color: AppColors.dynamicTextLight,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                Container(
                                  height: 2,
                                  width: screenWidth * 0.7,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: screenHeight * 0.04),
                                
                                // 🎚️ 進度條 Slider
                                Slider(
                                  value: _currentPosition,
                                  max: _totalDuration,
                                  onChanged: null, // 目前不支援拖曳跳轉
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatTime(_currentPosition),
                                        style: TextStyle(
                                            fontSize: screenWidth * 0.035),
                                      ),
                                      Text(
                                        _formatTime(_totalDuration),
                                        style: TextStyle(
                                            fontSize: screenWidth * 0.035),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.04),
                                
                                // 🎮 控制按鈕區域
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // 重播按鈕
                                    IconButton(
                                      onPressed: _isLoading ? null : _restart,
                                      icon: const Icon(Icons.replay),
                                      iconSize: screenWidth * 0.09,
                                      color: AppColors.dynamicTextDark,
                                      tooltip: l10n?.playbackTooltipReplay ?? '重新播放',
                                    ),
                                    // 播放/暫停按鈕 (主要按鈕，圓形背景)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.dynamicPrimary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _togglePlayPause,
                                        icon: Icon(
                                          _isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                        ),
                                        iconSize: screenWidth * 0.12,
                                        color: Colors.white,
                                        tooltip: _isPlaying 
                                            ? (l10n?.playbackTooltipPause ?? '暫停') 
                                            : (l10n?.playbackTooltipPlay ?? '播放'),
                                      ),
                                    ),
                                    // 停止按鈕
                                    IconButton(
                                      onPressed: _isLoading ? null : _stop,
                                      icon: const Icon(Icons.stop),
                                      iconSize: screenWidth * 0.09,
                                      color: AppColors.dynamicTextDark,
                                      tooltip: l10n?.playbackTooltipStop ?? '停止',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
```

---

### 檔案路徑：`lib/pages/playback_page_simple.dart`

**說明**: 簡化版的 MIDI 播放器頁面 (模擬播放，無實際音訊功能)。可作為參考或備用版本。

```dart
// lib/pages/playback_page_simple.dart
import 'package:flutter/material.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:music_practice_app/l10n/app_localizations.dart';

class PlaybackPage extends StatefulWidget {
  final PlatformFile? file;

  const PlaybackPage({super.key, this.file});

  @override
  State<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  bool _isPlaying = false;
  bool _isPaused = false;
  double _currentPosition = 0.0;
  final double _totalDuration = 180.0; // 模擬3分鐘長度

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.file?.name ?? (l10n?.playbackPageTitle ?? 'MIDI 播放器'),
            style: TextStyle(
              color: AppColors.dynamicTextDark,
            ),
          ),
        ),
        backgroundColor: AppColors.dynamicBackground,
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.dynamicTextDark,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 播放進度條
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.dynamicCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // 進度滑桿
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4.0,
                    ),
                    child: Slider(
                      value: _currentPosition,
                      max: _totalDuration,
                      onChanged: _isPlaying
                          ? (value) {
                              setState(() {
                                _currentPosition = value;
                              });
                            }
                          : null,
                      activeColor: AppColors.dynamicPrimary,
                      inactiveColor:
                          AppColors.dynamicTextLight.withOpacity(0.3),
                    ),
                  ),

                  // 時間顯示
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(_currentPosition),
                          style: TextStyle(
                            color: AppColors.dynamicTextLight,
                          ),
                        ),
                        Text(
                          _formatTime(_totalDuration),
                          style: TextStyle(
                            color: AppColors.dynamicTextLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 控制按鈕
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 重新開始按鈕
                IconButton(
                  onPressed: _restart,
                  icon: Icon(
                    Icons.replay,
                    size: 32,
                    color: AppColors.dynamicTextDark,
                  ),
                ),

                // 播放/暫停按鈕
                IconButton(
                  onPressed: _togglePlayPause,
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 48,
                    color: AppColors.dynamicPrimary,
                  ),
                ),

                // 停止按鈕
                IconButton(
                  onPressed: _stop,
                  icon: Icon(
                    Icons.stop,
                    size: 32,
                    color: AppColors.dynamicTextDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 狀態顯示
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.dynamicCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusText(),
                style: TextStyle(
                  color: AppColors.dynamicTextDark,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _isPlaying = false;
        _isPaused = true;
      } else {
        _isPlaying = true;
        _isPaused = false;
        // 模擬播放進度
        _simulatePlayback();
      }
    });
  }

  void _restart() {
    setState(() {
      _currentPosition = 0.0;
      _isPlaying = true;
      _isPaused = false;
    });
    _simulatePlayback();
  }

  void _stop() {
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _currentPosition = 0.0;
    });
  }

  void _simulatePlayback() {
    if (_isPlaying && !_isPaused) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_isPlaying && !_isPaused && mounted) {
          setState(() {
            _currentPosition += 1.0;
            if (_currentPosition >= _totalDuration) {
              _currentPosition = _totalDuration;
              _isPlaying = false;
            }
          });
          if (_isPlaying) {
            _simulatePlayback();
          }
        }
      });
    }
  }

  String _formatTime(double seconds) {
    final int minutes = (seconds / 60).floor();
    final int remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getStatusText() {
    final l10n = AppLocalizations.of(context);
    if (_isPlaying) {
      return l10n?.playbackPagePlaying ?? '播放中...';
    } else if (_isPaused) {
      return l10n?.playbackPagePaused ?? '已暫停';
    } else if (_currentPosition > 0) {
      return l10n?.playbackPageStopped ?? '已停止';
    } else {
      return '';
    }
  }
}
```

---

## 2. 邏輯控制層 (Logic/Controller)

### 檔案路徑：`lib/services/midi_player_service.dart`

**說明**: MIDI 播放器的核心邏輯服務，負責：
- 載入和初始化 SoundFont (TimGM6mb.sf2)
- 解析 MIDI 檔案 (使用 `flutter_midi_pro`)
- 高精度時間追蹤與播放控制 (play, pause, resume, stop)
- 音量控制整合 (從 `SettingsService` 讀取)
- Stream 狀態廣播 (播放狀態、進度)

```dart
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
```

---

## 3. 主題與顏色配置 (Theme/Colors)

### 檔案路徑：`lib/utils/app_colors.dart`

**說明**: 顏色配置類，提供靜態常數顏色和動態主題顏色。所有 UI 元件使用 `AppColors.dynamicXxx` 來自動適應主題切換。

```dart
// lib/utils/app_colors.dart
import 'package:flutter/material.dart';
import 'theme_manager.dart';

class AppColors {
  // 靜態常數顏色（供 const 使用）
  static const Color primary = Color(0xFFD8AE7E);
  static const Color background = Color(0xFFFFF2D7);
  static const Color card = Color(0xFFFFE0B5);
  static const Color accent = Color(0xFFF8C794);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF888888);

  // 動態主題顏色（主題切換時使用）
  static Color get dynamicPrimary =>
      ThemeManager.instance.currentColors['primary']!;
  static Color get dynamicBackground =>
      ThemeManager.instance.currentColors['background']!;
  static Color get dynamicCard => ThemeManager.instance.currentColors['card']!;
  static Color get dynamicAccent =>
      ThemeManager.instance.currentColors['accent']!;
  static Color get dynamicTextDark =>
      ThemeManager.instance.currentColors['textDark']!;
  static Color get dynamicTextLight =>
      ThemeManager.instance.currentColors['textLight']!;
}
```

---

### 檔案路徑：`lib/utils/theme_manager.dart`

**說明**: 主題管理器，定義 5 個主題配色方案（default, ocean, forest, sunset, lavender），並提供主題切換功能。使用 `ChangeNotifier` 實現響應式更新。

```dart
// lib/utils/theme_manager.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  static ThemeManager? _instance;
  static ThemeManager get instance => _instance ??= ThemeManager._();
  ThemeManager._();

  String _currentTheme = 'default';
  String get currentTheme => _currentTheme;

  // 主題配置
  static const Map<String, Map<String, Color>> themes = {
    'default': {
      'primary': Color(0xFFCFAB8D), // 柔和的淺藍
      'background': Color(0xFFBBDCE5), // 接近白色的淺灰綠
      'card': Color(0xFFF0F8FF), // 淺米色/灰褐色
      'accent': Color(0xFFECEEDF), // 柔和的土色/淺棕色
      'textDark': Color(0xFF333333),
      'textLight': Color(0xFF888888),
    },
    'ocean': {
      'primary': Color(0xFF7FADCC), // 中度藍 (按鈕/主要操作)
      'background': Color(0xFFE6F3FF), // ✨ 極淺藍色 (背景藍調強化)
      'card': Color(0xFFDDE8F4), // ✨ 柔和淺藍 (卡片背景)
      'accent': Color(0xFFF2745E), // 珊瑚橙 (強調/點綴，對比強烈)
      'textDark': Color(0xFF1C3C5B), // 深海藍 (主要文字)
      'textLight': Color(0xFF6A8BAA), // 中度灰藍 (次要文字)
    },
    'forest': {
      'primary': Color(0xFF96A78D), // 沉穩灰綠色 (按鈕/主要操作)
      'background': Color(0xFFF0F0F0), // 極淺中性灰 (背景)
      'card': Color(0xFFD9E9CF), // 極淺薄荷綠 (卡片背景)
      'accent': Color(0xFFB6CEB4), // 柔和淺綠 (強調/點綴)
      'textDark': Color(0xFF2C3E2D), // 深墨綠色 (主要文字/森林陰影感)
      'textLight': Color(0xFF96A78D), // 沉穩灰綠色 (次要文字)
    },
    'sunset': {
      'primary': Color(0xFFF6A85B), // 暖夕橘金
      'background': Color(0xFFFFF7ED), // 柔霧杏白
      'card': Color(0xFFFFE3C3), // 奶杏橙沙
      'accent': Color(0xFFEFA8A4), // 夕陽玫瑰粉
      'textDark': Color(0xFF4A2E05), // 深焦糖棕
      'textLight': Color(0xFFB08A6B), // 淡暖可可
    },
    'lavender': {
      'primary': Color(0xFFE6B7BC), // 柔霧粉
      'background': Color(0xFFFAF7F0), // 霧奶米白
      'card': Color(0xFFFFF8F9), // 微粉暖白
      'accent': Color(0xFFB6D2CD), // 柔薄荷灰
      'textDark': Color(0xFF6A4C52), // 深霧玫棕
      'textLight': Color(0xFFA89A9A), // 灰粉淺棕
    },
  };

  // 初始化主題
  Future<void> initTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('selected_theme');
      if (savedTheme != null && themes.containsKey(savedTheme)) {
        _currentTheme = savedTheme;
      } else {
        _currentTheme = 'default';
      }
    } catch (e) {
      debugPrint('⚠️ ThemeManager: 載入主題設定失敗: $e');
      _currentTheme = 'default';
    }
  }

  // 更改主題
  Future<void> setTheme(String themeName) async {
    if (themes.containsKey(themeName)) {
      _currentTheme = themeName;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_theme', themeName);
        notifyListeners(); // 通知監聽器主題已更改
      } catch (e) {
        debugPrint('⚠️ ThemeManager: 保存主題設定失敗: $e');
      }
    }
  }

  // 獲取當前主題顏色
  Map<String, Color> get currentColors =>
      themes[_currentTheme] ?? themes['default']!;
}
```

---

## 4. 套件依賴 (Dependencies)

### 檔案路徑：`pubspec.yaml`

**說明**: 專案依賴配置，重點關注 MIDI 和音訊相關套件。

```yaml
name: music_practice_app
description: "A new Flutter project."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.4.1 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:  # 多語言支援
    sdk: flutter

  # 核心功能套件 (最終確認版)
  file_picker: ^8.0.0
  flutter_midi_pro: ^3.1.4     # <--- ⭐ MIDI 鋼琴演奏核心套件
  path_provider: ^2.1.5

  # 導覽與 UI 套件
  go_router: ^14.2.0
  flutter_vector_icons: ^2.0.0
  flutter_svg: ^2.0.10
  cupertino_icons: ^1.0.8
  intl: ^0.20.2
  flutter_sound: ^9.28.0
  permission_handler: ^12.0.1
  open_file: ^3.3.2  # 用於開啟檔案/資料夾
  record: ^6.1.1  # 升級修正 linux 平台未實作 startStream 問題
  shared_preferences: ^2.3.2  # 本地儲存套件
  fftea: ^1.5.0+1  # FFT/STFT 頻譜分析 (音訊分析系統核心,支援任意大小輸入)
  image_picker: ^1.1.2  # 圖片選擇器
  syncfusion_flutter_pdfviewer: ^28.1.36  # PDF 檢視器
  
  # Firebase 認證套件
  firebase_core: ^3.8.1  # Firebase 核心
  firebase_auth: ^5.3.3  # Firebase 認證
  cloud_firestore: ^5.5.2  # Firestore 資料庫（儲存使用者資料）
  google_sign_in: ^6.2.2  # Google 登入

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  flutter_lints: ^4.0.0
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon.png"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/icon.png"
  windows:
    generate: true
    image_path: "assets/icon.png"
  macos:
    generate: true
    image_path: "assets/icon.png"
  linux:
    generate: true
    image_path: "assets/icon.png"

flutter:
  uses-material-design: true
  assets:
    - assets/ # 宣告整個 assets 資料夾
    - assets/TimGM6mb.sf2 # ⭐ SoundFont 檔案 (MIDI 音色庫)
```

**重點依賴說明**:
- **`flutter_midi_pro: ^3.1.4`**: MIDI 播放核心套件，支援載入 SoundFont、播放音符、控制音量
- **`assets/TimGM6mb.sf2`**: SoundFont 音色庫檔案 (6MB)，提供鋼琴音色

---

## 5. 補充資訊

### 5.1 UI 組件說明

**播放器 UI 結構** (`playback_page.dart`):
```
Scaffold
└── AppBar (標題: 檔案名稱)
└── Body
    └── Card (主卡片)
        ├── 專輯封面區域 (Icon + 檔名 + 檔案大小)
        ├── 分隔線
        ├── Slider (進度條，目前不可拖曳)
        ├── 時間顯示 (00:00 / 總時長)
        └── 控制按鈕區域
            ├── IconButton (重播)
            ├── IconButton (播放/暫停，圓形背景)
            └── IconButton (停止)
```

### 5.2 顏色變數對照表

| AppColors 變數 | 用途 | 主題來源 |
|---|---|---|
| `dynamicPrimary` | 主要按鈕、強調色 | ThemeManager.currentColors['primary'] |
| `dynamicBackground` | 頁面背景色 | ThemeManager.currentColors['background'] |
| `dynamicCard` | 卡片背景色 | ThemeManager.currentColors['card'] |
| `dynamicAccent` | 強調/點綴色 | ThemeManager.currentColors['accent'] |
| `dynamicTextDark` | 主要文字顏色 | ThemeManager.currentColors['textDark'] |
| `dynamicTextLight` | 次要文字顏色 | ThemeManager.currentColors['textLight'] |

### 5.3 主題切換流程

```dart
// 使用者在設定頁選擇主題
await ThemeManager.instance.setTheme('ocean');

// ThemeManager 內部:
// 1. 更新 _currentTheme = 'ocean'
// 2. 保存到 SharedPreferences
// 3. 呼叫 notifyListeners()

// 所有監聽 ThemeManager 的 Widget 自動重建
// AppColors.dynamicXxx 取得新的顏色值
// UI 即時更新
```

### 5.4 MIDI 播放流程

```dart
// 1. 用戶點擊播放按鈕
_midiService.play('/path/to/file.mid');

// 2. MidiPlayerService 內部:
// - 載入 MIDI 檔案
// - 解析音符事件 (MidiParser)
// - 預計算 Tempo 段
// - 啟動高精度播放循環 (8ms 間隔)

// 3. 播放循環 (_startPlaybackLoop):
// - 每 8ms 檢查一次
// - 播放已排程的音符 (_playScheduledNotes)
// - 預先排程未來 50ms 的音符 (_scheduleUpcomingNotes)
// - 更新進度 (Stream<double>)

// 4. UI 監聽 Stream 更新:
// - playingStateStream: 更新播放/暫停按鈕圖示
// - progressStream: 更新進度條位置
```

### 5.5 關鍵技術點

1. **Look-Ahead Scheduling**: 預先排程 50ms 內的音符，確保播放流暢
2. **Tempo 快取**: 預計算所有 tempo 段的累積時間，避免播放時重複計算
3. **音量整合**: 從 `SettingsService` 讀取音量設定，自動應用到 MIDI 播放
4. **Stream 狀態廣播**: 使用 `StreamController.broadcast()` 通知 UI 更新
5. **響應式主題**: 使用 `ChangeNotifier` + `ThemeManager`，所有 UI 元件自動響應主題變更

---

## 📞 聯絡資訊

如有任何疑問或需要進一步說明，請隨時聯繫專案團隊。

**文件版本**: 1.0  
**最後更新**: 2025-11-20

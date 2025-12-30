import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart' show Level;

/// 共用的節拍器服務，使用 Isolate 確保穩定計時
class MetronomeService {
  static final MetronomeService _instance = MetronomeService._internal();
  factory MetronomeService() => _instance;
  MetronomeService._internal();

  FlutterSoundPlayer? _audioPlayer;
  bool _audioPlayerReady = false;
  Uint8List? _beepBuffer;
  int _activeListeners = 0;
  
  // Isolate 相關
  Isolate? _timerIsolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  StreamSubscription? _subscription;
  
  // 回調
  VoidCallback? _onBeat;
  bool _isRunning = false;
  int _currentBpm = 100;

  Future<void> initialize() async {
    if (_audioPlayer != null && _audioPlayerReady) return;

    try {
      _beepBuffer = _generateBeepSound();
      _audioPlayer = FlutterSoundPlayer();
      _audioPlayer!.setLogLevel(Level.error);
      await _audioPlayer!.openPlayer();
      await _audioPlayer!.setVolume(0.5);
      _audioPlayerReady = true;
      _activeListeners++;
    } catch (e) {
      print('❌ Metronome Service Init Error: $e');
      _audioPlayer = null;
      _audioPlayerReady = false;
    }
  }
  
  /// 開始節拍器 (使用 Isolate 確保穩定)
  Future<void> startMetronome(int bpm, {VoidCallback? onBeat}) async {
    if (_isRunning) {
      stopMetronome();
    }
    
    _currentBpm = bpm;
    _onBeat = onBeat;
    _isRunning = true;
    
    // 建立接收 Port
    _receivePort = ReceivePort();
    
    // 監聽 Isolate 發來的拍子訊號
    _subscription = _receivePort!.listen((message) {
      if (message is String && message == 'beat' && _isRunning) {
        playBeat();
        _onBeat?.call();
      } else if (message is SendPort) {
        _sendPort = message;
        // 發送 BPM 給 Isolate 開始計時
        _sendPort!.send(_currentBpm);
      }
    });
    
    // 啟動 Isolate
    _timerIsolate = await Isolate.spawn(
      _metronomeIsolateEntry,
      _receivePort!.sendPort,
    );
  }
  
  /// 停止節拍器
  void stopMetronome() {
    _isRunning = false;
    _sendPort?.send('stop');
    _subscription?.cancel();
    _subscription = null;
    _receivePort?.close();
    _receivePort = null;
    _timerIsolate?.kill(priority: Isolate.immediate);
    _timerIsolate = null;
    _sendPort = null;
    _onBeat = null;
  }
  
  /// 更新 BPM (不需要重啟)
  void updateBpm(int bpm) {
    _currentBpm = bpm;
    _sendPort?.send(bpm);
  }
  
  /// Isolate 入口點 - 在獨立線程中運行高精度計時
  static void _metronomeIsolateEntry(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);
    
    int bpm = 100;
    bool running = true;
    Stopwatch? stopwatch;
    int lastBeatCount = 0;
    
    receivePort.listen((message) {
      if (message is int) {
        bpm = message;
        // 重置計時
        stopwatch = Stopwatch()..start();
        lastBeatCount = 0;
        // 立即發送第一拍
        mainSendPort.send('beat');
      } else if (message == 'stop') {
        running = false;
        stopwatch?.stop();
        receivePort.close();
      }
    });
    
    // 高精度計時循環
    Timer.periodic(const Duration(microseconds: 500), (timer) {
      if (!running) {
        timer.cancel();
        return;
      }
      
      if (stopwatch != null && stopwatch!.isRunning) {
        final intervalMs = 60000.0 / bpm;
        final elapsedMs = stopwatch!.elapsedMilliseconds;
        final expectedBeats = (elapsedMs / intervalMs).floor();
        
        if (expectedBeats > lastBeatCount) {
          lastBeatCount = expectedBeats;
          mainSendPort.send('beat');
        }
      }
    });
  }

  Future<void> playBeat() async {
    if (!_audioPlayerReady || _beepBuffer == null || _audioPlayer == null) {
      return;
    }

    try {
      // 使用 fire-and-forget 方式播放，避免阻塞
      _audioPlayer!.startPlayer(
        fromDataBuffer: _beepBuffer!,
        codec: Codec.pcm16WAV,
        sampleRate: 44100,
        whenFinished: () {},
      ).catchError((e) => null);
    } catch (e) {
      // 忽略播放錯誤
    }
  }

  void release() {
    stopMetronome();
    _activeListeners--;
    if (_activeListeners <= 0) {
      _activeListeners = 0;
      Future.delayed(const Duration(seconds: 5), () {
        if (_activeListeners == 0) {
          _cleanup();
        }
      });
    }
  }

  void _cleanup() {
    _audioPlayer?.closePlayer().catchError((e) => null);
    _audioPlayer = null;
    _audioPlayerReady = false;
    _beepBuffer = null;
  }

  Uint8List _generateBeepSound() {
    const int sampleRate = 44100;
    const double duration = 0.05;
    final int numSamples = (sampleRate * duration).round();
    const double frequency = 1000.0;
    const double masterGain = 0.5;

    final List<int> samples = [];
    samples.addAll('RIFF'.codeUnits);
    samples.addAll(_int32ToBytes(36 + numSamples * 2));
    samples.addAll('WAVE'.codeUnits);
    samples.addAll('fmt '.codeUnits);
    samples.addAll(_int32ToBytes(16));
    samples.addAll(_int16ToBytes(1));
    samples.addAll(_int16ToBytes(1));
    samples.addAll(_int32ToBytes(sampleRate));
    samples.addAll(_int32ToBytes(sampleRate * 2));
    samples.addAll(_int16ToBytes(2));
    samples.addAll(_int16ToBytes(16));
    samples.addAll('data'.codeUnits);
    samples.addAll(_int32ToBytes(numSamples * 2));

    const int fadeInSamples = 50;
    const int fadeOutSamples = 200;

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double envelope = 1.0;

      if (i < fadeInSamples) {
        envelope = i / fadeInSamples;
      } else if (i > numSamples - fadeOutSamples) {
        envelope = (numSamples - i) / fadeOutSamples;
      }

      final double sample = masterGain * envelope * sin(2 * pi * frequency * t);
      final int sampleInt = (sample * 32767).round().clamp(-32768, 32767);
      samples.addAll(_int16ToBytes(sampleInt));
    }
    return Uint8List.fromList(samples);
  }

  List<int> _int32ToBytes(int value) => [
        value & 0xFF,
        (value >> 8) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 24) & 0xFF
      ];
  List<int> _int16ToBytes(int value) => [value & 0xFF, (value >> 8) & 0xFF];
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:metronome/metronome.dart' as metro;

/// 共用的節拍器服務，使用 metronome 套件實現高精度跨平台節拍
/// 
/// 優點：
/// 1. 原生平台實作，比 Dart Timer 更精確
/// 2. 支援 BPM > 600 的高速節拍
/// 3. 低延遲音訊引擎
/// 4. 支援拍號和強拍
class MetronomeService {
  static final MetronomeService _instance = MetronomeService._internal();
  factory MetronomeService() => _instance;
  MetronomeService._internal();

  final metro.Metronome _metronome = metro.Metronome();
  bool _isInitialized = false;
  int _activeListeners = 0;
  
  // 回調
  void Function()? _onBeat;
  StreamSubscription<int>? _tickSubscription;
  bool _isRunning = false;
  int _currentBpm = 100;

  /// 初始化節拍器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 使用 assets 中的節拍器音效（慢練只用普通拍聲音）
      _metronome.init(
        'assets/audio/Perc_MetronomeQuartz_lo.wav',
        accentedPath: 'assets/audio/Perc_MetronomeQuartz_lo.wav',
        bpm: 100,
        volume: 70,
        enableTickCallback: true,
        timeSignature: 4,
        sampleRate: 44100,
      );
      
      _isInitialized = true;
      _activeListeners++;
    } catch (e) {
      debugPrint('❌ Metronome Service Init Error: $e');
      _isInitialized = false;
    }
  }
  
  /// 開始節拍器
  Future<void> startMetronome(int bpm, {void Function()? onBeat}) async {
    if (_isRunning) {
      stopMetronome();
    }
    
    if (!_isInitialized) {
      await initialize();
    }
    
    _currentBpm = bpm;
    _onBeat = onBeat;
    _isRunning = true;
    
    // 設定 BPM
    _metronome.setBPM(bpm);
    
    // 監聽節拍回調
    if (onBeat != null) {
      _tickSubscription = _metronome.tickStream.listen((int tick) {
        _onBeat?.call();
      });
    }
    
    // 開始播放
    _metronome.play();
  }
  
  /// 停止節拍器
  void stopMetronome() {
    _isRunning = false;
    _metronome.stop();
    _tickSubscription?.cancel();
    _tickSubscription = null;
    _onBeat = null;
  }
  
  /// 暫停節拍器
  void pauseMetronome() {
    _metronome.pause();
    _isRunning = false;
  }
  
  /// 更新 BPM (不需要重啟)
  void updateBpm(int bpm) {
    _currentBpm = bpm;
    _metronome.setBPM(bpm);
  }
  
  /// 設定音量 (0-100)
  void setVolume(int volume) {
    _metronome.setVolume(volume.clamp(0, 100));
  }
  
  /// 取得目前音量
  Future<int> getVolume() async {
    return await _metronome.getVolume();
  }
  
  /// 設定拍號
  void setTimeSignature(int beats) {
    _metronome.setTimeSignature(beats);
  }
  
  /// 是否正在播放
  Future<bool> getIsPlaying() async {
    return await _metronome.isPlaying() ?? false;
  }
  
  /// 同步取得播放狀態（使用內部追蹤）
  bool get isPlaying => _isRunning;
  
  /// 是否已初始化
  bool get isInitialized => _isInitialized;
  
  /// 取得目前 BPM
  int get currentBpm => _currentBpm;

  /// 播放一次節拍音效（向後相容）
  Future<void> playBeat() async {
    // metronome 套件沒有單次播放功能
    // 保留空實作以維持 API 相容性
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
    _metronome.destroy();
    _isInitialized = false;
  }
}

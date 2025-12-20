import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart' show Level;

/// 音訊播放控制器
/// 
/// Phase 3 重構: 從 PracticePage 提取的播放邏輯
/// 負責所有音訊播放相關操作，包括播放、暫停、停止等
/// 
/// 繼承 ChangeNotifier 以支援 Provider 狀態管理
class AudioPlaybackController extends ChangeNotifier {
  // ===== 播放器實例 =====
  FlutterSoundPlayer? _player;
  
  // ===== 狀態 =====
  bool _isPlaying = false;
  bool _isPaused = false;
  double _playbackPosition = 0.0;
  double _playbackDuration = 0.0;
  
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  double get playbackPosition => _playbackPosition;
  double get playbackDuration => _playbackDuration;
  
  Timer? _playbackTimer;
  
  // ===== 回調 =====
  void Function(double position, double duration)? onProgressUpdate;
  void Function()? onPlaybackComplete;
  void Function(String message)? onError;
  
  AudioPlaybackController({
    this.onProgressUpdate,
    this.onPlaybackComplete,
    this.onError,
  });
  
  /// 初始化播放器
  Future<void> initialize() async {
    try {
      _player = FlutterSoundPlayer();
      _player!.setLogLevel(Level.error);
      await _player!.openPlayer();
      debugPrint('✅ AudioPlaybackController 初始化完成');
    } catch (e) {
      debugPrint('❌ AudioPlaybackController 初始化失敗: $e');
      onError?.call('播放器初始化失敗: $e');
    }
  }
  
  /// 跳轉到指定位置
  Future<void> seek(double position) async {
    if (_player == null) return;
    
    try {
      await _player!.seekToPlayer(Duration(milliseconds: (position * 1000).toInt()));
      _playbackPosition = position;
      notifyListeners();
      onProgressUpdate?.call(_playbackPosition, _playbackDuration);
    } catch (e) {
      debugPrint('❌ 跳轉失敗: $e');
    }
  }
  
  /// 播放音訊
  Future<bool> play(String audioPath) async {
    if (_player == null) {
      onError?.call('播放器未初始化');
      return false;
    }
    
    // 檢查檔案
    final file = File(audioPath);
    if (!await file.exists()) {
      onError?.call('音訊檔案不存在');
      return false;
    }
    
    final size = await file.length();
    if (size == 0) {
      onError?.call('音訊檔案為空');
      return false;
    }
    
    debugPrint('▶️ 準備播放: $audioPath (大小: $size bytes)');
    
    try {
      // 決定播放編碼
      Codec playbackCodec = Codec.pcm16WAV;
      if (audioPath.endsWith('.aac')) {
        playbackCodec = Codec.aacADTS;
      }
      
      _isPlaying = true;
      _isPaused = false;
      _playbackPosition = 0.0;
      notifyListeners();
      
      await _player!.startPlayer(
        fromURI: audioPath,
        codec: playbackCodec,
        whenFinished: () {
          _stopTimer();
          _isPlaying = false;
          _isPaused = false;
          _playbackPosition = 0.0;
          notifyListeners();
          onPlaybackComplete?.call();
          debugPrint('⏹️ 播放完成');
        },
      );
      
      // 啟動進度計時器
      _startTimer();
      
      debugPrint('✅ 開始播放');
      return true;
    } catch (e) {
      debugPrint('❌ 播放失敗: $e');
      _isPlaying = false;
      _isPaused = false;
      notifyListeners();
      onError?.call('播放失敗: $e');
      return false;
    }
  }
  
  /// 暫停播放
  Future<void> pause() async {
    if (_player == null || !_isPlaying || _isPaused) return;
    
    try {
      await _player!.pausePlayer();
      _stopTimer();
      _isPaused = true;
      notifyListeners();
      debugPrint('⏸️ 播放已暫停');
    } catch (e) {
      debugPrint('❌ 暫停失敗: $e');
      onError?.call('暫停失敗: $e');
    }
  }
  
  /// 繼續播放
  Future<void> resume() async {
    if (_player == null || !_isPlaying || !_isPaused) return;
    
    try {
      await _player!.resumePlayer();
      _startTimer();
      _isPaused = false;
      notifyListeners();
      debugPrint('▶️ 繼續播放');
    } catch (e) {
      debugPrint('❌ 繼續播放失敗: $e');
      onError?.call('繼續播放失敗: $e');
    }
  }
  
  /// 停止播放
  Future<void> stop() async {
    if (_player == null) return;
    
    try {
      _stopTimer();
      await _player!.stopPlayer();
      _isPlaying = false;
      _isPaused = false;
      _playbackPosition = 0.0;
      notifyListeners();
      debugPrint('⏹️ 播放已停止');
    } catch (e) {
      debugPrint('❌ 停止播放失敗: $e');
      onError?.call('停止播放失敗: $e');
    }
  }
  
  /// 啟動進度計時器
  void _startTimer() {
    _stopTimer();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isPlaying || _player == null || _isPaused) {
        return;
      }
      
      try {
        final progressMap = await _player!.getProgress();
        final progress = progressMap['progress'];
        final duration = progressMap['duration'];
        
        if (progress != null && duration != null) {
          _playbackPosition = progress.inMilliseconds / 1000.0;
          _playbackDuration = duration.inMilliseconds / 1000.0;
          notifyListeners();
          onProgressUpdate?.call(_playbackPosition, _playbackDuration);
        }
      } catch (e) {
        // 忽略進度獲取錯誤
      }
    });
  }
  
  /// 停止計時器
  void _stopTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
  }
  
  /// 重置狀態
  void reset() {
    _stopTimer();
    _isPlaying = false;
    _isPaused = false;
    _playbackPosition = 0.0;
    _playbackDuration = 0.0;
    notifyListeners();
  }
  
  /// 清理資源
  @override
  Future<void> dispose() async {
    _stopTimer();
    
    if (_isPlaying) {
      await stop();
    }
    
    await _player?.closePlayer();
    _player = null;
    
    debugPrint('🧹 AudioPlaybackController 已清理');
    super.dispose();
  }
  
  // ===== 便捷方法 =====
  
  /// 格式化時間
  String formatTime(double seconds) {
    final min = seconds ~/ 60;
    final sec = (seconds % 60).toInt();
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
  
  /// 格式化播放進度
  String get formattedProgress {
    return '${formatTime(_playbackPosition)} / ${formatTime(_playbackDuration)}';
  }
  
  /// 播放進度百分比
  double get progressPercent {
    if (_playbackDuration <= 0) return 0.0;
    return (_playbackPosition / _playbackDuration).clamp(0.0, 1.0);
  }
}

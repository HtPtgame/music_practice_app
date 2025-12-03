import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 音效服務 - 用於播放簡短的 UI 音效
class SoundEffectService {
  static final SoundEffectService _instance = SoundEffectService._internal();
  factory SoundEffectService() => _instance;
  SoundEffectService._internal();

  AudioPlayer? _player;
  bool _isInitialized = false;

  /// 初始化音效播放器
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      _player = AudioPlayer();
      // 設置為低延遲模式
      await _player!.setPlayerMode(PlayerMode.lowLatency);
      // 預載音效
      await _player!.setSource(AssetSource('unlock.mp3'));
      _isInitialized = true;
      debugPrint('✅ SoundEffectService 初始化成功');
    } catch (e) {
      debugPrint('❌ SoundEffectService 初始化失敗: $e');
    }
  }

  /// 播放解鎖音效（清脆的叮聲）
  Future<void> playUnlockSound() async {
    if (!_isInitialized) await init();
    
    try {
      await _player?.setVolume(0.8);
      await _player?.stop(); // 停止之前的播放
      await _player?.play(AssetSource('unlock.mp3'));
      debugPrint('🔔 播放解鎖音效');
    } catch (e) {
      debugPrint('❌ 播放音效失敗: $e');
    }
  }

  /// 播放獲得新動物音效（用於恭喜畫面）
  Future<void> playNewAnimalSound() async {
    if (!_isInitialized) await init();
    
    try {
      await _player?.setVolume(0.8);
      await _player?.stop(); // 停止之前的播放
      await _player?.play(AssetSource('new_animal.mp3'));
      debugPrint('🎉 播放獲得新動物音效');
    } catch (e) {
      debugPrint('❌ 播放音效失敗: $e');
    }
  }

  /// 釋放資源
  void dispose() {
    _player?.dispose();
    _player = null;
    _isInitialized = false;
  }
}

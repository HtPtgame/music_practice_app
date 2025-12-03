import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart' show Level;

/// 共用的節拍器服務，避免重複創建音訊播放器
class MetronomeService {
  static final MetronomeService _instance = MetronomeService._internal();
  factory MetronomeService() => _instance;
  MetronomeService._internal();

  FlutterSoundPlayer? _audioPlayer;
  bool _audioPlayerReady = false;
  Uint8List? _beepBuffer;
  int _activeListeners = 0;

  Future<void> initialize() async {
    if (_audioPlayer != null && _audioPlayerReady) return;

    try {
      _beepBuffer = _generateBeepSound();
      _audioPlayer = FlutterSoundPlayer();
      _audioPlayer!.setLogLevel(Level.error);
      await _audioPlayer!.openPlayer();
      await _audioPlayer!.setVolume(0.4);
      _audioPlayerReady = true;
      _activeListeners++;
    } catch (e) {
      print('❌ Metronome Service Init Error: $e');
      _audioPlayer = null;
      _audioPlayerReady = false;
    }
  }

  Future<void> playBeat() async {
    if (!_audioPlayerReady || _beepBuffer == null || _audioPlayer == null) {
      return;
    }

    try {
      // 不需要等待完成，讓音訊重疊播放
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
    _activeListeners--;
    if (_activeListeners <= 0) {
      _activeListeners = 0;
      // 延遲清理，避免頻繁創建/銷毀
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

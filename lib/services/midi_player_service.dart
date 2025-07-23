// lib/services/midi_player_service.dart
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:flutter/foundation.dart';

class MidiPlayerService {
  static MidiPlayerService? _instance;
  static MidiPlayerService get instance => _instance ??= MidiPlayerService._();
  
  MidiPlayerService._();
  
  MidiPro? _midiPro;
  int? _soundfontId;
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _midiPro = MidiPro();
      
      // 使用正確的方法載入音色庫
      _soundfontId = await _midiPro!.loadSoundfont(
        path: 'assets/TimGM6mb.sf2',
        bank: 0,
        program: 0,
      );
      
      // 選擇鋼琴音色
      await _midiPro!.selectInstrument(
        sfId: _soundfontId!,
        channel: 0,
        bank: 0,
        program: 0,
      );
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('MIDI播放器初始化失敗: $e');
      rethrow;
    }
  }
  
  Future<void> playNote(int note, {int velocity = 100, int channel = 0}) async {
    if (!_isInitialized || _midiPro == null || _soundfontId == null) {
      await initialize();
    }
    
    try {
      await _midiPro!.playNote(
        channel: channel,
        key: note,
        velocity: velocity,
        sfId: _soundfontId!,
      );
    } catch (e) {
      debugPrint('播放音符失敗: $e');
    }
  }
  
  Future<void> stopNote(int note, {int channel = 0}) async {
    if (!_isInitialized || _midiPro == null || _soundfontId == null) return;
    
    try {
      await _midiPro!.stopNote(
        channel: channel,
        key: note,
        sfId: _soundfontId!,
      );
    } catch (e) {
      debugPrint('停止音符失敗: $e');
    }
  }
  
  Future<void> stopAllNotes() async {
    if (!_isInitialized || _midiPro == null || _soundfontId == null) return;
    
    try {
      // 停止所有音符 - 可能需要逐一停止
      for (int note = 0; note < 128; note++) {
        await _midiPro!.stopNote(
          channel: 0,
          key: note,
          sfId: _soundfontId!,
        );
      }
    } catch (e) {
      debugPrint('停止所有音符失敗: $e');
    }
  }
  
  void dispose() {
    if (_midiPro != null) {
      _midiPro!.dispose();
    }
    _isInitialized = false;
  }
}

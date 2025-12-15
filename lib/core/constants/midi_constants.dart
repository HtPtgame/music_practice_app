/// MIDI 相關常數
///
/// 集中管理所有 MIDI 處理相關的魔術數字
class MidiConstants {
  // 私有建構子，防止實例化
  MidiConstants._();

  // ==================== MIDI 音符範圍 ====================
  
  /// 鋼琴最低音符 (A0)
  static const int minPianoNote = 21;
  
  /// 鋼琴最高音符 (C8)
  static const int maxPianoNote = 108;
  
  /// MIDI 最低音符值
  static const int minMidiNote = 0;
  
  /// MIDI 最高音符值
  static const int maxMidiNote = 127;

  // ==================== MIDI 速度 ====================
  
  /// 預設速度倍率
  static const double defaultTempo = 1.0;
  
  /// 最小速度倍率
  static const double minTempo = 0.25;
  
  /// 最大速度倍率
  static const double maxTempo = 2.0;
  
  /// 預設 Ticks Per Quarter Note
  static const int defaultTPQ = 480;

  // ==================== MIDI 音量 ====================
  
  /// 預設音量 (0-127)
  static const int defaultVelocity = 64;
  
  /// 最小音量
  static const int minVelocity = 0;
  
  /// 最大音量
  static const int maxVelocity = 127;

  // ==================== MIDI 通道 ====================
  
  /// 預設 MIDI 通道
  static const int defaultChannel = 0;
  
  /// MIDI 通道數量
  static const int totalChannels = 16;
}

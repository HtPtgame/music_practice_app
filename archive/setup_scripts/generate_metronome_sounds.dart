// 用於生成節拍器音效的腳本
// 執行方式: dart run generate_metronome_sounds.dart

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() async {
  // 生成主拍音效 (較低頻率)
  final clickSound = generateClickSound(
    frequency: 1000.0,
    duration: 0.03,
    gain: 0.7,
  );
  await File('assets/audio/metronome_click.wav').writeAsBytes(clickSound);
  print('✅ 已生成 metronome_click.wav');

  // 生成強拍音效 (較高頻率)
  final accentSound = generateClickSound(
    frequency: 1500.0,
    duration: 0.04,
    gain: 0.9,
  );
  await File('assets/audio/metronome_accent.wav').writeAsBytes(accentSound);
  print('✅ 已生成 metronome_accent.wav');

  print('\n🎵 節拍器音效生成完成！');
}

Uint8List generateClickSound({
  required double frequency,
  required double duration,
  required double gain,
  int sampleRate = 44100,
}) {
  final int numSamples = (sampleRate * duration).round();
  
  final List<int> bytes = [];
  
  // WAV Header
  bytes.addAll('RIFF'.codeUnits);
  bytes.addAll(_int32ToBytes(36 + numSamples * 2));
  bytes.addAll('WAVE'.codeUnits);
  bytes.addAll('fmt '.codeUnits);
  bytes.addAll(_int32ToBytes(16)); // Subchunk1Size
  bytes.addAll(_int16ToBytes(1));  // AudioFormat (PCM)
  bytes.addAll(_int16ToBytes(1));  // NumChannels (Mono)
  bytes.addAll(_int32ToBytes(sampleRate));
  bytes.addAll(_int32ToBytes(sampleRate * 2)); // ByteRate
  bytes.addAll(_int16ToBytes(2));  // BlockAlign
  bytes.addAll(_int16ToBytes(16)); // BitsPerSample
  bytes.addAll('data'.codeUnits);
  bytes.addAll(_int32ToBytes(numSamples * 2));

  // 生成音頻數據
  final int fadeInSamples = (numSamples * 0.05).round();
  final int fadeOutSamples = (numSamples * 0.5).round();

  for (int i = 0; i < numSamples; i++) {
    final double t = i / sampleRate;
    double envelope = 1.0;

    // 淡入
    if (i < fadeInSamples) {
      envelope = i / fadeInSamples;
    }
    // 淡出
    else if (i > numSamples - fadeOutSamples) {
      envelope = (numSamples - i) / fadeOutSamples;
    }

    // 使用正弦波
    final double sample = gain * envelope * sin(2 * pi * frequency * t);
    final int sampleInt = (sample * 32767).round().clamp(-32768, 32767);
    bytes.addAll(_int16ToBytes(sampleInt));
  }

  return Uint8List.fromList(bytes);
}

List<int> _int32ToBytes(int value) => [
  value & 0xFF,
  (value >> 8) & 0xFF,
  (value >> 16) & 0xFF,
  (value >> 24) & 0xFF,
];

List<int> _int16ToBytes(int value) => [
  value & 0xFF,
  (value >> 8) & 0xFF,
];

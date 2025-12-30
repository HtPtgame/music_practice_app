/// 檢測到的音符模型
class DetectedNote {
  final int midiNote;
  final double time;
  final double confidence;
  
  // ML 特徵
  final double peakEnergy;
  final double harmonicRatio;
  final double onsetStrength;
  final double spectralFlatness;
  final int durationFrames;

  DetectedNote({
    required this.midiNote,
    required this.time,
    required this.confidence,
    this.peakEnergy = 0.0,
    this.harmonicRatio = 0.0,
    this.onsetStrength = 0.0,
    this.spectralFlatness = 0.0,
    this.durationFrames = 0,
  });

  @override
  String toString() => 'Detected(MIDI: $midiNote, Time: ${time.toStringAsFixed(2)}s)';
}
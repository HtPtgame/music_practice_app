/// 時間軸分析服務 (2025/11/29)
///
/// 智能分析功能:
/// 1. 延遲開始: 用戶可能錄製前等待數秒
/// 2. 中途停頓 (中斷): 演奏時出現靜音片段
/// 3. 結尾靜音 (錄製結束後的靜音)
/// 4. 時長異常 (錄音時長與MIDI不符)
/// 注意: 跳過段落偵測已移除（判定準確度不足）
library;

import 'dart:math';
import 'models/spectrogram.dart';
import 'models/note_event.dart';

/// 時間軸分析結果
class TimelineAnalysisResult {
  /// 音樂實際開始時間 (秒)
  final double musicStartTime;

  /// 音樂實際結束時間 (秒)
  final double musicEndTime;

  /// 實際音樂時長 (秒)
  double get actualMusicDuration => musicEndTime - musicStartTime;

  /// MIDI 預期時長 (秒)
  final double expectedDuration;

  /// 時長比例 (實際/預期)
  double get durationRatio => actualMusicDuration / expectedDuration;

  /// 時長差異 (秒)
  double get durationDiff => (actualMusicDuration - expectedDuration).abs();

  /// 開場靜音時長 (秒)
  final double startDelay;

  /// 結尾靜音時長 (秒)
  final double endSilence;

  /// 音樂中的靜音片段 (中斷或未演奏的段落)
  /// 格式: [(開始時間, 結束時間), ...]
  final List<SilentSegment> silentSegments;

  /// 音樂中的演奏段落
  /// 格式: [(開始時間, 結束時間), ...]
  final List<MusicSegment> musicSegments;

  /// 是否有音樂中斷 (中途靜音)
  bool get hasInterruptions => silentSegments.any((s) => s.duration > 2.0);

  /// 時長狀態
  DurationStatus get durationStatus {
    if (durationRatio < 0.85) return DurationStatus.tooShort;
    if (durationRatio > 1.15) return DurationStatus.tooLong;
    if (durationRatio < 0.95 || durationRatio > 1.05) {
      return DurationStatus.slightDifference;
    }
    return DurationStatus.normal;
  }

  /// 總體分析狀態
  AnalysisStatus get overallStatus {
    if (hasInterruptions) return AnalysisStatus.interrupted;
    if (startDelay > 5.0) return AnalysisStatus.lateStart;
    if (durationStatus == DurationStatus.tooShort) {
      return AnalysisStatus.incomplete;
    }
    if (durationStatus == DurationStatus.tooLong) {
      return AnalysisStatus.tooLong;
    }
    return AnalysisStatus.normal;
  }

  TimelineAnalysisResult({
    required this.musicStartTime,
    required this.musicEndTime,
    required this.expectedDuration,
    required this.startDelay,
    required this.endSilence,
    required this.silentSegments,
    required this.musicSegments,
  });

  /// 生成分析報告
  String generateReport() {
    final sb = StringBuffer();
    sb.writeln('═══ 時間軸分析報告 ═══\n');

    // 時長資訊
    sb.writeln('📊 時長資訊:');
    sb.writeln('  預期時長: ${expectedDuration.toStringAsFixed(1)}秒');
    sb.writeln('  實際時長: ${actualMusicDuration.toStringAsFixed(1)}秒');
    sb.writeln('  時長比例: ${(durationRatio * 100).toStringAsFixed(1)}%');
    sb.writeln('  時長差異: ${durationDiff >= 0 ? '+' : ''}${durationDiff.toStringAsFixed(1)}秒');
    sb.writeln();

    // 靜音資訊
    if (startDelay > 0.5 || endSilence > 0.5) {
      sb.writeln('🔇 靜音資訊:');
      if (startDelay > 0.5) {
        sb.writeln('  開場靜音: ${startDelay.toStringAsFixed(1)}秒');
      }
      if (endSilence > 0.5) {
        sb.writeln('  結尾靜音: ${endSilence.toStringAsFixed(1)}秒');
      }
      sb.writeln();
    }

    // 段落資訊
    if (musicSegments.length > 1) {
      sb.writeln('🎵 演奏段落: ${musicSegments.length}段');
      for (int i = 0; i < musicSegments.length; i++) {
        final seg = musicSegments[i];
        sb.writeln('  段落${i + 1}: ${seg.startTime.toStringAsFixed(1)}s - '
            '${seg.endTime.toStringAsFixed(1)}s '
            '(時長: ${seg.duration.toStringAsFixed(1)}s)');
      }
      sb.writeln();
    }

    // 中斷資訊
    if (hasInterruptions) {
      sb.writeln('⚠️ 音樂中有 ${silentSegments.where((s) => s.duration > 2.0).length} 處中斷:');
      for (final seg in silentSegments.where((s) => s.duration > 2.0)) {
        sb.writeln('  ${seg.startTime.toStringAsFixed(1)}s - '
            '${seg.endTime.toStringAsFixed(1)}s '
            '(持續 ${seg.duration.toStringAsFixed(1)}秒)');
      }
      sb.writeln();
    }

    // 總體狀態
    sb.writeln('📋 總體狀態: ${_getStatusDescription(overallStatus)}');

    return sb.toString();
  }

  String _getStatusDescription(AnalysisStatus status) {
    switch (status) {
      case AnalysisStatus.normal:
        return '✅ 正常完整';
      case AnalysisStatus.lateStart:
        return '⏰ 開場延遲較長';
      case AnalysisStatus.incomplete:
        return '⚠️ 演奏不完整';
      case AnalysisStatus.interrupted:
        return '🔴 演奏有中斷';
      case AnalysisStatus.tooLong:
        return '🔶 時長過長';
    }
  }
}

/// 靜音段落資訊
class SilentSegment {
  final double startTime;
  final double endTime;
  double get duration => endTime - startTime;

  SilentSegment(this.startTime, this.endTime);

  @override
  String toString() =>
      'SilentSegment(${startTime.toStringAsFixed(1)}s - ${endTime.toStringAsFixed(1)}s, ${duration.toStringAsFixed(1)}s)';
}

/// 音樂段落資訊
class MusicSegment {
  final double startTime;
  final double endTime;
  double get duration => endTime - startTime;

  MusicSegment(this.startTime, this.endTime);

  @override
  String toString() =>
      'MusicSegment(${startTime.toStringAsFixed(1)}s - ${endTime.toStringAsFixed(1)}s, ${duration.toStringAsFixed(1)}s)';
}

/// 時長狀態
enum DurationStatus {
  normal, // 正常範圍 (95%-105%)
  slightDifference, // 輕微差異 (85%-95% 或 105%-115%)
  tooShort, // 過短 (<85%)
  tooLong, // 過長 (>115%)
}

/// 分析狀態
enum AnalysisStatus {
  normal, // 正常
  lateStart, // 延遲開始
  incomplete, // 不完整
  interrupted, // 中斷
  tooLong, // 過長
}

/// 時間軸分析服務
class TimelineAnalysisService {
  /// 能量閾值倍數 (相對於噪音底板)
  static const double energyThresholdMultiplier = 3.0;

  /// 最小連續音樂幀數
  static const int minContinuousMusicFrames = 5;

  /// 最小連續靜音幀數 (用於檢測中斷)
  static const int minContinuousSilentFrames = 10;

  /// 中斷閾值時長 (秒) - 超過此時長視為中斷
  static const double interruptionThreshold = 2.0;

  /// 開場延遲警告閾值 (秒) - 超過此時長顯示警告
  static const double startDelayWarningThreshold = 5.0;

  /// 時長容差
  static const double durationToleranceNormal = 0.05; // ±5%
  static const double durationToleranceSlight = 0.15; // ±15%

  /// 執行時間軸分析
  Future<TimelineAnalysisResult> analyze({
    required Spectrogram spectrogram,
    required MidiTimeline midiTimeline,
  }) async {
    print('\n🔍 開始執行時間軸分析...');

    // 1. 估算噪音底板
    final noiseFloor = _estimateNoiseFloor(spectrogram);
    final threshold = noiseFloor * energyThresholdMultiplier;
    print('📊 噪音底板: ${noiseFloor.toStringAsFixed(6)}');
    print('📊 音樂閾值: ${threshold.toStringAsFixed(6)}');

    // 2. 檢測音樂段落與靜音段落
    final segments = _detectAllSegments(spectrogram, threshold);
    print('🎵 檢測到 ${segments['music']!.length} 個音樂段落');
    print('🔇 檢測到 ${segments['silent']!.length} 個靜音段落');

    // 3. 計算總體音樂起始和結束
    final musicSegments = segments['music']! as List<MusicSegment>;
    final silentSegments = segments['silent']! as List<SilentSegment>;

    if (musicSegments.isEmpty) {
      throw Exception('無法在音訊中偵測到音樂段落，請檢查錄音品質');
    }

    final musicStartTime = musicSegments.first.startTime;
    final musicEndTime = musicSegments.last.endTime;
    final totalDuration = spectrogram.timeFrames * spectrogram.timeResolution;

    print('🎹 音樂起始: ${musicStartTime.toStringAsFixed(2)}s');
    print('🎹 音樂結束: ${musicEndTime.toStringAsFixed(2)}s');
    print('📏 總時長: ${totalDuration.toStringAsFixed(2)}s');

    // 4. 計算靜音時長
    final startDelay = musicStartTime;
    final endSilence = totalDuration - musicEndTime;

    // 5. 生成結果
    final result = TimelineAnalysisResult(
      musicStartTime: musicStartTime,
      musicEndTime: musicEndTime,
      expectedDuration: midiTimeline.duration,
      startDelay: startDelay,
      endSilence: endSilence,
      silentSegments: silentSegments,
      musicSegments: musicSegments,
    );

    print('\n${result.generateReport()}');
    print('✅ 時間軸分析完成\n');

    return result;
  }

  /// 估算噪音底板
  double _estimateNoiseFloor(Spectrogram spectrogram) {
    const windowSize = 0.5; // 使用前 0.5 秒估算
    final windowFrames = (windowSize / spectrogram.timeResolution).round();
    final maxFrames = min(windowFrames, spectrogram.timeFrames);

    final energies = <double>[];
    for (int frame = 0; frame < maxFrames; frame++) {
      energies.add(_calculateFrameEnergy(spectrogram, frame));
    }

    energies.sort();
    return energies[energies.length ~/ 2]; // 中位數
  }

  /// 計算幀能量
  double _calculateFrameEnergy(Spectrogram spectrogram, int frame) {
    if (frame < 0 || frame >= spectrogram.timeFrames) return 0.0;

    double totalEnergy = 0.0;
    for (int bin = 0; bin < spectrogram.freqBins; bin++) {
      final magnitude = spectrogram.data[frame][bin];
      totalEnergy += magnitude * magnitude;
    }

    return sqrt(totalEnergy / spectrogram.freqBins);
  }

  /// 檢測音樂段落與靜音段落
  Map<String, List<dynamic>> _detectAllSegments(
    Spectrogram spectrogram,
    double threshold,
  ) {
    final musicSegments = <MusicSegment>[];
    final silentSegments = <SilentSegment>[];

    bool inMusic = false;
    int musicStartFrame = 0;
    int consecutiveMusicFrames = 0;
    int consecutiveSilentFrames = 0;
    int silentStartFrame = 0;

    for (int frame = 0; frame < spectrogram.timeFrames; frame++) {
      final energy = _calculateFrameEnergy(spectrogram, frame);
      final isMusic = energy > threshold;

      if (isMusic) {
        consecutiveMusicFrames++;
        consecutiveSilentFrames = 0;

        // 確認進入音樂段落
        if (!inMusic && consecutiveMusicFrames >= minContinuousMusicFrames) {
          // 結束之前的靜音段落
          if (silentStartFrame > 0) {
            final silentStart = silentStartFrame * spectrogram.timeResolution;
            final silentEnd = (frame - minContinuousMusicFrames) *
                spectrogram.timeResolution;
            if (silentEnd > silentStart) {
              silentSegments.add(SilentSegment(silentStart, silentEnd));
            }
          }

          musicStartFrame = frame - minContinuousMusicFrames;
          inMusic = true;
        }
      } else {
        consecutiveSilentFrames++;
        consecutiveMusicFrames = 0;

        // 確認進入靜音段落
        if (inMusic && consecutiveSilentFrames >= minContinuousSilentFrames) {
          final musicStart = musicStartFrame * spectrogram.timeResolution;
          final musicEnd =
              (frame - minContinuousSilentFrames) * spectrogram.timeResolution;
          musicSegments.add(MusicSegment(musicStart, musicEnd));

          silentStartFrame = frame - minContinuousSilentFrames;
          inMusic = false;
        } else if (!inMusic && silentStartFrame == 0) {
          silentStartFrame = frame;
        }
      }
    }

    // 處理結尾狀態
    if (inMusic) {
      final musicStart = musicStartFrame * spectrogram.timeResolution;
      final musicEnd = spectrogram.timeFrames * spectrogram.timeResolution;
      musicSegments.add(MusicSegment(musicStart, musicEnd));
    } else if (silentStartFrame > 0) {
      final silentStart = silentStartFrame * spectrogram.timeResolution;
      final silentEnd = spectrogram.timeFrames * spectrogram.timeResolution;
      silentSegments.add(SilentSegment(silentStart, silentEnd));
    }

    return {
      'music': musicSegments,
      'silent': silentSegments,
    };
  }

}

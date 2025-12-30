/// 自動時間對齊服務
///
/// 功能:
/// 1. 檢測錄音的真正起始點 (裁剪開頭靜音)
/// 2. 估算環境底噪水平
/// 3. 自動對齊 MIDI 時間軸與錄音起始點
///
/// ⚠️ 注意: 只裁剪開頭靜音,不影響樂曲中間的休止符
library;

import 'dart:math';
import 'models/spectrogram.dart';
import 'models/note_event.dart';

/// 自動對齊服務
class AutoAlignmentService {
  /// 底噪估算窗口大小 (秒)
  static const double noiseFloorWindowSize = 0.5;

  /// 音樂起始檢測閾值倍數 (相對於底噪)
  static const double startThresholdMultiplier = 3.0;

  /// 最小連續音樂幀數 (避免誤判短暫雜訊為起始點)
  static const int minContinuousFrames = 3;

  /// 檢測錄音的實際起始點
  ///
  /// 策略:
  /// 1. 估算前 0.5 秒的底噪水平
  /// 2. 找到第一個能量超過 底噪*3 的時間點
  /// 3. 需要連續 3 幀以上才算真正開始 (避免誤判)
  ///
  /// 參數:
  /// - [spectrogram]: 頻譜圖
  ///
  /// 返回: 實際音樂起始時間 (秒)
  double detectActualStart(Spectrogram spectrogram) {
    // 1. 估算底噪水平
    final noiseFloor = _estimateNoiseFloor(spectrogram);
    final threshold = noiseFloor * startThresholdMultiplier;

    print('🔍 檢測錄音起始點:');
    print('  底噪水平: ${noiseFloor.toStringAsFixed(6)}');
    print(
        '  檢測閾值: ${threshold.toStringAsFixed(6)} (底噪 × $startThresholdMultiplier)');

    // 2. 找到第一個超過閾值的連續區域
    int consecutiveFrames = 0;
    int? startFrame;

    for (int frame = 0; frame < spectrogram.timeFrames; frame++) {
      final energy = _calculateFrameEnergy(spectrogram, frame);

      if (energy > threshold) {
        consecutiveFrames++;
        startFrame ??= frame;

        // 連續超過閾值足夠久,確認為真正起始點
        if (consecutiveFrames >= minContinuousFrames) {
          final startTime = startFrame * spectrogram.timeResolution;
          print(
              '  ✅ 檢測到起始點: ${startTime.toStringAsFixed(3)}秒 (第 $startFrame 幀)');
          print('  📊 連續強能量幀數: $consecutiveFrames');
          return startTime;
        }
      } else {
        // 重置計數器 (避免誤判短暫雜訊)
        consecutiveFrames = 0;
        startFrame = null;
      }
    }

    // 沒找到明顯起始點,返回 0 (可能整段都是靜音或音樂從頭開始)
    print('  ⚠️ 未檢測到明顯起始點,假設從 0 秒開始');
    return 0.0;
  }

  /// 對齊 MIDI 時間軸
  ///
  /// 創建一個新的時間軸,將所有 MIDI 事件偏移到與實際錄音起始點對齊
  ///
  /// 參數:
  /// - [timeline]: 原始 MIDI 時間軸
  /// - [actualStart]: 實際錄音起始時間 (秒)
  ///
  /// 返回: 對齊後的新時間軸
  ///
  /// ⚠️ 注意: NoteEvent 是 immutable,所以會創建新對象
  MidiTimeline alignMidiTimeline(MidiTimeline timeline, double actualStart) {
    if (timeline.events.isEmpty) return timeline;

    // 計算偏移量 = 錄音起始時間 - MIDI 第一個音符時間
    final firstNoteTime = timeline.events.first.startTime;
    final offset = actualStart - firstNoteTime;

    print('\n⏰ 對齊 MIDI 時間軸:');
    print('  MIDI 第一音符: ${firstNoteTime.toStringAsFixed(3)}秒');
    print('  錄音起始點: ${actualStart.toStringAsFixed(3)}秒');
    print('  時間偏移: ${offset >= 0 ? '+' : ''}${offset.toStringAsFixed(3)}秒');

    if (offset.abs() < 0.01) {
      print('  ✅ 時間已對齊,無需調整');
      return timeline;
    }

    // 創建新的對齊後事件列表
    final alignedEvents = timeline.events.map((event) {
      return NoteEvent(
        midiNote: event.midiNote,
        startTime: event.startTime + offset,
        endTime: event.endTime + offset,
        velocity: event.velocity,
      );
    }).toList();

    print('  ✅ 已調整 ${alignedEvents.length} 個 MIDI 事件');
    print('  📍 新起始時間: ${alignedEvents.first.startTime.toStringAsFixed(3)}秒\n');

    // 創建新的時間軸
    return MidiTimeline(
      events: alignedEvents,
      duration: timeline.duration,
    );
  }

  /// 估算底噪水平
  ///
  /// 使用前 0.5 秒的能量中位數作為底噪估算
  /// (中位數比平均值更穩健,不受短暫峰值影響)
  double _estimateNoiseFloor(Spectrogram spectrogram) {
    final windowFrames =
        (noiseFloorWindowSize / spectrogram.timeResolution).round();
    final maxFrames = min(windowFrames, spectrogram.timeFrames);

    final energies = <double>[];
    for (int frame = 0; frame < maxFrames; frame++) {
      energies.add(_calculateFrameEnergy(spectrogram, frame));
    }

    // 排序後取中位數
    energies.sort();
    final medianIndex = energies.length ~/ 2;
    return energies[medianIndex];
  }

  /// 計算單個時間幀的總能量
  double _calculateFrameEnergy(Spectrogram spectrogram, int frame) {
    if (frame < 0 || frame >= spectrogram.timeFrames) {
      return 0.0;
    }

    double totalEnergy = 0.0;
    for (int bin = 0; bin < spectrogram.freqBins; bin++) {
      final magnitude = spectrogram.data[frame][bin];
      totalEnergy += magnitude * magnitude; // 能量 = 幅度平方
    }

    return sqrt(totalEnergy / spectrogram.freqBins); // RMS 能量
  }

  /// 檢測錄音結尾點 (2025/11/27 實作)
  ///
  /// 用於裁剪錄音結尾的靜音段
  ///
  /// 參數:
  /// - [spectrogram]: 頻譜圖
  ///
  /// 返回: 實際音樂結束時間 (秒)
  double detectActualEnd(Spectrogram spectrogram) {
    // 1. 估算底噪水平
    final noiseFloor = _estimateNoiseFloor(spectrogram);
    final threshold = noiseFloor * startThresholdMultiplier;

    print('🔍 檢測錄音結尾點:');
    print('  底噪水平: ${noiseFloor.toStringAsFixed(6)}');
    print('  檢測閾值: ${threshold.toStringAsFixed(6)}');

    // 2. 從後往前搜索最後一個有效音樂時間點
    int consecutiveFrames = 0;
    int? endFrame;

    for (int frame = spectrogram.timeFrames - 1; frame >= 0; frame--) {
      final energy = _calculateFrameEnergy(spectrogram, frame);

      if (energy > threshold) {
        consecutiveFrames++;
        endFrame ??= frame;

        // 連續超過閾值足夠久,確認為真正結束點
        if (consecutiveFrames >= minContinuousFrames) {
          final endTime = endFrame * spectrogram.timeResolution;
          print(
              '  ✅ 檢測到結尾點: ${endTime.toStringAsFixed(3)}秒 (第 $endFrame 幀)');
          print('  📊 連續強能量幀數: $consecutiveFrames');
          return endTime;
        }
      } else {
        // 重置計數器
        consecutiveFrames = 0;
        endFrame = null;
      }
    }

    // 沒找到明顯結尾點,返回總時長
    final totalDuration = spectrogram.timeFrames * spectrogram.timeResolution;
    print('  ⚠️ 未檢測到明顯結尾點,使用總時長: ${totalDuration.toStringAsFixed(3)}秒');
    return totalDuration;
  }

  /// 檢測演奏中的靜音間隙 (中斷檢測) - 2025/11/27 新增
  ///
  /// 用於檢測演奏中途停頓的時間點
  ///
  /// 參數:
  /// - [spectrogram]: 頻譜圖
  /// - [minSilenceDuration]: 最小靜音時長 (秒),預設 2.0 秒
  ///
  /// 返回: 靜音間隙列表 [(開始時間, 結束時間), ...]
  List<(double, double)> detectSilentGaps(
    Spectrogram spectrogram, {
    double minSilenceDuration = 2.0,
  }) {
    final noiseFloor = _estimateNoiseFloor(spectrogram);
    final threshold = noiseFloor * startThresholdMultiplier;
    final minSilentFrames =
        (minSilenceDuration / spectrogram.timeResolution).round();

    final silentGaps = <(double, double)>[];
    int consecutiveSilentFrames = 0;
    int? silentStartFrame;

    print('🔍 檢測靜音間隙 (閾值: ${minSilenceDuration.toStringAsFixed(1)}秒)...');

    for (int frame = 0; frame < spectrogram.timeFrames; frame++) {
      final energy = _calculateFrameEnergy(spectrogram, frame);
      final isSilent = energy <= threshold;

      if (isSilent) {
        consecutiveSilentFrames++;
        silentStartFrame ??= frame;

        // 達到最小靜音時長時記錄開始
        if (consecutiveSilentFrames == minSilentFrames) {
          final startTime = silentStartFrame * spectrogram.timeResolution;
          silentGaps.add((startTime, 0.0)); // 暫時不知道結束時間
        }
      } else {
        // 結束靜音段落
        if (consecutiveSilentFrames >= minSilentFrames) {
          final endTime = frame * spectrogram.timeResolution;
          // 更新最後一個靜音段落的結束時間
          if (silentGaps.isNotEmpty) {
            final lastGap = silentGaps.removeLast();
            silentGaps.add((lastGap.$1, endTime));
            print(
                '  發現間隙: ${lastGap.$1.toStringAsFixed(1)}s - ${endTime.toStringAsFixed(1)}s '
                '(${(endTime - lastGap.$1).toStringAsFixed(1)}秒)');
          }
        }

        consecutiveSilentFrames = 0;
        silentStartFrame = null;
      }
    }

    // 處理結尾仍在靜音的情況
    if (consecutiveSilentFrames >= minSilentFrames && silentGaps.isNotEmpty) {
      final lastGap = silentGaps.removeLast();
      final endTime = spectrogram.timeFrames * spectrogram.timeResolution;
      silentGaps.add((lastGap.$1, endTime));
    }

    print('  ✅ 檢測到 ${silentGaps.length} 個靜音間隙');
    return silentGaps;
  }

  /// 進階對齊 MIDI 時間軸 (支援分段對齊) - 2025/11/27 更新
  ///
  /// 對齊策略更新:
  /// 1. 單段演奏: 簡單偏移
  /// 2. 多段演奏 (有中斷): 分段對齊以匹配 MIDI 段落
  /// 3. 跳過段落: 識別未演奏的 MIDI 段落
  ///
  /// 參數:
  /// - [timeline]: 原始 MIDI 時間軸
  /// - [actualStart]: 實際起始時間 (秒)
  /// - [musicSegments]: 檢測到的音樂段落 (可選,用於多段對齊)
  ///
  /// 返回: 對齊後的新時間軸
  MidiTimeline alignMidiTimelineAdvanced(
    MidiTimeline timeline,
    double actualStart, {
    List<(double, double)>? musicSegments,
  }) {
    if (timeline.events.isEmpty) return timeline;

    // 沒有提供音樂段落,使用簡單對齊
    if (musicSegments == null || musicSegments.isEmpty) {
      return alignMidiTimeline(timeline, actualStart);
    }

    // 只有一個段落,使用簡單對齊
    if (musicSegments.length == 1) {
      return alignMidiTimeline(timeline, actualStart);
    }

    print('\n⏰ 進階分段對齊:');
    print('  檢測到 ${musicSegments.length} 個音樂段落');
    print('  MIDI 總時長: ${timeline.duration.toStringAsFixed(1)}秒');

    // 多段對齊: 較複雜
    // 策略: 將 MIDI 分段,依序與音樂段落配對
    final alignedEvents = <NoteEvent>[];
    int musicSegmentIndex = 0;
    double currentMidiTime = 0.0;

    for (final segment in musicSegments) {
      final segmentStart = segment.$1;
      final segmentEnd = segment.$2;
      final segmentDuration = segmentEnd - segmentStart;

      print('  處理段落 ${musicSegmentIndex + 1}: '
          '${segmentStart.toStringAsFixed(1)}s - ${segmentEnd.toStringAsFixed(1)}s '
          '(${segmentDuration.toStringAsFixed(1)}秒)');

      // 收集 MIDI 中對應這個時間範圍的音符
      final segmentNotes = <NoteEvent>[];
      double segmentMidiDuration = 0.0;

      for (final event in timeline.events) {
        if (event.startTime < currentMidiTime) continue;

        segmentNotes.add(event);
        segmentMidiDuration = event.endTime - currentMidiTime;

        // 達到這個段落的預期時長後停止
        if (segmentMidiDuration >= segmentDuration * 0.9) {
          break;
        }
      }

      // 對齊這些音符
      final offset = segmentStart - currentMidiTime;
      for (final note in segmentNotes) {
        alignedEvents.add(NoteEvent(
          midiNote: note.midiNote,
          startTime: note.startTime + offset,
          endTime: note.endTime + offset,
          velocity: note.velocity,
        ));
      }

      print('    對齊 ${segmentNotes.length} 個音符,偏移 ${offset.toStringAsFixed(1)}秒');

      // 更新下一個段落的起始時間
      if (segmentNotes.isNotEmpty) {
        currentMidiTime = segmentNotes.last.endTime;
      }
      musicSegmentIndex++;
    }

    print('  ✅ 分段對齊完成,總共對齊 ${alignedEvents.length} 個音符\n');

    return MidiTimeline(
      events: alignedEvents,
      duration: timeline.duration,
    );
  }
}

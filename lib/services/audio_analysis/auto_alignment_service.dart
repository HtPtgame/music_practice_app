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

  /// 檢測錄音結尾點 (可選功能,暫不實作)
  ///
  /// 用於未來擴展:裁剪錄音結尾的靜音段
  double? detectActualEnd(Spectrogram spectrogram) {
    // TODO: 從後往前搜索最後一個有效音樂時間點
    return null;
  }
}

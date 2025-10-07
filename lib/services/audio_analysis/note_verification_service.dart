import 'models/spectrogram.dart';
import 'models/note_event.dart';

/// 音符驗證服務接口
/// 
/// 負責驗證特定音符在特定時間是否存在
abstract class INoteVerifier {
  /// 驗證單個音符在指定時間是否存在
  /// 
  /// [midiNote] MIDI 音符號 (21-108)
  /// [time] 時間點 (秒)
  /// [spectrogram] 頻譜圖
  /// 返回 true 如果音符存在
  Future<bool> verifyNote(
    int midiNote,
    double time,
    Spectrogram spectrogram,
  );
  
  /// 驗證音符在時間範圍內是否存在
  /// 
  /// [noteEvent] 音符事件 (包含時間範圍)
  /// [spectrogram] 頻譜圖
  /// 返回驗證置信度 (0-1)
  Future<double> verifyNoteEvent(
    NoteEvent noteEvent,
    Spectrogram spectrogram,
  );
  
  /// 批量驗證多個音符
  /// 
  /// [timeline] MIDI 時間軸
  /// [spectrogram] 頻譜圖
  /// 返回 Map<NoteEvent, 驗證結果>
  Future<Map<NoteEvent, bool>> verifyAll(
    MidiTimeline timeline,
    Spectrogram spectrogram,
  );
}

import 'models/note_event.dart';
import 'models/performance_error.dart';

/// 錯誤分類服務接口
/// 
/// 負責將驗證結果分類為不同類型的錯誤
abstract class IErrorClassifier {
  /// 分類錯誤
  /// 
  /// [standard] MIDI 標準答案時間軸
  /// [verifications] 驗證結果 Map<NoteEvent, 是否存在>
  /// [alignment] 時間對齊結果
  /// 返回 [List<PerformanceError>] 錯誤列表
  List<PerformanceError> classify(
    MidiTimeline standard,
    Map<NoteEvent, bool> verifications,
    AlignmentResult alignment,
  );
  
  /// 檢測節奏錯誤
  /// 
  /// [expected] 預期時間
  /// [actual] 實際時間
  /// [tolerance] 容差 (秒,默認 0.1)
  /// 返回 [ErrorType] 或 null (如果在容差內)
  ErrorType? detectTimingError(
    double expected,
    double actual, {
    double tolerance = 0.1,
  });
}

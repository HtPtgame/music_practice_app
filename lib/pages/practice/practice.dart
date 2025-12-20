/// Practice Page 模組匯出
/// 
/// Phase 3 重構: 統一匯出 PracticePage 相關元件
library practice;

// 狀態管理
export 'state/practice_phase.dart';
export 'state/practice_state.dart';

// 控制器
export 'controllers/recording_controller.dart';
export 'controllers/audio_playback_controller.dart';
export 'controllers/analysis_controller.dart';

// UI 元件
export 'widgets/recording_controls_widget.dart';
export 'widgets/playback_controls_widget.dart';
export 'widgets/analysis_controls_widget.dart';
export 'widgets/upload_controls_widget.dart';
export 'widgets/mode_selector_widget.dart';
export 'widgets/analysis_progress_dialog.dart';

// 重構後的頁面
export 'practice_page_refactored.dart';
/// Drawing Canvas 模組
/// 
/// Phase 3 重構: 統一導出所有繪圖相關元件
library drawing;

// Managers
export 'managers/brush_texture_pool.dart';
export 'managers/drawing_cache_manager.dart';
export 'managers/drawing_history_manager.dart';

// Painters
export 'painters/drawing_painter.dart';

// Main Widget
export 'drawing_canvas_refactored.dart';

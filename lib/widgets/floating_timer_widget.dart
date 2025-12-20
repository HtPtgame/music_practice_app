// lib/widgets/floating_timer_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:veloria/services/practice_timer_service.dart';
import 'package:veloria/utils/app_colors.dart';
import 'package:veloria/l10n/app_localizations.dart';

/// 浮動計時器 Widget
/// 在所有頁面上方顯示當前計時狀態
class FloatingTimerWidget extends StatefulWidget {
  const FloatingTimerWidget({super.key});

  @override
  State<FloatingTimerWidget> createState() => _FloatingTimerWidgetState();
}

class _FloatingTimerWidgetState extends State<FloatingTimerWidget> {
  final PracticeTimerService _timerService = PracticeTimerService();
  Timer? _uiUpdateTimer;
  bool _isExpanded = false;
  Offset _position = const Offset(16, 100);
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _timerService.addListener(_onTimerChanged);
    _startUIUpdateTimer();
  }

  void _onTimerChanged() {
    if (mounted) setState(() {});
  }

  void _startUIUpdateTimer() {
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // 運行或暫停時都需要更新 UI（顯示/隱藏狀態可能改變）
      if (mounted && (_timerService.isRunning || _timerService.isPaused)) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timerService.removeListener(_onTimerChanged);
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 不顯示條件：未運行且未暫停 或 設定關閉
    // 暫停時仍顯示浮動視窗，讓用戶可以繼續或停止
    final shouldShow = (_timerService.isRunning || _timerService.isPaused) && 
                       _timerService.showFloatingTimer;
    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    // 確保位置在螢幕範圍內
    final screenSize = MediaQuery.of(context).size;
    final safePosition = Offset(
      _position.dx.clamp(0, screenSize.width - 120),
      _position.dy.clamp(MediaQuery.of(context).padding.top + 10, screenSize.height - 150),
    );

    return Positioned(
      left: safePosition.dx,
      top: safePosition.dy,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() => _isDragging = true);
        },
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
        },
        onTap: () {
          if (!_isDragging) {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: _isExpanded ? 16 : 12,
            vertical: _isExpanded ? 12 : 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.dynamicPrimary,
            borderRadius: BorderRadius.circular(_isExpanded ? 16 : 24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isExpanded ? _buildExpandedContent() : _buildCollapsedContent(),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(
          _timerService.formatTodayTotal(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 標題行 - 今日總練習時長
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              _timerService.formatTodayTotal(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 提示文字 - 顯示今日總練習
        Text(
          l10n?.timerTodayPractice ?? '今日練習',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 12),
        // 控制按鈕
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 暫停/繼續按鈕
            _buildControlButton(
              icon: _timerService.isRunning ? Icons.pause : Icons.play_arrow,
              label: _timerService.isRunning 
                  ? (l10n?.timerPause ?? '暫停') 
                  : (l10n?.timerContinue ?? '繼續'),
              onTap: () {
                if (_timerService.isRunning) {
                  _timerService.pause();
                } else {
                  _timerService.resume();
                }
              },
            ),
            const SizedBox(width: 12),
            // 停止按鈕
            _buildControlButton(
              icon: Icons.stop,
              label: l10n?.timerStop ?? '結束',
              onTap: () async {
                await _timerService.stop();
                if (mounted) {
                  setState(() {
                    _isExpanded = false;
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 浮動計時器 Overlay 管理器
/// 用於在全局顯示浮動計時器
class FloatingTimerOverlay {
  static OverlayEntry? _overlayEntry;
  
  /// 顯示浮動計時器
  static void show(BuildContext context) {
    if (_overlayEntry != null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => const FloatingTimerWidget(),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  /// 隱藏浮動計時器
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
  
  /// 更新浮動計時器
  static void update() {
    _overlayEntry?.markNeedsBuild();
  }
}

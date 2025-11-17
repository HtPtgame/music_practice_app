import 'package:flutter/material.dart';

/// Phase 1B: 倒數計時 Overlay Widget
///
/// 在用戶按下錄音按鈕後，顯示 3-2-1 倒數計時，
/// 讓用戶有時間準備，然後才真正開始錄音。
class CountdownOverlay extends StatefulWidget {
  final VoidCallback onCountdownComplete;
  final VoidCallback? onCancel;

  const CountdownOverlay({
    super.key,
    required this.onCountdownComplete,
    this.onCancel,
  });

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  int _currentCount = 3;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _startCountdown();
  }

  void _startCountdown() async {
    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;

      setState(() {
        _currentCount = i;
      });

      _controller.reset();
      _controller.forward();

      await Future.delayed(const Duration(milliseconds: 1000));
    }

    if (mounted) {
      widget.onCountdownComplete();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Stack(
        children: [
          // 半透明背景
          Container(
            color: Colors.black.withOpacity(0.5),
          ),

          // 倒數數字
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getCountColor(_currentCount),
                        boxShadow: [
                          BoxShadow(
                            color:
                                _getCountColor(_currentCount).withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$_currentCount',
                          style: const TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 取消按鈕
          if (widget.onCancel != null)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    '取消',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getCountColor(int count) {
    switch (count) {
      case 3:
        return const Color(0xFFE53935); // 柔和的紅色
      case 2:
        return const Color(0xFFFB8C00); // 柔和的橙色
      case 1:
        return const Color(0xFF43A047); // 柔和的綠色
      default:
        return const Color(0xFF1E88E5); // 柔和的藍色
    }
  }
}

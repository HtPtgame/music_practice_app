import 'package:flutter/material.dart';

/// 統一錯誤處理工具
///
/// 提供一致的錯誤顯示和處理方式，改善使用者體驗
class ErrorHandler {
  // 私有建構子，防止實例化
  ErrorHandler._();

  /// 顯示錯誤 SnackBar
  static void show(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    final message = customMessage ?? _parseError(error);
    
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(
                label: '重試',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
  
  /// 顯示警告
  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// 顯示成功訊息
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// 解析錯誤訊息
  static String _parseError(dynamic error) {
    if (error is Exception) {
      final errorString = error.toString();
      // 移除 "Exception: " 前綴
      if (errorString.startsWith('Exception: ')) {
        return errorString.substring('Exception: '.length);
      }
      return errorString;
    }
    return error.toString();
  }
  
  /// 顯示詳細錯誤對話框（開發用）
  static void showDetailDialog(
    BuildContext context,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('錯誤詳情'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '錯誤訊息:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(error.toString()),
              if (stackTrace != null) ...[
                const SizedBox(height: 16),
                const Text(
                  '堆疊追蹤:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  stackTrace.toString(),
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }
  
  /// 記錄錯誤並顯示（結合 debugPrint 和 UI 提示）
  static void logAndShow(
    BuildContext context,
    dynamic error,
    StackTrace? stackTrace, {
    String? customMessage,
  }) {
    // 記錄到控制台
    debugPrint('❌ Error: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace:\n$stackTrace');
    }
    
    // 顯示給使用者
    show(context, error, customMessage: customMessage);
  }
}

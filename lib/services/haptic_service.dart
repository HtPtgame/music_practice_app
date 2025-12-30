// lib/services/haptic_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:veloria/core/services/settings_service.dart';

/// 音效和震動管理服務
class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  final SettingsService _settingsService = SettingsService();

  /// 輕度震動回饋（按鈕點擊）
  Future<void> lightImpact() async {
    if (await _settingsService.isVibrationEnabled()) {
      try {
        await HapticFeedback.lightImpact();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('HapticService: ⚠️ Light impact failed: $e');
        }
      }
    }
  }

  /// 中度震動回饋（選擇項目）
  Future<void> mediumImpact() async {
    if (await _settingsService.isVibrationEnabled()) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('HapticService: ⚠️ Medium impact failed: $e');
        }
      }
    }
  }

  /// 重度震動回饋（重要操作）
  Future<void> heavyImpact() async {
    if (await _settingsService.isVibrationEnabled()) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('HapticService: ⚠️ Heavy impact failed: $e');
        }
      }
    }
  }

  /// 選擇回饋（滑動選擇器）
  Future<void> selectionClick() async {
    if (await _settingsService.isVibrationEnabled()) {
      try {
        await HapticFeedback.selectionClick();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('HapticService: ⚠️ Selection click failed: $e');
        }
      }
    }
  }

  /// 震動模式（長按）
  Future<void> vibrate() async {
    if (await _settingsService.isVibrationEnabled()) {
      try {
        await HapticFeedback.vibrate();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('HapticService: ⚠️ Vibrate failed: $e');
        }
      }
    }
  }
}

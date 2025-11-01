// lib/services/settings_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 設定管理服務 - 使用 SharedPreferences 持久化儲存
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;
  
  // 設定鍵名常數
  static const String _keyMasterVolume = 'master_volume';
  static const String _keyMidiVolume = 'midi_volume';
  static const String _keyRecordingVolume = 'recording_volume';
  static const String _keyMetronomeVolume = 'metronome_volume';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keySelectedLanguage = 'selected_language';

  // 預設值
  static const double _defaultMasterVolume = 0.8;
  static const double _defaultMidiVolume = 0.7;
  static const double _defaultRecordingVolume = 0.9;
  static const double _defaultMetronomeVolume = 0.6;
  static const bool _defaultSoundEnabled = true;
  static const bool _defaultVibrationEnabled = true;
  static const String _defaultLanguage = 'zh_TW';

  /// 初始化服務
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 確保已初始化
  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }

  // ==================== 音量設定 ====================

  /// 取得主音量
  Future<double> getMasterVolume() async {
    await _ensureInitialized();
    return _prefs?.getDouble(_keyMasterVolume) ?? _defaultMasterVolume;
  }

  /// 儲存主音量
  Future<bool> setMasterVolume(double volume) async {
    await _ensureInitialized();
    return await _prefs?.setDouble(_keyMasterVolume, volume) ?? false;
  }

  /// 取得 MIDI 音量
  Future<double> getMidiVolume() async {
    await _ensureInitialized();
    return _prefs?.getDouble(_keyMidiVolume) ?? _defaultMidiVolume;
  }

  /// 儲存 MIDI 音量
  Future<bool> setMidiVolume(double volume) async {
    await _ensureInitialized();
    return await _prefs?.setDouble(_keyMidiVolume, volume) ?? false;
  }

  /// 取得錄音音量
  Future<double> getRecordingVolume() async {
    await _ensureInitialized();
    return _prefs?.getDouble(_keyRecordingVolume) ?? _defaultRecordingVolume;
  }

  /// 儲存錄音音量
  Future<bool> setRecordingVolume(double volume) async {
    await _ensureInitialized();
    return await _prefs?.setDouble(_keyRecordingVolume, volume) ?? false;
  }

  /// 取得節拍器音量
  Future<double> getMetronomeVolume() async {
    await _ensureInitialized();
    return _prefs?.getDouble(_keyMetronomeVolume) ?? _defaultMetronomeVolume;
  }

  /// 儲存節拍器音量
  Future<bool> setMetronomeVolume(double volume) async {
    await _ensureInitialized();
    return await _prefs?.setDouble(_keyMetronomeVolume, volume) ?? false;
  }

  // ==================== 音效/震動設定 ====================

  /// 取得音效開關狀態
  Future<bool> isSoundEnabled() async {
    await _ensureInitialized();
    return _prefs?.getBool(_keySoundEnabled) ?? _defaultSoundEnabled;
  }

  /// 儲存音效開關狀態
  Future<bool> setSoundEnabled(bool enabled) async {
    await _ensureInitialized();
    return await _prefs?.setBool(_keySoundEnabled, enabled) ?? false;
  }

  /// 取得震動開關狀態
  Future<bool> isVibrationEnabled() async {
    await _ensureInitialized();
    return _prefs?.getBool(_keyVibrationEnabled) ?? _defaultVibrationEnabled;
  }

  /// 儲存震動開關狀態
  Future<bool> setVibrationEnabled(bool enabled) async {
    await _ensureInitialized();
    return await _prefs?.setBool(_keyVibrationEnabled, enabled) ?? false;
  }

  // ==================== 語言設定 ====================

  /// 取得選擇的語言
  Future<String> getSelectedLanguage() async {
    await _ensureInitialized();
    return _prefs?.getString(_keySelectedLanguage) ?? _defaultLanguage;
  }

  /// 儲存選擇的語言
  Future<bool> setSelectedLanguage(String languageCode) async {
    await _ensureInitialized();
    return await _prefs?.setString(_keySelectedLanguage, languageCode) ?? false;
  }

  // ==================== 批次操作 ====================

  /// 取得所有設定
  Future<Map<String, dynamic>> getAllSettings() async {
    await _ensureInitialized();
    return {
      'masterVolume': await getMasterVolume(),
      'midiVolume': await getMidiVolume(),
      'recordingVolume': await getRecordingVolume(),
      'metronomeVolume': await getMetronomeVolume(),
      'soundEnabled': await isSoundEnabled(),
      'vibrationEnabled': await isVibrationEnabled(),
      'selectedLanguage': await getSelectedLanguage(),
    };
  }

  /// 重置所有設定到預設值
  Future<bool> resetToDefaults() async {
    await _ensureInitialized();
    try {
      await setMasterVolume(_defaultMasterVolume);
      await setMidiVolume(_defaultMidiVolume);
      await setRecordingVolume(_defaultRecordingVolume);
      await setMetronomeVolume(_defaultMetronomeVolume);
      await setSoundEnabled(_defaultSoundEnabled);
      await setVibrationEnabled(_defaultVibrationEnabled);
      await setSelectedLanguage(_defaultLanguage);
      return true;
    } catch (e) {
      debugPrint('SettingsService: ❌ Failed to reset settings: $e');
      return false;
    }
  }

  /// 清除所有設定
  Future<bool> clearAll() async {
    await _ensureInitialized();
    return await _prefs?.clear() ?? false;
  }
}

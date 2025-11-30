import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  static const String _keyMasterVolume = 'master_volume';
  static const String _keyMidiVolume = 'midi_volume';
  static const String _keyRecordingVolume = 'recording_volume';
  static const String _keyMetronomeVolume = 'metronome_volume';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keySelectedLanguage = 'selected_language';

  static const double _defaultMasterVolume = 0.8;
  static const double _defaultMidiVolume = 0.7;
  static const double _defaultRecordingVolume = 0.9;
  static const double _defaultMetronomeVolume = 0.6;
  static const bool _defaultSoundEnabled = true;
  static const bool _defaultVibrationEnabled = true;
  static const String _defaultLanguage = 'zh_TW';

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }

  Future<double> getMasterVolume() async {
    await _ensureInitialized();
    return _prefs?.getDouble(_keyMasterVolume) ?? _defaultMasterVolume;
  }

  Future<bool> setMasterVolume(double volume) async {
    await _ensureInitialized();
    return await _prefs?.setDouble(_keyMasterVolume, volume) ?? false;
  }

  Future<double> getMidiVolume() async {
    await _ensureInitialized();
    return _prefs?.getDouble(_keyMidiVolume) ?? _defaultMidiVolume;
  }

  Future<bool> setMidiVolume(double volume) async {
    await _ensureInitialized();
    return await _prefs?.setDouble(_keyMidiVolume, volume) ?? false;
  }

  Future<double> getRecordingVolume() async {
    await _ensureInitialized();
    return _prefs?.getDouble(_keyRecordingVolume) ?? _defaultRecordingVolume;
  }

  Future<bool> setRecordingVolume(double volume) async {
    await _ensureInitialized();
    return await _prefs?.setDouble(_keyRecordingVolume, volume) ?? false;
  }

  Future<double> getMetronomeVolume() async {
    await _ensureInitialized();
    return _prefs?.getDouble(_keyMetronomeVolume) ?? _defaultMetronomeVolume;
  }

  Future<bool> setMetronomeVolume(double volume) async {
    await _ensureInitialized();
    return await _prefs?.setDouble(_keyMetronomeVolume, volume) ?? false;
  }

  Future<bool> isSoundEnabled() async {
    await _ensureInitialized();
    return _prefs?.getBool(_keySoundEnabled) ?? _defaultSoundEnabled;
  }

  Future<bool> setSoundEnabled(bool enabled) async {
    await _ensureInitialized();
    return await _prefs?.setBool(_keySoundEnabled, enabled) ?? false;
  }

  Future<bool> isVibrationEnabled() async {
    await _ensureInitialized();
    return _prefs?.getBool(_keyVibrationEnabled) ?? _defaultVibrationEnabled;
  }

  Future<bool> setVibrationEnabled(bool enabled) async {
    await _ensureInitialized();
    return await _prefs?.setBool(_keyVibrationEnabled, enabled) ?? false;
  }

  Future<String> getSelectedLanguage() async {
    await _ensureInitialized();
    return _prefs?.getString(_keySelectedLanguage) ?? _defaultLanguage;
  }

  Future<bool> setSelectedLanguage(String languageCode) async {
    await _ensureInitialized();
    return await _prefs?.setString(_keySelectedLanguage, languageCode) ?? false;
  }

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

  Future<bool> clearAll() async {
    await _ensureInitialized();
    return await _prefs?.clear() ?? false;
  }
}

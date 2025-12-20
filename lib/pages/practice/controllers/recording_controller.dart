import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart' show Level;
import 'package:music_practice_app/core/constants/audio_constants.dart';

/// 錄音控制器
/// 
/// Phase 3 重構: 從 PracticePage 提取的錄音邏輯
/// 負責所有錄音相關操作，包括開始、停止、權限管理等
/// 
/// 繼承 ChangeNotifier 以支援 Provider 狀態管理
class RecordingController extends ChangeNotifier {
  // ===== 錄音器實例 =====
  final AudioRecorder _recordAlt = AudioRecorder();
  FlutterSoundRecorder? _recorder;
  
  // ===== 設定 =====
  bool useAltRecorder = true;
  bool _enableCountdown = true;
  
  bool get enableCountdown => _enableCountdown;
  void setEnableCountdown(bool value) {
    _enableCountdown = value;
    notifyListeners();
  }
  
  // ===== 狀態 =====
  bool _isRecording = false;
  bool get isRecording => _isRecording;
  
  int _recordingDurationSeconds = 0;
  int get recordingDuration => _recordingDurationSeconds;
  int get recordingDurationSeconds => _recordingDurationSeconds;
  
  String? _audioPath;
  String? get audioPath => _audioPath;
  
  void setAudioPath(String? path) {
    _audioPath = path;
    notifyListeners();
  }
  
  Timer? _recordingTimer;
  
  // ===== 回調 =====
  void Function(int seconds)? onDurationUpdate;
  void Function(String? path)? onRecordingComplete;
  void Function(String message)? onError;
  void Function(String message)? onSuccess;
  void Function(String message)? onWarning;
  
  RecordingController({
    this.useAltRecorder = true,
    this.onDurationUpdate,
    this.onRecordingComplete,
    this.onError,
    this.onSuccess,
    this.onWarning,
  });
  
  /// 初始化錄音器
  Future<void> initialize() async {
    try {
      _recorder = FlutterSoundRecorder();
      _recorder!.setLogLevel(Level.error);
      await _recorder!.openRecorder();
      debugPrint('✅ RecordingController 初始化完成');
    } catch (e) {
      debugPrint('❌ RecordingController 初始化失敗: $e');
      onError?.call('錄音器初始化失敗: $e');
    }
  }
  
  /// 開始錄音
  Future<bool> startRecording() async {
    if (useAltRecorder) {
      return await _startAltRecording();
    } else {
      return await _startFlutterSoundRecording();
    }
  }
  
  /// 使用 record 套件錄音
  Future<bool> _startAltRecording() async {
    debugPrint('🎤 (ALT) 使用 record 套件開始錄音');
    
    // 檢查權限
    if (!await _recordAlt.hasPermission()) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint('❌ (ALT) 未授權麥克風');
        onError?.call('麥克風權限被拒絕');
        return false;
      }
    }
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final altPath = '${dir.path}/practice_record_alt.wav';
      
      // 刪除舊檔案
      if (await File(altPath).exists()) {
        await File(altPath).delete();
      }
      
      // 開始錄音
      await _recordAlt.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: AudioConstants.standardSampleRate,
          numChannels: AudioConstants.monoChannel,
          bitRate: AudioConstants.standardBitRate,
        ),
        path: altPath,
      );
      
      _isRecording = true;
      _audioPath = altPath;
      _recordingDurationSeconds = 0;
      notifyListeners();
      
      // 啟動計時器
      _startTimer();
      
      debugPrint('✅ (ALT) 錄音開始: $altPath');
      return true;
    } catch (e) {
      debugPrint('❌ (ALT) 錄音啟動失敗: $e');
      onError?.call('錄音啟動失敗: $e');
      return false;
    }
  }
  
  /// 使用 flutter_sound 錄音
  Future<bool> _startFlutterSoundRecording() async {
    debugPrint('🎤 開始錄音程序...');
    
    // 檢查權限
    var micStatus = await Permission.microphone.status;
    if (micStatus != PermissionStatus.granted) {
      micStatus = await Permission.microphone.request();
    }
    
    if (micStatus != PermissionStatus.granted) {
      debugPrint('❌ 麥克風權限被拒絕');
      onError?.call('麥克風權限被拒絕');
      return false;
    }
    
    try {
      // 確保錄音器處於正確狀態
      if (_recorder == null) {
        await initialize();
        if (_recorder == null) {
          throw Exception('無法初始化錄音器');
        }
      }
      
      // 如果正在錄音，先停止
      if (_isRecording || _recorder!.isRecording) {
        await _recorder!.stopRecorder();
        await Future.delayed(const Duration(milliseconds: 1000));
        _isRecording = false;
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final wavPath = '${directory.path}/practice_record.wav';
      
      // 刪除舊檔案
      final wavFile = File(wavPath);
      if (await wavFile.exists()) {
        await wavFile.delete();
      }
      
      // 開始錄音
      await _recorder!.startRecorder(
        toFile: wavPath,
        codec: Codec.pcm16WAV,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 705600,
      );
      
      _isRecording = true;
      _audioPath = wavPath;
      _recordingDurationSeconds = 0;
      notifyListeners();
      
      // 啟動計時器
      _startTimer();
      
      debugPrint('✅ WAV 錄音已開始');
      return true;
    } catch (e) {
      debugPrint('❌ 錄音啟動失敗: $e');
      _isRecording = false;
      _recordingDurationSeconds = 0;
      _recordingTimer?.cancel();
      onError?.call('錄音啟動失敗: $e');
      return false;
    }
  }
  
  /// 停止錄音
  Future<String?> stopRecording() async {
    if (useAltRecorder) {
      return await _stopAltRecording();
    } else {
      return await _stopFlutterSoundRecording();
    }
  }
  
  /// 停止 record 套件錄音
  Future<String?> _stopAltRecording() async {
    debugPrint('🛑 (ALT) 停止 record 錄音');
    
    try {
      final path = await _recordAlt.stop();
      _recordingTimer?.cancel();
      _isRecording = false;
      notifyListeners();
      
      if (path != null) {
        final f = File(path);
        if (await f.exists()) {
          final size = await f.length();
          debugPrint('✅ (ALT) 錄音完成: $path 大小: $size bytes');
          _audioPath = path;
          onRecordingComplete?.call(path);
          onSuccess?.call('錄音成功！時長: $_recordingDurationSeconds 秒，大小: ${(size / 1024).toStringAsFixed(1)} KB');
          return path;
        }
      }
      
      onWarning?.call('錄音檔案未找到');
      return null;
    } catch (e) {
      debugPrint('❌ (ALT) 停止錄音失敗: $e');
      _isRecording = false;
      _recordingTimer?.cancel();
      notifyListeners();
      onError?.call('停止錄音失敗: $e');
      return null;
    }
  }
  
  /// 停止 flutter_sound 錄音
  Future<String?> _stopFlutterSoundRecording() async {
    debugPrint('🛑 停止錄音程序...');
    
    try {
      if (_recorder == null || !_isRecording) {
        _isRecording = false;
        return null;
      }
      
      // 等待確保數據寫入
      await Future.delayed(const Duration(milliseconds: 1000));
      
      String? recordedPath = await _recorder!.stopRecorder();
      
      // 再等待確保檔案系統同步
      await Future.delayed(const Duration(milliseconds: 1500));
      
      _recordingTimer?.cancel();
      _isRecording = false;
      notifyListeners();
      
      // 驗證錄音檔案
      String? finalPath = await _validateRecordingFile(recordedPath);
      
      if (finalPath != null) {
        _audioPath = finalPath;
        final fileSize = await File(finalPath).length();
        debugPrint('✅ 錄音成功！路徑: $finalPath，大小: $fileSize bytes');
        onRecordingComplete?.call(finalPath);
        onSuccess?.call('錄音成功！時長: $_recordingDurationSeconds 秒，大小: ${(fileSize / 1024).toStringAsFixed(1)} KB');
        return finalPath;
      } else {
        onWarning?.call('未找到錄音檔案');
        return null;
      }
    } catch (e) {
      debugPrint('❌ 停止錄音失敗: $e');
      _isRecording = false;
      _recordingTimer?.cancel();
      notifyListeners();
      onError?.call('停止錄音失敗: $e');
      return null;
    }
  }
  
  /// 驗證錄音檔案
  Future<String?> _validateRecordingFile(String? recordedPath) async {
    // 1. 檢查錄音器返回的路徑
    if (recordedPath != null) {
      final file = File(recordedPath);
      if (await file.exists()) {
        final size = await file.length();
        if (size > 44) {
          return recordedPath;
        }
      }
    }
    
    // 2. 檢查預期路徑
    if (_audioPath != null) {
      final file = File(_audioPath!);
      if (await file.exists()) {
        final size = await file.length();
        if (size > 44) {
          return _audioPath;
        }
      }
    }
    
    // 3. 搜索其他可能位置
    final directory = await getApplicationDocumentsDirectory();
    final possiblePaths = [
      '${directory.path}/practice_record.wav',
      '${directory.path}/practice_record_alt.wav',
      '${directory.path}/flutter_sound.wav',
    ];
    
    for (final path in possiblePaths) {
      final file = File(path);
      if (await file.exists()) {
        final size = await file.length();
        if (size > 44) {
          return path;
        }
      }
    }
    
    return null;
  }
  
  /// 啟動計時器
  void _startTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      _recordingDurationSeconds++;
      notifyListeners();
      onDurationUpdate?.call(_recordingDurationSeconds);
      debugPrint('🔴 錄音中... $_recordingDurationSeconds 秒');
    });
  }
  
  /// 取消錄音
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    
    _recordingTimer?.cancel();
    
    if (useAltRecorder) {
      await _recordAlt.stop();
    } else {
      await _recorder?.stopRecorder();
    }
    
    _isRecording = false;
    _recordingDurationSeconds = 0;
    notifyListeners();
    
    // 刪除錄音檔案
    if (_audioPath != null) {
      final file = File(_audioPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _audioPath = null;
    
    debugPrint('⏹️ 錄音已取消');
  }
  
  /// 清理資源
  @override
  Future<void> dispose() async {
    _recordingTimer?.cancel();
    
    if (_isRecording) {
      await cancelRecording();
    }
    
    await _recorder?.closeRecorder();
    await _recordAlt.dispose();
    
    debugPrint('🧹 RecordingController 已清理');
    super.dispose();
  }
}

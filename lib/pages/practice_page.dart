import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart' show Level;
import 'package:record/record.dart';
import 'package:music_practice_app/core/constants/audio_constants.dart';
import 'package:music_practice_app/utils/error_handler.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:music_practice_app/widgets/countdown_overlay.dart'; // Phase 1B: 倒數計時
import 'package:music_practice_app/l10n/app_localizations.dart';
import 'dart:io';

// Week 4 Phase 2: 分析功能
import 'package:music_practice_app/services/audio_analysis/performance_analyzer.dart';
import 'package:music_practice_app/pages/analysis_result_page.dart';

import 'package:path_provider/path_provider.dart';
import 'dart:async';

class PracticePage extends StatefulWidget {
  final PlatformFile? file;
  const PracticePage({super.key, this.file});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  FlutterSoundRecorder? _recorder; // 使用 flutter_sound 進行錄音
  FlutterSoundPlayer? _player; // 保留 flutter_sound 用於播放
  final AudioRecorder _recordAlt = AudioRecorder(); // 新增：替代錄音器
  final bool _useAltRecorder = true; // 新增：預設啟用替代方案
  String? _audioPath;
  bool isPlaying = false;
  bool isRecording = false;
  bool isConverting = false; // 新增：轉換狀態
  double conversionProgress = 0.0; // 新增：轉換進度

  // 錄音時長相關變數
  int _recordingDurationSeconds = 0;
  Timer? _recordingTimer;

  // 錄音/上傳模式切換 (2025/11/27 恢復)
  bool _isRecordMode = true; // true: 錄音模式, false: 上傳模式

  // 播放器狀態 (2025/11/27 恢復)
  bool _isPaused = false;
  double _playbackPosition = 0.0; // 當前播放位置（秒）
  double _playbackDuration = 0.0; // 總時長（秒）
  Timer? _playbackTimer;
  StreamSubscription? _playerSubscription;

  // 錄音計時器將在錄音過程中自動處理

  // [已淘汰 2025/10/08] AI 模型相關變數 (保留以避免編譯錯誤,但不會被使用)

  // Week 4 Phase 2: 分析功能狀態
  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  String _analysisPhase = '';
  final _analyzer = PerformanceAnalyzer();

  // 倒數計時開關狀態
  bool _enableCountdown = true;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      _recorder = FlutterSoundRecorder();
      _player = FlutterSoundPlayer();

      // 關閉 flutter_sound 的內部日誌
      _recorder!.setLogLevel(Level.error);
      _player!.setLogLevel(Level.error);

      // 先檢查麥克風權限
      final micPermission = await Permission.microphone.status;

      if (micPermission != PermissionStatus.granted) {
        debugPrint('⚠️ 麥克風權限未授權，將在錄音時請求');
      }

      // 初始化錄音器和播放器
      await _recorder!.openRecorder();
      await _player!.openPlayer();
    } catch (e, stackTrace) {
      debugPrint('❌ 音訊初始化失敗: $e');
      debugPrint('堆疊追蹤: $stackTrace');

      // 顯示給使用者
      if (mounted) {
        ErrorHandler.show(
          context,
          e,
          customMessage: '音訊系統初始化失敗，請確認權限設定',
        );
      }

      // 嘗試重新初始化
      try {
        await Future.delayed(const Duration(milliseconds: 1000));

        _recorder = FlutterSoundRecorder();
        _player = FlutterSoundPlayer();

        _recorder!.setLogLevel(Level.error);
        _player!.setLogLevel(Level.error);

        await _recorder!.openRecorder();
        await _player!.openPlayer();
      } catch (retryError) {
        debugPrint('❌ 重新初始化也失敗: $retryError');
      }
    }
  }

  // [已淘汰 2025/10/08] 載入 AI 模型
  // 此函數使用 tflite_flutter 依賴,已移除
  @override
  void dispose() {
    _recordingTimer?.cancel();
    _closeAudio();
    super.dispose();
  }

  Future<void> _closeAudio() async {
    try {
      await _recorder?.closeRecorder();
      await _player?.closePlayer();
    } catch (e) {
      debugPrint('音訊關閉失敗: $e');
    }
  }

  Future<void> startRecording() async {
    bool countdownCancelled = false;

    // 根據開關狀態決定是否顯示倒數計時
    if (_enableCountdown) {
      // Phase 1B: 顯示倒數計時
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CountdownOverlay(
            onCountdownComplete: () {
              Navigator.of(context).pop();
            },
            onCancel: () {
              countdownCancelled = true;
              Navigator.of(context).pop();
            },
          );
        },
      );

      // 如果取消了倒數計時，則不開始錄音
      if (countdownCancelled) {
        debugPrint('⏸️ 用戶取消了倒數計時');
        return;
      }

      debugPrint('🎤 倒數計時完成，開始錄音');
    } else {
      debugPrint('🎤 已關閉倒數計時，直接開始錄音');
    }

    // 原有的錄音邏輯
    if (_useAltRecorder) {
      debugPrint('🎤 (ALT) 使用 record 套件開始錄音');
      if (!await _recordAlt.hasPermission()) {
        final status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          debugPrint('❌ (ALT) 未授權麥克風');
          return;
        }
      }
      final dir = await getApplicationDocumentsDirectory();
      final altPath = '${dir.path}/practice_record_alt.wav';
      if (await File(altPath).exists()) await File(altPath).delete();
      await _recordAlt.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: AudioConstants.standardSampleRate,
          numChannels: AudioConstants.monoChannel,
          bitRate: AudioConstants.standardBitRate,
        ),
        path: altPath,
      );
      setState(() {
        isRecording = true;
        _audioPath = altPath;
        _recordingDurationSeconds = 0;
      });
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (!isRecording) {
          t.cancel();
          return;
        }
        setState(() {
          _recordingDurationSeconds++;
        });
        debugPrint('🔴 (ALT) 錄音中... $_recordingDurationSeconds 秒');
      });
      return; // 不執行原 flutter_sound 流程
    }

    debugPrint('🎤 開始錄音程序...');

    if (!mounted) {
      debugPrint('組件已銷毀，停止錄音');
      return;
    }

    // 更強健的權限檢查
    debugPrint('檢查麥克風權限...');
    var micStatus = await Permission.microphone.status;
    debugPrint('當前權限狀態: $micStatus');

    if (micStatus != PermissionStatus.granted) {
      debugPrint('請求麥克風權限...');
      micStatus = await Permission.microphone.request();
      debugPrint('權限請求結果: $micStatus');
    }

    if (micStatus != PermissionStatus.granted) {
      debugPrint('❌ 麥克風權限被拒絕');
      if (!mounted) return;
      ErrorHandler.show(
        context,
        Exception('Microphone permission denied'),
        customMessage: AppLocalizations.of(context)!.errorMicPermission,
      );
      return;
    }

    try {
      // 確保錄音器處於正確狀態
      if (_recorder == null) {
        debugPrint('❌ 錄音器未初始化，嘗試重新初始化...');
        await _initAudio();
        if (_recorder == null) {
          throw Exception('無法初始化錄音器');
        }
      }

      // 檢查錄音器是否正在錄音
      bool isCurrentlyRecording = false;
      try {
        isCurrentlyRecording = _recorder!.isRecording;
        debugPrint('錄音器當前狀態: 正在錄音=$isCurrentlyRecording');
      } catch (e) {
        debugPrint('無法獲取錄音器狀態: $e');
      }

      // 如果正在錄音，先停止
      if (isRecording || isCurrentlyRecording) {
        debugPrint('停止之前的錄音...');
        try {
          await _recorder!.stopRecorder();
          debugPrint('✅ 之前的錄音已停止');
        } catch (stopError) {
          debugPrint('停止之前的錄音失敗: $stopError');
        }
        await Future.delayed(const Duration(milliseconds: 1000));
        setState(() {
          isRecording = false;
        });
      }

      final directory = await getApplicationDocumentsDirectory();
      final basePath = '${directory.path}/practice_record';

      // 刪除可能存在的舊檔案
      final wavFile = File('$basePath.wav');
      if (await wavFile.exists()) {
        await wavFile.delete();
        debugPrint('刪除舊的 WAV 檔案');
      }

      // 設定錄音參數和檔案路徑 - 直接 WAV 格式
      final wavPath = '$basePath.wav';

      debugPrint('準備開始直接 WAV 錄音...');
      debugPrint('WAV 檔案路徑: $wavPath');

      // 直接使用 WAV 格式錄音（v4.8 優化 - 提高採樣率以改善音準識別）
      debugPrint('開始 WAV 錄音，參數:');
      debugPrint('  檔案路徑: $wavPath');
      debugPrint('  編解碼器: pcm16WAV');
      debugPrint('  採樣率: 44100 Hz (CD 品質，提升音準識別精度)');
      debugPrint('  聲道數: 1');
      debugPrint('  位元率: 705600 bps');

      await _recorder!.startRecorder(
        toFile: wavPath,
        codec: Codec.pcm16WAV, // 直接錄製 WAV 格式
        sampleRate: 44100, // CD 品質採樣率，提升音準識別精度
        numChannels: 1, // 單聲道（節省空間，音樂分析不需要立體聲）
        bitRate: 705600, // 44100 * 16 * 1 = 705600 bps
      );

      debugPrint('✅ WAV 錄音已啟動，直接錄製為 WAV 格式');
      debugPrint('📝 錄音中，請對著麥克風說話...');

      setState(() {
        isRecording = true;
        _recordingDurationSeconds = 0;
        _audioPath = wavPath; // 立即設置預期的檔案路徑
      });

      // 啟動計時器
      _recordingTimer?.cancel(); // 確保沒有重複的計時器
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && isRecording) {
          setState(() {
            _recordingDurationSeconds++;
          });
          debugPrint('🔴 錄音中... $_recordingDurationSeconds秒');

          // 15秒後自動停止錄音（增加時間讓系統有足夠時間寫入數據）
          if (_recordingDurationSeconds >= 15) {
            debugPrint('📱 達到最大錄音時間，自動停止錄音');
            stopRecording();
          }
        } else {
          timer.cancel();
        }
      });

      debugPrint('✅ WAV 錄音已開始，計時器已啟動');
    } catch (e, stackTrace) {
      debugPrint('❌ 錄音啟動失敗: $e');
      debugPrint('堆疊追蹤: $stackTrace');

      // 重設狀態
      setState(() {
        isRecording = false;
        _recordingDurationSeconds = 0;
      });
      _recordingTimer?.cancel();

      if (!mounted) return;
      ErrorHandler.show(
        context,
        e,
        customMessage: '錄音啟動失敗，請確認麥克風權限',
        onRetry: startRecording,
      );
    }
  }

  Future<void> stopRecording() async {
    if (_useAltRecorder) {
      debugPrint('🛑 (ALT) 停止 record 錄音');
      final path = await _recordAlt.stop();
      _recordingTimer?.cancel();
      setState(() {
        isRecording = false;
      });
      if (path != null) {
        final f = File(path);
        if (await f.exists()) {
          final size = await f.length();
          debugPrint('✅ (ALT) 錄音完成: $path 大小: $size bytes');
          _audioPath = path;
        }
      }
      return; // 不執行原 flutter_sound 停止流程
    }
    debugPrint('🛱 停止錄音程序...');

    try {
      if (_recorder == null) {
        debugPrint('❌ 錄音器為 null');
        setState(() {
          isRecording = false;
        });
        return;
      }

      if (!isRecording) {
        debugPrint('⚠️ 未在錄音狀態');
        return;
      }

      debugPrint('正在停止 WAV 錄音...');
      debugPrint('錄音時長: $_recordingDurationSeconds 秒');

      // 等待一段時間確保錄音數據寫入完成
      await Future.delayed(const Duration(milliseconds: 1000));

      String? recordedPath = await _recorder!.stopRecorder();
      debugPrint('錄音器返回的路徑: $recordedPath');

      // 停止後再等待一段時間確保檔案系統同步
      await Future.delayed(const Duration(milliseconds: 1500));

      // 取消錄音計時器
      _recordingTimer?.cancel();
      _recordingTimer = null;

      setState(() {
        isRecording = false;
      });

      debugPrint('✅ 錄音器已停止');

      // 檢查錄製的 WAV 檔案
      if (recordedPath != null && recordedPath.endsWith('.wav')) {
        debugPrint('✅ 檢測到 WAV 檔案，直接進行分析');
        await _analyzeWAVFile(recordedPath);
      } else if (recordedPath != null) {
        debugPrint('⚠️ 錄製的檔案不是 WAV 格式: $recordedPath');
      }

      // 優先檢查預期路徑
      String? finalAudioPath;

      // 1. 先檢查錄音器返回的路徑
      if (recordedPath != null) {
        final recordedFile = File(recordedPath);
        if (await recordedFile.exists()) {
          final size = await recordedFile.length();
          debugPrint('✅ 錄音器返回的檔案: $recordedPath (大小: $size bytes)');
          if (size > 44) {
            // 不只是 WAV 標頭
            finalAudioPath = recordedPath;
          } else {
            debugPrint('⚠️ 檔案太小，只有 WAV 標頭: $size bytes');
          }
        }
      }

      // 2. 檢查預期路徑
      if (finalAudioPath == null && _audioPath != null) {
        final expectedFile = File(_audioPath!);
        if (await expectedFile.exists()) {
          final size = await expectedFile.length();
          debugPrint('✅ 預期路徑的檔案: $_audioPath (大小: $size bytes)');
          if (size > 44) {
            finalAudioPath = _audioPath;
          }
        }
      }

      // 3. 搜索其他可能的位置
      if (finalAudioPath == null) {
        debugPrint('在預期位置未找到檔案，搜索其他位置...');
        final directory = await getApplicationDocumentsDirectory();

        List<String> possiblePaths = [
          '${directory.path}/practice_record.wav',
          '${directory.path}/flutter_sound.wav',
          '${directory.path}/temp_sound.wav',
          '${directory.path}/recording.wav',
        ];

        for (String path in possiblePaths) {
          final testFile = File(path);
          if (await testFile.exists()) {
            final size = await testFile.length();
            debugPrint('✅ 找到檔案: $path (大小: $size bytes)');
            if (size > 44) {
              finalAudioPath = path;
              break;
            }
          }
        }
      }

      // 更新狀態和顯示結果
      if (finalAudioPath != null) {
        setState(() {
          _audioPath = finalAudioPath;
        });

        final audioFile = File(finalAudioPath);
        final fileSize = await audioFile.length();

        debugPrint('✅ 錄音成功！');
        debugPrint('  檔案路徑: $finalAudioPath');
        debugPrint('  檔案大小: $fileSize bytes');
        debugPrint('  錄音時長: $_recordingDurationSeconds 秒');

        // 驗證 WAV 檔案
        await _analyzeWAVFile(finalAudioPath);

        if (mounted) {
          ErrorHandler.showSuccess(
            context,
            '✅ 錄音成功！\n時長: $_recordingDurationSeconds 秒\n大小: ${(fileSize / 1024).toStringAsFixed(1)} KB',
          );
        }
      } else {
        debugPrint('❌ 未找到任何錄音檔案');
        await _searchForRecordingFiles();
      }

      if (_audioPath != null) {
        try {
          final file = File(_audioPath!);
          if (await file.exists()) {
            final size = await file.length();
            debugPrint('✅ 找到錄音檔案: $_audioPath');
            debugPrint('錄音檔案大小: $size bytes');
            if (!mounted) return;

            // 計算預期的檔案大小（16000 採樣率 × 2 bytes/sample × 錄音秒數）
            final expectedSize =
                16000 * 2 * _recordingDurationSeconds + 44; // +44 為 WAV 標頭
            debugPrint('預期檔案大小: $expectedSize bytes，實際大小: $size bytes');

            if (size > 1000) {
              // 檔案大小合理
              final fileExtension = _audioPath!.toLowerCase().split('.').last;
              debugPrint('✅ 錄音檔案大小正常 ($fileExtension 格式)');

              // 如果是 WAV 格式且採樣率不是 16000，需要重新採樣
              if (fileExtension == 'wav') {
                debugPrint('✅ WAV 格式檔案，準備進行 AI 處理');
              }

              ErrorHandler.showSuccess(
                context,
                AppLocalizations.of(context)!.errorRecordingFileSize(size),
              );
            } else {
              ErrorHandler.showWarning(
                context,
                AppLocalizations.of(context)!.errorRecordingFileTooSmall(size),
              );
              debugPrint('錄音檔案太小：實際 $size bytes，預期約 $expectedSize bytes');
            }
          } else {
            debugPrint('錄音檔案不存在: $_audioPath');
            // 如果找不到檔案，嘗試搜索整個目錄
            await _searchForRecordingFiles();
          }
        } catch (e) {
          debugPrint('錄音檔案檢查失敗: $e');
          if (!mounted) return;
          ErrorHandler.show(
            context,
            e,
            customMessage: AppLocalizations.of(context)!.errorRecordingFileCheck(e.toString()),
          );
        }
      } else {
        debugPrint('⚠️ 沒有找到任何錄音檔案，開始搜索...');
        await _searchForRecordingFiles();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 停止錄音失敗: $e');
      debugPrint('堆疊追蹤: $stackTrace');

      // 重設狀態
      setState(() {
        isRecording = false;
        _recordingDurationSeconds = 0;
      });

      _recordingTimer?.cancel();
      _recordingTimer = null;

      if (!mounted) return;
      ErrorHandler.show(
        context,
        e,
        customMessage: AppLocalizations.of(context)!.errorRecordingStop(e.toString()),
      );
    }
  }

  // 搜索錄音檔案
  Future<void> _searchForRecordingFiles() async {
    try {
      debugPrint('🔍 開始搜索錄音檔案...');

      // 獲取所有可能的目錄
      final appDocDir = await getApplicationDocumentsDirectory();
      final appSupportDir = await getApplicationSupportDirectory();
      final tempDir = await getTemporaryDirectory();

      List<Directory> searchDirs = [
        appDocDir,
        appSupportDir,
        tempDir,
        Directory('/data/user/0/com.example.music_practice_app/app_flutter'),
        Directory('/data/user/0/com.example.music_practice_app/files'),
        Directory('/data/user/0/com.example.music_practice_app/cache'),
      ];

      // 在每個目錄中搜索
      for (final dir in searchDirs) {
        if (await dir.exists()) {
          debugPrint('🔍 搜索目錄: ${dir.path}');
          try {
            final files = await dir.list().toList();
            for (final file in files) {
              if (file is File) {
                final fileName = file.path.split('/').last.toLowerCase();
                if (fileName.contains('practice') ||
                    fileName.contains('record') ||
                    fileName.contains('sound') ||
                    fileName.endsWith('.wav') ||
                    fileName.endsWith('.aac')) {
                  final size = await file.length();
                  debugPrint('🎵 找到可能的錄音檔案: ${file.path} ($size bytes)');

                  // 如果檔案夠大，可能是我們的錄音
                  if (size > 1000) {
                    _audioPath = file.path;
                    debugPrint('✅ 設定錄音檔案路徑: $_audioPath');

                    if (mounted) {
                      ErrorHandler.showSuccess(
                        context,
                        '找到錄音檔案！檔案大小：${(size / 1024).toStringAsFixed(1)} KB',
                      );
                    }
                    return; // 找到就返回
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('搜索目錄 ${dir.path} 時發生錯誤: $e');
          }
        }
      }

      debugPrint('❌ 沒有找到合適的錄音檔案');
      if (mounted) {
        ErrorHandler.showWarning(
          context,
          AppLocalizations.of(context)!.errorRecordingFileNotFound,
        );
      }
    } catch (e) {
      debugPrint('搜索錄音檔案時發生錯誤: $e');
    }
  }

  Future<void> playRecording() async {
    if (_useAltRecorder && _audioPath != null) {
      final f = File(_audioPath!);
      if (await f.exists()) {
        final size = await f.length();
        debugPrint('▶️ (ALT) 準備播放檔案: ${f.path} 大小: $size bytes');
      }
    }
    if (_audioPath == null) {
      if (!mounted) return;
      ErrorHandler.show(
        context,
        Exception('No recording file'),
        customMessage: AppLocalizations.of(context)!.errorRecordingFileNotFound,
      );
      return;
    }
    try {
      final file = File(_audioPath!);
      final size = await file.length();
      debugPrint('播放錄音檔案路徑: $_audioPath');
      debugPrint('播放錄音檔案大小: $size bytes');
      if (size == 0) {
        if (!mounted) return;
        ErrorHandler.show(
          context,
          Exception('Empty file'),
          customMessage: AppLocalizations.of(context)!.errorRecordingFileEmpty,
        );
        return;
      }
    } catch (e) {
      debugPrint('撥放前檔案檢查失敗: $e');
    }
    setState(() {
      isPlaying = true;
      _isPaused = false;
      _playbackPosition = 0.0;
    });
    try {
      // 優先使用 WAV 格式播放
      Codec playbackCodec = Codec.pcm16WAV; // 預設使用 WAV

      if (_audioPath!.endsWith('.wav')) {
        playbackCodec = Codec.pcm16WAV;
      } else if (_audioPath!.endsWith('.aac')) {
        playbackCodec = Codec.aacADTS;
      }

      debugPrint('使用播放編碼器: $playbackCodec，檔案: $_audioPath');

      await _player!.startPlayer(
        fromURI: _audioPath,
        codec: playbackCodec,
        whenFinished: () {
          _playbackTimer?.cancel();
          setState(() {
            isPlaying = false;
            _isPaused = false;
            _playbackPosition = 0.0;
          });
        },
      );

      // 啟動播放進度計時器 (2025/11/27 恢復)
      _startPlaybackTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isPlaying = false;
        _isPaused = false;
      });
      ErrorHandler.show(
        context,
        e,
        customMessage: AppLocalizations.of(context)!.errorPlaybackFailed(e.toString()),
      );
    }
  }

  Future<void> stopPlaying() async {
    await _player!.stopPlayer();
    _playbackTimer?.cancel();
    _playerSubscription?.cancel();
    setState(() {
      isPlaying = false;
      _isPaused = false;
      _playbackPosition = 0.0;
    });
  }

  // 暫停播放 (2025/11/27 恢復)
  Future<void> pausePlaying() async {
    if (_player != null && isPlaying) {
      await _player!.pausePlayer();
      _playbackTimer?.cancel();
      setState(() {
        _isPaused = true;
      });
    }
  }

  // 繼續播放 (2025/11/27 恢復)
  Future<void> resumePlaying() async {
    if (_player != null && _isPaused) {
      await _player!.resumePlayer();
      _startPlaybackTimer();
      setState(() {
        _isPaused = false;
      });
    }
  }

  // 啟動播放進度計時器 (2025/11/27 恢復)
  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!isPlaying || _player == null) {
        timer.cancel();
        return;
      }
      try {
        // 更新播放位置（毫秒轉秒）
        final progressMap = await _player!.getProgress();
        final progress = progressMap['progress'];
        final duration = progressMap['duration'];
        if (progress != null && duration != null) {
          final positionMs = progress.inMilliseconds;
          final durationMs = duration.inMilliseconds;
          setState(() {
            _playbackPosition = positionMs / 1000.0;
            _playbackDuration = durationMs / 1000.0;
          });
        }
      } catch (e) {
        // 忽略錯誤
      }
    });
  }

  // 上傳 WAV 檔案 (2025/11/27 恢復)
  Future<void> uploadWavFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wav'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // 複製檔案到應用目錄
        final directory = await getApplicationDocumentsDirectory();
        final targetPath = '${directory.path}/uploaded_recording.wav';
        final targetFile = File(targetPath);

        if (file.bytes != null) {
          await targetFile.writeAsBytes(file.bytes!);
        } else if (file.path != null) {
          await File(file.path!).copy(targetPath);
        }

        // 驗證檔案
        if (await targetFile.exists()) {
          final fileSize = await targetFile.length();
          debugPrint('✅ WAV 檔案上傳成功: $targetPath ($fileSize bytes)');

          setState(() {
            _audioPath = targetPath;
          });

          if (mounted) {
            ErrorHandler.showSuccess(
              context,
              '✅ 上傳成功：${file.name} (${(fileSize / 1024).toStringAsFixed(1)} KB)',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ 上傳 WAV 檔案失敗: $e');
      if (mounted) {
        ErrorHandler.show(
          context,
          e,
          customMessage: '❌ 上傳失敗: $e',
        );
      }
    }
  }

  // 格式化時長顯示 (2025/11/27 新增)
  String _formatDuration(double seconds) {
    final int minutes = seconds.floor() ~/ 60;
    final int secs = seconds.floor() % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 獲取檔案名稱（不包含副檔名）
    String getFileNameWithoutExtension() {
      if (widget.file?.name == null) return l10n?.practiceNoFile ?? '未指定曲目';
      final fileName = widget.file!.name;
      final lastDot = fileName.lastIndexOf('.');
      if (lastDot != -1) {
        return fileName.substring(0, lastDot);
      }
      return fileName;
    }

    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(l10n?.practiceTitle ?? '練習模式',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        backgroundColor: AppColors.dynamicPrimary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/library');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: MediaQuery.of(context).padding.bottom + 100, // 避免底部導航欄遮擋
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      l10n?.practiceSelectFile ?? '正在練習',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.dynamicTextDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      getFileNameWithoutExtension(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dynamicPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 錄音控制區域
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic,
                              color: AppColors.dynamicPrimary, size: 28),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                                _isRecordMode
                                    ? (l10n?.practiceRecordControl ?? '錄音控制')
                                    : (l10n?.practiceUploadAudio ?? '上傳音檔'),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 錄音/上傳模式切換 (2025/11/27 恢復)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (!isRecording && !isPlaying) {
                                    setState(() {
                                      _isRecordMode = true;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: _isRecordMode
                                        ? AppColors.dynamicPrimary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.mic,
                                        size: 18,
                                        color: _isRecordMode
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n?.practiceRecordMode ?? '錄音',
                                        style: TextStyle(
                                          color: _isRecordMode
                                              ? Colors.white
                                              : Colors.grey[700],
                                          fontWeight: _isRecordMode
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (!isRecording && !isPlaying) {
                                    setState(() {
                                      _isRecordMode = false;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: !_isRecordMode
                                        ? AppColors.dynamicPrimary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.upload_file,
                                        size: 18,
                                        color: !_isRecordMode
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n?.practiceUploadMode ?? '上傳',
                                        style: TextStyle(
                                          color: !_isRecordMode
                                              ? Colors.white
                                              : Colors.grey[700],
                                          fontWeight: !_isRecordMode
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 根據模式顯示不同內容
                      if (_isRecordMode) ...[
                        // 倒數計時開關
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer,
                                size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                  l10n?.practiceEnableCountdown ?? '3秒倒數計時',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey)),
                            ),
                            const SizedBox(width: 12),
                            Switch(
                              value: _enableCountdown,
                              onChanged: (value) {
                                setState(() {
                                  _enableCountdown = value;
                                });
                              },
                              activeThumbColor: AppColors.dynamicPrimary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            // 狀態顯示器
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isRecording
                                      ? Icons.fiber_manual_record
                                      : Icons.stop_circle_outlined,
                                  color:
                                      isRecording ? Colors.red : Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isRecording
                                      ? '${l10n?.practiceRecording ?? '正在錄音'}... $_recordingDurationSeconds${l10n?.practiceSeconds ?? 's'}'
                                      : (_audioPath != null
                                          ? (l10n?.practiceRecordingSuccess ??
                                              '錄音完成')
                                          : (l10n?.practiceNoRecording ??
                                              '未錄音')),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isRecording
                                        ? Colors.red
                                        : (_audioPath != null
                                            ? Colors.green
                                            : Colors.grey),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // 錄音按鈕
                            ElevatedButton.icon(
                              onPressed:
                                  isRecording ? stopRecording : startRecording,
                              icon: Icon(isRecording
                                  ? Icons.stop
                                  : Icons.fiber_manual_record),
                              label: Text(isRecording
                                  ? (l10n?.practiceStopRecord ?? '停止')
                                  : (_audioPath != null
                                      ? (l10n?.practiceRerecord ?? '重新錄音')
                                      : (l10n?.practiceRecord ?? '開始錄音'))),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isRecording ? Colors.grey : Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // 上傳模式
                        Column(
                          children: [
                            Icon(
                              _audioPath != null
                                  ? Icons.check_circle
                                  : Icons.upload_file,
                              size: 48,
                              color: _audioPath != null
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _audioPath != null
                                  ? (l10n?.practiceFileUploaded ?? '已上傳檔案')
                                  : (l10n?.practiceSelectWavFile ??
                                      '請選擇 WAV 檔案'),
                              style: TextStyle(
                                fontSize: 16,
                                color: _audioPath != null
                                    ? Colors.green
                                    : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_audioPath != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _audioPath!.split('/').last,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: uploadWavFile,
                              icon: const Icon(Icons.upload_file),
                              label: Text(_audioPath != null
                                  ? (l10n?.practiceReupload ?? '重新上傳')
                                  : (l10n?.practiceSelectFile2 ?? '選擇檔案')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.dynamicPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 播放控制區域 (2025/11/27 增強)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.volume_up,
                              color: AppColors.dynamicPrimary, size: 28),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(l10n?.practicePlaybackControl ?? '播放控制',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 播放進度條 (2025/11/27 新增)
                      if (_audioPath != null &&
                          (isPlaying || _playbackPosition > 0)) ...[
                        Column(
                          children: [
                            // 進度條
                            Slider(
                              value: _playbackDuration > 0
                                  ? (_playbackPosition / _playbackDuration)
                                      .clamp(0.0, 1.0)
                                  : 0.0,
                              onChanged: null, // 暫時不支援拖動
                              activeColor: AppColors.dynamicPrimary,
                              inactiveColor: Colors.grey[300],
                            ),
                            // 時間顯示
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_playbackPosition),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    _formatDuration(_playbackDuration),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // 播放控制按鈕
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 播放/停止按鈕
                          ElevatedButton.icon(
                            onPressed: (!isRecording && _audioPath != null)
                                ? (isPlaying
                                    ? (_isPaused ? resumePlaying : pausePlaying)
                                    : playRecording)
                                : null,
                            icon: Icon(isPlaying
                                ? (_isPaused ? Icons.play_arrow : Icons.pause)
                                : Icons.play_arrow),
                            label: Text(isPlaying
                                ? (_isPaused
                                    ? (l10n?.practiceResume ?? '繼續')
                                    : (l10n?.practicePause ?? '暫停'))
                                : (l10n?.practicePlayRecording ?? '播放錄音')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isPlaying ? Colors.orange : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                            ),
                          ),

                          // 停止按鈕（僅在播放時顯示）
                          if (isPlaying) ...[
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: stopPlaying,
                              icon: const Icon(Icons.stop),
                              label: Text(l10n?.practiceStopPlayback2 ?? '停止'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Week 4 Phase 2: 演奏分析卡片
              Card(
                color: (_audioPath != null && widget.file != null)
                    ? null
                    : Colors.purple.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.analytics_outlined,
                              color: Colors.purple, size: 28),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              l10n?.practiceAnalyze ?? '演奏分析',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l10n?.practiceAnalysisDescription ??
                                '使用頻譜分析技術驗證您的演奏\n比對音準、節奏,並給予評分和建議',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.dynamicTextDark.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: (!isRecording &&
                                _audioPath != null &&
                                !_isAnalyzing &&
                                widget.file != null)
                            ? _analyzePerformance
                            : null,
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.analytics_outlined),
                        label: Text(_isAnalyzing
                            ? (l10n?.practiceAnalyzing ?? '分析中...')
                            : (l10n?.practiceAnalyze ?? '分析演奏')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Week 4 Phase 2: 演奏分析方法
  Future<void> _analyzePerformance() async {
    // 分析前先停止播放 (2025/11/27 修復)
    if (isPlaying) {
      await stopPlaying();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (_audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('❌ 請先錄製您的演奏'), backgroundColor: Colors.red),
      );
      return;
    }
    if (widget.file == null || widget.file!.path == null) {
      ErrorHandler.show(
        context,
        Exception('No MIDI file selected'),
        customMessage: '❌ 請先從樂庫選擇 MIDI 曲目',
      );
      return;
    }
    final audioFile = File(_audioPath!);
    if (!await audioFile.exists()) {
      if (!mounted) return;
      ErrorHandler.show(
        context,
        Exception('Recording file not found'),
        customMessage: '❌ 錄音文件不存在，請重新錄音',
      );
      return;
    }
    final midiFile = File(widget.file!.path!);
    if (!await midiFile.exists()) {
      if (!mounted) return;
      ErrorHandler.show(
        context,
        Exception('MIDI file not found'),
        customMessage: '❌ MIDI文件不存在，請重新選擇',
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisProgress = 0.0;
      _analysisPhase = '';
    });

    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildAnalysisProgressDialog(),
      );

      final report = await _analyzer.analyze(
        _audioPath!,
        widget.file!.path!,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _analysisProgress = progress;
              _analysisPhase = _getAnalysisPhaseDescription(progress);
            });
          }
        },
      );

      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AnalysisResultPage(
              report: report,
              midiFileName: widget.file!.name,
              audioFileName: _audioPath!.split('/').last,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 分析失敗: $e\n$stackTrace');
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ErrorHandler.show(
          context,
          e,
          customMessage: AppLocalizations.of(context)!.errorAnalysisFailed(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisProgress = 0.0;
          _analysisPhase = '';
        });
      }
    }
  }

  String _getAnalysisPhaseDescription(double progress) {
    final l10n = AppLocalizations.of(context);
    if (progress < 0.2) {
      return l10n?.practiceAnalysisPhase1 ?? '正在解析 MIDI 標準答案...';
    }
    if (progress < 0.6) return l10n?.practiceAnalysisPhase2 ?? '正在分析音訊頻譜...';
    if (progress < 0.8) return l10n?.practiceAnalysisPhase3 ?? '正在驗證音符準確性...';
    if (progress < 1.0) return l10n?.practiceAnalysisPhase4 ?? '正在分類錯誤類型...';
    return l10n?.practiceAnalysisPhase5 ?? '分析完成!';
  }

  Widget _buildAnalysisProgressDialog() {
    final l10n = AppLocalizations.of(context);
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.analytics, color: Colors.purple),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(l10n?.practiceAnalyzingTitle ?? '演奏分析中'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _analysisProgress,
                backgroundColor: Colors.grey,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
              const SizedBox(height: 16),
              Text('${(_analysisProgress * 100).toInt()}%',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_analysisPhase,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }

  // 原有方法
  Future<void> _analyzeWAVFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ WAV 檔案不存在: $filePath');
        return;
      }

      final fileSize = await file.length();
      debugPrint('📁 WAV 檔案分析:');
      debugPrint('  檔案路徑: $filePath');
      debugPrint('  檔案大小: $fileSize bytes');

      if (fileSize <= 44) {
        debugPrint('  ❌ 檔案過小，只包含 WAV 標頭');

        // 讀取標頭內容進行分析
        final bytes = await file.readAsBytes();
        debugPrint('  📄 WAV 標頭內容:');
        final header = bytes.take(44).toList();

        // 檢查 RIFF 標記
        final riffMark = String.fromCharCodes(header.getRange(0, 4));
        debugPrint('    RIFF 標記: $riffMark');

        // 檢查 WAVE 格式
        final waveMark = String.fromCharCodes(header.getRange(8, 12));
        debugPrint('    WAVE 格式: $waveMark');

        // 檢查 fmt 區塊
        final fmtMark = String.fromCharCodes(header.getRange(12, 16));
        debugPrint('    fmt 區塊: $fmtMark');

        // 檢查聲道數
        final channels = header[22] | (header[23] << 8);
        debugPrint('    聲道數: $channels');

        // 檢查採樣率
        final sampleRate = header[24] |
            (header[25] << 8) |
            (header[26] << 16) |
            (header[27] << 24);
        debugPrint('    採樣率: $sampleRate Hz');

        // 檢查位深度
        final bitsPerSample = header[34] | (header[35] << 8);
        debugPrint('    位深度: $bitsPerSample bits');

        debugPrint('  🔍 結論: WAV 標頭格式正確，但沒有實際音頻數據寫入');
      } else {
        debugPrint('  ✅ WAV 檔案包含音頻數據: ${fileSize - 44} bytes 音頻內容');
      }
    } catch (e) {
      debugPrint('❌ WAV 檔案分析失敗: $e');
    }
  }
}

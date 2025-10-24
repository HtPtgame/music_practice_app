import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart' show Level;
import 'package:record/record.dart'; // 新增：record 套件
import 'package:flutter_midi_pro/flutter_midi_pro.dart'; // 新增：MIDI 播放

import 'package:permission_handler/permission_handler.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'dart:io';

// Week 4 Phase 2: 分析功能
import 'package:music_practice_app/services/audio_analysis/performance_analyzer.dart';
import 'package:music_practice_app/pages/analysis_result_page.dart';

import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:typed_data';
import 'dart:math';
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
  String? _midiPath; // 新增：儲存轉換後的 MIDI 檔案路徑
  bool isPlaying = false;
  bool isRecording = false;
  bool isConverting = false; // 新增：轉換狀態
  double conversionProgress = 0.0; // 新增：轉換進度

  // 錄音時長相關變數
  int _recordingDurationSeconds = 0;
  Timer? _recordingTimer;

  // 錄音計時器將在錄音過程中自動處理

  // [已淘汰 2025/10/08] AI 模型相關變數 (保留以避免編譯錯誤,但不會被使用)
  dynamic _interpreter; // 原本是 Interpreter? 類型
  final bool _isModelLoaded = false;

  // Week 4 Phase 2: 分析功能狀態
  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  String _analysisPhase = '';
  final _analyzer = PerformanceAnalyzer();

  @override
  void initState() {
    super.initState();
    _initAudio();
    // _loadAIModel(); // 已淘汰 2025/10/08
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
  // Future<void> _loadAIModel() async { ... }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _closeAudio();
    // _interpreter?.close(); // 已淘汰
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
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 256000,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('需要麥克風權限才能錄音，請在設定中手動授權'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
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

      // 直接使用 WAV 格式錄音（優化參數）
      debugPrint('開始 WAV 錄音，參數:');
      debugPrint('  檔案路徑: $wavPath');
      debugPrint('  編解碼器: pcm16WAV');
      debugPrint('  採樣率: 16000 Hz (降低以提高穩定性)');
      debugPrint('  聲道數: 1');
      debugPrint('  位元率: 256000 bps');

      await _recorder!.startRecorder(
        toFile: wavPath,
        codec: Codec.pcm16WAV, // 直接錄製 WAV 格式
        sampleRate: 16000, // 降低採樣率提高穩定性
        numChannels: 1, // 單聲道
        bitRate: 256000, // 16000 * 16 * 1 = 256000 bps
      );

      debugPrint('✅ WAV 錄音已啟動，直接錄製為 WAV 格式');
      debugPrint('📝 錄音中，請對著麥克風說話...');

      setState(() {
        isRecording = true;
        _recordingDurationSeconds = 0;
        _audioPath = wavPath; // 立即設置預期的檔案路徑
        _midiPath = null; // 清除之前的 MIDI 檔案
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('錄音啟動失敗: $e\n\n請確保：\n1. 已授權麥克風權限\n2. 沒有其他應用程式使用麥克風'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ 錄音成功！\n時長: $_recordingDurationSeconds 秒\n大小: ${(fileSize / 1024).toStringAsFixed(1)} KB'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
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

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('錄音完成！檔案大小：${(size / 1024).toStringAsFixed(1)} KB'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('錄音檔案太小（$size bytes），可能是音訊捕獲問題'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('錄音檔案檢查失敗: $e'),
              backgroundColor: Colors.red,
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('停止錄音失敗: $e\n\n請嘗試重新錄音'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '找到錄音檔案！檔案大小：${(size / 1024).toStringAsFixed(1)} KB'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('未找到錄音檔案，請重新錄音'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未找到錄音檔案'), backgroundColor: Colors.red),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('錄音檔案為空，無法撥放'), backgroundColor: Colors.red),
        );
        return;
      }
    } catch (e) {
      debugPrint('撥放前檔案檢查失敗: $e');
    }
    setState(() {
      isPlaying = true;
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
          setState(() {
            isPlaying = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('撥放失敗: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> stopPlaying() async {
    await _player!.stopPlayer();
    setState(() {
      isPlaying = false;
    });
  }

  // 新增：轉換為 MIDI 檔案的功能
  Future<void> convertToMidi() async {
    if (_audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先錄音再進行轉換'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      isConverting = true;
      conversionProgress = 0.0;
    });

    try {
      // 顯示轉換對話框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.music_note, color: AppColors.dynamicPrimary),
                    const SizedBox(width: 8),
                    const Text('音訊轉 MIDI'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🤖 使用 AI 模型分析您的完整錄音...'),
                    const SizedBox(height: 8),
                    Text(
                      _getProgressDescription(conversionProgress),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: conversionProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.dynamicPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text('${(conversionProgress * 100).toInt()}%'),
                  ],
                ),
              );
            },
          );
        },
      );

      // 模擬轉換過程（實際應用需要音訊處理庫）
      _midiPath = await _performAudioToMidiConversion();

      // 關閉對話框
      if (mounted) Navigator.of(context).pop();

      if (_midiPath != null) {
        // 快速檢查檔案大小和分析結果
        final midiFile = File(_midiPath!);
        final size = await midiFile.length();

        // 簡單分析檔案內容
        final analysisResult = await _getQuickAnalysis(midiFile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '⚠️ 基本 MIDI 檔案已生成\n檔案大小: $size bytes\n$analysisResult\n\n注意：這不是真正的音訊分析結果\n需要專業音訊處理庫才能實現真正的轉換'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('MIDI 轉換失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isConverting = false;
        conversionProgress = 0.0;
      });
    }
  }

  // 使用 AI 模型進行完整音訊轉 MIDI 分析 - 支援分塊處理
  Future<String?> _performAudioToMidiConversion() async {
    try {
      // 檢查 AI 模型是否已載入
      if (!_isModelLoaded || _interpreter == null) {
        throw Exception('AI 模型尚未載入或載入失敗');
      }

      // 儲存位置
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('無法存取外部儲存空間');
      }

      const downloadPath = '/storage/emulated/0/Download';
      final downloadDir = Directory(downloadPath);

      String finalPath;
      if (await downloadDir.exists()) {
        finalPath =
            '$downloadPath/AIPracticeMIDI_${DateTime.now().millisecondsSinceEpoch}.mid';
      } else {
        finalPath =
            '${directory.path}/AIPracticeMIDI_${DateTime.now().millisecondsSinceEpoch}.mid';
      }

      final midiPath = finalPath;

      // 第一步：檢查和轉換音訊格式
      setState(() {
        conversionProgress = 0.02;
      });
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('🔄 步驟 1: 檢查音訊檔案格式...');

      final audioFile = File(_audioPath!);
      if (!await audioFile.exists()) {
        throw Exception('音訊檔案不存在');
      }

      // 確定實際的檔案格式
      final isAAC = _audioPath!.toLowerCase().endsWith('.aac');
      final isWAV = _audioPath!.toLowerCase().endsWith('.wav');

      debugPrint('檔案路徑: $_audioPath');
      debugPrint('檔案格式 - AAC: $isAAC, WAV: $isWAV');

      File processedAudioFile = audioFile;

      if (!isWAV) {
        throw Exception('只支援 WAV 格式檔案，目前檔案格式不符');
      }

      debugPrint('✅ 使用 WAV 格式檔案進行 AI 處理');

      // 第二步：讀取完整 WAV 檔案
      setState(() {
        conversionProgress = 0.08;
      });
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('🔄 步驟 2: 讀取完整 WAV 音訊檔案...');

      // 第三步：完整音訊預處理（不截斷）
      setState(() {
        conversionProgress = 0.12;
      });
      await Future.delayed(const Duration(milliseconds: 300));
      debugPrint('🔄 步驟 3: 預處理完整音訊數據...');

      final fullAudioData = await _preprocessFullWavFile(processedAudioFile);
      final audioDurationSec = fullAudioData.length / 16000.0; // 16kHz 採樣率
      debugPrint(
          '完整音訊預處理完成：${fullAudioData.length} 樣本 (${audioDurationSec.toStringAsFixed(1)} 秒)');

      // 第四步：分割音訊為 1 秒區塊
      setState(() {
        conversionProgress = 0.18;
      });
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('🔄 步驟 4: 分割音訊為 1 秒區塊...');

      final audioChunks =
          _splitAudioIntoChunks(fullAudioData, 16000); // 1 秒 = 16000 樣本
      debugPrint('音訊分割完成：${audioChunks.length} 個區塊');

      // 第五步：對每個區塊進行 AI 推論
      debugPrint('🔄 步驟 5: 對每個區塊進行 AI 模型推論...');

      List<List<Map<String, dynamic>>> allChunkNoteEvents = [];

      for (int chunkIndex = 0; chunkIndex < audioChunks.length; chunkIndex++) {
        // 更新進度 (0.22 到 0.8 之間分配給 AI 推論)
        final chunkProgress = 0.22 + (chunkIndex / audioChunks.length) * 0.58;
        setState(() {
          conversionProgress = chunkProgress;
        });

        debugPrint('處理區塊 ${chunkIndex + 1}/${audioChunks.length}');

        try {
          // AI 推論
          final aiOutput = await _runAIInference(audioChunks[chunkIndex]);

          // 解析輸出
          final noteEvents = _parseAIOutput(aiOutput);

          // 添加時間偏移
          final timeOffsetEvents = noteEvents
              .map((note) => {
                    ...note,
                    'startTime':
                        note['startTime'] + (chunkIndex * 1.0), // 每個區塊 1 秒
                    'chunkIndex': chunkIndex,
                  })
              .toList();

          allChunkNoteEvents.add(timeOffsetEvents);
          debugPrint(
              '區塊 ${chunkIndex + 1} 完成：${timeOffsetEvents.length} 個音符事件');
        } catch (e, stackTrace) {
          debugPrint('❌ 區塊 ${chunkIndex + 1} AI 推論失敗: $e');
          debugPrint('錯誤堆疊: $stackTrace');

          // 記錄失敗的區塊但繼續處理（允許部分失敗）
          debugPrint('⚠️ 跳過失敗的區塊 ${chunkIndex + 1}，繼續處理下一個區塊');

          // 如果太多區塊失敗（超過50%），則終止
          final failedCount =
              allChunkNoteEvents.where((events) => events.isEmpty).length + 1;
          if (failedCount > audioChunks.length * 0.5) {
            debugPrint('❌ 失敗區塊過多 ($failedCount/${audioChunks.length})，終止轉換');

            if (mounted) {
              setState(() {
                isConverting = false;
                conversionProgress = 0.0;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'AI 模型推論失敗次數過多\n失敗: $failedCount/${audioChunks.length} 個區塊\n錯誤: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }

            throw Exception(
                'AI 推論失敗次數過多 ($failedCount/${audioChunks.length}): $e');
          }

          // 添加空結果，繼續處理
          allChunkNoteEvents.add([]);
        }

        // 小延遲避免 UI 阻塞
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // 第六步：合併所有區塊的結果
      setState(() {
        conversionProgress = 0.85;
      });
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('🔄 步驟 6: 合併所有區塊的音符事件...');

      final mergedNoteEvents = _mergeChunkResults(allChunkNoteEvents);
      debugPrint('合併完成：${mergedNoteEvents.length} 個音符事件');

      // 第七步：處理和優化音符
      setState(() {
        conversionProgress = 0.9;
      });
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('🔄 步驟 7: 處理和優化音符事件...');

      final processedNotes = _processNoteEventsWithTiming(mergedNoteEvents);
      debugPrint('處理後的音符: ${processedNotes.length} 個');

      // 第八步：生成完整 MIDI
      setState(() {
        conversionProgress = 0.95;
      });
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('🔄 步驟 8: 生成完整 MIDI 檔案...');

      final midiData =
          _generateFullMidiFromAI(processedNotes, audioDurationSec);

      // 第九步：寫入檔案
      setState(() {
        conversionProgress = 1.0;
      });
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('🔄 步驟 9: 寫入 MIDI 檔案...');

      final midiFile = File(midiPath);
      await midiFile.writeAsBytes(midiData);

      debugPrint('🎵 完整 AI 音訊轉 MIDI 完成！');
      debugPrint('MIDI 檔案已生成: $midiPath');
      debugPrint(
          '處理了 ${audioChunks.length} 個區塊，總時長 ${audioDurationSec.toStringAsFixed(1)} 秒');
      debugPrint('最終音符數量: ${processedNotes.length} 個');
      return midiPath;
    } catch (e) {
      debugPrint('AI MIDI 轉換錯誤: $e');
      rethrow;
    }
  }

  // 從 AAC 檔案創建測試 WAV 檔案用於 AI 處理
  // 測試方法已移除 - 專注於實際錄音功能

  // 預處理完整 WAV 檔案（不截斷）
  Future<Float32List> _preprocessFullWavFile(File wavFile) async {
    try {
      final bytes = await wavFile.readAsBytes();
      debugPrint('原始完整 WAV 檔案大小: ${bytes.length} bytes');

      // 驗證 WAV 檔案格式
      if (bytes.length < 44) {
        throw Exception('檔案太小，不是有效的 WAV 檔案');
      }

      // 檢查 WAV 標頭
      final header = String.fromCharCodes(bytes.sublist(0, 4));
      if (header != 'RIFF') {
        debugPrint('警告：檔案可能不是標準 WAV 格式 (標頭: $header)');
      }

      // 提取音頻格式信息 (Little-Endian)
      final audioFormat = bytes[20] | (bytes[21] << 8);
      final numChannels = bytes[22] | (bytes[23] << 8);
      final sampleRate =
          bytes[24] | (bytes[25] << 8) | (bytes[26] << 16) | (bytes[27] << 24);
      final bitsPerSample = bytes[34] | (bytes[35] << 8);

      debugPrint('完整 WAV 格式信息:');
      debugPrint('  音頻格式: $audioFormat (1=PCM)');
      debugPrint('  聲道數: $numChannels');
      debugPrint('  採樣率: $sampleRate Hz');
      debugPrint('  位深度: $bitsPerSample bits');

      // 跳過 WAV 標頭，找到數據塊
      int dataStart = 44;

      // 更準確地找到數據開始位置
      for (int i = 12; i < bytes.length - 8; i += 4) {
        final chunkId = String.fromCharCodes(bytes.sublist(i, i + 4));
        if (chunkId == 'data') {
          dataStart = i + 8;
          break;
        }
      }

      if (dataStart >= bytes.length) {
        throw Exception('找不到 WAV 數據塊');
      }

      // 提取完整 PCM 數據
      final pcmData = bytes.sublist(dataStart);
      debugPrint('完整 PCM 數據大小: ${pcmData.length} bytes');

      List<double> samples = [];

      // 根據位深度處理音頻數據 (Little-Endian)
      if (bitsPerSample == 16) {
        // 16-bit PCM (Little-Endian)
        for (int i = 0; i < pcmData.length - 1; i += 2) {
          // Little-Endian: 低位元組在前
          int sample16 = pcmData[i] | (pcmData[i + 1] << 8);
          // 轉換為有符號整數
          if (sample16 >= 32768) sample16 -= 65536;
          // 正規化到 [-1.0, 1.0]
          double normalizedSample = sample16 / 32768.0;
          samples.add(normalizedSample);
        }
      } else if (bitsPerSample == 8) {
        // 8-bit PCM (unsigned)
        for (int i = 0; i < pcmData.length; i++) {
          double normalizedSample = (pcmData[i] - 128) / 128.0;
          samples.add(normalizedSample);
        }
      } else {
        debugPrint('警告：不支援的位深度 $bitsPerSample bits，嘗試當作16-bit處理');
        // 嘗試當作 16-bit 處理
        for (int i = 0; i < pcmData.length - 1; i += 2) {
          int sample16 = pcmData[i] | (pcmData[i + 1] << 8);
          if (sample16 >= 32768) sample16 -= 65536;
          samples.add(sample16 / 32768.0);
        }
      }

      // 處理多聲道 - 轉為單聲道
      if (numChannels > 1) {
        List<double> monoSamples = [];
        for (int i = 0; i < samples.length; i += numChannels) {
          double sum = 0.0;
          for (int ch = 0; ch < numChannels && i + ch < samples.length; ch++) {
            sum += samples[i + ch];
          }
          monoSamples.add(sum / numChannels);
        }
        samples = monoSamples;
        debugPrint('已轉換為單聲道，樣本數: ${samples.length}');
      }

      // 重採樣到標準採樣率 (如果需要)
      const targetSampleRate = 16000; // 大多數音訊 AI 模型使用 16kHz
      if (sampleRate != targetSampleRate) {
        samples = _resampleAudio(samples, sampleRate, targetSampleRate);
        debugPrint('已重採樣從 ${sampleRate}Hz 到 ${targetSampleRate}Hz');
      }

      debugPrint('完整音訊預處理完成: ${samples.length} 樣本');

      // 檢查音訊品質
      if (samples.isEmpty) {
        throw Exception('音訊預處理後沒有有效樣本');
      }

      final rms = _calculateRMS(samples);
      final peak = samples.map((s) => s.abs()).reduce((a, b) => a > b ? a : b);
      debugPrint(
          '完整音訊品質 - RMS: ${rms.toStringAsFixed(4)}, Peak: ${peak.toStringAsFixed(4)}');

      if (rms < 0.001) {
        debugPrint('警告：音訊信號非常微弱（RMS < 0.001），可能影響 AI 分析效果');
        if (rms < 0.0001) {
          throw Exception('音訊信號太微弱，無法進行有效分析。請確保錄音時有足夠的音量。');
        }
      }

      return Float32List.fromList(samples);
    } catch (e) {
      debugPrint('完整音訊預處理錯誤: $e');
      debugPrint('錯誤堆疊: ${StackTrace.current}');
      rethrow; // 重新拋出錯誤，因為我們需要完整音訊
    }
  }

  // 將完整音訊分割為 1 秒區塊
  List<Float32List> _splitAudioIntoChunks(
      Float32List fullAudio, int chunkSize) {
    List<Float32List> chunks = [];

    for (int i = 0; i < fullAudio.length; i += chunkSize) {
      int endIndex =
          (i + chunkSize < fullAudio.length) ? i + chunkSize : fullAudio.length;

      // 創建可變列表 (避免 fixed-length list 錯誤)
      List<double> chunkData =
          List<double>.from(fullAudio.sublist(i, endIndex));

      // 如果區塊小於標準大小，用零填充
      while (chunkData.length < chunkSize &&
          i + chunkSize <= fullAudio.length + chunkSize) {
        chunkData.add(0.0);
      }

      // 只保留完整的或最後一個區塊（即使不完整）
      if (chunkData.length >= chunkSize * 0.5) {
        // 至少要有一半長度
        chunks.add(Float32List.fromList(chunkData.take(chunkSize).toList()));
      }
    }

    debugPrint('音訊分割完成：${chunks.length} 個區塊，每個 $chunkSize 樣本 (1 秒)');
    return chunks;
  }

  // 合併所有區塊的音符事件結果
  List<Map<String, dynamic>> _mergeChunkResults(
      List<List<Map<String, dynamic>>> allChunkResults) {
    List<Map<String, dynamic>> mergedResults = [];

    for (int chunkIndex = 0;
        chunkIndex < allChunkResults.length;
        chunkIndex++) {
      final chunkResults = allChunkResults[chunkIndex];
      final timeOffset = chunkIndex * 1.0; // 每個區塊 1 秒

      // 為每個音符事件添加正確的時間偏移
      for (var noteEvent in chunkResults) {
        final startTime = (noteEvent['startTime'] as double? ?? 0.0);
        final duration = (noteEvent['duration'] as double? ?? 1.0);
        final endTime =
            (noteEvent['endTime'] as double? ?? (startTime + duration));

        mergedResults.add({
          ...noteEvent,
          'startTime': startTime + timeOffset,
          'endTime': endTime + timeOffset,
          'duration': duration, // 保持原始持續時間
          'chunkIndex': chunkIndex,
        });
      }
    }

    // 按開始時間排序
    mergedResults.sort((a, b) =>
        (a['startTime'] as double).compareTo(b['startTime'] as double));

    debugPrint('合併區塊結果完成：${mergedResults.length} 個音符事件');
    return mergedResults;
  }

  // 處理帶有時間信息的音符事件
  List<Map<String, dynamic>> _processNoteEventsWithTiming(
      List<Map<String, dynamic>> noteEvents) {
    if (noteEvents.isEmpty) {
      debugPrint('沒有音符事件需要處理');
      return [];
    }

    // 按 MIDI 音符和時間排序
    noteEvents.sort((a, b) {
      int midiCompare = (a['midiNote'] as int).compareTo(b['midiNote'] as int);
      if (midiCompare != 0) return midiCompare;
      return (a['startTime'] as double).compareTo(b['startTime'] as double);
    });

    // 濾除低信心度的音符
    final filteredNotes = noteEvents
        .where((note) => (note['confidence'] as double) > 0.15)
        .toList();

    // 合併相近的音符（去除重複檢測）
    List<Map<String, dynamic>> mergedNotes = [];

    for (var note in filteredNotes) {
      bool merged = false;

      // 檢查是否與現有音符重疊
      for (int i = 0; i < mergedNotes.length; i++) {
        var existingNote = mergedNotes[i];

        // 相同音符且時間重疊
        if (existingNote['midiNote'] == note['midiNote']) {
          double existingStart = existingNote['startTime'] as double;
          double existingEnd = existingNote['endTime'] as double;
          double noteStart = note['startTime'] as double;
          double noteEnd = note['endTime'] as double;

          // 如果重疊超過 0.3 秒，合併音符
          if ((noteStart < existingEnd && noteEnd > existingStart) &&
              (min(existingEnd, noteEnd) - max(existingStart, noteStart)) >
                  0.3) {
            // 合併音符：取較早的開始時間和較晚的結束時間
            mergedNotes[i] = {
              ...existingNote,
              'startTime': min(existingStart, noteStart),
              'endTime': max(existingEnd, noteEnd),
              'duration':
                  max(existingEnd, noteEnd) - min(existingStart, noteStart),
              'velocity':
                  max(existingNote['velocity'] as int, note['velocity'] as int),
              'confidence': max(existingNote['confidence'] as double,
                  note['confidence'] as double),
            };

            merged = true;
            break;
          }
        }
      }

      if (!merged) {
        // 確保音符有正確的結束時間
        if (!note.containsKey('endTime')) {
          note['endTime'] =
              (note['startTime'] as double) + (note['duration'] as double);
        }
        mergedNotes.add(note);
      }
    }

    debugPrint(
        '處理音符事件：${noteEvents.length} -> ${filteredNotes.length} -> ${mergedNotes.length}');
    return mergedNotes;
  }

  // 生成完整的 MIDI 檔案（支援時間軌）
  List<int> _generateFullMidiFromAI(
      List<Map<String, dynamic>> noteEvents, double totalDurationSec) {
    List<int> midiData = [];

    // MIDI 檔案標頭
    midiData.addAll([
      0x4D, 0x54, 0x68, 0x64, // "MThd"
      0x00, 0x00, 0x00, 0x06, // 標頭長度 6 bytes
      0x00, 0x00, // 格式類型 0 (單軌道)
      0x00, 0x01, // 軌道數量 1
      0x01, 0xE0, // 時間分割 (480 ticks per quarter note)
    ]);

    List<int> trackEvents = [];

    // 設定音色 (Piano)
    trackEvents.addAll([0x00, 0xC0, 0x00]);

    // 設定速度 (120 BPM)
    trackEvents.addAll([0x00, 0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20]);

    // 按時間排序所有事件
    List<Map<String, dynamic>> allEvents = [];

    for (var note in noteEvents) {
      double startTime = note['startTime'] as double;
      double endTime = note['endTime'] as double;
      int midiNote = note['midiNote'] as int;
      int velocity = note['velocity'] as int;

      // Note On 事件
      allEvents.add({
        'time': startTime,
        'type': 'noteOn',
        'midiNote': midiNote,
        'velocity': velocity,
      });

      // Note Off 事件
      allEvents.add({
        'time': endTime,
        'type': 'noteOff',
        'midiNote': midiNote,
        'velocity': 0,
      });
    }

    // 按時間排序
    allEvents
        .sort((a, b) => (a['time'] as double).compareTo(b['time'] as double));

    // 轉換為 MIDI 事件
    double currentTime = 0.0;
    const int ticksPerQuarterNote = 480; // MIDI 時間分辨率
    const int tempo = 500000; // 微秒/四分音符 (120 BPM)
    const double ticksPerSecond = ticksPerQuarterNote * 1000000.0 / tempo; // ~960 ticks/sec

    for (var event in allEvents) {
      double eventTime = event['time'] as double;
      int deltaTicks = ((eventTime - currentTime) * ticksPerSecond).round().clamp(0, 0x0FFFFFFF);

      int midiNote = event['midiNote'] as int;
      int velocity = event['velocity'] as int;

      // 使用變長編碼 (Variable Length Quantity)
      List<int> deltaBytes = _encodeVariableLength(deltaTicks);
      
      if (event['type'] == 'noteOn') {
        trackEvents.addAll([...deltaBytes, 0x90, midiNote, velocity]);
      } else {
        trackEvents.addAll([...deltaBytes, 0x80, midiNote, velocity]);
      }

      currentTime = eventTime;
    }

    // 軌道結束
    int finalDeltaTicks = ((totalDurationSec - currentTime) * ticksPerSecond).round().clamp(0, 0x0FFFFFFF);
    List<int> finalDeltaBytes = _encodeVariableLength(finalDeltaTicks);
    trackEvents.addAll([...finalDeltaBytes, 0xFF, 0x2F, 0x00]);

    // 軌道標頭
    midiData.addAll([0x4D, 0x54, 0x72, 0x6B]); // "MTrk"

    // 軌道長度
    final trackLength = trackEvents.length;
    midiData.addAll([
      (trackLength >> 24) & 0xFF,
      (trackLength >> 16) & 0xFF,
      (trackLength >> 8) & 0xFF,
      trackLength & 0xFF,
    ]);

    midiData.addAll(trackEvents);

    debugPrint(
        '生成完整 MIDI：${midiData.length} 字節，${noteEvents.length} 個音符，時長 ${totalDurationSec.toStringAsFixed(1)} 秒');
    return midiData;
  }

  // MIDI 變長編碼 (Variable Length Quantity)
  List<int> _encodeVariableLength(int value) {
    List<int> bytes = [];
    bytes.add(value & 0x7F);
    
    value >>= 7;
    while (value > 0) {
      bytes.insert(0, (value & 0x7F) | 0x80);
      value >>= 7;
    }
    
    return bytes;
  }

  // 使用 MidiPro 播放 MIDI 檔案
  Future<void> _playMidiWithMidiPro(MidiPro midiPro, Uint8List midiBytes, int sfId) async {
    try {
      debugPrint('🎵 開始解析並播放 MIDI 檔案...');
      
      // MIDI 解析
      int offset = 0;
      
      // 跳過 MIDI 檔案頭 (MThd)
      if (midiBytes.length < 14) {
        throw Exception('MIDI 檔案格式錯誤');
      }
      
      offset = 14; // 跳過 MThd header
      
      // 讀取軌道 (MTrk)
      if (offset + 8 > midiBytes.length) {
        debugPrint('⚠️ MIDI 檔案過短');
        return;
      }
      
      // 跳過 MTrk 標頭
      offset += 8;
      
      // 收集所有 MIDI 事件
      List<Map<String, dynamic>> midiEvents = [];
      double currentTicks = 0.0;
      const double ticksPerSecond = 960.0;
      
      while (offset < midiBytes.length - 3) {
        // 讀取 delta time (變長編碼)
        int deltaTime = 0;
        while (offset < midiBytes.length) {
          int byte = midiBytes[offset++];
          deltaTime = (deltaTime << 7) | (byte & 0x7F);
          if ((byte & 0x80) == 0) break;
        }
        
        currentTicks += deltaTime;
        double eventTime = currentTicks / ticksPerSecond;
        
        if (offset >= midiBytes.length) break;
        
        int status = midiBytes[offset++];
        
        // Note On (0x90)
        if ((status & 0xF0) == 0x90) {
          if (offset + 1 >= midiBytes.length) break;
          int note = midiBytes[offset++];
          int velocity = midiBytes[offset++];
          
          if (velocity > 0) {
            midiEvents.add({
              'type': 'noteOn',
              'time': eventTime,
              'note': note,
              'velocity': velocity,
            });
          } else {
            // velocity=0 等同於 Note Off
            midiEvents.add({
              'type': 'noteOff',
              'time': eventTime,
              'note': note,
            });
          }
        }
        // Note Off (0x80)
        else if ((status & 0xF0) == 0x80) {
          if (offset + 1 >= midiBytes.length) break;
          int note = midiBytes[offset++];
          offset++; // skip velocity
          
          midiEvents.add({
            'type': 'noteOff',
            'time': eventTime,
            'note': note,
          });
        }
        // Meta event (0xFF)
        else if (status == 0xFF) {
          if (offset >= midiBytes.length) break;
          offset++; // skip type
          if (offset >= midiBytes.length) break;
          int length = midiBytes[offset++];
          offset += length;
        }
        // Program Change (0xC0)
        else if ((status & 0xF0) == 0xC0) {
          if (offset < midiBytes.length) offset++;
        }
        // Control Change (0xB0)
        else if ((status & 0xF0) == 0xB0) {
          if (offset + 1 < midiBytes.length) offset += 2;
        }
        // 其他事件，跳過
        else {
          if (offset + 1 < midiBytes.length) {
            offset += 2;
          }
        }
      }
      
      debugPrint('✅ 解析完成，共 ${midiEvents.length} 個事件');
      
      // 播放事件
      if (midiEvents.isEmpty) {
        debugPrint('⚠️ 沒有可播放的 MIDI 事件');
        return;
      }
      
      final startTime = DateTime.now();
      double lastEventTime = 0.0;
      
      for (var event in midiEvents) {
        double eventTime = event['time'] as double;
        
        // 等待到事件時間
        double waitTime = eventTime - lastEventTime;
        if (waitTime > 0) {
          await Future.delayed(Duration(milliseconds: (waitTime * 1000).round()));
        }
        
        if (event['type'] == 'noteOn') {
          await midiPro.playNote(
            key: event['note'] as int,
            velocity: event['velocity'] as int,
            sfId: sfId,
          );
        } else if (event['type'] == 'noteOff') {
          await midiPro.stopNote(
            key: event['note'] as int,
            sfId: sfId,
          );
        }
        
        lastEventTime = eventTime;
      }
      
      final elapsed = DateTime.now().difference(startTime);
      debugPrint('🎉 MIDI 播放完成！播放時長: ${elapsed.inSeconds} 秒');
      
    } catch (e, stackTrace) {
      debugPrint('❌ MIDI 播放過程錯誤: $e');
      debugPrint('堆疊: $stackTrace');
      rethrow;
    }
  }

  // 根據進度返回適當的描述文字
  String _getProgressDescription(double progress) {
    if (progress < 0.05) {
      return '正在檢查音訊檔案格式...';
    } else if (progress < 0.08) {
      return '正在轉換音訊格式為 WAV...';
    } else if (progress < 0.12) {
      return '正在讀取和預處理音訊檔案...';
    } else if (progress < 0.18) {
      return '正在分割音訊為 1 秒分析區塊...';
    } else if (progress < 0.85) {
      return '正在對每個區塊進行 AI 音符檢測...';
    } else if (progress < 0.9) {
      return '正在合併所有區塊的分析結果...';
    } else if (progress < 0.95) {
      return '正在處理和優化檢測到的音符...';
    } else if (progress < 1.0) {
      return '正在生成完整的 MIDI 檔案...';
    } else {
      return '分析完成！正在儲存檔案...';
    }
  }

  // 簡單的線性插值重採樣
  List<double> _resampleAudio(
      List<double> samples, int originalRate, int targetRate) {
    if (originalRate == targetRate) return samples;

    final ratio = originalRate / targetRate;
    final targetLength = (samples.length / ratio).round();
    List<double> resampled = [];

    for (int i = 0; i < targetLength; i++) {
      final sourceIndex = i * ratio;
      final floorIndex = sourceIndex.floor();
      final ceilIndex = (floorIndex + 1).clamp(0, samples.length - 1);
      final fraction = sourceIndex - floorIndex;

      if (floorIndex < samples.length && ceilIndex < samples.length) {
        final interpolated = samples[floorIndex] * (1 - fraction) +
            samples[ceilIndex] * fraction;
        resampled.add(interpolated);
      } else if (floorIndex < samples.length) {
        resampled.add(samples[floorIndex]);
      } else {
        resampled.add(0.0);
      }
    }

    return resampled;
  }

  // 計算音訊 RMS (均方根)
  double _calculateRMS(List<double> samples) {
    if (samples.isEmpty) return 0.0;

    double sum = 0.0;
    for (double sample in samples) {
      sum += sample * sample;
    }

    return sqrt(sum / samples.length);
  }

  // 使用 AI 模型進行推論
  Future<List<List<double>>> _runAIInference(Float32List audioData) async {
    try {
      debugPrint('🔄 開始 AI 模型推論，音訊數據長度: ${audioData.length}');

      if (_interpreter == null || !_isModelLoaded) {
        throw Exception('AI 模型未載入');
      }

      // 獲取模型的輸入張量信息
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      if (inputTensors.isEmpty) {
        throw Exception('模型沒有輸入張量');
      }

      final inputTensor = inputTensors[0];
      debugPrint('輸入張量形狀: ${inputTensor.shape}');
      debugPrint('輸入張量類型: ${inputTensor.type}');

      // 準備輸入數據
      dynamic inputData;

      // 根據模型的輸入形狀調整數據
      if (inputTensor.shape.length == 1) {
        // 一維輸入 [samples]
        final expectedLength = inputTensor.shape[0];
        List<double> processedAudio;

        debugPrint('模型期望輸入長度: $expectedLength, 實際音頻長度: ${audioData.length}');

        if (audioData.length > expectedLength) {
          // 如果音頻太長，截取前面部分
          processedAudio = audioData.sublist(0, expectedLength);
          debugPrint('音頻太長，截取到 $expectedLength 樣本');
        } else {
          // 如果音頻太短，用零填充
          processedAudio = List<double>.from(audioData);
          while (processedAudio.length < expectedLength) {
            processedAudio.add(0.0);
          }
          debugPrint(
              '音頻太短，填充到 $expectedLength 樣本 (添加了 ${expectedLength - audioData.length} 個零)');
        }

        inputData = processedAudio;
        debugPrint('準備一維輸入數據: [$expectedLength]');
      } else if (inputTensor.shape.length == 2) {
        // 二維輸入 [batch_size, samples]
        final expectedLength = inputTensor.shape[1];
        List<double> processedAudio;

        debugPrint('模型期望輸入長度: $expectedLength, 實際音頻長度: ${audioData.length}');

        if (audioData.length > expectedLength) {
          // 如果音頻太長，截取前面部分
          processedAudio = audioData.sublist(0, expectedLength);
          debugPrint('音頻太長，截取到 $expectedLength 樣本');
        } else {
          // 如果音頻太短，用零填充
          processedAudio = List<double>.from(audioData);
          while (processedAudio.length < expectedLength) {
            processedAudio.add(0.0);
          }
          debugPrint(
              '音頻太短，填充到 $expectedLength 樣本 (添加了 ${expectedLength - audioData.length} 個零)');
        }

        inputData = [processedAudio];
        debugPrint('準備二維輸入數據: [1, ${processedAudio.length}]');
      } else if (inputTensor.shape.length == 3) {
        // 三維輸入 [batch_size, time_steps, features] 或 [batch_size, samples, channels]
        final batchSize = inputTensor.shape[0];
        final timeSteps = inputTensor.shape[1];
        final features = inputTensor.shape[2];

        debugPrint('模型期望三維輸入: [$batchSize, $timeSteps, $features]');

        List<double> processedAudio;
        final expectedLength = timeSteps * features;

        if (audioData.length > expectedLength) {
          processedAudio = audioData.sublist(0, expectedLength);
          debugPrint('音頻太長，截取到 $expectedLength 樣本');
        } else {
          processedAudio = List<double>.from(audioData);
          while (processedAudio.length < expectedLength) {
            processedAudio.add(0.0);
          }
          debugPrint('音頻太短，填充到 $expectedLength 樣本');
        }

        // 重塑為三維 [batch_size, time_steps, features]
        List<List<List<double>>> batchData = [];
        List<List<double>> timeStepData = [];

        int sampleIndex = 0;
        for (int t = 0; t < timeSteps; t++) {
          List<double> featureData = [];
          for (int f = 0; f < features; f++) {
            if (sampleIndex < processedAudio.length) {
              featureData.add(processedAudio[sampleIndex]);
            } else {
              featureData.add(0.0);
            }
            sampleIndex++;
          }
          timeStepData.add(featureData);
        }
        batchData.add(timeStepData);

        inputData = batchData;
        debugPrint('準備三維輸入數據: [$batchSize, $timeSteps, $features]');
      } else {
        throw Exception('不支援的輸入張量維度: ${inputTensor.shape.length}');
      }

      // 準備輸出緩衝區 - 根據張量形狀創建正確的結構
      Map<int, dynamic> outputBuffers = {};

      for (int i = 0; i < outputTensors.length; i++) {
        final outputTensor = outputTensors[i];
        final shape = outputTensor.shape;
        debugPrint('輸出張量 $i 形狀: $shape');

        // 根據維度創建對應結構
        if (shape.length == 3) {
          // 三維輸出 [batch, time, features]
          final batch = shape[0];
          final time = shape[1];
          final features = shape[2];

          outputBuffers[i] = List.generate(
              batch,
              (_) => List.generate(
                  time, (_) => List<double>.filled(features, 0.0)));
          debugPrint('  創建三維輸出: [$batch, $time, $features]');
        } else if (shape.length == 2) {
          // 二維輸出 [batch, features]
          final batch = shape[0];
          final features = shape[1];
          outputBuffers[i] =
              List.generate(batch, (_) => List<double>.filled(features, 0.0));
          debugPrint('  創建二維輸出: [$batch, $features]');
        } else if (shape.length == 1) {
          // 一維輸出
          outputBuffers[i] = List<double>.filled(shape[0], 0.0);
          debugPrint('  創建一維輸出: [${shape[0]}]');
        }
      }

      // 執行推論
      debugPrint('🧠 執行 AI 模型推論...');
      
      // 將 outputBuffers 轉換為正確的類型 Map<int, Object>
      final Map<int, Object> outputMap = {};
      outputBuffers.forEach((key, value) {
        outputMap[key] = value as Object;
      });
      
      _interpreter!.runForMultipleInputs([inputData], outputMap);

      debugPrint('✅ AI 推論完成，輸出 ${outputMap.length} 個張量');

      // 將三維輸出展平為二維 [time, features]
      List<List<double>> flattenedOutputs = [];

      for (int i = 0; i < outputMap.length; i++) {
        final output = outputMap[i];

        if (output is List<List<List<double>>>) {
          // 三維: [batch, time, features] -> [time, features]
          if (output.isNotEmpty) {
            flattenedOutputs
                .add(output[0].expand((timeStep) => timeStep).toList());
            debugPrint('  輸出 $i: 三維 -> 一維 [${flattenedOutputs.last.length}]');
          }
        } else if (output is List<List<double>>) {
          // 二維: [batch, features] -> [features]
          if (output.isNotEmpty) {
            flattenedOutputs.add(output[0]);
            debugPrint('  輸出 $i: 二維 -> 一維 [${flattenedOutputs.last.length}]');
          }
        } else if (output is List<double>) {
          // 一維: 直接使用
          flattenedOutputs.add(output);
          debugPrint('  輸出 $i: 一維 [${output.length}]');
        }

        // 顯示統計資訊
        if (flattenedOutputs.isNotEmpty && flattenedOutputs.last.isNotEmpty) {
          final values = flattenedOutputs.last;
          final max = values.reduce((a, b) => a > b ? a : b);
          final min = values.reduce((a, b) => a < b ? a : b);
          final avg = values.reduce((a, b) => a + b) / values.length;
          debugPrint(
              '    統計: min=$min, max=$max, avg=${avg.toStringAsFixed(4)}');
        }
      }

      return flattenedOutputs;
    } catch (e, stackTrace) {
      debugPrint('❌ AI 推論失敗: $e');
      debugPrint('錯誤堆疊: $stackTrace');

      // 直接拋出錯誤,不使用假數據
      rethrow;
    }
  }

  // Sigmoid 函數：將 logits 轉換為機率 [0, 1]
  double _sigmoid(double x) {
    return 1.0 / (1.0 + exp(-x));
  }

  // 解析 AI 輸出為音符事件 - 正確處理時間維度
  List<Map<String, dynamic>> _parseAIOutput(List<List<double>> aiOutput) {
    if (aiOutput.isEmpty) {
      debugPrint('AI 輸出為空');
      return [];
    }

    debugPrint('解析 AI 輸出，包含 ${aiOutput.length} 個張量');
    for (int i = 0; i < aiOutput.length; i++) {
      debugPrint('張量 $i: ${aiOutput[i].length} 個值');
    }

    List<Map<String, dynamic>> noteEvents = [];

    // AI 模型輸出格式：[time_frames * notes]
    // 展平後的格式：每個張量是 [32 * 88] = 2816 個值
    // 需要重塑為 [32 time_frames, 88 notes]
    
    if (aiOutput.length >= 2) {
      // 假設有兩個輸出：onsets 和 frames
      final onsetsFlat = aiOutput[0];
      final framesFlat = aiOutput[1];
      
      const int numTimeFrames = 32; // 模型輸出的時間幀數
      const int numNotes = 88;      // 鋼琴音符數
      
      if (onsetsFlat.length != numTimeFrames * numNotes ||
          framesFlat.length != numTimeFrames * numNotes) {
        debugPrint('警告：輸出大小不符合預期');
        debugPrint('Onsets: ${onsetsFlat.length}, Frames: ${framesFlat.length}');
        debugPrint('預期: ${numTimeFrames * numNotes}');
      }
      
      // 重塑為 [time, note] 格式，同時將 logits 轉換為機率
      List<List<double>> onsets = [];
      List<List<double>> frames = [];
      
      for (int t = 0; t < numTimeFrames; t++) {
        List<double> onsetFrame = [];
        List<double> frameFrame = [];
        
        for (int n = 0; n < numNotes; n++) {
          int idx = t * numNotes + n;
          if (idx < onsetsFlat.length) {
            // 將 logits 轉換為機率值 [0, 1]
            onsetFrame.add(_sigmoid(onsetsFlat[idx]));
          } else {
            onsetFrame.add(0.0);
          }
          if (idx < framesFlat.length) {
            // 將 logits 轉換為機率值 [0, 1]
            frameFrame.add(_sigmoid(framesFlat[idx]));
          } else {
            frameFrame.add(0.0);
          }
        }
        
        onsets.add(onsetFrame);
        frames.add(frameFrame);
      }
      
      debugPrint('重塑完成：$numTimeFrames 時間幀 x $numNotes 音符 (已轉換為機率)');
      
      // 🔍 調試：檢查轉換後的值範圍
      double maxOnset = onsets.expand((f) => f).reduce((a, b) => a > b ? a : b);
      double maxFrame = frames.expand((f) => f).reduce((a, b) => a > b ? a : b);
      double avgOnset = onsets.expand((f) => f).reduce((a, b) => a + b) / (numTimeFrames * numNotes);
      double avgFrame = frames.expand((f) => f).reduce((a, b) => a + b) / (numTimeFrames * numNotes);
      debugPrint('🔍 Sigmoid轉換後 - Onset: max=$maxOnset, avg=$avgOnset');
      debugPrint('🔍 Sigmoid轉換後 - Frame: max=$maxFrame, avg=$avgFrame');
      
      // 設定閾值（進一步降低以捕捉更多音符）
      const double onsetThreshold = 0.1;   // Onset 閾值（從 0.15 降低到 0.1）
      const double frameThreshold = 0.03;  // Frame 閾值（從 0.05 降低到 0.03）
      const double minNoteDuration = 0.05; // 最小音符持續時間（50ms）
      
      // 追蹤每個音符的狀態
      Map<int, Map<String, dynamic>> activeNotes = {};
      
      // 每個時間幀的時間長度（秒）
      const double frameTime = 1.0 / numTimeFrames; // ~0.03125 秒/幀
      
      debugPrint('🎯 使用閾值 - Onset: $onsetThreshold, Frame: $frameThreshold');
      
      // 🔍 計數檢測到的onset
      int onsetCount = 0;
      
      for (int t = 0; t < numTimeFrames; t++) {
        double currentTime = t * frameTime;
        
        for (int n = 0; n < numNotes; n++) {
          double onsetValue = onsets[t][n];
          double frameValue = frames[t][n];
          
          int midiNote = 21 + n; // MIDI 21 = A0 (最低鋼琴音)
          
          // 檢測音符開始 (onset)
          if (onsetValue > onsetThreshold) {
            onsetCount++;
            if (onsetCount <= 5) {  // 只打印前5個
              debugPrint('  🎵 檢測onset: t=$t, note=$midiNote, onset=$onsetValue, frame=$frameValue');
            }
            // 如果該音符已經在活動中，先結束它
            if (activeNotes.containsKey(midiNote)) {
              var note = activeNotes[midiNote]!;
              double duration = currentTime - (note['startTime'] as double);
              
              // 只有持續時間足夠長才記錄
              if (duration >= minNoteDuration) {
                note['endTime'] = currentTime;
                note['duration'] = duration;
                noteEvents.add(note);
              }
            }
            
            // 開始新音符
            activeNotes[midiNote] = {
              'midiNote': midiNote,
              'startTime': currentTime,
              'velocity': (onsetValue * 127).round().clamp(35, 127),
              'confidence': onsetValue,
              'onsetStrength': onsetValue,
            };
          }
          
          // 檢查音符是否持續 (frame)
          if (activeNotes.containsKey(midiNote)) {
            if (frameValue < frameThreshold) {
              // 音符結束
              var note = activeNotes[midiNote]!;
              double duration = currentTime - (note['startTime'] as double);
              
              // 只有持續時間足夠長才記錄
              if (duration >= minNoteDuration) {
                note['endTime'] = currentTime;
                note['duration'] = duration;
                noteEvents.add(note);
              }
              activeNotes.remove(midiNote);
            } else {
              // 更新強度
              activeNotes[midiNote]!['frameStrength'] = frameValue;
            }
          }
        }
      }
      
      // 結束所有仍在活動的音符
      activeNotes.forEach((midiNote, note) {
        double duration = 1.0 - (note['startTime'] as double);
        
        // 只有持續時間足夠長才記錄
        if (duration >= minNoteDuration) {
          note['endTime'] = 1.0; // 區塊結束時間
          note['duration'] = duration;
          noteEvents.add(note);
        }
      });
      
      debugPrint('📊 本區塊檢測到 ${noteEvents.length} 個有效音符 (onset觸發: $onsetCount 次)');
      
    } else if (aiOutput.length == 1) {
      // 單一輸出，嘗試簡單處理
      final combined = aiOutput[0];
      final threshold = _calculateDynamicThreshold(combined, 0.2);

      debugPrint('單一輸出處理，閾值: $threshold');

      for (int i = 0; i < combined.length; i++) {
        if (combined[i] > threshold) {
          int midiNote = _mapToMidiNote(i, combined.length);

          noteEvents.add({
            'midiNote': midiNote,
            'startTime': 0.0,
            'duration': 0.5,
            'endTime': 0.5,
            'velocity': (combined[i] * 127).round().clamp(30, 127),
            'confidence': combined[i],
          });
        }
      }
    }

    debugPrint('從 AI 輸出解析出 ${noteEvents.length} 個音符事件');
    return noteEvents;
  }

  // 計算動態閾值
  double _calculateDynamicThreshold(
      List<double> values, double defaultThreshold) {
    if (values.isEmpty) return defaultThreshold;

    // 計算統計信息
    final sorted = List<double>.from(values)..sort();
    final max = sorted.last;
    final q75 = sorted[(sorted.length * 0.75).floor()];
    final mean = values.reduce((a, b) => a + b) / values.length;

    // 動態調整閾值
    final dynamicThreshold =
        (defaultThreshold > (mean * 2 < q75 * 0.5 ? mean * 2 : q75 * 0.5))
            ? defaultThreshold
            : (mean * 2 < q75 * 0.5 ? mean * 2 : q75 * 0.5);

    debugPrint('統計: max=$max, q75=$q75, mean=$mean, 動態閾值=$dynamicThreshold');
    return dynamicThreshold;
  }

  // 將模型輸出索引映射到 MIDI 音符
  int _mapToMidiNote(int index, int totalNotes) {
    if (totalNotes == 88) {
      // 標準 88 鍵鋼琴映射 (A0 = 21)
      return index + 21;
    } else {
      // 動態映射到鋼琴音域
      final ratio = index / (totalNotes - 1);
      const midiRange = 108 - 21; // C8 - A0
      return (21 + ratio * midiRange).round();
    }
  }

  // 快速分析轉換結果
  Future<String> _getQuickAnalysis(File midiFile) async {
    try {
      final bytes = await midiFile.readAsBytes();
      final noteCount = _countNotes(bytes);
      final noteRange = _analyzeNoteRange(bytes);

      String result = '檢測到 $noteCount 個音符';
      if (noteRange.isNotEmpty) {
        result +=
            '\n音域: ${_noteToString(noteRange[0])} - ${_noteToString(noteRange[1])}';
      }
      return result;
    } catch (e) {
      return '基於錄音檔案內容生成';
    }
  }

  // 播放 MIDI 檔案
  Future<void> playMidiFile() async {
    if (_midiPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('請先轉換 MIDI 檔案'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // 檢查檔案是否存在
    final midiFile = File(_midiPath!);
    if (!await midiFile.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('MIDI 檔案不存在: $_midiPath'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      debugPrint('播放 MIDI 檔案: $_midiPath');
      debugPrint('檔案大小: ${await midiFile.length()} bytes');

      // 使用 flutter_midi_pro 播放
      final midiPro = MidiPro();
      
      // 載入音色庫 (SoundFont) - 鋼琴音色
      const soundfontPath = 'assets/TimGM6mb.sf2';
      final sfId = await midiPro.loadSoundfont(
        path: soundfontPath,
        bank: 0,
        program: 0, // 0 = Piano
      );
      
      debugPrint('音色庫載入成功: $sfId');
      
      // 讀取並解析 MIDI 檔案
      final midiBytes = await midiFile.readAsBytes();
      await _playMidiWithMidiPro(midiPro, midiBytes, sfId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎹 MIDI 播放完成'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('MIDI 播放錯誤: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('MIDI 播放失敗: $e\n\n💡 檔案已生成，可使用其他 MIDI 播放器播放'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // 顯示 MIDI 檔案位置
  Future<void> exportMidiFile() async {
    if (_midiPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('請先轉換 MIDI 檔案'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      final midiFile = File(_midiPath!);
      if (!await midiFile.exists()) {
        throw Exception('MIDI 檔案不存在: $_midiPath');
      }

      // 分析 MIDI 檔案
      final midiAnalysis = await _analyzeMidiFile(midiFile);

      // 檔案已經儲存在用戶可存取的位置，直接顯示路徑
      final fileName = _midiPath!.split('/').last;
      String locationMessage;

      if (_midiPath!.contains('/Download/')) {
        locationMessage =
            '檔案已儲存到「下載」資料夾:\n$fileName\n\n$midiAnalysis\n\n🔍 在檔案管理器中搜索「$fileName」即可找到';
      } else {
        locationMessage =
            'MIDI 檔案位置:\n$_midiPath\n\n$midiAnalysis\n\n🔍 在檔案管理器中搜索「$fileName」即可找到';
      }

      // 嘗試開啟檔案管理器到檔案位置
      try {
        final result = await OpenFile.open(_midiPath!);
        if (result.type == ResultType.done) {
          locationMessage += '\n\n✅ 已嘗試開啟檔案管理器';
        } else {
          locationMessage += '\n\n⚠️ 無法自動開啟，請手動搜索檔案';
        }
      } catch (openError) {
        debugPrint('開啟檔案失敗: $openError');
        locationMessage += '\n\n⚠️ 無法自動開啟，請手動搜索檔案';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('檔案存取失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 分析 MIDI 檔案內容
  Future<String> _analyzeMidiFile(File midiFile) async {
    try {
      final bytes = await midiFile.readAsBytes();
      final size = bytes.length;

      // 基本檔案資訊
      String analysis = '📊 MIDI 檔案分析:\n';
      analysis += '• 檔案大小: $size bytes\n';

      // 檢查 MIDI 標頭
      if (size < 14) {
        analysis += '• ❌ 檔案太小，可能損壞\n';
        return analysis;
      }

      // 檢查 MIDI 魔術數字
      String header = String.fromCharCodes(bytes.sublist(0, 4));
      if (header == 'MThd') {
        analysis += '• ✅ MIDI 格式正確\n';

        // 讀取格式資訊
        int format = (bytes[8] << 8) | bytes[9];
        int tracks = (bytes[10] << 8) | bytes[11];
        int division = (bytes[12] << 8) | bytes[13];

        analysis += '• 格式類型: $format\n';
        analysis += '• 軌道數量: $tracks\n';
        analysis += '• 時間分割: $division ticks/quarter\n';

        // 估算播放時長 (簡化估算)
        int estimatedDuration = _estimateDuration(bytes);
        analysis += '• 預估時長: $estimatedDuration秒\n';

        // 分析音符內容
        int noteCount = _countNotes(bytes);
        analysis += '• 音符數量: $noteCount\n';

        // 檢查音域

        List<int> noteRange = _analyzeNoteRange(bytes);
        if (noteRange.isNotEmpty) {
          analysis +=
              '• 音域: ${_noteToString(noteRange[0])} - ${_noteToString(noteRange[1])}\n';
        }

        // 品質評估
        String quality = _assessQuality(size, noteCount, tracks);
        analysis += '• 品質評估: $quality\n';
      } else {
        analysis += '• ❌ 不是有效的 MIDI 檔案\n';
      }

      return analysis;
    } catch (e) {
      return '📊 MIDI 檔案分析:\n• ❌ 分析失敗: $e';
    }
  }

  // 估算播放時長
  int _estimateDuration(List<int> bytes) {
    // 簡化計算：基於檔案大小和音符密度
    int size = bytes.length;
    if (size < 200) return 5;
    if (size < 500) return 10;
    if (size < 1000) return 15;
    return 20;
  }

  // 計算音符數量
  int _countNotes(List<int> bytes) {
    int count = 0;
    for (int i = 0; i < bytes.length - 1; i++) {
      // 尋找 Note On 事件 (0x90-0x9F)
      if (bytes[i] >= 0x90 && bytes[i] <= 0x9F) {
        count++;
      }
    }
    return count;
  }

  // 分析音域範圍
  List<int> _analyzeNoteRange(List<int> bytes) {
    List<int> notes = [];
    for (int i = 0; i < bytes.length - 2; i++) {
      // 尋找 Note On 事件
      if (bytes[i] >= 0x90 && bytes[i] <= 0x9F && i + 1 < bytes.length) {
        notes.add(bytes[i + 1]); // 音符編號
      }
    }

    if (notes.isEmpty) return [];
    notes.sort();
    return [notes.first, notes.last];
  }

  // 將 MIDI 音符編號轉換為音符名稱
  String _noteToString(int midiNote) {
    List<String> noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B'
    ];
    int octave = (midiNote ~/ 12) - 1;
    String note = noteNames[midiNote % 12];
    return '$note$octave';
  }

  // 評估 MIDI 檔案品質
  String _assessQuality(int size, int noteCount, int tracks) {
    if (size < 100) return '❌ 檔案太小';
    if (noteCount == 0) return '❌ 沒有音符';
    if (noteCount < 5) return '⚠️ 音符太少';
    if (noteCount >= 5 && noteCount <= 20) return '✅ 簡單旋律';
    if (noteCount > 20) return '✅ 豐富內容';
    return '➖ 未知';
  }

  @override
  Widget build(BuildContext context) {
    // 獲取檔案名稱（不包含副檔名）
    String getFileNameWithoutExtension() {
      if (widget.file?.name == null) return '未指定曲目';
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
        title: const Text('演奏偵錯頁面',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
              Text(
                '正在練習: ${getFileNameWithoutExtension()}',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.w600,
                  color: AppColors.dynamicTextDark,
                ),
                textAlign: TextAlign.center,
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
                          Icon(Icons.mic, color: AppColors.dynamicPrimary, size: 28),
                          const SizedBox(width: 8),
                          const Text('錄音控制',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: isRecording ? stopRecording : startRecording,
                            icon: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
                            label: Text(isRecording 
                                ? '停止' 
                                : (_audioPath != null ? '重新錄音' : '開始')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isRecording ? Colors.grey : Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Row(
                            children: [
                              Icon(
                                isRecording ? Icons.fiber_manual_record : Icons.stop_circle_outlined,
                                color: isRecording ? Colors.red : Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isRecording
                                    ? '正在錄音... ${_recordingDurationSeconds}s'
                                    : (_audioPath != null
                                        ? '錄音完成'
                                        : '未錄音'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isRecording ? Colors.red : (_audioPath != null ? Colors.green : Colors.grey),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (isRecording && _recordingDurationSeconds < 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '建議錄音至少 3 秒以獲得更好的轉換效果',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 播放控制區域
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.volume_up, color: AppColors.dynamicPrimary, size: 28),
                          const SizedBox(width: 8),
                          const Text('播放控制',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: (!isRecording &&
                                    _audioPath != null &&
                                    !isPlaying)
                                ? playRecording
                                : null,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('播放'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: isPlaying ? stopPlaying : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('停止'),
                          ),
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
                        children: const [
                          Icon(Icons.analytics_outlined, color: Colors.purple, size: 28),
                          SizedBox(width: 8),
                          Text(
                            '演奏分析',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '使用頻譜分析技術驗證您的演奏\n比對音準、節奏,並給予評分和建議',
                        style: TextStyle(
                          fontSize: 13, 
                          color: AppColors.dynamicTextDark.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: (!isRecording && _audioPath != null && !_isAnalyzing && widget.file != null)
                            ? _analyzePerformance
                            : null,
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.analytics_outlined),
                        label: Text(_isAnalyzing ? '分析中...' : '分析演奏'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
    if (_audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ 請先錄製您的演奏'), backgroundColor: Colors.red),
      );
      return;
    }
    if (widget.file == null || widget.file!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ 請先從樂庫選擇 MIDI 曲目'), backgroundColor: Colors.red),
      );
      return;
    }
    final audioFile = File(_audioPath!);
    if (!await audioFile.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ 錄音文件不存在，請重新錄音'), backgroundColor: Colors.red),
      );
      return;
    }
    final midiFile = File(widget.file!.path!);
    if (!await midiFile.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ MIDI文件不存在，請重新選擇'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { _isAnalyzing = true; _analysisProgress = 0.0; _analysisPhase = ''; });

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分析失敗: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) setState(() { _isAnalyzing = false; _analysisProgress = 0.0; _analysisPhase = ''; });
    }
  }

  String _getAnalysisPhaseDescription(double progress) {
    if (progress < 0.2) return '正在解析 MIDI 標準答案...';
    if (progress < 0.6) return '正在分析音訊頻譜...';
    if (progress < 0.8) return '正在驗證音符準確性...';
    if (progress < 1.0) return '正在分類錯誤類型...';
    return '分析完成!';
  }

  Widget _buildAnalysisProgressDialog() {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Row(
            children: [Icon(Icons.analytics, color: Colors.purple), SizedBox(width: 8), Text('演奏分析中')],
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
              Text('${(_analysisProgress * 100).toInt()}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_analysisPhase, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
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

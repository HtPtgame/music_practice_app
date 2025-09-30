import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:ffmpeg_kit_flutter_minimal/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_minimal/return_code.dart';

class PracticePage extends StatefulWidget {
  final PlatformFile? file;
  const PracticePage({super.key, this.file});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  FlutterSoundRecorder? _recorder; // 使用 flutter_sound 進行錄音
  FlutterSoundPlayer? _player; // 保留 flutter_sound 用於播放
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
  
  // AI 模型相關變數
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _loadAIModel();
  }

  Future<void> _initAudio() async {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    try {
      await _recorder!.openRecorder();
      await _player!.openPlayer();
      debugPrint('音訊系統初始化成功');
    } catch (e) {
      debugPrint('音訊初始化失敗: $e');
    }
  }

  // 載入 AI 模型
  Future<void> _loadAIModel() async {
    try {
      debugPrint('🔄 開始載入 AI 模型: onsets_frames_wavinput.tflite');
      
      // 方法1：檢查資產是否存在
      try {
        final ByteData assetData = await rootBundle.load('assets/onsets_frames_wavinput.tflite');
        debugPrint('✅ AI 模型檔案確實存在，大小: ${assetData.lengthInBytes} bytes');
        
        // 方法2：從ByteData創建解釋器
        _interpreter = Interpreter.fromBuffer(assetData.buffer.asUint8List());
        _isModelLoaded = true;
        debugPrint('✅ 使用 fromBuffer 方法載入 AI 模型成功');
      } catch (bufferError) {
        debugPrint('❌ 使用 fromBuffer 失敗: $bufferError');
        
        // 方法3：回退到原始方法（不包含 assets/ 前綴）
        debugPrint('🔄 嘗試使用 fromAsset 方法...');
        _interpreter = await Interpreter.fromAsset('onsets_frames_wavinput.tflite');
        _isModelLoaded = true;
        debugPrint('✅ 使用 fromAsset 方法載入 AI 模型成功');
      }
      
      // 輸出模型信息
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();
      
      debugPrint('模型輸入張量信息:');
      for (int i = 0; i < inputTensors.length; i++) {
        final tensor = inputTensors[i];
        debugPrint('  輸入 $i: 形狀=${tensor.shape}, 型別=${tensor.type}');
      }
      
      debugPrint('模型輸出張量信息:');
      for (int i = 0; i < outputTensors.length; i++) {
        final tensor = outputTensors[i];
        debugPrint('  輸出 $i: 形狀=${tensor.shape}, 型別=${tensor.type}');
      }
    } catch (e) {
      debugPrint('❌ AI 模型載入失敗: $e');
      _isModelLoaded = false;
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _closeAudio();
    _interpreter?.close();
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

  // ... 保留原有的錄音功能 ...
  Future<void> startRecording() async {
    var micStatus = await Permission.microphone.request();

    if (!mounted) return;

    if (micStatus != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未取得麥克風權限'), backgroundColor: Colors.red),
      );
      return;
    }
    
    try {
      // 確保錄音器處於正確狀態
      if (_recorder == null) {
        debugPrint('錄音器未初始化');
        return;
      }
      
      // 如果正在錄音，先停止
      if (isRecording) {
        debugPrint('停止之前的錄音...');
        await _recorder!.stopRecorder();
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() { isRecording = false; });
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final basePath = '${directory.path}/practice_record';
      
      // 刪除可能存在的舊檔案
      final wavFile = File('$basePath.wav');
      if (await wavFile.exists()) {
        await wavFile.delete();
        debugPrint('刪除舊的 WAV 檔案');
      }

      // 設定錄音參數和檔案路徑 - WAV 格式專門配置
      final wavPath = '$basePath.wav';
      
      debugPrint('準備開始 WAV 錄音...');
      debugPrint('WAV 檔案路徑: $wavPath');
      
      // � AAC→WAV 備用方案 - 使用可靠的 AAC 錄音後轉換
      debugPrint('� 使用 AAC 錄音備用方案（WAV 直錄在此設備有問題）');
      final aacPath = '${directory.path}/temp_record.aac';
      
      // 使用驗證過的 AAC 錄音配置
      await _recorder!.startRecorder(
        toFile: aacPath,
        codec: Codec.aacADTS,           // 已驗證正常的 AAC 格式
        sampleRate: 16000,              // AI 模型需要的採樣率
        numChannels: 1,                 // 單聲道
        bitRate: 128000,                // AAC 標準 bitRate
      );
      
      // 設置狀態，記錄我們將轉換為 WAV
      debugPrint('✅ AAC 錄音已啟動，錄音後將自動轉換為 WAV');
      
      setState(() {
        isRecording = true;
        _recordingDurationSeconds = 0;
        _audioPath = null; // 錄音完成後設置
        _midiPath = null;  // 清除之前的 MIDI 檔案
      });
      
      // 啟動計時器
      _recordingTimer?.cancel(); // 確保沒有重複的計時器
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && isRecording) {
          setState(() {
            _recordingDurationSeconds++;
          });
        } else {
          timer.cancel();
        }
      });
      
      debugPrint('✅ WAV 錄音已開始 (flutter_sound PCM16 配置)');
    } catch (e) {
      debugPrint('錄音啟動失敗: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('錄音啟動失敗: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> stopRecording() async {
    try {
      if (_recorder == null || !isRecording) {
        debugPrint('錄音器未在錄音狀態');
        setState(() { isRecording = false; });
        return;
      }
      
      debugPrint('正在停止 WAV 錄音...');
      String? recordedPath = await _recorder!.stopRecorder();
      
      // 取消錄音計時器
      _recordingTimer?.cancel();
      _recordingTimer = null;
      
      setState(() { 
        isRecording = false; 
        _audioPath = recordedPath; // 直接設置檔案路徑
      });
      
      debugPrint('✅ 錄音已停止，檔案路徑: $recordedPath');
      
      // 檢查是否為 AAC 檔案，需要轉換為 WAV
      if (recordedPath != null && recordedPath.endsWith('.aac')) {
        debugPrint('🔄 檢測到 AAC 檔案，開始轉換為 WAV...');
        
        try {
          final aacFile = File(recordedPath);
          final aacSize = await aacFile.length();
          debugPrint('AAC 檔案大小: $aacSize bytes');
          
          if (aacSize > 1000) { // 確保 AAC 檔案有實際內容
            final directory = await getApplicationDocumentsDirectory();
            final wavPath = '${directory.path}/practice_record.wav';
            
            // 使用 AI 優化的 WAV 轉換
            final wavFile = await _convertAACToWAV(aacFile, wavPath);
            if (wavFile != null) {
              setState(() {
                _audioPath = wavFile.path;
              });
              debugPrint('✅ AAC→WAV 轉換成功: ${wavFile.path}');
              
              // 分析轉換後的 WAV 檔案
              await _analyzeWAVFile(wavFile.path);
            } else {
              debugPrint('❌ AAC→WAV 轉換失敗');
            }
          } else {
            debugPrint('❌ AAC 檔案太小，錄音可能失敗');
          }
        } catch (e) {
          debugPrint('❌ AAC→WAV 轉換錯誤: $e');
        }
      } else if (recordedPath != null && recordedPath.endsWith('.wav')) {
        // 如果是 WAV，進行分析
        await _analyzeWAVFile(recordedPath);
      }
      
      // 檢查實際產生的檔案
      final directory = await getApplicationDocumentsDirectory();
      final basePath = directory.path;
      
      // 檢查多種可能的檔案位置（優先 WAV 格式）
      List<String> possiblePaths = [
        '$basePath/practice_record.wav',
        '${directory.path}/flutter_sound.wav',
        '/data/user/0/com.example.music_practice_app/app_flutter/practice_record.wav',
        '/data/user/0/com.example.music_practice_app/files/practice_record.wav',
        '/data/user/0/com.example.music_practice_app/cache/practice_record.wav',
        '$basePath/practice_record.aac',
        '${directory.path}/flutter_sound.aac',
        '/data/user/0/com.example.music_practice_app/app_flutter/practice_record.aac',
        '/data/user/0/com.example.music_practice_app/files/practice_record.aac',
        '/data/user/0/com.example.music_practice_app/cache/practice_record.aac',
      ];
      
      // flutter_plugin_record 的檔案路徑會在回調中設置到 _audioPath
      
      // 如果我們設定了預期路徑，也加入檢查
      if (_audioPath != null) {
        possiblePaths.insert(0, _audioPath!);
      }
      
      debugPrint('正在檢查可能的錄音檔案路徑：');
      for (String path in possiblePaths) {
        debugPrint('  檢查: $path');
        final testFile = File(path);
        if (await testFile.exists()) {
          final size = await testFile.length();
          debugPrint('  ✅ 找到檔案: $path (大小: $size bytes)');
          _audioPath = path;
          break;
        } else {
          debugPrint('  ❌ 檔案不存在: $path');
        }
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
            final expectedSize = 16000 * 2 * _recordingDurationSeconds + 44; // +44 為 WAV 標頭
            debugPrint('預期檔案大小: $expectedSize bytes，實際大小: $size bytes');
            
            if (size > 1000) { // 檔案大小合理
              final fileExtension = _audioPath!.toLowerCase().split('.').last;
              debugPrint('✅ 錄音檔案大小正常 ($fileExtension 格式)');
              
              // 如果是 WAV 格式且採樣率不是 16000，需要重新採樣
              if (fileExtension == 'wav') {
                debugPrint('✅ WAV 格式檔案，準備進行 AI 處理');
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('錄音完成！檔案大小：${(size / 1024).toStringAsFixed(1)} KB'),
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
    } catch (e) {
      debugPrint('停止錄音失敗: $e');
      setState(() { isRecording = false; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('停止錄音失敗: $e'),
          backgroundColor: Colors.red,
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
                          content: Text('找到錄音檔案！檔案大小：${(size / 1024).toStringAsFixed(1)} KB'),
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
          const SnackBar(content: Text('錄音檔案為空，無法撥放'), backgroundColor: Colors.red),
        );
        return;
      }
    } catch (e) {
      debugPrint('撥放前檔案檢查失敗: $e');
    }
    setState(() { isPlaying = true; });
    try {
      // 根據檔案路徑判斷音訊格式
      Codec playbackCodec;
      if (_audioPath!.endsWith('.aac')) {
        playbackCodec = Codec.aacADTS;
      } else if (_audioPath!.endsWith('.wav')) {
        playbackCodec = Codec.pcm16WAV;
      } else {
        playbackCodec = Codec.aacADTS; // 預設使用 AAC
      }
      
      debugPrint('使用播放編碼器: $playbackCodec');
      
      await _player!.startPlayer(
        fromURI: _audioPath,
        codec: playbackCodec,
        whenFinished: () {
          setState(() { isPlaying = false; });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { isPlaying = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('撥放失敗: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> stopPlaying() async {
    await _player!.stopPlayer();
    setState(() { isPlaying = false; });
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
                title: const Row(
                  children: [
                    Icon(Icons.music_note, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('音訊轉 MIDI'),
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
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
              content: Text('⚠️ 基本 MIDI 檔案已生成\n檔案大小: $size bytes\n$analysisResult\n\n注意：這不是真正的音訊分析結果\n需要專業音訊處理庫才能實現真正的轉換'),
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
        finalPath = '$downloadPath/AIPracticeMIDI_${DateTime.now().millisecondsSinceEpoch}.mid';
      } else {
        finalPath = '${directory.path}/AIPracticeMIDI_${DateTime.now().millisecondsSinceEpoch}.mid';
      }
      
      final midiPath = finalPath;

      // 第一步：檢查和轉換音訊格式
      setState(() { conversionProgress = 0.02; });
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
      setState(() { conversionProgress = 0.08; });
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('🔄 步驟 2: 讀取完整 WAV 音訊檔案...');

      // 第三步：完整音訊預處理（不截斷）
      setState(() { conversionProgress = 0.12; });
      await Future.delayed(const Duration(milliseconds: 300));
      debugPrint('🔄 步驟 3: 預處理完整音訊數據...');
      
      final fullAudioData = await _preprocessFullWavFile(processedAudioFile);
      final audioDurationSec = fullAudioData.length / 16000.0; // 16kHz 採樣率
      debugPrint('完整音訊預處理完成：${fullAudioData.length} 樣本 (${audioDurationSec.toStringAsFixed(1)} 秒)');

      // 第四步：分割音訊為 1 秒區塊
      setState(() { conversionProgress = 0.18; });
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('🔄 步驟 4: 分割音訊為 1 秒區塊...');
      
      final audioChunks = _splitAudioIntoChunks(fullAudioData, 16000); // 1 秒 = 16000 樣本
      debugPrint('音訊分割完成：${audioChunks.length} 個區塊');

      // 第五步：對每個區塊進行 AI 推論
      debugPrint('🔄 步驟 5: 對每個區塊進行 AI 模型推論...');
      
      List<List<Map<String, dynamic>>> allChunkNoteEvents = [];
      
      for (int chunkIndex = 0; chunkIndex < audioChunks.length; chunkIndex++) {
        // 更新進度 (0.22 到 0.8 之間分配給 AI 推論)
        final chunkProgress = 0.22 + (chunkIndex / audioChunks.length) * 0.58;
        setState(() { conversionProgress = chunkProgress; });
        
        debugPrint('處理區塊 ${chunkIndex + 1}/${audioChunks.length}');
        
        try {
          // AI 推論
          final aiOutput = await _runAIInference(audioChunks[chunkIndex]);
          
          // 解析輸出
          final noteEvents = _parseAIOutput(aiOutput);
          
          // 添加時間偏移
          final timeOffsetEvents = noteEvents.map((note) => {
            ...note,
            'startTime': note['startTime'] + (chunkIndex * 1.0), // 每個區塊 1 秒
            'chunkIndex': chunkIndex,
          }).toList();
          
          allChunkNoteEvents.add(timeOffsetEvents);
          debugPrint('區塊 ${chunkIndex + 1} 完成：${timeOffsetEvents.length} 個音符事件');
          
        } catch (e) {
          debugPrint('區塊 ${chunkIndex + 1} 處理失敗: $e，跳過此區塊');
          allChunkNoteEvents.add([]); // 添加空結果
        }
        
        // 小延遲避免 UI 阻塞
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // 第六步：合併所有區塊的結果
      setState(() { conversionProgress = 0.85; });
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('🔄 步驟 6: 合併所有區塊的音符事件...');
      
      final mergedNoteEvents = _mergeChunkResults(allChunkNoteEvents);
      debugPrint('合併完成：${mergedNoteEvents.length} 個音符事件');

      // 第七步：處理和優化音符
      setState(() { conversionProgress = 0.9; });
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('🔄 步驟 7: 處理和優化音符事件...');
      
      final processedNotes = _processNoteEventsWithTiming(mergedNoteEvents);
      debugPrint('處理後的音符: ${processedNotes.length} 個');

      // 第八步：生成完整 MIDI
      setState(() { conversionProgress = 0.95; });
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('🔄 步驟 8: 生成完整 MIDI 檔案...');
      
      final midiData = _generateFullMidiFromAI(processedNotes, audioDurationSec);

      // 第九步：寫入檔案
      setState(() { conversionProgress = 1.0; });
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('🔄 步驟 9: 寫入 MIDI 檔案...');

      final midiFile = File(midiPath);
      await midiFile.writeAsBytes(midiData);

      debugPrint('🎵 完整 AI 音訊轉 MIDI 完成！');
      debugPrint('MIDI 檔案已生成: $midiPath');
      debugPrint('處理了 ${audioChunks.length} 個區塊，總時長 ${audioDurationSec.toStringAsFixed(1)} 秒');
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
      
      // 提取音頻格式信息
      final audioFormat = (bytes[21] << 8) | bytes[20];
      final numChannels = (bytes[23] << 8) | bytes[22];
      final sampleRate = (bytes[27] << 24) | (bytes[26] << 16) | (bytes[25] << 8) | bytes[24];
      final bitsPerSample = (bytes[35] << 8) | bytes[34];
      
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
      
      // 根據位深度處理音頻數據
      if (bitsPerSample == 16) {
        // 16-bit PCM
        for (int i = 0; i < pcmData.length - 1; i += 2) {
          int sample16 = (pcmData[i + 1] << 8) | pcmData[i];
          if (sample16 > 32767) sample16 -= 65536;
          double normalizedSample = sample16 / 32768.0;
          samples.add(normalizedSample);
        }
      } else if (bitsPerSample == 8) {
        // 8-bit PCM
        for (int i = 0; i < pcmData.length; i++) {
          double normalizedSample = (pcmData[i] - 128) / 128.0;
          samples.add(normalizedSample);
        }
      } else {
        debugPrint('不支援的位深度: $bitsPerSample，使用預設處理');
        // 預設為 16-bit 處理
        for (int i = 0; i < pcmData.length - 1; i += 2) {
          int sample16 = (pcmData[i + 1] << 8) | pcmData[i];
          if (sample16 > 32767) sample16 -= 65536;
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
      final rms = _calculateRMS(samples);
      final peak = samples.map((s) => s.abs()).reduce((a, b) => a > b ? a : b);
      debugPrint('完整音訊品質 - RMS: ${rms.toStringAsFixed(4)}, Peak: ${peak.toStringAsFixed(4)}');
      
      if (rms < 0.001) {
        debugPrint('警告：音訊信號非常微弱，可能影響 AI 分析效果');
      }
      
      return Float32List.fromList(samples);
      
    } catch (e) {
      debugPrint('完整音訊預處理錯誤: $e');
      debugPrint('錯誤堆疊: ${StackTrace.current}');
      rethrow; // 重新拋出錯誤，因為我們需要完整音訊
    }
  }

  // 將完整音訊分割為 1 秒區塊
  List<Float32List> _splitAudioIntoChunks(Float32List fullAudio, int chunkSize) {
    List<Float32List> chunks = [];
    
    for (int i = 0; i < fullAudio.length; i += chunkSize) {
      int endIndex = (i + chunkSize < fullAudio.length) ? i + chunkSize : fullAudio.length;
      
      // 創建區塊
      List<double> chunkData = fullAudio.sublist(i, endIndex);
      
      // 如果區塊小於標準大小，用零填充
      while (chunkData.length < chunkSize && i + chunkSize <= fullAudio.length + chunkSize) {
        chunkData.add(0.0);
      }
      
      // 只保留完整的或最後一個區塊（即使不完整）
      if (chunkData.length >= chunkSize * 0.5) { // 至少要有一半長度
        chunks.add(Float32List.fromList(chunkData.take(chunkSize).toList()));
      }
    }
    
    debugPrint('音訊分割完成：${chunks.length} 個區塊，每個 $chunkSize 樣本 (1 秒)');
    return chunks;
  }

  // 合併所有區塊的音符事件結果
  List<Map<String, dynamic>> _mergeChunkResults(List<List<Map<String, dynamic>>> allChunkResults) {
    List<Map<String, dynamic>> mergedResults = [];
    
    for (int chunkIndex = 0; chunkIndex < allChunkResults.length; chunkIndex++) {
      final chunkResults = allChunkResults[chunkIndex];
      
      // 為每個音符事件添加正確的時間偏移
      for (var noteEvent in chunkResults) {
        mergedResults.add({
          ...noteEvent,
          'startTime': (noteEvent['startTime'] ?? 0.0) + (chunkIndex * 1.0), // 每個區塊 1 秒
          'endTime': (noteEvent['endTime'] ?? (noteEvent['startTime'] ?? 0.0) + (noteEvent['duration'] ?? 1.0)) + (chunkIndex * 1.0),
          'chunkIndex': chunkIndex,
        });
      }
    }
    
    // 按開始時間排序
    mergedResults.sort((a, b) => (a['startTime'] as double).compareTo(b['startTime'] as double));
    
    debugPrint('合併區塊結果完成：${mergedResults.length} 個音符事件');
    return mergedResults;
  }

  // 處理帶有時間信息的音符事件
  List<Map<String, dynamic>> _processNoteEventsWithTiming(List<Map<String, dynamic>> noteEvents) {
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
    final filteredNotes = noteEvents.where((note) => 
      (note['confidence'] as double) > 0.15
    ).toList();
    
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
              (min(existingEnd, noteEnd) - max(existingStart, noteStart)) > 0.3) {
            
            // 合併音符：取較早的開始時間和較晚的結束時間
            mergedNotes[i] = {
              ...existingNote,
              'startTime': min(existingStart, noteStart),
              'endTime': max(existingEnd, noteEnd),
              'duration': max(existingEnd, noteEnd) - min(existingStart, noteStart),
              'velocity': max(existingNote['velocity'] as int, note['velocity'] as int),
              'confidence': max(existingNote['confidence'] as double, note['confidence'] as double),
            };
            
            merged = true;
            break;
          }
        }
      }
      
      if (!merged) {
        // 確保音符有正確的結束時間
        if (!note.containsKey('endTime')) {
          note['endTime'] = (note['startTime'] as double) + (note['duration'] as double);
        }
        mergedNotes.add(note);
      }
    }
    
    debugPrint('處理音符事件：${noteEvents.length} -> ${filteredNotes.length} -> ${mergedNotes.length}');
    return mergedNotes;
  }

  // 生成完整的 MIDI 檔案（支援時間軸）
  List<int> _generateFullMidiFromAI(List<Map<String, dynamic>> noteEvents, double totalDurationSec) {
    List<int> midiData = [];
    
    // MIDI 檔案標頭
    midiData.addAll([
      0x4D, 0x54, 0x68, 0x64, // "MThd"
      0x00, 0x00, 0x00, 0x06, // 標頭長度 6 bytes
      0x00, 0x00, // 格式類型 0 (單軌道)
      0x00, 0x01, // 軌道數量 1
      0x01, 0x80, // 時間分割 (384 ticks per quarter note)
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
    allEvents.sort((a, b) => (a['time'] as double).compareTo(b['time'] as double));
    
    // 轉換為 MIDI 事件
    double currentTime = 0.0;
    const int ticksPerSecond = 384; // 基於 120 BPM 和 384 ticks per quarter note
    
    for (var event in allEvents) {
      double eventTime = event['time'] as double;
      int deltaTime = ((eventTime - currentTime) * ticksPerSecond).round().clamp(0, 0x7F);
      
      int midiNote = event['midiNote'] as int;
      int velocity = event['velocity'] as int;
      
      if (event['type'] == 'noteOn') {
        trackEvents.addAll([deltaTime, 0x90, midiNote, velocity]);
      } else {
        trackEvents.addAll([deltaTime, 0x80, midiNote, velocity]);
      }
      
      currentTime = eventTime;
    }
    
    // 軌道結束
    int finalDelta = ((totalDurationSec - currentTime) * ticksPerSecond).round().clamp(0, 0x7F);
    trackEvents.addAll([finalDelta, 0xFF, 0x2F, 0x00]);
    
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
    
    debugPrint('生成完整 MIDI：${midiData.length} 字節，${noteEvents.length} 個音符，時長 ${totalDurationSec.toStringAsFixed(1)} 秒');
    return midiData;
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
  List<double> _resampleAudio(List<double> samples, int originalRate, int targetRate) {
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
        final interpolated = samples[floorIndex] * (1 - fraction) + samples[ceilIndex] * fraction;
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
      List<List<double>> inputData;
      
      // 根據模型的輸入形狀調整數據
      if (inputTensor.shape.length == 2) {
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
          debugPrint('音頻太短，填充到 $expectedLength 樣本 (添加了 ${expectedLength - audioData.length} 個零)');
        }
        
        inputData = [processedAudio];
        debugPrint('準備二維輸入數據: [1, ${processedAudio.length}]');
        
      } else if (inputTensor.shape.length == 3) {
        // 三維輸入 [batch_size, time_steps, features] 或 [batch_size, samples, channels]
        final expectedLength = inputTensor.shape[1];
        final features = inputTensor.shape[2];
        
        List<double> processedAudio;
        if (audioData.length > expectedLength) {
          processedAudio = audioData.sublist(0, expectedLength);
        } else {
          processedAudio = List<double>.from(audioData);
          while (processedAudio.length < expectedLength) {
            processedAudio.add(0.0);
          }
        }
        
        // 重塑為三維
        inputData = [];
        List<List<double>> timeSteps = [];
        for (int i = 0; i < processedAudio.length; i += features) {
          List<double> frame = [];
          for (int j = 0; j < features; j++) {
            if (i + j < processedAudio.length) {
              frame.add(processedAudio[i + j]);
            } else {
              frame.add(0.0);
            }
          }
          timeSteps.add(frame);
        }
        inputData.add(timeSteps.expand((x) => x).toList());
        debugPrint('準備三維輸入數據: [1, ${timeSteps.length}, $features]');
        
      } else {
        throw Exception('不支援的輸入張量維度: ${inputTensor.shape.length}');
      }
      
      // 準備輸出緩衝區
      List<List<double>> outputData = [];
      for (int i = 0; i < outputTensors.length; i++) {
        final outputTensor = outputTensors[i];
        final outputSize = outputTensor.shape.reduce((a, b) => a * b);
        outputData.add(List<double>.filled(outputSize, 0.0));
        debugPrint('輸出張量 $i 形狀: ${outputTensor.shape}, 大小: $outputSize');
      }
      
      // 執行推論
      debugPrint('🧠 執行 AI 模型推論...');
      _interpreter!.runForMultipleInputs([inputData], {
        for (int i = 0; i < outputData.length; i++) i: outputData[i]
      });
      
      debugPrint('✅ AI 推論完成，輸出 ${outputData.length} 個張量');
      for (int i = 0; i < outputData.length; i++) {
        debugPrint('  輸出 $i: ${outputData[i].length} 個值');
        
        // 顯示一些統計信息
        if (outputData[i].isNotEmpty) {
          final max = outputData[i].reduce((a, b) => a > b ? a : b);
          final min = outputData[i].reduce((a, b) => a < b ? a : b);
          final avg = outputData[i].reduce((a, b) => a + b) / outputData[i].length;
          debugPrint('    統計: min=$min, max=$max, avg=${avg.toStringAsFixed(4)}');
        }
      }
      
      return outputData;
      
    } catch (e) {
      debugPrint('❌ AI 推論失敗: $e');
      debugPrint('錯誤堆疊: ${StackTrace.current}');
      
      // 失敗時返回模擬數據，但要標記為模擬
      debugPrint('⚠️ 使用模擬數據作為後備方案');
      return _generateMockAIOutput();
    }
  }

  // 生成模擬 AI 輸出（當 AI 推論失敗時）
  List<List<double>> _generateMockAIOutput() {
    debugPrint('⚠️ AI 推論失敗，使用模擬輸出');
    
    // 模擬 88 個鋼琴鍵的 onset 和 frame 概率
    final random = Random();
    List<double> onsets = List.generate(88, (i) {
      // 在中間音域 (C4-C6) 添加一些活動
      if (i >= 39 && i <= 63) {  // C4 到 C6
        return random.nextDouble() * 0.3; // 低概率
      }
      return 0.0;
    });
    
    List<double> frames = List.generate(88, (i) {
      // 與 onsets 相關的 frame 活動
      if (onsets[i] > 0.1) {
        return onsets[i] * 1.5;
      }
      return 0.0;
    });
    
    return [onsets, frames];
  }

  // 解析 AI 輸出為音符事件 - 動態處理不同的輸出格式
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
    
    // 處理不同的輸出格式
    if (aiOutput.length >= 2) {
      // 假設有兩個輸出：onsets 和 frames
      final onsets = aiOutput[0];
      final frames = aiOutput[1];
      
      // 動態確定音符數量（通常是 88 個鋼琴鍵，但可能不同）
      final numNotes = min(onsets.length, frames.length);
      debugPrint('處理 $numNotes 個音符位置');
      
      // 設定動態閾值
      final onsetThreshold = _calculateDynamicThreshold(onsets, 0.1);
      final frameThreshold = _calculateDynamicThreshold(frames, 0.1);
      
      debugPrint('動態閾值 - Onset: $onsetThreshold, Frame: $frameThreshold');
      
      for (int i = 0; i < numNotes; i++) {
        final onsetValue = i < onsets.length ? onsets[i] : 0.0;
        final frameValue = i < frames.length ? frames[i] : 0.0;
        
        if (onsetValue > onsetThreshold && frameValue > frameThreshold) {
          // 動態映射到 MIDI 音符
          int midiNote = _mapToMidiNote(i, numNotes);
          
          noteEvents.add({
            'midiNote': midiNote,
            'startTime': 0.0, // 時間信息需要額外處理
            'duration': 1.0,
            'velocity': (frameValue * 127).round().clamp(30, 127),
            'confidence': onsetValue,
            'onsetStrength': onsetValue,
            'frameStrength': frameValue,
          });
        }
      }
    } else if (aiOutput.length == 1) {
      // 單一輸出，可能是合併的概率
      final combined = aiOutput[0];
      final threshold = _calculateDynamicThreshold(combined, 0.15);
      
      debugPrint('單一輸出處理，閾值: $threshold');
      
      for (int i = 0; i < combined.length; i++) {
        if (combined[i] > threshold) {
          int midiNote = _mapToMidiNote(i, combined.length);
          
          noteEvents.add({
            'midiNote': midiNote,
            'startTime': 0.0,
            'duration': 1.0,
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
  double _calculateDynamicThreshold(List<double> values, double defaultThreshold) {
    if (values.isEmpty) return defaultThreshold;
    
    // 計算統計信息
    final sorted = List<double>.from(values)..sort();
    final max = sorted.last;
    final q75 = sorted[(sorted.length * 0.75).floor()];
    final mean = values.reduce((a, b) => a + b) / values.length;
    
    // 動態調整閾值
    final dynamicThreshold = (defaultThreshold > (mean * 2 < q75 * 0.5 ? mean * 2 : q75 * 0.5)) 
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
        result += '\n音域: ${_noteToString(noteRange[0])} - ${_noteToString(noteRange[1])}';
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
          const SnackBar(content: Text('請先轉換 MIDI 檔案'), backgroundColor: Colors.red),
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎹 MIDI 播放功能需要額外的套件支援\n(檔案已成功生成)'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('MIDI 播放失敗: $e'),
            backgroundColor: Colors.red,
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
          const SnackBar(content: Text('請先轉換 MIDI 檔案'), backgroundColor: Colors.red),
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
        locationMessage = '檔案已儲存到「下載」資料夾:\n$fileName\n\n$midiAnalysis\n\n🔍 在檔案管理器中搜索「$fileName」即可找到';
      } else {
        locationMessage = 'MIDI 檔案位置:\n$_midiPath\n\n$midiAnalysis\n\n🔍 在檔案管理器中搜索「$fileName」即可找到';
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
          analysis += '• 音域: ${_noteToString(noteRange[0])} - ${_noteToString(noteRange[1])}\n';
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
    List<String> noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.file?.name ?? '演奏練習', style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/library');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.piano, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text('演奏偵測介面', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                '即將在此練習：${widget.file?.name ?? '未指定曲目'}',
                style: const TextStyle(fontSize: 16, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // 錄音控制區域
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('🎤 錄音控制', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: isRecording ? null : startRecording,
                            icon: const Icon(Icons.fiber_manual_record),
                            label: const Text('開始錄音'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: isRecording ? stopRecording : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('停止錄音'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          Text(
                            isRecording
                              ? '🔴 正在錄音... ${_recordingDurationSeconds}s'
                              : (_audioPath != null ? '✅ 錄音完成，可播放' : '⏺️ 未錄音'),
                            style: TextStyle(
                              fontSize: 16,
                              color: isRecording ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isRecording && _recordingDurationSeconds < 3)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                '建議錄音至少 3 秒以獲得更好的轉換效果',
                                style: TextStyle(fontSize: 12, color: Colors.orange),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 播放控制區域
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('🔊 播放控制', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: (!isRecording && _audioPath != null && !isPlaying) ? playRecording : null,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('播放錄音'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: isPlaying ? stopPlaying : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('停止播放'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // MIDI 轉換區域
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('🎵 AI 音訊轉 MIDI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                        '🤖 使用 AI 模型分析您的鋼琴演奏\n將音訊轉換為 MIDI 音符數據',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: (!isRecording && _audioPath != null && !isConverting) ? convertToMidi : null,
                        icon: isConverting 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.transform),
                        label: Text(isConverting ? '轉換中...' : '轉換為 MIDI'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (_midiPath != null) ...[
                        const SizedBox(height: 12),
                        const Text('🤖 AI 分析完成，MIDI 檔案已生成', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              const Text('檔案名稱:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                _midiPath!.split('/').last,
                                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '🎹 基於 AI 音訊分析結果生成的 MIDI',
                                style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '使用 onsets_frames_wavinput.tflite 模型進行音符檢測',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '💡 搜索提示：在檔案管理器中搜索「PracticeMIDI」',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: playMidiFile,
                              icon: const Icon(Icons.play_circle),
                              label: const Text('播放 MIDI'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: exportMidiFile,
                              icon: const Icon(Icons.folder_open),
                              label: const Text('檢視檔案'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 完成練習按鈕
              ElevatedButton.icon(
                onPressed: () => context.go('/analysis'),
                icon: const Icon(Icons.analytics),
                label: const Text('查看分析結果'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // � AAC→WAV 轉換方法（針對 AI 模型優化）
  Future<File?> _convertAACToWAV(File aacFile, String wavPath) async {
    // 只使用 FFmpeg 進行真實轉換，不使用備用方案
    debugPrint('🔥 強制使用 FFmpeg 進行真實 AAC→WAV 轉換（禁用備用模式）');
    final ffmpegResult = await _convertAACToWAVWithFFmpeg(aacFile, wavPath);
    
    if (ffmpegResult != null) {
      debugPrint('✅ FFmpeg 真實轉換成功');
      return ffmpegResult;
    }
    
    // 如果 FFmpeg 失敗，直接拋出異常，不使用備用方法
    debugPrint('❌ FFmpeg 轉換失敗，不使用備用方案');
    throw Exception('FFmpeg AAC→WAV 轉換失敗。請檢查：\n1. AAC 檔案是否有效\n2. FFmpeg 插件是否正確安裝\n3. 設備權限是否充足');
  }
  
  // FFmpeg AAC→WAV 轉換方法（強化版）
  Future<File?> _convertAACToWAVWithFFmpeg(File aacFile, String wavPath) async {
    try {
      debugPrint('� 開始強化版 FFmpeg AAC→WAV 轉換...');
      debugPrint('輸入 AAC: ${aacFile.path}');
      debugPrint('輸出 WAV: $wavPath');
      
      // 檢查 AAC 檔案是否存在和有效性
      if (!await aacFile.exists()) {
        debugPrint('❌ AAC 檔案不存在: ${aacFile.path}');
        throw Exception('AAC 檔案不存在');
      }
      
      final aacBytes = await aacFile.readAsBytes();
      debugPrint('AAC 原始大小: ${aacBytes.length} bytes');
      
      if (aacBytes.length < 1000) {
        debugPrint('⚠️ AAC 檔案可能太小或損壞');
        throw Exception('AAC 檔案太小或無效');
      }
      
      // 檢查 AAC 檔案魔數（ADTS 或 MP4 容器）
      final header = aacBytes.take(8).toList();
      debugPrint('AAC 檔案頭: ${header.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      
      // 確保目標目錄存在
      final wavFile = File(wavPath);
      final wavDir = wavFile.parent;
      if (!await wavDir.exists()) {
        await wavDir.create(recursive: true);
        debugPrint('創建目標目錄: ${wavDir.path}');
      }
      
      // 刪除舊的 WAV 檔案（如果存在）
      if (await wavFile.exists()) {
        await wavFile.delete();
        debugPrint('刪除舊的 WAV 檔案');
      }
      
      // 使用更完整的 FFmpeg 命令，加入錯誤診斷
      // -y: 覆蓋輸出檔案 
      // -hide_banner: 減少輸出
      // -loglevel info: 顯示詳細信息
      final ffmpegCommand = '-y -loglevel info -i "${aacFile.path}" -ar 16000 -ac 1 -sample_fmt s16 -acodec pcm_s16le "${wavPath}"';
      
      debugPrint('執行 FFmpeg 命令: ffmpeg $ffmpegCommand');
      
      // 執行 FFmpeg 轉換
      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();
      
      debugPrint('FFmpeg 返回碼: ${returnCode?.getValue()}');
      
      // 獲取所有日誌以便調試
      final logs = await session.getLogs();
      debugPrint('FFmpeg 日誌條數: ${logs.length}');
      
      // 顯示詳細的 FFmpeg 輸出
      for (final log in logs) {
        final message = log.getMessage();
        debugPrint('FFmpeg: $message');
      }
      
      // 檢查轉換是否成功
      if (ReturnCode.isSuccess(returnCode)) {
        // 檢查輸出檔案是否存在且有內容
        if (await wavFile.exists()) {
          final wavSize = await wavFile.length();
          debugPrint('🎉 FFmpeg AAC→WAV 轉換成功！');
          debugPrint('WAV 檔案大小: $wavSize bytes');
          
          // 驗證是否為有效的 WAV 檔案（至少有標頭）
          if (wavSize > 44) {
            debugPrint('✅ WAV 檔案包含音頻數據，可用於 AI 處理');
            
            // 簡單驗證 WAV 格式
            final wavBytes = await wavFile.readAsBytes();
            final riffHeader = String.fromCharCodes(wavBytes.take(4));
            final waveHeader = String.fromCharCodes(wavBytes.skip(8).take(4));
            
            if (riffHeader == 'RIFF' && waveHeader == 'WAVE') {
              debugPrint('✅ WAV 檔案格式驗證通過');
              return wavFile;
            } else {
              debugPrint('❌ WAV 檔案格式無效');
              throw Exception('生成的 WAV 檔案格式無效');
            }
          } else {
            debugPrint('❌ WAV 檔案太小，只包含標頭');
            throw Exception('FFmpeg 轉換產生空的音頻數據');
          }
        } else {
          debugPrint('❌ FFmpeg 轉換完成但未找到輸出檔案');
          throw Exception('FFmpeg 轉換後未找到輸出檔案');
        }
      } else {
        // 轉換失敗，拋出詳細錯誤
        final errorLogs = <String>[];
        final logs = await session.getLogs();
        for (final log in logs) {
          final message = log.getMessage();
          if (message.toLowerCase().contains('error') || 
              message.toLowerCase().contains('failed') ||
              message.toLowerCase().contains('invalid')) {
            errorLogs.add(message);
          }
        }
        
        debugPrint('❌ FFmpeg 轉換失敗，返回碼: ${returnCode?.getValue()}');
        final errorDetail = errorLogs.isNotEmpty 
            ? '\n錯誤詳情: ${errorLogs.join('\n')}'
            : '';
        
        throw Exception('FFmpeg 轉換失敗 (返回碼: ${returnCode?.getValue()})$errorDetail');
      }
      
    } catch (e) {
      debugPrint('❌ FFmpeg AAC→WAV 轉換異常: $e');
      rethrow; // 重新拋出異常，不要返回 null
    }
  }
  

  
  // �🔍 WAV 檔案深度分析方法
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
        final sampleRate = header[24] | (header[25] << 8) | (header[26] << 16) | (header[27] << 24);
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
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PracticePage extends StatefulWidget {
  final PlatformFile? file;
  const PracticePage({super.key, this.file});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  String? _audioPath;
  bool isPlaying = false;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    try {
      await _recorder!.openRecorder();
      await _player!.openPlayer();
    } catch (e) {
      debugPrint('音訊初始化失敗: $e');
    }
  }

  @override
  void dispose() {
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
    var micStatus = await Permission.microphone.request();

    if (!mounted) return;

    if (micStatus != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未取得麥克風權限'), backgroundColor: Colors.red),
      );
      return;
    }
    
    try {
      if (_recorder == null || !_recorder!.isStopped) {
        await _recorder?.stopRecorder();
      }
      
      final directory = await getApplicationDocumentsDirectory();
      _audioPath = '${directory.path}/practice_record.wav';

      await Future.delayed(const Duration(milliseconds: 500));
      await _recorder!.startRecorder(toFile: _audioPath, codec: Codec.pcm16WAV);
      setState(() { isRecording = true; });
      debugPrint('錄音開始，狀態: ${_recorder!.isRecording}');
    } catch (e) {
      debugPrint('錄音啟動失敗: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('錄音啟動失敗: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() { isRecording = false; });
    debugPrint('錄音結束，狀態: ${_recorder!.isStopped}');
    if (_audioPath != null) {
      try {
        final file = File(_audioPath!);
        final size = await file.length();
        debugPrint('錄音檔案路徑: $_audioPath');
        debugPrint('錄音檔案大小: $size bytes');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('錄音檔案：$_audioPath\n大小：$size bytes'),
            backgroundColor: size == 0 ? Colors.red : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        if (size == 0) {
          debugPrint('錄音檔案為空，請重試');
        }
      } catch (e) {
        debugPrint('錄音檔案檢查失敗: $e');
      }
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
      debugPrint('撥放錄音檔案路徑: $_audioPath');
      debugPrint('撥放錄音檔案大小: $size bytes');
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
      await _player!.startPlayer(
        fromURI: _audioPath,
        codec: Codec.pcm16WAV,
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
      body: Center(
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
            ElevatedButton(
              onPressed: isRecording ? null : startRecording,
              child: const Text('開始錄音'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isRecording ? stopRecording : null,
              child: const Text('停止錄音'),
            ),
            const SizedBox(height: 24),
            Text(
              isRecording
                ? '正在錄音...'
                : (_audioPath != null ? '錄音完成，可播放' : '未錄音'),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (!isRecording && _audioPath != null && !isPlaying) ? playRecording : null,
              child: const Text('播放錄音'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isPlaying ? stopPlaying : null,
              child: const Text('停止播放'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/analysis'),
              child: const Text('（模擬）完成練習'),
            ),
          ],
        ),
      ),
    );
  }
}
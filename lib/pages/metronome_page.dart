// lib/pages/metronome_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:async';
import 'dart:math';

class MetronomePage extends StatefulWidget {
  const MetronomePage({super.key});

  @override
  State<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage> with TickerProviderStateMixin {
  // 節拍器狀態
  bool _isPlaying = false;
  int _bpm = 120; // 每分鐘節拍數
  int _timeSignature = 4; // 拍號 (4/4, 3/4, 2/4)
  int _currentBeat = 0; // 當前拍子
  
  // 計時器
  Timer? _timer;
  
  // 音效播放器
  FlutterSoundPlayer? _audioPlayer;
  
  // 動畫控制器
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // 音效
  bool _soundEnabled = true;
  bool _accentEnabled = true; // 重音節拍
  
  @override
  void initState() {
    super.initState();
    
    // 初始化動畫
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));
    
    // 初始化音效播放器
    _initAudioPlayer();
  }
  
  Future<void> _initAudioPlayer() async {
    try {
      _audioPlayer = FlutterSoundPlayer();
      await _audioPlayer!.openPlayer();
    } catch (e) {
      debugPrint('音效播放器初始化失敗: $e');
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _audioPlayer?.closePlayer();
    super.dispose();
  }
  
  void _startStopMetronome() {
    if (_isPlaying) {
      _stopMetronome();
    } else {
      _startMetronome();
    }
  }
  
  void _startMetronome() {
    setState(() {
      _isPlaying = true;
      _currentBeat = 0;
    });
    
    // 計算間隔時間 (毫秒)
    int intervalMs = (60000 / _bpm).round();
    
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      _playBeat();
    });
    
    // 立即播放第一拍
    _playBeat();
  }
  
  void _stopMetronome() {
    setState(() {
      _isPlaying = false;
      _currentBeat = 0;
    });
    
    _timer?.cancel();
    _timer = null;
  }
  
  void _playBeat() {
    setState(() {
      _currentBeat = (_currentBeat % _timeSignature) + 1;
    });
    
    // 觸覺反饋
    if (_soundEnabled) {
      HapticFeedback.lightImpact();
    }
    
    // 視覺動畫
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
    
    // 這裡可以添加音效播放
    _playSound(_currentBeat == 1 && _accentEnabled);
  }
  
  void _playSound(bool isAccent) async {
    if (!_soundEnabled || _audioPlayer == null) return;
    
    try {
      // 生成節拍音效
      final audioData = _generateBeepSound(isAccent);
      await _audioPlayer!.startPlayer(
        fromDataBuffer: audioData,
        codec: Codec.pcm16WAV,
        sampleRate: 44100,
      );
    } catch (e) {
      // 如果自定義音效失敗，使用系統音效作為備用
      debugPrint('音效播放失敗，使用系統音效: $e');
      if (isAccent) {
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.mediumImpact(); // 重音用更強的震動
      } else {
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.lightImpact();
      }
    }
  }
  
  Uint8List _generateBeepSound(bool isAccent) {
    // 生成節拍音效 - 簡單的嗶聲
    const int sampleRate = 44100;
    const double duration = 0.1; // 100ms
    final int numSamples = (sampleRate * duration).round();
    
    // 重音用更高頻率和音量
    final double frequency = isAccent ? 1000.0 : 800.0; // Hz
    final double amplitude = isAccent ? 0.8 : 0.6;
    
    final List<int> samples = [];
    
    // WAV 檔案標頭 (44 bytes)
    samples.addAll('RIFF'.codeUnits);
    samples.addAll(_int32ToBytes(36 + numSamples * 2)); // 檔案大小
    samples.addAll('WAVE'.codeUnits);
    samples.addAll('fmt '.codeUnits);
    samples.addAll(_int32ToBytes(16)); // fmt chunk 大小
    samples.addAll(_int16ToBytes(1));  // PCM 格式
    samples.addAll(_int16ToBytes(1));  // 單聲道
    samples.addAll(_int32ToBytes(sampleRate)); // 採樣率
    samples.addAll(_int32ToBytes(sampleRate * 2)); // 位元率
    samples.addAll(_int16ToBytes(2));  // 區塊對齊
    samples.addAll(_int16ToBytes(16)); // 位深度
    samples.addAll('data'.codeUnits);
    samples.addAll(_int32ToBytes(numSamples * 2)); // 數據大小
    
    // 生成正弦波音頻數據
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double envelope = 1.0 - (t / duration); // 淡出效果
      final double sample = amplitude * envelope * 
          (0.7 * sin(2 * pi * frequency * t) + 
           0.3 * sin(2 * pi * frequency * 2 * t)); // 添加諧波
      
      final int sampleInt = (sample * 32767).round().clamp(-32768, 32767);
      samples.addAll(_int16ToBytes(sampleInt));
    }
    
    return Uint8List.fromList(samples);
  }
  
  List<int> _int32ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }
  
  List<int> _int16ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
    ];
  }
  
  void _changeBPM(int delta) {
    setState(() {
      _bpm = (_bpm + delta).clamp(40, 200);
    });
    
    // 如果正在播放，重新啟動以應用新的BPM
    if (_isPlaying) {
      _stopMetronome();
      _startMetronome();
    }
  }
  
  void _changeTimeSignature() {
    setState(() {
      if (_timeSignature == 4) {
        _timeSignature = 3;
      } else if (_timeSignature == 3) {
        _timeSignature = 2;
      } else {
        _timeSignature = 4;
      }
      _currentBeat = 0;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: Text(
          '節拍器',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.dynamicTextDark,
          ),
        ),
        backgroundColor: AppColors.dynamicBackground,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _soundEnabled ? Icons.volume_up : Icons.volume_off,
              color: AppColors.dynamicTextDark,
            ),
            onPressed: () {
              setState(() {
                _soundEnabled = !_soundEnabled;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
            
              // BPM 顯示
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.dynamicCard,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'BPM',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.dynamicTextLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_bpm',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dynamicPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // BPM 調整按鈕
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBPMButton('-10', () => _changeBPM(-10)),
                      _buildBPMButton('-1', () => _changeBPM(-1)),
                      _buildBPMButton('+1', () => _changeBPM(1)),
                      _buildBPMButton('+10', () => _changeBPM(10)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 拍號和節拍顯示
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.dynamicCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // 拍號
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '拍號: ',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.dynamicTextDark,
                        ),
                      ),
                      GestureDetector(
                        onTap: _changeTimeSignature,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.dynamicPrimary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_timeSignature/4',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 節拍指示器
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_timeSignature, (index) {
                      bool isActive = _isPlaying && (index + 1) == _currentBeat;
                      bool isAccent = index == 0;
                      
                      return AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          double scale = isActive ? _pulseAnimation.value : 1.0;
                          
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive 
                                    ? (isAccent ? Colors.red : AppColors.dynamicPrimary)
                                    : AppColors.dynamicTextLight.withOpacity(0.3),
                                border: Border.all(
                                  color: isAccent ? Colors.red : AppColors.dynamicPrimary,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive ? Colors.white : AppColors.dynamicTextDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 設定選項
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSettingButton(
                  icon: _accentEnabled ? Icons.music_note : Icons.music_off,
                  label: '重音',
                  isActive: _accentEnabled,
                  onTap: () {
                    setState(() {
                      _accentEnabled = !_accentEnabled;
                    });
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // 播放/停止按鈕
            GestureDetector(
              onTap: _startStopMetronome,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPlaying ? Colors.red : const Color(0xFF2E7D32),
                  boxShadow: [
                    BoxShadow(
                      color: (_isPlaying ? Colors.red : const Color(0xFF2E7D32)).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  _isPlaying ? Icons.stop : Icons.play_arrow,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
        ),
      ),
    );
  }
  
  Widget _buildBPMButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.dynamicPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(50, 40),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
  
  Widget _buildSettingButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.dynamicPrimary : AppColors.dynamicCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.dynamicPrimary,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : AppColors.dynamicPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.dynamicPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// lib/pages/metronome_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

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
  bool _audioPlayerReady = false;
  
  // 動畫控制器
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // 擺動指針動畫控制器
  late AnimationController _pendulumController;
  late Animation<double> _pendulumAnimation;
  
  // 音效
  final bool _soundEnabled = true;
  bool _accentEnabled = true; // 重音節拍
  
  @override
  void initState() {
    super.initState();
    
    // 初始化脈衝動畫
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
    
    // 初始化擺動指針動畫
    _pendulumController = AnimationController(
      duration: Duration(milliseconds: (60000 / _bpm).round()),
      vsync: this,
    );
    
    _pendulumAnimation = Tween<double>(
      begin: -0.4, // 左側 -23度
      end: 0.4,    // 右側 +23度
    ).animate(CurvedAnimation(
      parent: _pendulumController,
      curve: Curves.easeInOut,
    ));
    
    // 在背景非同步初始化音效播放器，避免阻塞 UI
    _initAudioPlayer();
  }
  
  Future<void> _initAudioPlayer() async {
    try {
      _audioPlayer = FlutterSoundPlayer();
      await _audioPlayer!.openPlayer();
      if (mounted) {
        setState(() {
          _audioPlayerReady = true;
        });
      }
      debugPrint('音效播放器初始化成功');
    } catch (e) {
      debugPrint('音效播放器初始化失敗: $e');
      if (mounted) {
        setState(() {
          _audioPlayerReady = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _pendulumController.dispose();
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
    
    // 確保擺動動畫已停止和重置
    _pendulumController.stop();
    _pendulumController.reset();
    
    // 更新擺動動畫速度
    _pendulumController.duration = Duration(milliseconds: intervalMs);
    _pendulumController.repeat(reverse: true);
    
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
    
    // 確保動畫控制器完全停止
    if (_pendulumController.isAnimating) {
      _pendulumController.stop();
    }
    _pendulumController.reset();
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
    if (!_soundEnabled || _audioPlayer == null || !_audioPlayerReady) return;
    
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
  
  // Show BPM input page
  void _showBPMInputDialog(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // 半透明背景
        pageBuilder: (context, animation, secondaryAnimation) {
          return _BPMInputPage(
            currentBPM: _bpm,
            onBPMChanged: (newBPM) {
              setState(() {
                _bpm = newBPM;
                if (_isPlaying) {
                  _stopMetronome();
                  _startMetronome();
                }
              });
            },
          );
        },
      ),
    );
  }

  // Show time signature selection page
  void _showTimeSignatureDialog(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // 半透明背景
        pageBuilder: (context, animation, secondaryAnimation) {
          return _TimeSignaturePage(
            currentTimeSignature: _timeSignature,
            onTimeSignatureChanged: (newTimeSignature) {
              setState(() {
                _timeSignature = newTimeSignature;
              });
            },
          );
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
    const bottomNavHeight = 80.0; // 底部導覽欄高度
    const bottomPadding = 24.0; // 與導覽欄保持的安全距離（增加）
    final availableHeight = screenHeight - appBarHeight - bottomNavHeight - bottomPadding - MediaQuery.of(context).padding.bottom;
    
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
      ),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(), // 禁止滾動
        child: Container(
          height: availableHeight,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              // 合併的卡片 - BPM調整 + 擺錘區域 (自適應高度)
              Expanded(
                flex: 7,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.dynamicCard,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                  children: [
                    // BPM控制區 - 固定在頂部，縮小間距
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Column(
                        children: [
                          // BPM Display (可點擊輸入)
                          GestureDetector(
                            onTap: () => _showBPMInputDialog(context),
                            child: Column(
                              children: [
                                Text(
                                  '$_bpm',
                                  style: TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.dynamicPrimary,
                                  ),
                                ),
                                Text(
                                  'BPM (點擊輸入)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.dynamicTextLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // BPM Control Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildCircularButton(
                                icon: Icons.remove,
                                onPressed: () => _changeBPM(-1),
                                size: 45,
                              ),
                              const SizedBox(width: 50),
                              _buildCircularButton(
                                icon: Icons.add,
                                onPressed: () => _changeBPM(1),
                                size: 45,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // 分隔線 - 縮小邊距
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      color: AppColors.dynamicTextLight.withOpacity(0.1),
                    ),
                    
                    // Pendulum Area - 佔據剩餘空間
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // 計算擺錘桿的實際可用長度
                            final pendulumAreaHeight = constraints.maxHeight;
                            const pivotBottomPadding = 40.0;
                            const weightRadius = 32.0;
                            final rodLength = (pendulumAreaHeight - pivotBottomPadding - weightRadius - 50).clamp(60.0, 250.0);
                          
                            return Stack(
                              children: [
                              // Scale marks background - 固定在擺錘軸心上方
                              Positioned(
                                bottom: pivotBottomPadding,
                                left: 0,
                                right: 0,
                                height: rodLength + weightRadius + 50, // 刻度高度 = 桿長 + 重錘 + 額外空間
                                child: CustomPaint(
                                  painter: MetronomeScalePainter(
                                    color: AppColors.dynamicTextLight.withOpacity(0.3),
                                    rodLength: rodLength,
                                  ),
                                ),
                              ),
                              // Pendulum with pivot at bottom (軸心在下方)
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: pivotBottomPadding),
                                  child: AnimatedBuilder(
                                    animation: _pendulumAnimation,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _isPlaying ? _pendulumAnimation.value : 0,
                                        alignment: Alignment.bottomCenter, // 軸心在底部
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Top weight
                                            Container(
                                              width: weightRadius,
                                              height: weightRadius,
                                              decoration: BoxDecoration(
                                                color: _currentBeat == 1 && _isPlaying
                                                    ? Colors.red
                                                    : AppColors.dynamicPrimary,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: (_currentBeat == 1 && _isPlaying
                                                        ? Colors.red
                                                        : AppColors.dynamicPrimary)
                                                        .withOpacity(0.5),
                                                    blurRadius: 10,
                                                    spreadRadius: 3,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Rod - 動態高度基於實際可用空間
                                            Container(
                                              width: 5,
                                              height: rodLength, // 使用計算好的長度
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    AppColors.dynamicPrimary,
                                                    AppColors.dynamicPrimary.withOpacity(0.6),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(2.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Pivot point indicator (軸心指示器)
                              Positioned(
                                bottom: pivotBottomPadding - 10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.dynamicTextDark,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.dynamicPrimary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Bottom Controls Card - 拍號控制與播放
          Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.dynamicCard,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // 垂直置中
                  children: [
                    // Beat indicators
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
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive 
                                      ? (isAccent && _accentEnabled ? Colors.red : AppColors.dynamicPrimary)
                                      : AppColors.dynamicTextLight.withOpacity(0.2),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Time Signature (點擊彈窗選擇)
                        _buildControlCard(
                          icon: Icons.music_note,
                          label: '$_timeSignature/4',
                          onTap: () => _showTimeSignatureDialog(context),
                        ),
                        // Play/Stop (大按鈕)
                        GestureDetector(
                          onTap: _startStopMetronome,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isPlaying ? Colors.red : const Color(0xFF2E7D32),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isPlaying ? Colors.red : const Color(0xFF2E7D32))
                                      .withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isPlaying ? Icons.stop : Icons.play_arrow,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Accent toggle
                        _buildControlCard(
                          icon: Icons.volume_up,
                          label: '重音',
                          onTap: () {
                            setState(() {
                              _accentEnabled = !_accentEnabled;
                            });
                          },
                          isActive: _accentEnabled,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
  
  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 60,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.dynamicPrimary,
        boxShadow: [
          BoxShadow(
            color: AppColors.dynamicPrimary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: size * 0.5),
        onPressed: onPressed,
      ),
    );
  }
  
  Widget _buildControlCard({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.dynamicPrimary : AppColors.dynamicCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.dynamicPrimary.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : AppColors.dynamicPrimary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.dynamicTextDark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  }

// BPM 輸入頁面
class _BPMInputPage extends StatefulWidget {
  final int currentBPM;
  final Function(int) onBPMChanged;

  const _BPMInputPage({
    required this.currentBPM,
    required this.onBPMChanged,
  });

  @override
  State<_BPMInputPage> createState() => _BPMInputPageState();
}

class _BPMInputPageState extends State<_BPMInputPage> {
  late String inputValue;

  @override
  void initState() {
    super.initState();
    inputValue = widget.currentBPM.toString();
  }

  void _handleNumberInput(String value) {
    setState(() {
      if (value == '清除') {
        inputValue = '0';
      } else if (value == '⌫') {
        if (inputValue.length > 1) {
          inputValue = inputValue.substring(0, inputValue.length - 1);
        } else {
          inputValue = '0';
        }
      } else {
        // 數字輸入
        if (inputValue == '0' || inputValue.isEmpty) {
          inputValue = value;
        } else if (inputValue.length < 3) {
          inputValue += value;
        }
      }
    });
  }

  void _handleConfirm() {
    int newBPM = int.tryParse(inputValue) ?? widget.currentBPM;
    if (newBPM >= 30 && newBPM <= 300) {
      widget.onBPMChanged(newBPM);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('BPM 必須在 30 到 300 之間'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.15), // 降低透明度
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(), // 點擊外部關閉
        child: Center(
          child: GestureDetector(
            onTap: () {}, // 防止點擊卡片時關閉
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 350), // 限制最大寬度
              decoration: BoxDecoration(
                color: AppColors.dynamicCard, // 實色背景
                borderRadius: BorderRadius.circular(24), // 圓角
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 關閉按鈕在卡片內左上角
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.dynamicTextDark),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  // BPM 顯示
                  Container(
                    width: 200, // 固定寬度
                    height: 100, // 固定高度
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.dynamicPrimary, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center, // 數字置中
                    child: Text(
                      inputValue,
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dynamicPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 數字鍵盤 (1-9)
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.3,
                    children: [
                      for (int i = 1; i <= 9; i++)
                        _buildNumberButton(i.toString()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 0, 清除, 刪除 (橫排顯示)
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberButton('清除', isSpecial: true),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildNumberButton('0'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildNumberButton('⌫', isSpecial: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 確定按鈕 (延長寬度)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dynamicPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '確定',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String text, {bool isSpecial = false}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSpecial
            ? Colors.red.withOpacity(0.1)
            : AppColors.dynamicPrimary.withOpacity(0.1),
        foregroundColor: isSpecial ? Colors.red : AppColors.dynamicPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      ),
      onPressed: () => _handleNumberInput(text),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: TextStyle(
            fontSize: text == '清除' || text == '⌫' ? 18 : 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// 拍號選擇頁面
class _TimeSignaturePage extends StatelessWidget {
  final int currentTimeSignature;
  final Function(int) onTimeSignatureChanged;

  const _TimeSignaturePage({
    required this.currentTimeSignature,
    required this.onTimeSignatureChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.15), // 降低透明度
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(), // 點擊外部關閉
        child: Center(
          child: GestureDetector(
            onTap: () {}, // 防止點擊卡片時關閉
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 50),
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 320), // 縮小卡片
              decoration: BoxDecoration(
                color: AppColors.dynamicCard, // 實色背景
                borderRadius: BorderRadius.circular(24), // 圓角
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 關閉按鈕在卡片內左上角
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.dynamicTextDark),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 拍號選項
                  for (var beats in [2, 3, 4, 6])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        onTap: () {
                          onTimeSignatureChanged(beats);
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: currentTimeSignature == beats
                                ? AppColors.dynamicPrimary.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: currentTimeSignature == beats
                                  ? AppColors.dynamicPrimary
                                  : AppColors.dynamicTextLight.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$beats/4',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: currentTimeSignature == beats
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: currentTimeSignature == beats
                                        ? AppColors.dynamicPrimary
                                        : AppColors.dynamicTextDark,
                                  ),
                                ),
                              ),
                              if (currentTimeSignature == beats)
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.dynamicPrimary,
                                  size: 26,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 自定義繪製器：繪製節拍器刻度
class MetronomeScalePainter extends CustomPainter {
  final Color color;
  final double rodLength;
  
  MetronomeScalePainter({
    required this.color,
    required this.rodLength,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final centerX = size.width / 2;
    final centerY = size.height; // 軸心位置在底部
    
    // 刻度弧形的半徑 = 擺錘桿長度 + 重錘半徑的一半
    final scaleRadius = rodLength + 17.5; // 17.5 = 重錘半徑的一半
    
    // 繪製扇形刻度線（從左 -40° 到右 +40°）
    for (int i = -4; i <= 4; i++) {
      // 角度從 -40度 到 +40度
      final angleDegrees = i * 10.0; // 每個刻度間隔10度
      // 轉換為弧度，0度向上
      final angleRadians = (angleDegrees) * pi / 180;
      
      const tickLength = 15.0; // 刻度線長度
      final startRadius = scaleRadius - tickLength;
      final endRadius = scaleRadius;
      
      final startX = centerX + startRadius * sin(angleRadians);
      final startY = centerY - startRadius * cos(angleRadians);
      final endX = centerX + endRadius * sin(angleRadians);
      final endY = centerY - endRadius * cos(angleRadians);
      
      final start = Offset(startX, startY);
      final end = Offset(endX, endY);
      
      // 中間刻度（0度）加粗
      if (i == 0) {
        canvas.drawLine(start, end, Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);
      } else {
        canvas.drawLine(start, end, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(MetronomeScalePainter oldDelegate) {
    return oldDelegate.rodLength != rodLength || oldDelegate.color != color;
  }
}
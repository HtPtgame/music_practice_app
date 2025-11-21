import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart' show Level;
import 'package:music_practice_app/services/settings_service.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:music_practice_app/l10n/app_localizations.dart';

class MetronomePage extends StatefulWidget {
  const MetronomePage({super.key});

  @override
  State<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage>
    with TickerProviderStateMixin {
  // --- 核心狀態 ---
  bool _isPlaying = false;
  int _bpm = 120;
  int _timeSignature = 4;

  final ValueNotifier<int> _currentBeatNotifier = ValueNotifier<int>(0);

  // --- 設定快取 ---
  bool _soundEnabled = true;
  bool _accentEnabled = true;
  double _cachedVolume = 0.5;

  // --- 服務與計時 ---
  final SettingsService _settingsService = SettingsService();
  Timer? _metronomeTimer;

  // --- 音訊系統 ---
  FlutterSoundPlayer? _audioPlayer;
  bool _audioPlayerReady = false;
  Uint8List? _normalBeepBuffer;
  Uint8List? _accentBeepBuffer;

  // --- 動畫控制器 ---
  late AnimationController _pendulumController;
  late Animation<double> _pendulumAnimation;

  @override
  void initState() {
    super.initState();
    _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    _initAnimations();
    _normalBeepBuffer = _generateBeepSound(false);
    _accentBeepBuffer = _generateBeepSound(true);
    await _initAudioPlayer();
    await _loadSettings();
  }

  void _initAnimations() {
    _pendulumController = AnimationController(
      duration: Duration(milliseconds: (60000 / _bpm).round()),
      vsync: this,
    );

    _pendulumAnimation = Tween<double>(
      // 0.52 radians 約等於 30度，對應第二條刻度線位置
      begin: -0.52, 
      end: 0.52,
    ).animate(CurvedAnimation(
      parent: _pendulumController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initAudioPlayer() async {
    try {
      _audioPlayer = FlutterSoundPlayer();
      _audioPlayer!.setLogLevel(Level.error);
      await _audioPlayer!.openPlayer();
      if (mounted) {
        setState(() {
          _audioPlayerReady = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Audio Player Init Error: $e');
    }
  }

  Future<void> _loadSettings() async {
    final sound = await _settingsService.isSoundEnabled();
    final metVol = await _settingsService.getMetronomeVolume();
    final masVol = await _settingsService.getMasterVolume();

    if (mounted) {
      setState(() {
        _soundEnabled = sound;
        _cachedVolume = metVol * masVol;
      });
      if (_audioPlayerReady) {
        await _audioPlayer!.setVolume(_cachedVolume);
      }
    }
  }

  @override
  void dispose() {
    _metronomeTimer?.cancel();
    _audioPlayer?.closePlayer();
    _pendulumController.dispose();
    super.dispose();
  }

  // --- 核心邏輯 ---

  void _toggleMetronome() {
    if (_isPlaying) {
      _stopMetronome();
    } else {
      _startMetronome();
    }
  }

  void _startMetronome() {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
      _currentBeatNotifier.value = 0;
    });

    _updatePendulumSpeed();
    _pendulumController.repeat(reverse: true);

    final double intervalMs = 60000 / _bpm;
    _tick(); 

    _metronomeTimer = Timer.periodic(Duration(milliseconds: intervalMs.round()), (timer) {
      _tick();
    });
  }

  void _stopMetronome() {
    _metronomeTimer?.cancel();
    _metronomeTimer = null;

    if (mounted) {
      setState(() {
        _isPlaying = false;
        _currentBeatNotifier.value = 0;
      });
      _pendulumController.stop();
      // 歸零回到中間 (0.5)
      _pendulumController.animateTo(0.5, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _tick() {
    if (!mounted) return;
    int nextBeat = (_currentBeatNotifier.value % _timeSignature) + 1;
    _currentBeatNotifier.value = nextBeat;

    final bool isAccent = nextBeat == 1 && _accentEnabled;
    _playBeatSound(isAccent);
  }

  void _playBeatSound(bool isAccent) {
    if (!_soundEnabled || !_audioPlayerReady || _normalBeepBuffer == null) return;
    final buffer = isAccent ? _accentBeepBuffer! : _normalBeepBuffer!;
    _audioPlayer!.startPlayer(
      fromDataBuffer: buffer,
      codec: Codec.pcm16WAV,
      sampleRate: 44100,
      whenFinished: () {},
    ).catchError((e) => null);
  }

  void _changeBPM(int delta) {
    final newBpm = (_bpm + delta).clamp(30, 200); // 保持上限 200
    if (newBpm == _bpm) return;

    setState(() {
      _bpm = newBpm;
    });

    if (_isPlaying) {
      _metronomeTimer?.cancel();
      _updatePendulumSpeed();
      final double intervalMs = 60000 / _bpm;
      _metronomeTimer = Timer.periodic(Duration(milliseconds: intervalMs.round()), (timer) {
        _tick();
      });
    }
  }

  void _updatePendulumSpeed() {
    _pendulumController.duration = Duration(milliseconds: (60000 / _bpm).round());
    if (_isPlaying) {
      _pendulumController.repeat(reverse: true);
    }
  }

  // --- 音訊生成 ---
  Uint8List _generateBeepSound(bool isAccent) {
    const int sampleRate = 44100;
    const double duration = 0.1; // 稍微延長以獲得更平滑的淡出
    final int numSamples = (sampleRate * duration).round();
    final double frequency = isAccent ? 1000.0 : 800.0; 
    final double masterGain = 0.7; 

    final List<int> samples = [];
    samples.addAll('RIFF'.codeUnits);
    samples.addAll(_int32ToBytes(36 + numSamples * 2));
    samples.addAll('WAVE'.codeUnits);
    samples.addAll('fmt '.codeUnits);
    samples.addAll(_int32ToBytes(16));
    samples.addAll(_int16ToBytes(1));
    samples.addAll(_int16ToBytes(1));
    samples.addAll(_int32ToBytes(sampleRate));
    samples.addAll(_int32ToBytes(sampleRate * 2));
    samples.addAll(_int16ToBytes(2));
    samples.addAll(_int16ToBytes(16));
    samples.addAll('data'.codeUnits);
    samples.addAll(_int32ToBytes(numSamples * 2));

    // 計算淡入淡出長度（避免 clicking/popping 雜音）
    const int fadeInSamples = 100;  // 約 2.3ms 淡入
    const int fadeOutSamples = 300; // 約 6.8ms 淡出

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      
      // 平滑的淡入淡出 envelope
      double envelope = 1.0;
      
      // 淡入（使用 sin 曲線更平滑）
      if (i < fadeInSamples) {
        envelope = sin((i / fadeInSamples) * pi / 2);
      }
      // 淡出（使用指數衰減）
      else {
        envelope = exp(-8 * t);
      }
      
      // 尾部額外的線性淡出（確保結尾完全靜音）
      if (i > numSamples - fadeOutSamples) {
        final fadeOutProgress = (numSamples - i) / fadeOutSamples;
        envelope *= fadeOutProgress;
      }
      
      // 生成純淨的正弦波
      final double sample = masterGain * envelope * sin(2 * pi * frequency * t);
      final int sampleInt = (sample * 32767).round().clamp(-32768, 32767);
      samples.addAll(_int16ToBytes(sampleInt));
    }
    return Uint8List.fromList(samples);
  }

  List<int> _int32ToBytes(int value) => [value & 0xFF, (value >> 8) & 0xFF, (value >> 16) & 0xFF, (value >> 24) & 0xFF];
  List<int> _int16ToBytes(int value) => [value & 0xFF, (value >> 8) & 0xFF];

  // --- UI 彈窗 ---
  void _showBPMInputDialog(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _BPMInputPage(
            currentBPM: _bpm,
            onBPMChanged: (newBPM) {
              int diff = newBPM - _bpm;
              if (diff != 0) _changeBPM(diff);
            },
          );
        },
      ),
    );
  }

  void _showTimeSignatureDialog(BuildContext context) {
      setState(() {
         if(_timeSignature == 4) _timeSignature = 3;
         else if (_timeSignature == 3) _timeSignature = 2;
         else _timeSignature = 4;
      });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: Text(
          l10n?.metronomeTitle ?? 'Metronome',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dynamicTextDark),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.dynamicTextDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // --- 上半部：擺錘與 BPM ---
              Expanded(
                flex: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.dynamicCard,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      // BPM Display
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 8),
                        child: GestureDetector(
                          onTap: () => _showBPMInputDialog(context),
                          child: Column(
                            children: [
                              Text(
                                '$_bpm',
                                style: TextStyle(fontSize: 64, fontWeight: FontWeight.w700, color: AppColors.dynamicPrimary, height: 1.0),
                              ),
                              Text(
                                'BPM (點擊輸入)',
                                style: TextStyle(fontSize: 12, color: AppColors.dynamicTextLight),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // BPM Slider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                             _buildRoundButton(Icons.remove, () => _changeBPM(-1)),
                             Expanded(
                               child: SliderTheme(
                                 data: SliderTheme.of(context).copyWith(
                                   activeTrackColor: AppColors.dynamicPrimary.withOpacity(0.2),
                                   thumbColor: AppColors.dynamicPrimary,
                                   overlayColor: AppColors.dynamicPrimary.withOpacity(0.1),
                                   thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                   trackHeight: 4,
                                 ),
                                 child: Slider(
                                   value: _bpm.toDouble(),
                                   min: 30,
                                   max: 200,
                                   onChanged: (val) => _changeBPM(val.toInt() - _bpm),
                                 ),
                               ),
                             ),
                             _buildRoundButton(Icons.add, () => _changeBPM(1)),
                          ],
                        ),
                      ),

                      // 擺錘動畫區
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double availableHeight = constraints.maxHeight;
                            final double radius = availableHeight - 30; 
                            // 擺桿長度調整
                            final double rodLength = radius - 24;

                            return Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                // 1. 背景刻度
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: MetronomeScalePainter(
                                      color: AppColors.dynamicTextLight.withOpacity(0.2), 
                                      radius: radius,
                                      // 刻度圓心向上位移，以配合軸心圓點的位置
                                      pivotOffset: const Offset(0, -6), 
                                    ),
                                  ),
                                ),
                                
                                // 2. 旋轉的擺錘 (僅包含重錘與擺桿)
                                // ✨ 修正 1：透過 Padding 抬高旋轉軸心，使其對齊下方的靜止圓點中心
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6), // 6px 是圓點半徑 (12/2)
                                  child: AnimatedBuilder(
                                    animation: _pendulumAnimation,
                                    builder: (context, child) {
                                      return Transform(
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.001)
                                          ..rotateZ(_pendulumAnimation.value),
                                        alignment: Alignment.bottomCenter, // 繞著自己的底部旋轉
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            // 重錘
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: AppColors.dynamicPrimary,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.dynamicPrimary.withOpacity(0.5),
                                                    blurRadius: 10,
                                                    spreadRadius: 3,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // 擺桿
                                            Container(
                                              width: 5,
                                              height: rodLength > 0 ? rodLength : 0,
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
                                            // 這裡不需要軸心圓點，因為它要跟著旋轉
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // 3. ✨ 修正 1：靜止的軸心圓點 (放在最上層，不參與旋轉)
                                Container(
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
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- 下半部：控制面板 ---
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicCard,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Beat Indicators
                      SizedBox(
                        height: 24, 
                        child: ValueListenableBuilder<int>(
                          valueListenable: _currentBeatNotifier,
                          builder: (context, currentBeat, _) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_timeSignature, (index) {
                                final bool isActive = currentBeat == (index + 1);
                                final bool isAccent = index == 0;
                                
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 80),
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  width: isActive ? 16 : 10,
                                  height: isActive ? 16 : 10,
                                  decoration: BoxDecoration(
                                    color: isActive 
                                        ? (isAccent && _accentEnabled ? Colors.redAccent : AppColors.dynamicPrimary)
                                        : AppColors.dynamicTextLight.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    boxShadow: isActive ? [
                                      BoxShadow(
                                        color: (isAccent && _accentEnabled ? Colors.redAccent : AppColors.dynamicPrimary).withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ] : [],
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlCard(
                            icon: Icons.music_note,
                            label: "$_timeSignature/4",
                            isActive: false,
                            onTap: () => _showTimeSignatureDialog(context),
                          ),

                          GestureDetector(
                            onTap: _toggleMetronome,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: _isPlaying ? Colors.redAccent : AppColors.dynamicPrimary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isPlaying ? Colors.redAccent : AppColors.dynamicPrimary).withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: Icon(
                                _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),

                          _buildControlCard(
                            icon: _accentEnabled ? Icons.volume_up : Icons.volume_mute,
                            label: l10n?.metronomeAccent ?? "重音",
                            isActive: _accentEnabled,
                            onTap: () => setState(() => _accentEnabled = !_accentEnabled),
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
      ),
    );
  }

  Widget _buildControlCard({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.dynamicPrimary : AppColors.dynamicTextLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              color: isActive ? Colors.white : AppColors.dynamicTextDark,
              size: 24
            ),
            const SizedBox(height: 4),
            Text(
              label, 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold, 
                color: isActive ? Colors.white : AppColors.dynamicTextDark
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.dynamicPrimary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.dynamicPrimary),
        ),
      ),
    );
  }
}

class MetronomeScalePainter extends CustomPainter {
  final Color color;
  final double radius;
  final Offset pivotOffset;

  MetronomeScalePainter({
    required this.color, 
    required this.radius,
    this.pivotOffset = const Offset(0, 0),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final centerX = size.width / 2;
    final centerY = size.height + pivotOffset.dy;

    // 繪製扇形刻度線（從左 -30° 到右 +30°）
    for (int i = -3; i <= 3; i++) {
      // 角度從 -30度 到 +30度
      final angleDegrees = i * 10.0; // 每個刻度間隔10度
      // 轉換為弧度，0度向上
      final angleRadians = (angleDegrees) * pi / 180;

      const tickLength = 15.0; // 刻度線長度
      final startRadius = radius - tickLength;
      final endRadius = radius;

      final startX = centerX + startRadius * sin(angleRadians);
      final startY = centerY - startRadius * cos(angleRadians);
      final endX = centerX + endRadius * sin(angleRadians);
      final endY = centerY - endRadius * cos(angleRadians);

      final start = Offset(startX, startY);
      final end = Offset(endX, endY);

      // 中間刻度（0度）加粗
      if (i == 0) {
        canvas.drawLine(
          start,
          end,
          Paint()
            ..color = color
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke,
        );
      } else {
        canvas.drawLine(start, end, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BPMInputPage extends StatefulWidget {
  final int currentBPM;
  final Function(int) onBPMChanged;
  const _BPMInputPage({required this.currentBPM, required this.onBPMChanged});
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
      if (value == 'C') { inputValue = '0'; } 
      else if (value == '⌫') {
        if (inputValue.length > 1) inputValue = inputValue.substring(0, inputValue.length - 1);
        else inputValue = '0';
      } else {
        if (inputValue == '0') inputValue = value;
        else if (inputValue.length < 3) inputValue += value;
      }
    });
  }

  void _handleConfirm() {
    int newBPM = int.tryParse(inputValue) ?? widget.currentBPM;
    if (newBPM < 30) newBPM = 30;
    if (newBPM > 200) newBPM = 200;
    widget.onBPMChanged(newBPM);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.4),
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: GestureDetector(
            onTap: () {}, 
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.dynamicCard,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text(inputValue, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.dynamicPrimary)),
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: [
                      for (var i = 1; i <= 9; i++) _buildNumBtn('$i'),
                      _buildNumBtn('C', isAction: true),
                      _buildNumBtn('0'),
                      _buildNumBtn('⌫', isAction: true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dynamicPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("確定", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumBtn(String label, {bool isAction = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNumberInput(label),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isAction ? Colors.red.withOpacity(0.1) : AppColors.dynamicTextLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isAction ? Colors.red : AppColors.dynamicTextDark)),
        ),
      ),
    );
  }
}
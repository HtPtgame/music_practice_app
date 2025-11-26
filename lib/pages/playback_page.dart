import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_practice_app/services/midi_player_service.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:music_practice_app/l10n/app_localizations.dart';

class PlaybackPage extends StatefulWidget {
  final PlatformFile? file;
  const PlaybackPage({super.key, this.file});

  @override
  State<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  final MidiPlayerService _midiService = MidiPlayerService();
  StreamSubscription? _playingStateSubscription;
  StreamSubscription? _progressSubscription;

  bool _isLoading = true;
  bool _isPlaying = false;

  double _currentPosition = 0.0;
  double get _totalDuration => _midiService.totalDurationMs / 1000.0; // 秒

  @override
  void initState() {
    super.initState();
    _initialize();

    _playingStateSubscription =
        _midiService.playingStateStream.listen((isPlaying) {
      if (mounted) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    });

    _progressSubscription = _midiService.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _currentPosition = progress * _totalDuration;
        });
      }
    });
  }

  Future<void> _initialize() async {
    await _midiService.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _playingStateSubscription?.cancel();
    _progressSubscription?.cancel();
    _midiService.stop();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (widget.file?.path == null) return;

    if (_isPlaying) {
      _midiService.pause();
    } else {
      if (_currentPosition > 0) {
        _midiService.resume();
      } else {
        try {
          await _midiService.play(widget.file!.path!);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('播放失敗: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: '確定',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        }
      }
    }
  }

  void _restart() async {
    if (widget.file?.path == null) return;
    
    try {
      await _midiService.stop();
      await Future.delayed(const Duration(milliseconds: 200));
      await _midiService.play(widget.file!.path!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('重新播放失敗: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _stop() {
    _midiService.stop();
  }

  String _formatTime(double seconds) {
    final int minutes = (seconds / 60).floor();
    final int remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    final primaryColor = AppColors.dynamicPrimary;
    final backgroundColor = AppColors.dynamicBackground;
    final cardColor = AppColors.dynamicCard;
    final textDark = AppColors.dynamicTextDark;
    final textLight = AppColors.dynamicTextLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n?.playbackTitle ?? 'MIDI Player',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textDark,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textDark),
          onPressed: () => context.go('/library'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 400),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                // 1. 視覺區域 (專輯封面) - 回歸靜態
                                Container(
                                  width: screenWidth * 0.5,
                                  height: screenWidth * 0.5,
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                    maxWidth: 200,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.music_note_rounded,
                                      size: 80,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 28),

                                // 2. 資訊區域 (歌名)
                                Text(
                                  widget.file?.name ?? (l10n?.playbackUnknownFile ?? 'Unknown Track'),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                // 副標題已移除

                                const SizedBox(height: 32),

                                // 3. 進度條區域
                                Column(
                                  children: [
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 6.0,
                                        activeTrackColor: primaryColor,
                                        inactiveTrackColor: primaryColor.withOpacity(0.2),
                                        thumbColor: primaryColor,
                                        overlayColor: primaryColor.withOpacity(0.1),
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                      ),
                                      child: Slider(
                                        value: _totalDuration > 0 
                                            ? _currentPosition.clamp(0.0, _totalDuration)
                                            : 0.0,
                                        max: _totalDuration > 0 ? _totalDuration : 1.0,
                                        onChanged: null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatTime(_currentPosition),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textLight,
                                            fontWeight: FontWeight.w500
                                          ),
                                        ),
                                        Text(
                                          _formatTime(_totalDuration),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textLight,
                                            fontWeight: FontWeight.w500
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 32),

                                // 4. 控制按鈕區域
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      onPressed: _isLoading ? null : _restart,
                                      icon: const Icon(Icons.replay_rounded),
                                      iconSize: 28,
                                      color: textLight,
                                      tooltip: l10n?.playbackTooltipReplay ?? 'Replay',
                                    ),
                                    
                                    Container(
                                      height: 72,
                                      width: 72,
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withOpacity(0.3),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          )
                                        ],
                                      ),
                                      child: IconButton(
                                        onPressed: _isLoading ? null : _togglePlayPause,
                                        icon: Icon(
                                          _isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                        ),
                                        iconSize: 36,
                                        color: Colors.white,
                                        tooltip: _isPlaying 
                                            ? (l10n?.playbackTooltipPause ?? 'Pause') 
                                            : (l10n?.playbackTooltipPlay ?? 'Play'),
                                      ),
                                    ),

                                    IconButton(
                                      onPressed: _isLoading ? null : _stop,
                                      icon: const Icon(Icons.stop_rounded),
                                      iconSize: 28,
                                      color: textLight,
                                      tooltip: l10n?.playbackTooltipStop ?? 'Stop',
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
                );
              },
            ),
    );
  }
}
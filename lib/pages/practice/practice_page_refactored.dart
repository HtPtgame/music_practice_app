/// PracticePage 重構版本
///
/// Phase 3 重構: 使用 Provider 狀態管理，整合新的控制器架構
/// 目標: 從原本 1620 行縮減至約 300 行
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:music_practice_app/utils/app_colors.dart';
import 'package:music_practice_app/l10n/app_localizations.dart';
import 'package:music_practice_app/pages/analysis_result_page.dart';
import 'package:music_practice_app/utils/error_handler.dart';
import 'package:music_practice_app/widgets/countdown_overlay.dart';

// 新的模組化元件
import 'practice.dart';

/// 重構後的練習頁面
///
/// 使用 Provider 架構，分離狀態、邏輯和 UI
class PracticePageRefactored extends StatelessWidget {
  final PlatformFile? file;

  const PracticePageRefactored({super.key, this.file});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => RecordingController(),
        ),
        ChangeNotifierProvider(
          create: (_) => AudioPlaybackController(),
        ),
        ChangeNotifierProvider(
          create: (_) => AnalysisController(),
        ),
        ChangeNotifierProvider(
          create: (_) => PracticeState(),
        ),
      ],
      child: _PracticePageContent(file: file),
    );
  }
}

/// 練習頁面主要內容
class _PracticePageContent extends StatefulWidget {
  final PlatformFile? file;

  const _PracticePageContent({this.file});

  @override
  State<_PracticePageContent> createState() => _PracticePageContentState();
}

class _PracticePageContentState extends State<_PracticePageContent> {
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    final recordingController = context.read<RecordingController>();
    final playbackController = context.read<AudioPlaybackController>();
    final analysisController = context.read<AnalysisController>();

    // 設定分析完成回調
    analysisController.setOnAnalysisComplete((report) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisResultPage(report: report),
        ),
      );
    });

    // 初始化音訊系統
    await recordingController.initialize();
    await playbackController.initialize();
  }

  @override
  void dispose() {
    // Provider 會自動處理 dispose
    super.dispose();
  }

  String _getFileNameWithoutExtension() {
    if (widget.file == null) return '未選擇檔案';
    final fileName = widget.file!.name;
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex != -1) {
      return fileName.substring(0, lastDotIndex);
    }
    return fileName;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final practiceState = context.watch<PracticeState>();
    final recordingController = context.watch<RecordingController>();
    final playbackController = context.watch<AudioPlaybackController>();
    final analysisController = context.watch<AnalysisController>();

    // 判斷是否可以分析
    final canAnalyze = recordingController.audioPath != null &&
        !recordingController.isRecording &&
        !playbackController.isPlaying &&
        !analysisController.isAnalyzing;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.practiceTitle ?? '練習'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          // 分析按鈕
          if (canAnalyze)
            IconButton(
              icon: const Icon(Icons.analytics),
              tooltip: l10n?.practiceAnalyze ?? '分析演奏',
              onPressed: () =>
                  _startAnalysis(analysisController, recordingController),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 檔案資訊卡片
              _buildFileInfoCard(l10n),

              const SizedBox(height: 16),

              // 模式選擇器
              ModeSelectorWidget(
                isRecordMode: practiceState.mode == RecordingMode.record,
                isRecording: recordingController.isRecording,
                isPlaying: playbackController.isPlaying,
                onModeChanged: (isRecord) {
                  practiceState.setMode(
                      isRecord ? RecordingMode.record : RecordingMode.upload);
                },
              ),

              const SizedBox(height: 16),

              // 根據模式顯示不同的控制區
              if (practiceState.mode == RecordingMode.record)
                _buildRecordingSection(
                    l10n, recordingController, playbackController)
              else
                _buildUploadSection(l10n, recordingController),

              const SizedBox(height: 16),

              // 播放控制區
              if (recordingController.audioPath != null)
                PlaybackControlsWidget(
                  audioPath: recordingController.audioPath,
                  isPlaying: playbackController.isPlaying,
                  isPaused: playbackController.isPaused,
                  isRecording: recordingController.isRecording,
                  playbackPosition: playbackController.playbackPosition,
                  playbackDuration: playbackController.playbackDuration,
                  onPlay: () =>
                      playbackController.play(recordingController.audioPath!),
                  onPause: () => playbackController.pause(),
                  onResume: () => playbackController.resume(),
                  onStop: () => playbackController.stop(),
                ),

              const SizedBox(height: 16),

              // 分析控制區
              if (recordingController.audioPath != null)
                AnalysisControlsWidget(
                  isRecording: recordingController.isRecording,
                  isAnalyzing: analysisController.isAnalyzing,
                  audioPath: recordingController.audioPath,
                  hasMidiFile: widget.file != null,
                  onAnalyze: () =>
                      _startAnalysis(analysisController, recordingController),
                ),

              // 分析中進度指示
              if (analysisController.isAnalyzing)
                _buildAnalysisProgress(l10n, analysisController),
            ],
          ),
        ),
      ),
    );
  }

  /// 構建檔案資訊卡片
  Widget _buildFileInfoCard(AppLocalizations? l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 8),
            Text(
              _getFileNameWithoutExtension(),
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
    );
  }

  /// 構建錄音區域
  Widget _buildRecordingSection(
    AppLocalizations? l10n,
    RecordingController recordingController,
    AudioPlaybackController playbackController,
  ) {
    return RecordingControlsWidget(
      isRecording: recordingController.isRecording,
      isPlaying: playbackController.isPlaying,
      enableCountdown: recordingController.enableCountdown,
      recordingDurationSeconds: recordingController.recordingDurationSeconds,
      audioPath: recordingController.audioPath,
      onStartRecording: () => _handleStartRecording(recordingController),
      onStopRecording: () => recordingController.stopRecording(),
      onCountdownChanged: (enabled) =>
          recordingController.setEnableCountdown(enabled),
    );
  }

  /// 處理開始錄音（含倒數計時）
  Future<void> _handleStartRecording(RecordingController recordingController) async {
    bool countdownCancelled = false;

    // 根據開關狀態決定是否顯示倒數計時
    if (recordingController.enableCountdown) {
      // Phase 1B: 顯示倒數計時
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return CountdownOverlay(
            onCountdownComplete: () {
              Navigator.of(dialogContext).pop();
            },
            onCancel: () {
              countdownCancelled = true;
              Navigator.of(dialogContext).pop();
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

    // 開始錄音
    await recordingController.startRecording();
  }

  /// 構建上傳區域
  Widget _buildUploadSection(
    AppLocalizations? l10n,
    RecordingController recordingController,
  ) {
    return UploadControlsWidget(
      audioPath: recordingController.audioPath,
      onUpload: () async {
        // 選擇 WAV 檔案
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['wav'],
        );
        if (result != null && result.files.single.path != null) {
          recordingController.setAudioPath(result.files.single.path!);
          if (mounted) {
            ErrorHandler.showSuccess(
              context,
              l10n?.practiceFileUploaded ?? '已選擇音檔',
            );
          }
        }
      },
    );
  }

  /// 構建分析進度指示器
  Widget _buildAnalysisProgress(
    AppLocalizations? l10n,
    AnalysisController analysisController,
  ) {
    return Card(
      color: AppColors.dynamicPrimary.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.practiceAnalyzing ?? '分析中...',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        analysisController.phase,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: analysisController.progress,
              backgroundColor: Colors.grey[300],
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.dynamicPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              '${(analysisController.progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 開始分析
  Future<void> _startAnalysis(
    AnalysisController analysisController,
    RecordingController recordingController,
  ) async {
    final l10n = AppLocalizations.of(context);

    if (widget.file == null) {
      ErrorHandler.showWarning(
        context,
        l10n?.practiceSelectFile ?? '請先選擇樂譜檔案',
      );
      return;
    }

    if (recordingController.audioPath == null) {
      ErrorHandler.showWarning(
        context,
        l10n?.practiceNoRecording ?? '請先錄製或上傳音檔',
      );
      return;
    }

    try {
      final report = await analysisController.analyze(
        audioPath: recordingController.audioPath!,
        midiPath: widget.file!.path!,
        getPhaseDescription: (progress) =>
            AnalysisProgressDialog.getPhaseDescription(context, progress),
      );

      if (report != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnalysisResultPage(report: report),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(
          context,
          e,
          customMessage: l10n?.practiceAnalysisFailed ?? '分析失敗',
        );
      }
    }
  }
}

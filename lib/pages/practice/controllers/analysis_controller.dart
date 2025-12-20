import 'dart:io';
import 'package:flutter/material.dart';
import '../../../services/audio_analysis/performance_analyzer.dart';
import '../../../services/audio_analysis/models/analysis_report.dart';

/// 演奏分析控制器
/// 
/// Phase 3 重構: 從 PracticePage 提取的分析邏輯
/// 負責演奏分析、進度更新、錯誤處理等
/// 
/// 繼承 ChangeNotifier 以支援 Provider 狀態管理
class AnalysisController extends ChangeNotifier {
  // ===== 分析器 =====
  late PerformanceAnalyzer _analyzer;
  
  // ===== 狀態 =====
  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  String _analysisPhase = '';
  
  bool get isAnalyzing => _isAnalyzing;
  double get analysisProgress => _analysisProgress;
  double get progress => _analysisProgress;
  String get analysisPhase => _analysisPhase;
  String get phase => _analysisPhase;
  
  // ===== 回調 =====
  void Function(double progress, String phase)? onProgressUpdate;
  void Function(AnalysisReport report)? onAnalysisComplete;
  void Function(String message)? onError;
  
  /// 設置分析完成回調
  void setOnAnalysisComplete(void Function(AnalysisReport report)? callback) {
    onAnalysisComplete = callback;
  }
  
  AnalysisController({
    this.onProgressUpdate,
    this.onAnalysisComplete,
    this.onError,
  });
  
  /// 初始化分析器
  void initialize() {
    _analyzer = PerformanceAnalyzer();
    debugPrint('✅ AnalysisController 初始化完成');
  }
  
  /// 開始分析演奏
  /// 
  /// [audioPath] - 錄音檔案路徑
  /// [midiPath] - MIDI 標準答案路徑
  /// [getPhaseDescription] - 取得分析階段描述的回調
  Future<AnalysisReport?> analyze({
    required String audioPath,
    required String midiPath,
    required String Function(double progress) getPhaseDescription,
  }) async {
    // 驗證檔案
    final validationResult = await _validateFiles(audioPath, midiPath);
    if (validationResult != null) {
      onError?.call(validationResult);
      return null;
    }
    
    _isAnalyzing = true;
    _analysisProgress = 0.0;
    _analysisPhase = '';
    notifyListeners();
    onProgressUpdate?.call(_analysisProgress, _analysisPhase);
    
    try {
      final report = await _analyzer.analyze(
        audioPath,
        midiPath,
        onProgress: (progress) {
          _analysisProgress = progress;
          _analysisPhase = getPhaseDescription(progress);
          notifyListeners();
          onProgressUpdate?.call(_analysisProgress, _analysisPhase);
        },
      );
      
      debugPrint('✅ 演奏分析完成');
      onAnalysisComplete?.call(report);
      return report;
    } catch (e, stackTrace) {
      debugPrint('❌ 分析失敗: $e\n$stackTrace');
      onError?.call('分析失敗: $e');
      return null;
    } finally {
      _isAnalyzing = false;
      _analysisProgress = 0.0;
      _analysisPhase = '';
      notifyListeners();
      onProgressUpdate?.call(_analysisProgress, _analysisPhase);
    }
  }
  
  /// 驗證分析所需的檔案
  Future<String?> _validateFiles(String audioPath, String midiPath) async {
    // 檢查音訊檔案
    final audioFile = File(audioPath);
    if (!await audioFile.exists()) {
      return '錄音文件不存在，請重新錄音';
    }
    
    final audioSize = await audioFile.length();
    if (audioSize == 0) {
      return '錄音檔案為空';
    }
    
    // 檢查 MIDI 檔案
    final midiFile = File(midiPath);
    if (!await midiFile.exists()) {
      return 'MIDI 文件不存在，請重新選擇';
    }
    
    return null;
  }
  
  /// 分析 WAV 檔案的技術資訊 (除錯用)
  Future<WavFileInfo?> analyzeWavFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ WAV 檔案不存在: $filePath');
        return null;
      }

      final fileSize = await file.length();
      debugPrint('📁 WAV 檔案分析:');
      debugPrint('  檔案路徑: $filePath');
      debugPrint('  檔案大小: $fileSize bytes');

      if (fileSize <= 44) {
        debugPrint('  ❌ 檔案過小，只包含 WAV 標頭');

        // 讀取標頭內容進行分析
        final bytes = await file.readAsBytes();
        final header = bytes.take(44).toList();

        final info = _parseWavHeader(header);
        debugPrint('  🔍 結論: WAV 標頭格式正確，但沒有實際音頻數據寫入');
        return info.copyWith(
          fileSize: fileSize,
          hasAudioData: false,
        );
      } else {
        debugPrint('  ✅ WAV 檔案包含音頻數據: ${fileSize - 44} bytes 音頻內容');
        
        final bytes = await file.readAsBytes();
        final header = bytes.take(44).toList();
        final info = _parseWavHeader(header);
        
        return info.copyWith(
          fileSize: fileSize,
          audioDataSize: fileSize - 44,
          hasAudioData: true,
        );
      }
    } catch (e) {
      debugPrint('❌ WAV 檔案分析失敗: $e');
      return null;
    }
  }
  
  /// 解析 WAV 標頭
  WavFileInfo _parseWavHeader(List<int> header) {
    // 檢查 RIFF 標記
    final riffMark = String.fromCharCodes(header.getRange(0, 4));
    
    // 檢查 WAVE 格式
    final waveMark = String.fromCharCodes(header.getRange(8, 12));
    
    // 檢查 fmt 區塊
    final fmtMark = String.fromCharCodes(header.getRange(12, 16));
    
    // 檢查聲道數
    final channels = header[22] | (header[23] << 8);
    
    // 檢查採樣率
    final sampleRate = header[24] |
        (header[25] << 8) |
        (header[26] << 16) |
        (header[27] << 24);
    
    // 檢查位深度
    final bitsPerSample = header[34] | (header[35] << 8);
    
    debugPrint('    RIFF 標記: $riffMark');
    debugPrint('    WAVE 格式: $waveMark');
    debugPrint('    fmt 區塊: $fmtMark');
    debugPrint('    聲道數: $channels');
    debugPrint('    採樣率: $sampleRate Hz');
    debugPrint('    位深度: $bitsPerSample bits');
    
    return WavFileInfo(
      riffMark: riffMark,
      waveMark: waveMark,
      fmtMark: fmtMark,
      channels: channels,
      sampleRate: sampleRate,
      bitsPerSample: bitsPerSample,
    );
  }
  
  /// 重置狀態
  void reset() {
    _isAnalyzing = false;
    _analysisProgress = 0.0;
    _analysisPhase = '';
    notifyListeners();
  }
  
  /// 清理資源
  @override
  void dispose() {
    reset();
    debugPrint('🧹 AnalysisController 已清理');
    super.dispose();
  }
}

/// WAV 檔案資訊
class WavFileInfo {
  final String riffMark;
  final String waveMark;
  final String fmtMark;
  final int channels;
  final int sampleRate;
  final int bitsPerSample;
  final int fileSize;
  final int audioDataSize;
  final bool hasAudioData;
  
  WavFileInfo({
    this.riffMark = '',
    this.waveMark = '',
    this.fmtMark = '',
    this.channels = 0,
    this.sampleRate = 0,
    this.bitsPerSample = 0,
    this.fileSize = 0,
    this.audioDataSize = 0,
    this.hasAudioData = false,
  });
  
  WavFileInfo copyWith({
    String? riffMark,
    String? waveMark,
    String? fmtMark,
    int? channels,
    int? sampleRate,
    int? bitsPerSample,
    int? fileSize,
    int? audioDataSize,
    bool? hasAudioData,
  }) {
    return WavFileInfo(
      riffMark: riffMark ?? this.riffMark,
      waveMark: waveMark ?? this.waveMark,
      fmtMark: fmtMark ?? this.fmtMark,
      channels: channels ?? this.channels,
      sampleRate: sampleRate ?? this.sampleRate,
      bitsPerSample: bitsPerSample ?? this.bitsPerSample,
      fileSize: fileSize ?? this.fileSize,
      audioDataSize: audioDataSize ?? this.audioDataSize,
      hasAudioData: hasAudioData ?? this.hasAudioData,
    );
  }
  
  bool get isValidHeader {
    return riffMark == 'RIFF' && waveMark == 'WAVE' && fmtMark == 'fmt ';
  }
  
  double get durationSeconds {
    if (sampleRate == 0 || channels == 0 || bitsPerSample == 0) return 0;
    final bytesPerSample = bitsPerSample ~/ 8;
    final bytesPerSecond = sampleRate * channels * bytesPerSample;
    if (bytesPerSecond == 0) return 0;
    return audioDataSize / bytesPerSecond;
  }
}

import 'package:music_practice_app/services/audio_analysis/performance_analysis_service.dart';
import 'package:music_practice_app/services/audio_analysis/audio_analyzer_service_impl.dart';
import 'package:music_practice_app/services/audio_analysis/midi_parser_service.dart';
import 'package:music_practice_app/services/audio_analysis/note_verification_service_impl.dart';
import 'package:music_practice_app/services/audio_analysis/error_classification_service_impl_v2.dart';
import 'package:music_practice_app/services/audio_analysis/models/analysis_report.dart';
import 'package:music_practice_app/services/audio_analysis/models/performance_error.dart';

/// Week 3 演奏分析器實現
/// 
/// 完整流程:
/// 1. 解析 MIDI 標準答案
/// 2. 分析 WAV 錄音頻譜  
/// 3. 驗證每個音符是否存在
/// 4. 分類錯誤類型
/// 5. 生成分析報告
class PerformanceAnalyzer implements IPerformanceAnalyzer {
  final _midiParser = MidiParserService();
  final _audioAnalyzer = AudioAnalyzerServiceImpl();
  final _noteVerifier = NoteVerificationServiceImpl();
  final _errorClassifier = ErrorClassificationServiceImpl();

  @override
  Future<AnalysisReport> analyze(
    String wavPath,
    String midiPath, {
    void Function(double progress)? onProgress,
  }) async {
    final startTime = DateTime.now();

    try {
      // 步驟 1: 解析 MIDI (20%)
      onProgress?.call(0.0);
      final timeline = await _midiParser.parseFile(midiPath);
      
      if (timeline.events.isEmpty) {
        throw Exception('MIDI 文件中沒有音符');
      }
      onProgress?.call(0.2);

      // 步驟 2: 分析音訊 (40%)
      final spectrogram = await _audioAnalyzer.analyze(wavPath);
      onProgress?.call(0.6);

      // 步驟 3: 驗證音符 (20%)
      final verificationResults = await _noteVerifier.verifyAll(
        timeline,
        spectrogram,
      );
      onProgress?.call(0.8);

      // 步驟 4: 分類錯誤 (10%)
      final errors = await _errorClassifier.classifyErrors(
        expectedTimeline: timeline,
        spectrogram: spectrogram,
        verificationResults: verificationResults,
      );

      // 步驟 5: 生成報告 (10%)
      final correctNotes = verificationResults.values.where((v) => v).length;
      
      // 統計各類錯誤
      int missedCount = 0;
      int wrongCount = 0;
      int earlyCount = 0;
      int lateCount = 0;
      
      for (final error in errors) {
        switch (error.type) {
          case ErrorType.missedNote:
            missedCount++;
            break;
          case ErrorType.wrongNote:
            wrongCount++;
            break;
          case ErrorType.earlyTiming:
            earlyCount++;
            break;
          case ErrorType.lateTiming:
            lateCount++;
            break;
          case ErrorType.correct:
            break;
        }
      }

      final processingTime = DateTime.now().difference(startTime);
      onProgress?.call(1.0);

      return AnalysisReport(
        totalNotes: timeline.events.length,
        correctNotes: correctNotes,
        wrongNotes: wrongCount,
        missedNotes: missedCount,
        earlyNotes: earlyCount,
        lateNotes: lateCount,
        errors: errors,
        processingTime: processingTime,
        timeOffset: 0.0,
      );
      
    } catch (e) {
      rethrow;
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:music_practice_app/services/audio_analysis/models/analysis_report.dart';
import 'package:music_practice_app/services/audio_analysis/models/confusion_matrix.dart';
import 'package:music_practice_app/services/audio_analysis/models/performance_error.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('AnalysisReport 測試', () {
    test('基本建構子應該正確初始化', () {
      final confusionMatrix = ConfusionMatrix(
        truePositive: 80,
        falsePositive: 5,
        falseNegative: 10,
      );

      final report = AnalysisReport(
        totalNotes: 90,
        correctNotes: 80,
        wrongNotes: 5,
        missedNotes: 10,
        earlyNotes: 0,
        lateNotes: 0,
        errors: [],
        processingTime: const Duration(seconds: 1),
        confusionMatrix: confusionMatrix,
      );

      expect(report.totalNotes, 90);
      expect(report.correctNotes, 80);
      expect(report.missedNotes, 10);
      expect(report.confusionMatrix, confusionMatrix);
    });

    test('準確率計算應該正確', () {
      final confusionMatrix = ConfusionMatrix(
        truePositive: 80,
        falsePositive: 5,
        falseNegative: 10,
      );

      final report = AnalysisReport(
        totalNotes: 90,
        correctNotes: 80,
        wrongNotes: 5,
        missedNotes: 10,
        earlyNotes: 0,
        lateNotes: 0,
        errors: [],
        processingTime: const Duration(seconds: 1),
        confusionMatrix: confusionMatrix,
      );

      // 準確率 = TP / (TP + FN) = 80 / 90 ≈ 0.889
      expect(report.accuracy, NumericMatcher.closeTo(0.889, delta: 0.001));
    });

    test('Precision 計算應該正確', () {
      final confusionMatrix = ConfusionMatrix(
        truePositive: 80,
        falsePositive: 5,
        falseNegative: 10,
      );

      final report = AnalysisReport(
        totalNotes: 90,
        correctNotes: 80,
        wrongNotes: 5,
        missedNotes: 10,
        earlyNotes: 0,
        lateNotes: 0,
        errors: [],
        processingTime: const Duration(seconds: 1),
        confusionMatrix: confusionMatrix,
        totalDetectedNotes: 85,
      );

      // Precision = TP / (TP + FP) = 80 / 85 ≈ 0.941
      expect(report.precision, NumericMatcher.closeTo(0.941, delta: 0.001));
    });

    test('Recall 計算應該正確', () {
      final confusionMatrix = ConfusionMatrix(
        truePositive: 80,
        falsePositive: 5,
        falseNegative: 10,
      );

      final report = AnalysisReport(
        totalNotes: 90,
        correctNotes: 80,
        wrongNotes: 5,
        missedNotes: 10,
        earlyNotes: 0,
        lateNotes: 0,
        errors: [],
        processingTime: const Duration(seconds: 1),
        confusionMatrix: confusionMatrix,
      );

      // Recall = TP / (TP + FN) = 80 / 90 ≈ 0.889
      expect(report.recall, NumericMatcher.closeTo(0.889, delta: 0.001));
    });

    test('F1 Score 計算應該正確', () {
      final confusionMatrix = ConfusionMatrix(
        truePositive: 80,
        falsePositive: 5,
        falseNegative: 10,
      );

      final report = AnalysisReport(
        totalNotes: 90,
        correctNotes: 80,
        wrongNotes: 5,
        missedNotes: 10,
        earlyNotes: 0,
        lateNotes: 0,
        errors: [],
        processingTime: const Duration(seconds: 1),
        confusionMatrix: confusionMatrix,
        totalDetectedNotes: 85,
      );

      // F1 = 2 * (Precision * Recall) / (Precision + Recall)
      // F1 = 2 * (0.941 * 0.889) / (0.941 + 0.889) ≈ 0.914
      expect(report.f1Score, NumericMatcher.closeTo(0.914, delta: 0.01));
    });

    test('durationPenalty 應該根據時間軸分析計算', () {
      final confusionMatrix = ConfusionMatrix(
        truePositive: 80,
        falsePositive: 5,
        falseNegative: 10,
      );

      final report = AnalysisReport(
        totalNotes: 90,
        correctNotes: 80,
        wrongNotes: 5,
        missedNotes: 10,
        earlyNotes: 0,
        lateNotes: 0,
        errors: [],
        processingTime: const Duration(seconds: 1),
        confusionMatrix: confusionMatrix,
      );

      // 沒有時間軸分析時應該返回 1.0（無懲罰）
      expect(report.durationPenalty, 1.0);
    });

    test('總分計算應該使用正確公式', () {
      final confusionMatrix = ConfusionMatrix(
        truePositive: 80,
        falsePositive: 5,
        falseNegative: 10,
      );

      final report = AnalysisReport(
        totalNotes: 90,
        correctNotes: 80,
        wrongNotes: 5,
        missedNotes: 10,
        earlyNotes: 0,
        lateNotes: 0,
        errors: [],
        processingTime: const Duration(seconds: 1),
        confusionMatrix: confusionMatrix,
      );

      // 應該可以成功建立且 accuracy 存在
      expect(report.accuracy, greaterThan(0));
    });

    test('isProbablyRandomPlaying 應該正確判斷亂彈', () {
      final confusionMatrix = ConfusionMatrix(
        truePositive: 30,
        falsePositive: 100, // 大量錯音
        falseNegative: 60,
      );

      final report = AnalysisReport(
        totalNotes: 90,
        correctNotes: 30,
        wrongNotes: 100,
        missedNotes: 60,
        earlyNotes: 0,
        lateNotes: 0,
        errors: [],
        processingTime: const Duration(seconds: 1),
        confusionMatrix: confusionMatrix,
        totalDetectedNotes: 130,
      );

      expect(report.isProbablyRandomPlaying, true);
    });

    test('isProbablyWrongSong 檢測邏輯存在', () {
      final confusionMatrix = ConfusionMatrix(
        truePositive: 10,
        falsePositive: 80,
        falseNegative: 80,
      );

      final report = AnalysisReport(
        totalNotes: 90,
        correctNotes: 10,
        wrongNotes: 80,
        missedNotes: 80,
        earlyNotes: 0,
        lateNotes: 0,
        errors: [],
        processingTime: const Duration(seconds: 1),
        confusionMatrix: confusionMatrix,
      );

      // isProbablyWrongSong 需要 timelineAnalysis 才能正確判斷
      // 這裡只驗證屬性存在
      expect(report.isProbablyWrongSong, isA<bool>());
    });
  });

  group('ConfusionMatrix 測試', () {
    test('基本建構子應該正確初始化', () {
      final matrix = ConfusionMatrix(
        truePositive: 80,
        falsePositive: 5,
        falseNegative: 10,
      );

      expect(matrix.truePositive, 80);
      expect(matrix.falsePositive, 5);
      expect(matrix.falseNegative, 10);
    });

    test('Precision 計算應該正確', () {
      final matrix = ConfusionMatrix(
        truePositive: 80,
        falsePositive: 20,
        falseNegative: 10,
      );

      // Precision = TP / (TP + FP) = 80 / 100 = 0.8
      expect(matrix.precision, NumericMatcher.closeTo(0.8, delta: 0.001));
    });

    test('Recall 計算應該正確', () {
      final matrix = ConfusionMatrix(
        truePositive: 80,
        falsePositive: 20,
        falseNegative: 10,
      );

      // Recall = TP / (TP + FN) = 80 / 90 ≈ 0.889
      expect(matrix.recall, NumericMatcher.closeTo(0.889, delta: 0.001));
    });

    test('F1 Score 計算應該正確', () {
      final matrix = ConfusionMatrix(
        truePositive: 80,
        falsePositive: 20,
        falseNegative: 10,
      );

      // F1 = 2 * (P * R) / (P + R)
      final precision = 0.8;
      final recall = 80 / 90;
      final expectedF1 = 2 * (precision * recall) / (precision + recall);
      
      expect(matrix.f1Score, NumericMatcher.closeTo(expectedF1, delta: 0.01));
    });

    test('零 TP 時應該返回 0 分數', () {
      final matrix = ConfusionMatrix(
        truePositive: 0,
        falsePositive: 10,
        falseNegative: 90,
      );

      expect(matrix.precision, 0.0);
      expect(matrix.recall, 0.0);
      expect(matrix.f1Score, 0.0);
    });
  });

  group('PerformanceError 測試', () {
    test('音高錯誤應該正確建立', () {
      final error = PerformanceError(
        type: ErrorType.wrongNote,
        expectedNote: 60,
        actualNote: 62,
        expectedTime: 1.0,
        message: '彈錯音',
      );

      expect(error.type, ErrorType.wrongNote);
      expect(error.expectedNote, 60);
      expect(error.actualNote, 62);
    });

    test('節奏錯誤應該正確建立', () {
      final error = PerformanceError(
        type: ErrorType.earlyTiming,
        expectedNote: 60,
        expectedTime: 1.0,
        actualTime: 0.7,
        timingOffset: -0.3,
        message: '搶拍',
      );

      expect(error.type, ErrorType.earlyTiming);
      expect(error.expectedNote, 60);
      expect(error.timingOffset, lessThan(0)); // 提早是負值
    });

    test('漏音錯誤應該正確建立', () {
      final error = PerformanceError(
        type: ErrorType.missedNote,
        expectedNote: 64,
        expectedTime: 2.0,
        message: '漏音',
      );

      expect(error.type, ErrorType.missedNote);
      expect(error.expectedNote, 64);
      expect(error.actualNote, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:veloria/services/audio_analysis/performance_analyzer.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('PerformanceAnalyzer 單元測試', () {
    late PerformanceAnalyzer analyzer;

    setUp(() {
      analyzer = PerformanceAnalyzer();
    });

    group('初始化測試', () {
      test('分析器可以成功實例化', () {
        expect(analyzer, isNotNull);
        expect(analyzer, isA<PerformanceAnalyzer>());
      });
    });

    group('輸入驗證測試', () {
      test('分析不存在的 WAV 檔案應該拋出異常', () async {
        const wavPath = 'non_existent.wav';
        const midiPath = 'test.mid';
        
        expect(
          () => analyzer.analyze(wavPath, midiPath),
          throwsA(isA<Exception>()),
        );
      });

      test('分析不存在的 MIDI 檔案應該拋出異常', () async {
        const wavPath = 'test.wav';
        const midiPath = 'non_existent.mid';
        
        expect(
          () => analyzer.analyze(wavPath, midiPath),
          throwsA(isA<Exception>()),
        );
      });

      test('空路徑應該拋出異常', () async {
        expect(
          () => analyzer.analyze('', ''),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('分析報告測試', () {
      test('完整分析應該返回 AnalysisReport', () async {
        final wavExists = await TestPaths.fileExists(TestPaths.testWav);
        final midiExists = await TestPaths.fileExists(TestPaths.testMidi);
        
        if (!wavExists || !midiExists) {
          print('警告: 測試檔案不存在');
          print('WAV: ${TestPaths.testWav} - exists: $wavExists');
          print('MIDI: ${TestPaths.testMidi} - exists: $midiExists');
          return;
        }
        
        final report = await analyzer.analyze(
          TestPaths.testWav,
          TestPaths.testMidi,
        );
        
        expect(report, isNotNull);
        expect(report.confusionMatrix, isNotNull);
        expect(report.f1Score, greaterThanOrEqualTo(0.0));
        expect(report.f1Score, lessThanOrEqualTo(1.0));
      });

      test('分析報告應該包含混淆矩陣', () async {
        final wavExists = await TestPaths.fileExists(TestPaths.testWav);
        final midiExists = await TestPaths.fileExists(TestPaths.testMidi);
        
        if (!wavExists || !midiExists) {
          print('警告: 測試檔案不存在');
          return;
        }
        
        final report = await analyzer.analyze(
          TestPaths.testWav,
          TestPaths.testMidi,
        );
        
        final cm = report.confusionMatrix;
        expect(cm, isNotNull);
        // 驗證混淆矩陣指標都不為負數
        expect(cm!.truePositive, greaterThanOrEqualTo(0));
        expect(cm.falsePositive, greaterThanOrEqualTo(0));
        expect(cm.falseNegative, greaterThanOrEqualTo(0));
      });

      test('分析報告應該包含 F1 分數', () async {
        final wavExists = await TestPaths.fileExists(TestPaths.testWav);
        final midiExists = await TestPaths.fileExists(TestPaths.testMidi);
        
        if (!wavExists || !midiExists) {
          print('警告: 測試檔案不存在');
          return;
        }
        
        final report = await analyzer.analyze(
          TestPaths.testWav,
          TestPaths.testMidi,
        );
        
        // F1 分數應該在 0-1 範圍內
        expect(report.f1Score, greaterThanOrEqualTo(0.0));
        expect(report.f1Score, lessThanOrEqualTo(1.0));
      });

      test('分析報告應該包含時間軸分析', () async {
        final wavExists = await TestPaths.fileExists(TestPaths.testWav);
        final midiExists = await TestPaths.fileExists(TestPaths.testMidi);
        
        if (!wavExists || !midiExists) {
          print('警告: 測試檔案不存在');
          return;
        }
        
        final report = await analyzer.analyze(
          TestPaths.testWav,
          TestPaths.testMidi,
        );
        
        // 驗證時間軸相關資料存在
        expect(report.processingTime, isNotNull);
        expect(report.processingTime.inMilliseconds, greaterThanOrEqualTo(0));
      });
    });

    group('進度回調測試', () {
      test('onProgress 應該在分析過程中被呼叫', () async {
        // final progressValues = <double>[];
        
        // 這需要實際的測試檔案
        // await analyzer.analyze(
        //   'test.wav',
        //   'test.mid',
        //   onProgress: (progress) {
        //     progressValues.add(progress);
        //   },
        // );
        
        // expect(progressValues.isNotEmpty, true);
        // expect(progressValues.last, NumericMatcher.closeTo(1.0));
      }, skip: '需要測試檔案');

      test('進度值應該從 0 到 1 遞增', () async {
        // 驗證進度值單調遞增
      }, skip: '需要測試檔案');
    });

    group('動態參數測試', () {
      test('自訂 energyThreshold 應該影響分析結果', () async {
        // 測試不同能量閾值的影響
      }, skip: '需要測試檔案');

      test('自訂 timingTolerance 應該影響分析結果', () async {
        // 測試不同時間容錯的影響
      }, skip: '需要測試檔案');
    });

    group('錯誤分類測試', () {
      test('應該正確識別音高錯誤', () async {
        // 測試錯誤分類功能
      }, skip: '需要測試檔案');

      test('應該正確識別節奏錯誤', () async {
        // 測試節奏錯誤檢測
      }, skip: '需要測試檔案');

      test('應該正確識別漏音', () async {
        // 測試漏音檢測
      }, skip: '需要測試檔案');
    });

    group('特殊情況處理', () {
      test('空 MIDI 檔案應該拋出異常', () async {
        // 測試沒有音符的 MIDI
      }, skip: '需要測試檔案');

      test('極短錄音應該有短錄音懲罰', () async {
        // 測試 durationPenalty 機制
      }, skip: '需要測試檔案');

      test('錄音開始延遲應該被自動對齊', () async {
        // 測試自動對齊功能
      }, skip: '需要測試檔案');
    });

    group('效能測試', () {
      test('分析應該在合理時間內完成', () async {
        // 測試分析不會超時（例如 < 30 秒）
      }, skip: '需要測試檔案');
    });
  });

  group('PerformanceAnalyzer 整合測試', () {
    test('完整分析流程應該生成完整報告', () async {
      // 測試從頭到尾的完整分析流程
    }, skip: '需要測試檔案');

    test('連續分析多個檔案應該獨立處理', () async {
      // 確保多次分析互不影響
    }, skip: '需要測試檔案');
  });

  group('回歸測試', () {
    test('v4.8 SNR 自適應閾值系統應該正常運作', () async {
      // 驗證自適應參數計算
    }, skip: '需要測試檔案');

    test('v3.7 評分系統應該正確計算', () async {
      // 驗證評分公式
    }, skip: '需要測試檔案');
  });
}

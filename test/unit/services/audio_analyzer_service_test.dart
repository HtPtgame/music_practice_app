import 'package:flutter_test/flutter_test.dart';
import 'package:music_practice_app/services/audio_analysis/audio_analyzer_service_impl.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('AudioAnalyzerServiceImpl 單元測試', () {
    late AudioAnalyzerServiceImpl analyzer;

    setUp(() {
      analyzer = AudioAnalyzerServiceImpl();
    });

    group('初始化與基本功能', () {
      test('服務可以成功實例化', () {
        expect(analyzer, isNotNull);
        expect(analyzer, isA<AudioAnalyzerServiceImpl>());
      });
    });

    group('WAV 檔案分析', () {
      test('分析不存在的檔案應該拋出異常', () async {
        const nonExistentPath = 'non_existent_file.wav';
        
        expect(
          () => analyzer.analyze(nonExistentPath),
          throwsA(isA<Exception>()),
        );
      });

      test('分析空路徑應該拋出異常', () async {
        expect(
          () => analyzer.analyze(''),
          throwsA(isA<Exception>()),
        );
      });

      // TODO: 需要實際的 WAV 測試檔案才能測試完整功能
      test('分析有效 WAV 檔案應該返回 Spectrogram', () async {
        // 檢查測試檔案是否存在
        final exists = await TestPaths.fileExists(TestPaths.testWav);
        if (!exists) {
          print('警告: 測試檔案不存在: ${TestPaths.testWav}');
          return;
        }
        
        final result = await analyzer.analyze(TestPaths.testWav);
        expect(result, isNotNull);
        expect(result.data, isNotEmpty);
        expect(result.timeFrames, greaterThan(0));
        expect(result.freqBins, greaterThan(0));
      });
    });

    group('頻譜圖特性驗證', () {
      test('頻譜圖應該有正確的時間和頻率維度', () async {
        final exists = await TestPaths.fileExists(TestPaths.testWav);
        if (!exists) {
          print('警告: 測試檔案不存在: ${TestPaths.testWav}');
          return;
        }
        
        final result = await analyzer.analyze(TestPaths.testWav);
        expect(result.data, isNotEmpty);
        // 驗證每個時間段都有頻率資料
        for (var frame in result.data) {
          expect(frame.length, greaterThan(0));
        }
      });

      test('頻譜圖的能量值應該在合理範圍內', () async {
        final exists = await TestPaths.fileExists(TestPaths.testWav);
        if (!exists) {
          print('警告: 測試檔案不存在: ${TestPaths.testWav}');
          return;
        }
        
        final result = await analyzer.analyze(TestPaths.testWav);
        // 驗證能量值不為負數
        for (var frame in result.data) {
          for (var value in frame) {
            expect(value, greaterThanOrEqualTo(0.0));
          }
        }
      });
    });

    group('效能測試', () {
      test('分析短音訊檔案應該在合理時間內完成', () async {
        // 確保分析不會超時
      }, skip: '需要測試 WAV 檔案');
    });
  });

  group('AudioAnalyzerServiceImpl 整合測試', () {
    test('連續分析多個檔案不會造成記憶體洩漏', () async {
      // 測試多次呼叫不會累積記憶體
    }, skip: '需要測試 WAV 檔案');
  });
}

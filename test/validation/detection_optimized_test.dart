import 'dart:io';
import 'package:music_practice_app/services/audio_analysis/performance_analyzer.dart';

/// 錄音偵測優化測試腳本 (2025/10/25)
/// 
/// 目的: 測試新的 F1 分數評估系統
/// 重點: 
/// - 驗證混淆矩陣計算正確性
/// - 測試「亂彈高分」問題是否被修復
/// - 測試錯誤曲目檢測能力
/// - 測試雜訊抑制能力
/// 
/// 測試計劃 (根據用戶需求):
/// 第一輪: 生日快樂.mid (單音無伴奏+短時長)
/// 第二輪: 測試音檔.mid (單音無伴奏+中時長) 
/// 第三輪: 小星星.mid (有伴奏+中時長)
/// 第四輪: 名偵探柯南.mid (旋律複雜+曲速極快+長時長)
void main(List<String> args) async {
  print('╔═══════════════════════════════════════════════════════════════╗');
  print('║     🎯 錄音偵測優化測試 - F1 分數驗證 (2025/10/25)         ║');
  print('╚═══════════════════════════════════════════════════════════════╝');
  print('');

  // 測試輪次定義 (根據用戶提供的測試計劃)
  final testRounds = {
    '1': {
      'name': '第一輪: 生日快樂 (單音無伴奏+短時長)',
      'midi': 'assets/test_voice/生日快樂.mid',
      'testCases': [
        {'path': 'assets/test_voice/生日快樂(midi轉檔).wav', 'name': '生日快樂(midi轉檔)', 'type': 'correct', 'expectedF1': '>0.95'},
        {'path': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '生日快樂(手機環境)', 'type': 'correct', 'expectedF1': '>0.85'},
        {'path': 'assets/test_voice/生日快樂(電腦環境錄製).wav', 'name': '生日快樂(電腦環境)', 'type': 'correct', 'expectedF1': '>0.85'},
        {'path': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '小星星(手機環境)', 'type': 'wrong-song', 'expectedF1': '<0.20'},
        {'path': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '名偵探柯南(手機環境)', 'type': 'wrong-song', 'expectedF1': '<0.20'},
        {'path': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '測試音檔(手機環境)', 'type': 'wrong-song', 'expectedF1': '<0.20'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'type': 'noise', 'expectedF1': '<0.05'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'type': 'noise', 'expectedF1': '<0.05'},
      ],
    },
    '2': {
      'name': '第二輪: 測試音檔 (單音無伴奏+中時長)',
      'midi': 'assets/test_voice/測試音檔.mid',
      'testCases': [
        {'path': 'assets/test_voice/測試音檔(midi轉檔).wav', 'name': '測試音檔(midi轉檔)', 'type': 'correct', 'expectedF1': '>0.95'},
        {'path': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '測試音檔(手機環境)', 'type': 'correct', 'expectedF1': '>0.85'},
        {'path': 'assets/test_voice/測試音檔(電腦環境錄製).wav', 'name': '測試音檔(電腦環境)', 'type': 'correct', 'expectedF1': '>0.85'},
        {'path': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '小星星(手機環境)', 'type': 'wrong-song', 'expectedF1': '<0.20'},
        {'path': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '名偵探柯南(手機環境)', 'type': 'wrong-song', 'expectedF1': '<0.20'},
        {'path': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '生日快樂(手機環境)', 'type': 'wrong-song', 'expectedF1': '<0.20'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'type': 'noise', 'expectedF1': '<0.05'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'type': 'noise', 'expectedF1': '<0.05'},
      ],
    },
    '3': {
      'name': '第三輪: 小星星 (有伴奏+中時長)',
      'midi': 'assets/test_voice/小星星.mid',
      'testCases': [
        {'path': 'assets/test_voice/小星星(midi轉檔).wav', 'name': '小星星(midi轉檔)', 'type': 'correct', 'expectedF1': '>0.90'},
        {'path': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '小星星(手機環境)', 'type': 'correct', 'expectedF1': '>0.80'},
        {'path': 'assets/test_voice/小星星(電腦環境錄製).wav', 'name': '小星星(電腦環境)', 'type': 'correct', 'expectedF1': '>0.80'},
        {'path': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '測試音檔(手機環境)', 'type': 'wrong-song', 'expectedF1': '<0.20'},
        {'path': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '名偵探柯南(手機環境)', 'type': 'wrong-song', 'expectedF1': '<0.20'},
        {'path': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '生日快樂(手機環境)', 'type': 'wrong-song', 'expectedF1': '<0.20'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'type': 'noise', 'expectedF1': '<0.05'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'type': 'noise', 'expectedF1': '<0.05'},
      ],
    },
    '4': {
      'name': '第四輪: 名偵探柯南 (旋律複雜+曲速極快+長時長)',
      'midi': 'assets/test_voice/名偵探柯南.mid',
      'testCases': [
        {'path': 'assets/test_voice/名偵探柯南(midi轉檔).wav', 'name': '名偵探柯南(midi轉檔)', 'type': 'correct', 'expectedF1': '>0.85'},
        {'path': 'assets/test_voice/名偵探柯南(手機環境錄製).wav', 'name': '名偵探柯南(手機環境)', 'type': 'correct', 'expectedF1': '>0.75'},
        {'path': 'assets/test_voice/名偵探柯南(電腦環境錄製).wav', 'name': '名偵探柯南(電腦環境)', 'type': 'correct', 'expectedF1': '>0.75'},
        {'path': 'assets/test_voice/小星星(手機環境錄製).wav', 'name': '小星星(手機環境)', 'type': 'wrong-song', 'expectedF1': '<0.20'},
        {'path': 'assets/test_voice/測試音檔(手機環境錄製).wav', 'name': '測試音檔(手機環境)', 'type': 'wrong-song', 'expectedF1': '<0.20'},
        {'path': 'assets/test_voice/生日快樂(手機環境錄製).wav', 'name': '生日快樂(手機環境)', 'type': 'wrong-song', 'expectedF1': '<0.20'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'type': 'noise', 'expectedF1': '<0.05'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'type': 'noise', 'expectedF1': '<0.05'},
      ],
    },
  };

  // 選擇測試輪次
  String roundChoice = '1';
  if (args.isNotEmpty) {
    roundChoice = args[0];
  } else {
    print('📋 測試輪次:');
    print('');
    testRounds.forEach((key, value) {
      print('   [$key] ${value['name']}');
      final tests = value['testCases'] as List;
      print('       → ${tests.length} 個測試案例');
      print('');
    });
    print('💡 使用方式: dart test_detection_optimized.dart [1-4]');
    print('   或使用 "all" 運行全部 4 輪測試');
    print('');
    print('🎯 測試重點:');
    print('   ✅ 正確演奏 → F1 分數應 >0.85');
    print('   ❌ 錯誤曲目 → F1 分數應 <0.20 (防止誤判)');
    print('   🔇 純雜訊 → F1 分數應 <0.05 (防止誤報)');
    print('');
    return;
  }

  // 處理 "all" 選項
  if (roundChoice.toLowerCase() == 'all') {
    print('🚀 運行全部 4 輪測試...');
    print('');
    
    for (final key in ['1', '2', '3', '4']) {
      await runTestRound(testRounds[key]!);
      print('');
      print('━' * 70);
      print('');
    }
    
    print('');
    print('✅ 全部 4 輪測試完成!');
    return;
  }

  if (!testRounds.containsKey(roundChoice)) {
    print('❌ 無效的輪次選擇: $roundChoice');
    print('   請選擇 1-4 或 "all"');
    return;
  }

  await runTestRound(testRounds[roundChoice]!);
}

/// 運行單個測試輪次
Future<void> runTestRound(Map<String, dynamic> round) async {
  final roundName = round['name'] as String;
  final midiPath = round['midi'] as String;
  final testCases = round['testCases'] as List<Map<String, String>>;

  print('╔═══════════════════════════════════════════════════════════════╗');
  print('║  $roundName');
  print('╚═══════════════════════════════════════════════════════════════╝');
  print('');
  print('📄 MIDI 檔案: $midiPath');
  print('🎵 測試案例數: ${testCases.length}');
  print('');

  // 結果收集
  final results = <Map<String, dynamic>>[];
  int testNum = 1;

  for (final testCase in testCases) {
    final wavPath = testCase['path']!;
    final testName = testCase['name']!;
    final testType = testCase['type']!;
    final expectedF1 = testCase['expectedF1']!;

    print('');
    print('─' * 70);
    print('🧪 測試 $testNum/${testCases.length}: $testName');
    print('   類型: $testType | 期望 F1: $expectedF1');
    print('─' * 70);

    // 檢查檔案存在
    final midiFile = File(midiPath);
    final wavFile = File(wavPath);

    if (!midiFile.existsSync()) {
      print('❌ MIDI 檔案不存在: $midiPath');
      results.add({
        'name': testName,
        'type': testType,
        'status': 'ERROR',
        'error': 'MIDI not found',
      });
      testNum++;
      continue;
    }

    if (!wavFile.existsSync()) {
      print('❌ WAV 檔案不存在: $wavPath');
      results.add({
        'name': testName,
        'type': testType,
        'status': 'ERROR',
        'error': 'WAV not found',
      });
      testNum++;
      continue;
    }

    try {
      // 執行分析
      print('🚀 開始分析...');
      
      final analyzer = PerformanceAnalyzer();
      final report = await analyzer.analyze(wavPath, midiPath);

      // 提取新指標
      final f1Score = report.f1Score;
      final precision = report.precision;
      final recall = report.recall;
      final fp = report.falsePositives;
      final totalDetected = report.totalDetectedNotes ?? 0;
      final isProbablyRandom = report.isProbablyRandomPlaying;
      final isProbablyWrong = report.isProbablyWrongSong;

      // 顯示結果
      print('');
      print('📊 混淆矩陣結果:');
      print('   期望音符數: ${report.totalNotes}');
      print('   檢測音符數: $totalDetected');
      print('   正確匹配 (TP): ${report.correctNotes}');
      print('   多彈/錯音 (FP): $fp');
      print('   漏音 (FN): ${report.missedNotes}');
      print('');
      print('🎯 評估指標:');
      print('   Precision (精確率): ${(precision * 100).toStringAsFixed(1)}%');
      print('   Recall (召回率): ${(recall * 100).toStringAsFixed(1)}%');
      print('   F1 Score: ${(f1Score * 100).toStringAsFixed(1)}%');
      print('   評級: ${report.grade}');
      print('');
      
      // 警告標記
      if (isProbablyRandom) {
        print('⚠️  系統判定: 疑似亂彈!');
      }
      if (isProbablyWrong) {
        print('⚠️  系統判定: 可能是錯誤曲目!');
      }

      // 判斷是否符合期望
      final passTest = _checkExpectation(f1Score, expectedF1, testType);
      final passIcon = passTest ? '✅' : '❌';
      
      print('');
      print('$passIcon 測試結果: ${passTest ? "PASS" : "FAIL"}');
      print('   期望: $expectedF1, 實際: ${(f1Score * 100).toStringAsFixed(1)}%');

      // 收集結果
      results.add({
        'name': testName,
        'type': testType,
        'status': 'SUCCESS',
        'f1Score': f1Score,
        'precision': precision,
        'recall': recall,
        'falsePositives': fp,
        'grade': report.grade,
        'passTest': passTest,
        'expectedF1': expectedF1,
        'isProbablyRandom': isProbablyRandom,
        'isProbablyWrong': isProbablyWrong,
      });

    } catch (e) {
      print('');
      print('❌ 測試失敗: $e');
      results.add({
        'name': testName,
        'type': testType,
        'status': 'ERROR',
        'error': e.toString(),
      });
    }

    testNum++;
  }

  // 輸出測試總結
  print('');
  print('');
  print('╔═══════════════════════════════════════════════════════════════╗');
  print('║                  📊 測試總結報告                              ║');
  print('╚═══════════════════════════════════════════════════════════════╝');
  print('');
  print('🎯 $roundName');
  print('');
  print('━' * 70);
  print('📈 結果匯總');
  print('━' * 70);
  print('');

  // 表格標題
  print('${_pad("測試案例", 25)} ${_pad("類型", 12)} ${_pad("F1分數", 10)} ${_pad("評級", 6)} ${_pad("結果", 10)}');
  print('─' * 70);

  // 表格內容
  int passCount = 0;
  int failCount = 0;
  int errorCount = 0;

  for (final result in results) {
    final name = result['name'] as String;
    final type = result['type'] as String;
    final status = result['status'] as String;

    if (status == 'SUCCESS') {
      final f1 = result['f1Score'] as double;
      final grade = result['grade'] as String;
      final pass = result['passTest'] as bool;
      
      final passIcon = pass ? '✅ PASS' : '❌ FAIL';
      print('${_pad(name, 25)} ${_pad(type, 12)} ${_pad('${(f1 * 100).toStringAsFixed(1)}%', 10)} ${_pad(grade, 6)} ${_pad(passIcon, 10)}');
      
      if (pass) {
        passCount++;
      } else {
        failCount++;
      }
    } else {
      print('${_pad(name, 25)} ${_pad(type, 12)} ${_pad('N/A', 10)} ${_pad('N/A', 6)} ${_pad('❌ ERROR', 10)}');
      errorCount++;
    }
  }

  print('');
  print('━' * 70);
  print('📊 統計');
  print('━' * 70);
  print('   ✅ 通過: $passCount');
  print('   ❌ 失敗: $failCount');
  print('   ⚠️  錯誤: $errorCount');
  print('   📊 通過率: ${(passCount / (passCount + failCount + errorCount) * 100).toStringAsFixed(1)}%');
  print('');

  // 分類分析
  final correctTests = results.where((r) => r['type'] == 'correct' && r['status'] == 'SUCCESS').toList();
  final wrongTests = results.where((r) => r['type'] == 'wrong-song' && r['status'] == 'SUCCESS').toList();
  final noiseTests = results.where((r) => r['type'] == 'noise' && r['status'] == 'SUCCESS').toList();

  if (correctTests.isNotEmpty) {
    print('🎵 正確演奏測試:');
    final avgF1 = correctTests.map((r) => r['f1Score'] as double).reduce((a, b) => a + b) / correctTests.length;
    print('   平均 F1: ${(avgF1 * 100).toStringAsFixed(1)}%');
    print('   通過: ${correctTests.where((r) => r['passTest'] == true).length}/${correctTests.length}');
    print('');
  }

  if (wrongTests.isNotEmpty) {
    print('❌ 錯誤曲目測試:');
    final avgF1 = wrongTests.map((r) => r['f1Score'] as double).reduce((a, b) => a + b) / wrongTests.length;
    print('   平均 F1: ${(avgF1 * 100).toStringAsFixed(1)}% (期望 <20%)');
    print('   通過: ${wrongTests.where((r) => r['passTest'] == true).length}/${wrongTests.length}');
    final wrongDetected = wrongTests.where((r) => r['isProbablyWrong'] == true).length;
    print('   智能檢測: $wrongDetected/${wrongTests.length} 被標記為錯誤曲目');
    print('');
  }

  if (noiseTests.isNotEmpty) {
    print('🔇 雜訊測試:');
    final avgF1 = noiseTests.map((r) => r['f1Score'] as double).reduce((a, b) => a + b) / noiseTests.length;
    print('   平均 F1: ${(avgF1 * 100).toStringAsFixed(1)}% (期望 <5%)');
    print('   通過: ${noiseTests.where((r) => r['passTest'] == true).length}/${noiseTests.length}');
    final avgFP = noiseTests.map((r) => r['falsePositives'] as int).reduce((a, b) => a + b) / noiseTests.length;
    print('   平均誤報: ${avgFP.toStringAsFixed(1)} 個音符');
    print('');
  }

  print('╔═══════════════════════════════════════════════════════════════╗');
  print('║              ✅ 測試輪次完成!                                 ║');
  print('╚═══════════════════════════════════════════════════════════════╝');
}

/// 檢查 F1 分數是否符合期望
bool _checkExpectation(double actualF1, String expected, String testType) {
  if (expected.startsWith('>')) {
    final threshold = double.parse(expected.substring(1));
    return actualF1 >= threshold;
  } else if (expected.startsWith('<')) {
    final threshold = double.parse(expected.substring(1));
    return actualF1 <= threshold;
  }
  return false;
}

/// 字符串填充 (處理中文字符寬度)
String _pad(String text, int width) {
  if (text.length >= width) return text.substring(0, width);
  
  // 計算中文字符數(佔2個寬度)
  int displayWidth = 0;
  for (int i = 0; i < text.length; i++) {
    if (text.codeUnitAt(i) > 127) {
      displayWidth += 2; // 中文字符
    } else {
      displayWidth += 1; // 英文字符
    }
  }
  
  final padding = width - displayWidth;
  return text + (' ' * (padding > 0 ? padding : 0));
}

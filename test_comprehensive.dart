import 'dart:io';
import 'lib/services/audio_analysis/performance_analyzer.dart';

/// 綜合測試腳本 - 最終參數優化
/// 
/// 測試計劃:
/// 步驟1: 小星星.mid vs 6個音檔
/// 步驟2: 測試音檔.mid vs 6個音檔  
/// 步驟3: 名偵探柯南.mid vs 6個音檔
/// 步驟4: 名偵探柯南.mid vs 4個音檔(柯南專屬)
void main(List<String> args) async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║       🎼 最終綜合測試 - 參數優化驗證                      ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');

  // 測試步驟定義
  final testSteps = {
    '1': {
      'name': '步驟1: 小星星.mid 全面測試',
      'midi': 'assets/test_voice/小星星.mid',
      'wavs': [
        {'path': 'assets/test_voice/小星星(midi轉檔).wav', 'name': '小星星(midi轉檔)', 'type': '和弦+伴奏'},
        {'path': 'assets/test_voice/小星星(環境).wav', 'name': '小星星(環境)', 'type': '和弦+伴奏'},
        {'path': 'assets/test_voice/測試音檔(midi轉檔).wav', 'name': '測試音檔(midi轉檔)', 'type': '單音'},
        {'path': 'assets/test_voice/測試音檔(環境).wav', 'name': '測試音檔(環境)', 'type': '單音'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'type': '噪音'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'type': '噪音'},
      ],
    },
    '2': {
      'name': '步驟2: 測試音檔.mid 全面測試',
      'midi': 'assets/test_voice/測試音檔.mid',
      'wavs': [
        {'path': 'assets/test_voice/小星星(midi轉檔).wav', 'name': '小星星(midi轉檔)', 'type': '和弦+伴奏'},
        {'path': 'assets/test_voice/小星星(環境).wav', 'name': '小星星(環境)', 'type': '和弦+伴奏'},
        {'path': 'assets/test_voice/測試音檔(midi轉檔).wav', 'name': '測試音檔(midi轉檔)', 'type': '單音'},
        {'path': 'assets/test_voice/測試音檔(環境).wav', 'name': '測試音檔(環境)', 'type': '單音'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'type': '噪音'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'type': '噪音'},
      ],
    },
    '3': {
      'name': '步驟3: 名偵探柯南.mid 全面測試',
      'midi': 'assets/test_voice/名偵探柯南.mid',
      'wavs': [
        {'path': 'assets/test_voice/小星星(midi轉檔).wav', 'name': '小星星(midi轉檔)', 'type': '和弦+伴奏'},
        {'path': 'assets/test_voice/小星星(環境).wav', 'name': '小星星(環境)', 'type': '和弦+伴奏'},
        {'path': 'assets/test_voice/測試音檔(midi轉檔).wav', 'name': '測試音檔(midi轉檔)', 'type': '單音'},
        {'path': 'assets/test_voice/測試音檔(環境).wav', 'name': '測試音檔(環境)', 'type': '單音'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'type': '噪音'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'type': '噪音'},
      ],
    },
    '4': {
      'name': '步驟4: 名偵探柯南.mid 專屬測試',
      'midi': 'assets/test_voice/名偵探柯南.mid',
      'wavs': [
        {'path': 'assets/test_voice/名偵探柯南(midi轉檔).wav', 'name': '名偵探柯南(midi轉檔)', 'type': '複雜音樂'},
        {'path': 'assets/test_voice/名偵探柯南(環境).wav', 'name': '名偵探柯南(環境)', 'type': '複雜音樂'},
        {'path': 'assets/test_voice/環境背景.wav', 'name': '環境背景', 'type': '噪音'},
        {'path': 'assets/test_voice/環境背景2.wav', 'name': '環境背景2', 'type': '噪音'},
      ],
    },
  };

  // 選擇測試步驟
  String stepChoice = '1';
  if (args.isNotEmpty) {
    stepChoice = args[0];
  } else {
    print('📋 測試步驟:');
    print('');
    testSteps.forEach((key, value) {
      print('   [$key] ${value['name']}');
      final wavs = value['wavs'] as List;
      print('       → ${wavs.length} 個音檔測試');
      print('');
    });
    print('💡 使用方式: dart test_comprehensive.dart [1-4]');
    print('   預設使用步驟 1');
    print('');
    return;
  }

  if (!testSteps.containsKey(stepChoice)) {
    print('❌ 無效的步驟選擇: $stepChoice');
    print('   請選擇 1-4');
    return;
  }

  final step = testSteps[stepChoice]!;
  final midiPath = step['midi'] as String;
  final wavList = step['wavs'] as List<Map<String, String>>;

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🎯 ${step['name']}');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📄 指定 MIDI: $midiPath');
  print('🎵 測試音檔數: ${wavList.length}');
  print('');

  // 結果收集
  final results = <Map<String, dynamic>>[];
  int testNum = 1;

  for (final wavInfo in wavList) {
    final wavPath = wavInfo['path']!;
    final wavName = wavInfo['name']!;
    final wavType = wavInfo['type']!;

    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🧪 測試 $testNum/${wavList.length}: $wavName ($wavType)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');

    // 檢查檔案
    final midiFile = File(midiPath);
    final wavFile = File(wavPath);

    if (!midiFile.existsSync()) {
      print('❌ MIDI 檔案不存在: $midiPath');
      results.add({
        'name': wavName,
        'type': wavType,
        'status': 'ERROR',
        'error': 'MIDI not found',
      });
      testNum++;
      continue;
    }

    if (!wavFile.existsSync()) {
      print('❌ WAV 檔案不存在: $wavPath');
      results.add({
        'name': wavName,
        'type': wavType,
        'status': 'ERROR',
        'error': 'WAV not found',
      });
      testNum++;
      continue;
    }

    print('📂 檢查文件...');
    print('   ✅ MIDI: $midiPath');
    print('   ✅ WAV: $wavPath');
    final wavSize = wavFile.lengthSync() / 1024 / 1024;
    print('   📊 WAV 大小: ${wavSize.toStringAsFixed(2)} MB');
    print('');

    try {
      // 執行分析
      print('🚀 開始分析...');
      print('');
      
      final analyzer = PerformanceAnalyzer();
      final report = await analyzer.analyze(
        wavPath,
        midiPath,
      );

      // 收集結果
      results.add({
        'name': wavName,
        'type': wavType,
        'status': 'SUCCESS',
        'totalNotes': report.totalNotes,
        'correctNotes': report.correctNotes,
        'missedNotes': report.missedNotes,
        'wrongNotes': report.wrongNotes,
        'accuracy': report.accuracy,
        'grade': report.grade,
        'processingTime': report.processingTime,
      });

      print('');
      print('📊 結果: ${report.accuracy.toStringAsFixed(1)}% (${report.grade})');
      print('   ✅ 正確: ${report.correctNotes}/${report.totalNotes}');
      print('   ❌ 漏音: ${report.missedNotes}');
      print('   ⏱️  時間: ${report.processingTime}ms');
      
    } catch (e, stackTrace) {
      print('');
      print('❌ 測試失敗: $e');
      results.add({
        'name': wavName,
        'type': wavType,
        'status': 'ERROR',
        'error': e.toString(),
      });
    }

    testNum++;
  }

  // 輸出總結
  print('');
  print('');
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║                  📊 測試總結報告                          ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');
  print('🎯 ${step['name']}');
  print('📄 指定 MIDI: $midiPath');
  print('');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📈 結果匯總');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('');

  // 表格標題
  print('${_pad('測試音檔', 25)} ${_pad('類型', 12)} ${_pad('準確率', 10)} ${_pad('評級', 6)} ${_pad('狀態', 10)}');
  print('${'─' * 70}');

  // 表格內容
  for (final result in results) {
    final name = result['name'] as String;
    final type = result['type'] as String;
    final status = result['status'] as String;

    if (status == 'SUCCESS') {
      final accuracy = result['accuracy'] as double;
      final grade = result['grade'] as String;
      print('${_pad(name, 25)} ${_pad(type, 12)} ${_pad('${accuracy.toStringAsFixed(1)}%', 10)} ${_pad(grade, 6)} ${_pad('✅ PASS', 10)}');
    } else {
      final error = result['error'] as String;
      print('${_pad(name, 25)} ${_pad(type, 12)} ${_pad('N/A', 10)} ${_pad('N/A', 6)} ${_pad('❌ FAIL', 10)}');
    }
  }

  print('');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('💡 分析建議');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('');

  // 分析噪音測試
  final noiseTests = results.where((r) => 
    r['type'] == '噪音' && r['status'] == 'SUCCESS'
  ).toList();
  
  if (noiseTests.isNotEmpty) {
    print('🔇 噪音抑制測試:');
    for (final test in noiseTests) {
      final accuracy = test['accuracy'] as double;
      final name = test['name'] as String;
      if (accuracy < 10.0) {
        print('   ✅ $name: ${accuracy.toStringAsFixed(1)}% 誤報 (良好)');
      } else if (accuracy < 20.0) {
        print('   ⚠️  $name: ${accuracy.toStringAsFixed(1)}% 誤報 (可接受)');
      } else {
        print('   ❌ $name: ${accuracy.toStringAsFixed(1)}% 誤報 (需調整)');
      }
    }
    print('');
  }

  // 分析音樂測試
  final musicTests = results.where((r) => 
    r['type'] != '噪音' && r['status'] == 'SUCCESS'
  ).toList();

  if (musicTests.isNotEmpty) {
    print('🎵 音樂檢測測試:');
    for (final test in musicTests) {
      final accuracy = test['accuracy'] as double;
      final name = test['name'] as String;
      final type = test['type'] as String;
      if (accuracy >= 90.0) {
        print('   ✅ $name ($type): ${accuracy.toStringAsFixed(1)}% (優秀)');
      } else if (accuracy >= 80.0) {
        print('   ⚠️  $name ($type): ${accuracy.toStringAsFixed(1)}% (良好)');
      } else {
        print('   ❌ $name ($type): ${accuracy.toStringAsFixed(1)}% (需改進)');
      }
    }
    print('');
  }

  print('╔═══════════════════════════════════════════════════════════╗');
  print('║              ✅ 測試完成!                                 ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');
  print('💡 下一步:');
  print('   - 分析結果並調整 energyThreshold 參數');
  print('   - 運行其他測試步驟 (dart test_comprehensive.dart [1-4])');
  print('');
}

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

// debug_test_runner.dart
// 優化的偵錯測試運行工具 - 2025/11/29
// 用法: dart tools/debug_test_runner.dart [測試輪次] [選項]
// 範例: dart tools/debug_test_runner.dart 4 -q  (執行第4輪測試，安靜模式)

import 'dart:io';
import 'dart:convert';

/// 測試配置
class TestConfig {
  final int round;
  final String name;
  final String midiPath;
  final int noteCount;
  final double duration;
  final String description;

  const TestConfig({
    required this.round,
    required this.name,
    required this.midiPath,
    required this.noteCount,
    required this.duration,
    required this.description,
  });

  /// 計算音符密度 (音符數/秒)
  double get noteDensity => noteCount / duration;
}

/// 四輪測試配置
const List<TestConfig> testRounds = [
  // 第一輪：生日快樂
  TestConfig(
    round: 1,
    name: '生日快樂',
    midiPath: 'assets/test_voice/生日快樂.mid',
    noteCount: 25,
    duration: 17.0,
    description: '簡單旋律測試',
  ),

  // 第二輪：測試音檔
  TestConfig(
    round: 2,
    name: '測試音檔',
    midiPath: 'assets/test_voice/測試音檔.mid',
    noteCount: 94,
    duration: 34.0,
    description: '單音無伴奏測試',
  ),

  // 第三輪：小星星
  TestConfig(
    round: 3,
    name: '小星星',
    midiPath: 'assets/test_voice/小星星.mid',
    noteCount: 147,
    duration: 27.0,
    description: '伴奏測試',
  ),

  // 第四輪：名偵探柯南
  TestConfig(
    round: 4,
    name: '名偵探柯南',
    midiPath: 'assets/test_voice/名偵探柯南.mid',
    noteCount: 1431,
    duration: 164.0,
    description: '複雜長曲測試',
  ),
];

/// 測試樣本類型
enum SampleType {
  midiConverted('MIDI轉檔', true),
  phoneRecording('手機錄製', true),
  phoneRecording2('手機錄製2', true),
  computerRecording('電腦錄製', true),
  shortRecording('短錄音(30秒)', true), // 新增：短錄音測試
  wrongSong('錯誤音檔', false),
  environmentNoise('環境噪音', false);

  final String label;
  final bool shouldPass;
  const SampleType(this.label, this.shouldPass);
}

void main(List<String> args) async {
  // 檢查是否請求幫助
  if (args.contains('help') || args.contains('-h') || args.contains('--help')) {
    _printUsage();
    exit(0);
  }

  // 解析參數
  int? targetRound;
  bool quietMode = false;

  for (final arg in args) {
    if (arg == '-q' || arg == '--quiet') {
      quietMode = true;
    } else {
      final round = int.tryParse(arg);
      if (round != null) {
        targetRound = round;
      }
    }
  }

  // 驗證輪次
  if (targetRound != null && (targetRound < 1 || targetRound > 4)) {
    print('❌ 無效的輪次：$targetRound (有效範圍: 1-4)');
    _printUsage();
    exit(1);
  }

  // 顯示標題
  if (!quietMode) {
    print('\n${'=' * 80}');
    print('🎯 偵錯測試運行工具 - Debug Test Runner');
    print('   版本: 2025/11/29');
    if (targetRound != null) {
      print('   模式: 第 $targetRound 輪測試 (${testRounds[targetRound - 1].name})');
    } else {
      print('   模式: 完整測試（4輪）');
    }
    print('=' * 80);
  }

  // 執行測試
  final roundsToRun = targetRound != null ? [targetRound - 1] : [0, 1, 2, 3];

  for (final roundIndex in roundsToRun) {
    final config = testRounds[roundIndex];
    await _runRound(config, quietMode);
  }

  if (!quietMode) {
    print('\n${'=' * 80}');
    print('✅ 所有測試完成！');
    print('${'=' * 80}\n');
  }
}

/// 執行單輪測試
Future<void> _runRound(TestConfig config, bool quietMode) async {
  if (!quietMode) {
    print('\n${'=' * 80}');
    print('📍 第 ${config.round} 輪測試：${config.name}');
    print('   描述: ${config.description}');
    print('   音符數: ${config.noteCount}, 時長: ${config.duration}秒');
    print('   音符密度: ${config.noteDensity.toStringAsFixed(2)} notes/sec');
    print('${'=' * 80}');
  }

  // 設定環境變數
  final env = {
    ...Platform.environment,
    'TEST_MODE': config.round.toString(),
  };

  // 執行 Flutter 測試 (使用 --reporter expanded 獲得更好的輸出格式)
  final testPath = 'test/integration/debug_accuracy_test.dart';
  
  if (!quietMode) {
    print('\n🚀 執行測試: flutter test $testPath\n');
  }

  final result = await Process.run(
    'flutter',
    ['test', testPath, '--reporter', 'expanded'],
    environment: env,
    runInShell: true,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );

  // 過濾並處理輸出
  if (result.stdout != null && result.stdout.toString().isNotEmpty) {
    final output = result.stdout.toString();
    final filteredOutput = _filterOutput(output, quietMode);
    if (filteredOutput.isNotEmpty) {
      print(filteredOutput);
    }
  }

  if (result.stderr != null && result.stderr.toString().isNotEmpty) {
    if (!quietMode || result.exitCode != 0) {
      final stderrOutput = result.stderr.toString();
      // 過濾 stderr 中的無用訊息
      final filteredStderr = _filterOutput(stderrOutput, quietMode);
      if (filteredStderr.isNotEmpty) {
        stderr.write(filteredStderr);
      }
    }
  }

  if (result.exitCode != 0) {
    if (!quietMode) {
      print('\n❌ 第 ${config.round} 輪測試失敗 (退出碼: ${result.exitCode})');
    }
    exit(result.exitCode);
  }

  if (!quietMode) {
    print('\n✅ 第 ${config.round} 輪測試完成\n');
  }
}

/// 過濾輸出，移除不需要的訊息
String _filterOutput(String output, bool quietMode) {
  final lines = output.split('\n');
  final filteredLines = <String>[];
  final seenLines = <String>{}; // 用於去重
  
  for (var line in lines) {
    // 移除 Flutter test 框架的時間戳記（如 "00:08 +9:"）
    line = line.replaceAll(RegExp(r'^\d{2}:\d{2}\s*[\+\-]?\d*:?\s*'), '');
    
    // 移除 "Shell:" 前綴
    line = line.replaceAll(RegExp(r'^Shell:\s*'), '');
    
    // 移除空的時間戳記行
    if (line.trim().isEmpty || RegExp(r'^\d{2}:\d{2}\s*$').hasMatch(line)) {
      continue;
    }
    
    // 移除重複的測試框架訊息
    if (line.contains('Loading') && line.contains('test')) continue;
    if (line.contains('Running') && line.contains('test')) continue;
    if (line.startsWith('✓') || line.startsWith('√')) continue; // 移除測試通過標記
    if (line.contains('All tests passed!')) continue;
    if (line.contains('tests passed')) continue;
    
    // 去除重複行
    final trimmedLine = line.trim();
    if (trimmedLine.isEmpty) continue;
    if (seenLines.contains(trimmedLine)) continue;
    seenLines.add(trimmedLine);
    
    // 在每個 WAV 測試之間加空行（偵測到新的測試開始）
    if (line.contains('📋 測試開始:') || line.contains('測試開始:')) {
      if (filteredLines.isNotEmpty && !filteredLines.last.trim().isEmpty) {
        filteredLines.add(''); // 加空行分隔
      }
    }
    
    filteredLines.add(line);
  }
  
  return filteredLines.join('\n');
}

/// 顯示使用說明
void _printUsage() {
  print('''
═══════════════════════════════════════════════════════════════════════════════
🎯 偵錯測試運行工具 - Debug Test Runner v2025/11/29
═══════════════════════════════════════════════════════════════════════════════

用法: dart tools/debug_test_runner.dart [測試輪次] [選項]

測試輪次:
  1  - 第一輪：生日快樂 (25 notes, 17s, 簡單旋律測試)
  2  - 第二輪：測試音檔 (94 notes, 34s, 單音無伴奏測試)
  3  - 第三輪：小星星 (147 notes, 27s, 伴奏測試)
  4  - 第四輪：名偵探柯南 (1431 notes, 164s, 複雜長曲測試)
  
  ※ 不指定輪次則執行全部4輪測試

選項:
  -q, --quiet      安靜模式
  -h, --help       顯示此幫助訊息
  help             顯示此幫助訊息

安靜模式差異 (-q):
  普通模式                          安靜模式
  ─────────────────────────────────────────────────────────────
  ✓ 顯示測試運行工具標題            ✗ 不顯示
  ✓ 顯示每輪測試的詳細資訊          ✗ 不顯示
  ✓ 顯示 "執行測試" 提示            ✗ 不顯示
  ✓ 顯示 "測試完成" 訊息            ✗ 不顯示
  ✓ 顯示測試結果（準確率等）        ✓ 顯示（僅保留核心結果）
  
輸出過濾（兩種模式都會）:
  • 移除 Flutter 時間戳記（如 "00:08 +9:"）
  • 移除 "Shell:" 前綴
  • 移除重複訊息
  • 在 WAV 測試之間自動加空行分隔

範例:
  dart tools/debug_test_runner.dart                    # 執行全部4輪測試
  dart tools/debug_test_runner.dart 4                  # 僅執行第4輪（名偵探柯南）
  dart tools/debug_test_runner.dart 4 -q               # 執行第4輪（安靜模式）
  dart tools/debug_test_runner.dart help               # 顯示幫助訊息

測試內容:
  每輪測試包含以下樣本：
  • MIDI轉檔 (1個)
  • 手機/電腦錄製 (3個) - 正確演奏
  • 錯誤音檔 (3個) - 其他曲目
  • 環境噪音 (2個)
  • 短錄音測試 (僅名偵探柯南, 1個) - 用於測試短錄音懲罰機制

═══════════════════════════════════════════════════════════════════════════════
''');
}

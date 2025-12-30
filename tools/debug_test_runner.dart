// debug_test_runner.dart
// 偵錯測試運行工具 - 2025/11/29 v2.0
// 透過執行 flutter test 來運行偵錯測試，並過濾輸出
//
// 用法: dart tools/debug_test_runner.dart [測試輪次] [選項]
// 範例: dart tools/debug_test_runner.dart 4 -q  (執行第4輪測試，安靜模式)

import 'dart:io';
import 'dart:convert';

/// 測試輪次資訊
const rounds = {
  1: ('生日快樂', 25, 17.0, '簡單旋律測試'),
  2: ('測試音檔', 94, 34.0, '單音無伴奏測試'),
  3: ('小星星', 147, 27.0, '伴奏測試'),
  4: ('名偵探柯南', 1431, 164.0, '複雜長曲測試'),
};

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

  // 執行測試
  final roundsToRun = targetRound != null ? [targetRound] : [1, 2, 3, 4];

  for (final round in roundsToRun) {
    await _runRound(round, quietMode);
  }

  if (!quietMode && roundsToRun.length > 1) {
    print('\n${'=' * 80}');
    print('✅ 所有測試完成！');
    print('${'=' * 80}\n');
  }
}

/// 執行單輪測試
Future<void> _runRound(int round, bool quietMode) async {
  // 設定環境變數
  final env = {
    ...Platform.environment,
    'TEST_MODE': round.toString(),
    'QUIET_MODE': quietMode ? '1' : '0',
  };

  // 執行 Flutter 測試
  const testPath = 'test/integration/debug_accuracy_test.dart';

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
      final filteredStderr = _filterOutput(result.stderr.toString(), quietMode);
      if (filteredStderr.isNotEmpty) {
        stderr.write(filteredStderr);
      }
    }
  }

  if (result.exitCode != 0 && !quietMode) {
    print('\n❌ 第 $round 輪測試失敗 (退出碼: ${result.exitCode})');
  }
  
  // 不管測試是否通過，都繼續執行下一輪
}

/// 過濾輸出
String _filterOutput(String output, bool quietMode) {
  final lines = output.split('\n');
  final filteredLines = <String>[];
  final seenContent = <String>{};  // 只追蹤有意義的內容行
  bool inSummaryTable = false;

  for (var line in lines) {
    // 移除 Flutter test 框架的時間戳記（如 "00:08 +9:"）
    line = line.replaceAll(RegExp(r'^\d{2}:\d{2}\s*[\+\-]?\d*:?\s*'), '');
    
    // 移除 "Shell:" 前綴
    line = line.replaceAll(RegExp(r'^Shell:\s*'), '');
    
    // 移除 "loading" 訊息
    if (line.toLowerCase().contains('loading') && line.contains('.dart')) continue;
    
    // 移除空的時間戳記行
    if (RegExp(r'^\d{2}:\d{2}\s*$').hasMatch(line)) continue;
    
    // 移除測試框架雜訊
    if (line.startsWith('✓') || line.startsWith('√')) continue;
    if (line.contains('All tests passed!')) continue;
    if (line.contains('tests passed')) continue;
    if (line.contains('Running') && line.contains('test')) continue;
    
    // 移除 flutter test 框架的 group/test 標題行
    if (line.contains('偵錯系統準確度測試') && line.contains('輪') && line.contains('：')) continue;

    // 偵測總表開始
    if (line.contains('準確率總表')) {
      inSummaryTable = true;
    }

    // 安靜模式：只顯示總表
    if (quietMode && !inSummaryTable) {
      if (line.contains('測試完成')) {
        inSummaryTable = false;
      }
      continue;
    }

    // 偵測總表結束
    if (inSummaryTable && line.contains('測試完成')) {
      filteredLines.add(line);
      inSummaryTable = false;
      continue;
    }

    final trimmedLine = line.trim();
    
    // 允許空行通過（作為分隔）
    if (trimmedLine.isEmpty) {
      // 避免連續多個空行
      if (filteredLines.isNotEmpty && filteredLines.last.trim().isNotEmpty) {
        filteredLines.add('');
      }
      continue;
    }
    
    // 分隔線始終允許通過（不去重）
    if (trimmedLine.startsWith('─') || trimmedLine.startsWith('=')) {
      filteredLines.add(line);
      continue;
    }
    
    // 去除有意義內容的重複（不包括格式化元素）
    if (seenContent.contains(trimmedLine)) continue;
    seenContent.add(trimmedLine);

    filteredLines.add(line);
  }

  return filteredLines.join('\n');
}

/// 顯示使用說明
void _printUsage() {
  print('''
═══════════════════════════════════════════════════════════════════════════════
🎯 偵錯測試運行工具 - Debug Test Runner v2.0
═══════════════════════════════════════════════════════════════════════════════

用法: dart tools/debug_test_runner.dart [測試輪次] [選項]

測試輪次:
  1  - 第一輪：生日快樂 (25 notes, 17s, 簡單旋律測試)
  2  - 第二輪：測試音檔 (94 notes, 34s, 單音無伴奏測試)
  3  - 第三輪：小星星 (147 notes, 27s, 伴奏測試)
  4  - 第四輪：名偵探柯南 (1431 notes, 164s, 複雜長曲測試)
  
  ※ 不指定輪次則執行全部4輪測試

選項:
  -q, --quiet      安靜模式（只顯示每輪的總表）
  -h, --help       顯示此幫助訊息
  help             顯示此幫助訊息

模式差異:
  ┌────────────────────────┬────────────┬────────────┐
  │ 內容                   │ 普通模式   │ 安靜模式   │
  ├────────────────────────┼────────────┼────────────┤
  │ 每個樣本的測試過程     │     ✓      │     ✗      │
  │ 每輪的準確率總表       │     ✓      │     ✓      │
  │ 警告摘要               │     ✓      │     ✓      │
  └────────────────────────┴────────────┴────────────┘

範例:
  dart tools/debug_test_runner.dart                    # 執行全部4輪測試
  dart tools/debug_test_runner.dart 4                  # 僅執行第4輪（名偵探柯南）
  dart tools/debug_test_runner.dart 4 -q               # 執行第4輪（安靜模式）
  dart tools/debug_test_runner.dart help               # 顯示幫助訊息

每輪測試內容:
  • MIDI轉檔 (1個) - 期望準確率 ≥90%
  • 手機/電腦錄製 (3個) - 期望準確率 ≥90%
  • 錯誤音檔 (3個) - 期望準確率 <50%
  • 環境噪音 (2個) - 期望準確率 <20%

═══════════════════════════════════════════════════════════════════════════════
''');
}

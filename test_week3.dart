import 'dart:io';
import 'lib/services/audio_analysis/performance_analyzer.dart';

/// 階段 2.3 整合測試 - 錯誤分類與準確度驗證
void main(List<String> args) async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║       🎼 階段 2.3: 錯誤分類與整合測試                     ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');
  
  // 測試配置表
  final testCases = {
    '1': {
      'name': '小星星 (MIDI轉檔) - 100%準確基準測試',
      'midi': 'assets/test_voice/小星星.mid',
      'wav': 'assets/test_voice/小星星(midi轉檔).wav',
      'expected': '應該達到 95-100% 準確率 (理想情況,含和弦+伴奏)',
    },
    '2': {
      'name': '小星星 (環境錄製) - 真實演奏測試',
      'midi': 'assets/test_voice/小星星.mid',
      'wav': 'assets/test_voice/小星星(環境).wav',
      'expected': '測試真實環境下的準確度 (含和弦+伴奏)',
    },
    '3': {
      'name': '測試音檔 (MIDI轉檔) - 單音測試',
      'midi': 'assets/test_voice/測試音檔.mid',
      'wav': 'assets/test_voice/測試音檔(midi轉檔).wav',
      'expected': '單音演奏基準測試',
    },
    '4': {
      'name': '測試音檔 (環境錄製) - 單音環境測試',
      'midi': 'assets/test_voice/測試音檔.mid',
      'wav': 'assets/test_voice/測試音檔(環境).wav',
      'expected': '單音真實環境測試',
    },
    '5': {
      'name': '環境背景音 - 噪音抑制測試',
      'midi': 'assets/test_voice/小星星.mid',
      'wav': 'assets/test_voice/環境背景.wav',
      'expected': '應該檢測不到任何音符 (驗證抗噪能力)',
    },
  };
  
  // 選擇測試案例
  String testChoice = '1';
  if (args.isNotEmpty) {
    testChoice = args[0];
  } else {
    print('📋 可用的測試案例:');
    print('');
    testCases.forEach((key, value) {
      print('   [$key] ${value['name']}');
      print('       → ${value['expected']}');
      print('');
    });
    print('💡 使用方式: dart test_week3.dart [1-5]');
    print('   預設使用測試案例 1 (小星星 MIDI轉檔)');
    print('');
  }
  
  final selectedTest = testCases[testChoice];
  if (selectedTest == null) {
    print('❌ 無效的測試案例: $testChoice');
    return;
  }
  
  final midiPath = selectedTest['midi'] as String;
  final wavPath = selectedTest['wav'] as String;
  
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🧪 測試案例: ${selectedTest['name']}');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('   預期結果: ${selectedTest['expected']}');
  print('');
  
  // 檢查文件
  print('📂 檢查文件...');
  final midiFile = File(midiPath);
  final wavFile = File(wavPath);
  
  if (!await midiFile.exists()) {
    print('❌ 找不到 MIDI: $midiPath');
    return;
  }
  print('   ✅ MIDI: $midiPath');
  
  if (!await wavFile.exists()) {
    print('   ❌ 找不到 WAV: $wavPath');
    return;
  }
  print('   ✅ WAV: $wavPath');
  
  // 顯示文件資訊
  final wavSize = await wavFile.length();
  print('   📊 WAV 大小: ${(wavSize / 1024 / 1024).toStringAsFixed(2)} MB');
  print('');
  
  try {
    // 創建分析器
    final analyzer = PerformanceAnalyzer();
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🚀 開始分析...');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    
    // 執行分析 (帶進度條)
    final report = await analyzer.analyze(
      wavPath,
      midiPath,
      onProgress: (progress) {
        final percent = (progress * 100).toStringAsFixed(0);
        final bar = '█' * (progress * 30).round();
        final empty = '░' * (30 - (progress * 30).round());
        print('\r   進度: $bar$empty $percent%');
      },
    );
    
    print('');
    print('╔═══════════════════════════════════════════════════════════╗');
    print('║                     📊 分析報告                           ║');
    print('╚═══════════════════════════════════════════════════════════╝');
    print('');
    
    // 基本統計
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📈 基本統計');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    print('   總音符數: ${report.totalNotes}');
    print('   ✅ 正確: ${report.correctNotes}');
    print('   ❌ 漏音: ${report.missedNotes}');
    print('   🔴 錯音: ${report.wrongNotes}');
    print('   ⏪ 搶拍: ${report.earlyNotes}');
    print('   ⏩ 拖拍: ${report.lateNotes}');
    print('');
    print('   準確率: ${(report.accuracy * 100).toStringAsFixed(1)}%');
    print('   節奏分數: ${report.rhythmScore.toStringAsFixed(1)}');
    print('   總分: ${report.overallScore.toStringAsFixed(1)}');
    print('   處理時間: ${report.processingTime.inMilliseconds}ms');
    print('');
    
    // 評級
    final gradeIcon = switch (report.grade) {
      'A' => '🏆',
      'B' => '🥈',
      'C' => '🥉',
      'D' => '📝',
      _ => '💪',
    };
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎯 評級');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    print('   $gradeIcon 評級: ${report.grade}');
    print('');
    
    // 錯誤詳情
    if (report.errors.isNotEmpty) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('⚠️  錯誤詳情 (前 20 個)');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      
      for (int i = 0; i < report.errors.length && i < 20; i++) {
        final error = report.errors[i];
        final icon = switch (error.type.toString().split('.').last) {
          'missedNote' => '❌',
          'wrongNote' => '🔴',
          'earlyTiming' => '⏪',
          'lateTiming' => '⏩',
          _ => '⚠️',
        };
        
        print('   ${(i + 1).toString().padLeft(2)}. $icon ${error.message}');
      }
      
      if (report.errors.length > 20) {
        print('   ... 還有 ${report.errors.length - 20} 個錯誤');
      }
      print('');
    }
    
    // 建議
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('💡 練習建議');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    
    if (report.accuracy >= 0.95) {
      print('   🌟 演奏非常出色!可以嘗試更難的曲目。');
    } else if (report.accuracy >= 0.85) {
      print('   👍 演奏很好!繼續保持,注意錯誤的地方。');
    } else if (report.accuracy >= 0.75) {
      print('   📝 建議重點練習錯誤較多的段落。');
    } else if (report.accuracy >= 0.65) {
      print('   💪 建議放慢速度,確保每個音符都準確。');
    } else {
      print('   🎯 建議分段練習,每次只練習幾小節。');
      print('   🎼 確保每個音符都能清晰彈出再加快速度。');
    }
    
    if (report.missedNotes > 0) {
      print('   ❌ 有 ${report.missedNotes} 個漏音,注意音符的清晰度');
    }
    
    if (report.earlyNotes + report.lateNotes > report.totalNotes * 0.1) {
      print('   🎵 節奏不夠穩定,建議使用節拍器練習');
    }
    print('');
    
    // 測試案例驗證
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔬 測試案例驗證');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    
    // 根據測試案例給出評估
    switch (testChoice) {
      case '1':
        // 小星星 MIDI轉檔 - 應該是95%+準確 (和弦會更難)
        if (report.accuracy >= 0.90) {
          print('   ✅ PASS: 小星星MIDI轉檔測試達到預期準確度');
          print('   → 頻譜驗證引擎能處理和弦+伴奏');
        } else {
          print('   ⚠️  WARNING: 準確度低於預期');
          print('   → 和弦檢測可能需要調整參數');
        }
        break;
        
      case '2':
        // 小星星真實錄製 - 應該是80-90%
        if (report.accuracy >= 0.75) {
          print('   ✅ PASS: 小星星環境測試表現良好');
          print('   → 系統能夠處理複雜音樂+環境噪音');
        } else if (report.accuracy >= 0.60) {
          print('   ⚠️  WARNING: 準確度略低');
          print('   → 和弦+伴奏在真實環境下更具挑戰性');
        } else {
          print('   ❌ FAIL: 準確度過低');
          print('   → 建議檢查錄音品質或調整參數');
        }
        break;

      case '3':
        // 測試音檔 MIDI轉檔 - 應該是95%+
        if (report.accuracy >= 0.95) {
          print('   ✅ PASS: 單音MIDI轉檔測試達到預期');
          print('   → 基礎功能穩定');
        } else {
          print('   ⚠️  WARNING: 單音測試準確度低於預期');
        }
        break;
        
      case '4':
        // 測試音檔環境錄製 - 應該是85-95%
        if (report.accuracy >= 0.85) {
          print('   ✅ PASS: 單音環境測試表現良好');
        } else {
          print('   ⚠️  WARNING: 準確度略低');
        }
        break;
        
      case '5':
        // 背景音測試 - 應該幾乎沒有檢測到音符
        if (report.correctNotes == 0 && report.totalNotes > 0) {
          print('   ✅ PASS: 正確識別為無演奏(純噪音)');
          print('   → 系統抗噪能力良好');
        } else if (report.correctNotes <= report.totalNotes * 0.1) {
          print('   ⚠️  WARNING: 檢測到少量誤報');
          print('   → 可能需要提高能量閾值');
        } else {
          print('   ❌ FAIL: 誤報率過高');
          print('   → 需要調整 energyThreshold 參數');
        }
        break;
    }
    print('');
    
    print('╔═══════════════════════════════════════════════════════════╗');
    print('║              ✅ 階段 2.3 測試完成!                        ║');
    print('╚═══════════════════════════════════════════════════════════╝');
    print('');
    print('💡 提示: 執行其他測試案例請使用:');
    print('   dart test_week3.dart 1  # 小星星 MIDI轉檔 (和弦+伴奏)');
    print('   dart test_week3.dart 2  # 小星星 環境錄製');
    print('   dart test_week3.dart 3  # 測試音檔 MIDI轉檔 (單音)');
    print('   dart test_week3.dart 4  # 測試音檔 環境錄製');
    print('   dart test_week3.dart 5  # 背景噪音抑制測試');
    
  } catch (e, stackTrace) {
    print('');
    print('❌ 測試失敗: $e');
    print('');
    print(stackTrace);
  }
}

/// 測試輔助工具
///
/// 提供常用的測試工具函數、Mock 物件和測試數據

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// 測試檔案路徑輔助
class TestPaths {
  /// 測試資源目錄
  static String get testAssets => 'assets/test_voice';
  
  /// 測試 MIDI 檔案 - 小星星
  static String get testMidi => '$testAssets/小星星.mid';
  
  /// 測試 WAV 檔案 - 小星星
  static String get testWav => '$testAssets/小星星(電腦環境錄製).wav';
  
  /// 測試 MIDI 檔案 - 名偵探柯南
  static String get conanMidi => '$testAssets/名偵探柯南.mid';
  
  /// 測試 WAV 檔案 - 名偵探柯南
  static String get conanWav => '$testAssets/名偵探柯南(電腦環境錄製).wav';
  
  /// 測試 MIDI 檔案 - 生日快樂
  static String get happyBirthdayMidi => '$testAssets/生日快樂.mid';
  
  /// 測試 WAV 檔案 - 生日快樂
  static String get happyBirthdayWav => '$testAssets/生日快樂(電腦環境錄製).wav';
  
  /// 檢查測試檔案是否存在
  static Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }
}

/// 測試數據產生器
class TestDataGenerator {
  /// 產生測試用的 MIDI 音符序列
  static List<int> generateMidiNotes({
    int count = 10,
    int minNote = 60,
    int maxNote = 72,
  }) {
    return List.generate(
      count,
      (index) => minNote + (index % (maxNote - minNote + 1)),
    );
  }
  
  /// 產生測試用的時間序列
  static List<double> generateTimestamps({
    int count = 10,
    double interval = 0.5,
  }) {
    return List.generate(count, (index) => index * interval);
  }
}

/// 非同步測試輔助
class AsyncTestHelper {
  /// 等待一小段時間（用於非同步操作）
  static Future<void> waitShort() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  /// 等待中等時間
  static Future<void> waitMedium() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  /// 等待較長時間
  static Future<void> waitLong() async {
    await Future.delayed(const Duration(seconds: 1));
  }
}

/// 數值比較輔助
class NumericMatcher {
  /// 檢查兩個浮點數是否接近（誤差範圍內）
  static Matcher closeTo(num value, {num delta = 0.01}) {
    return inInclusiveRange(value - delta, value + delta);
  }
  
  /// 檢查數值在指定範圍內
  static Matcher inRange(num min, num max) {
    return inInclusiveRange(min, max);
  }
}

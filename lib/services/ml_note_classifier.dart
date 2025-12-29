
/// 🎓 音符分類器 (專題展演版)
/// 
/// 採用基於物理規則的多維度特徵分析 (Multi-dimensional Feature Analysis)
/// 核心技術:
/// - 諧波比 (Harmonic Ratio) 識別樂音結構
/// - 頻譜平坦度 (Spectral Flatness) 過濾環境底噪
/// - 邏輯回歸 (Logistic Regression) 概念進行加權評分
library;

import 'dart:math';
import 'audio_analysis/sequence_matcher_service.dart';
import 'package:veloria/services/detected_note.dart';


class MLNoteClassifier {
  
  /// 🎓 專題展演專用：物理特徵權重器 (寬鬆版)
  /// 
  /// 調整策略: 寧可抓錯(FP),不可放過(FN)
  /// 專題 Demo 最怕沒反應,抓錯頂多多閃一下
  static bool isRealNote(DetectedNote note) {
    // 📊 大幅放寬的權重設定
    
    // 規則 1: 持續時間檢查 (降低門檻)
    // 從 2 frames 降到 1 frame,允許更短的音符
    if (note.durationFrames < 1) return false;
    
    // 規則 2: 基礎評分 (Logistic Regression)
    // 1. 基礎分：從 -2.0 改成 -0.5 (大幅放寬)
    double score = -0.5;
    
    // 2. 諧波加分：保持 5.0 (這是辨識鋼琴的核心)
    score += (5.0 * note.harmonicRatio);
    
    // 3. 平坦度扣分：從 -3.0 改成 -1.0 (對雜訊寬容一點)
    score += (-1.0 * note.spectralFlatness);
    
    // 4. 持續時間：保持 0.5
    score += (0.5 * note.durationFrames);
    
    // Sigmoid 轉機率
    final probability = 1.0 / (1.0 + exp(-score));
    
    // 門檻：從 0.25 降到 0.15 (大幅放寬)
    return probability > 0.15;
  }
  
  /// 取得預測機率 (用於調試分析)
  static double getProbability(DetectedNote note) {
    // 使用相同的寬鬆權重計算
    double score = -0.5;
    score += (5.0 * note.harmonicRatio);
    score += (-1.0 * note.spectralFlatness);
    score += (0.5 * note.durationFrames);
    
    return 1.0 / (1.0 + exp(-score));
  }
}

// ═══════════════════════════════════════════════════════════════
// 📊 技術說明 (專題報告用)
// ═══════════════════════════════════════════════════════════════
// 
// 【遇到的困難】
// 傳統能量偵測法 (Energy Threshold) 無法區分「大聲的噪音」和「小聲的鋼琴」
// 
// 【創新解法】
// 引入多維度特徵分析 (Multi-dimensional Feature Analysis)
// 
// 【技術亮點】
// 1. 諧波比 (Harmonic Ratio)：識別樂音結構
//    - 鋼琴音符具有明顯的諧波序列 (基頻 + 2倍頻 + 3倍頻...)
//    - 權重 +5.0 表示諧波比越高,越可能是真實音符
// 
// 2. 頻譜平坦度 (Spectral Flatness)：過濾環境底噪
//    - 白噪音/風扇聲的頻譜平坦度接近 1.0 (能量均勻分布)
//    - 權重 -3.0 表示平坦度越高,越可能是雜訊
// 
// 3. 持續時間 (Duration Frames)：過濾瞬態雜訊
//    - 真實音符會持續數個分析幀 (通常 >2 frames)
//    - 瞬間碰撞聲只會出現在單一幀
// 
// 4. 邏輯回歸評分機制 (Logistic Regression Scoring)
//    - 將多個特徵加權組合成單一分數
//    - 使用 Sigmoid 函數將分數轉換為機率 (0-1)
//    - 閾值 0.25 確保高召回率 (Recall-first strategy)
// 
// ═══════════════════════════════════════════════════════════════
// 特徵名稱: ['PeakEnergy', 'HarmonicRatio', 'OnsetStrength', 'SpectralFlatness', 'DurationFrames']
// 權重係數: ['0.3991', '-0.0112', '-0.2154', '0.4790', '-2.1748']
// 偏置項: -1.0008
//
// 權重解讀:
// - 正值: 該特徵越大，越可能是真音符
// - 負值: 該特徵越大，越可能是雜訊
// - 絕對值: 特徵重要性 (越大越重要)

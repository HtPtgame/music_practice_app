#!/usr/bin/env python3
"""
ML 分類器訓練腳本
目標: 訓練邏輯回歸模型，區分真實音符 vs 雜訊
輸出: Dart 可用的權重係數

數據來源: ml_training_data.csv (由 test_ml_data_collection.dart 產生)
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score
import matplotlib.pyplot as plt
import seaborn as sns

def load_data(csv_path='ml_training_data.csv'):
    """載入訓練數據"""
    print("📂 載入訓練數據...")
    df = pd.read_csv(csv_path)
    
    print(f"✅ 載入 {len(df)} 筆數據")
    print(f"   - 特徵維度: {df.shape[1] - 1}")
    print(f"   - 標籤分佈:")
    print(df['Label'].value_counts())
    
    # 檢查缺失值
    if df.isnull().sum().any():
        print("⚠️ 發現缺失值，正在移除...")
        df = df.dropna()
    
    return df

def visualize_features(df):
    """視覺化特徵分佈"""
    print("\n📊 繪製特徵分佈圖...")
    
    features = ['PeakEnergy', 'HarmonicRatio', 'OnsetStrength', 'SpectralFlatness', 'DurationFrames']
    
    fig, axes = plt.subplots(2, 3, figsize=(15, 10))
    axes = axes.flatten()
    
    for idx, feature in enumerate(features):
        ax = axes[idx]
        
        # 分別繪製 Label=0 和 Label=1 的分佈
        df[df['Label'] == 0][feature].hist(ax=ax, bins=30, alpha=0.6, label='雜訊 (0)', color='red')
        df[df['Label'] == 1][feature].hist(ax=ax, bins=30, alpha=0.6, label='真音符 (1)', color='blue')
        
        ax.set_xlabel(feature)
        ax.set_ylabel('頻率')
        ax.set_title(f'{feature} 分佈')
        ax.legend()
        ax.grid(True, alpha=0.3)
    
    # 刪除多餘的子圖
    fig.delaxes(axes[5])
    
    plt.tight_layout()
    plt.savefig('feature_distribution.png', dpi=150)
    print("✅ 特徵分佈圖已保存: feature_distribution.png")
    
    # 繪製相關性熱力圖
    print("\n📈 繪製特徵相關性熱力圖...")
    plt.figure(figsize=(10, 8))
    correlation = df[features + ['Label']].corr()
    sns.heatmap(correlation, annot=True, fmt='.2f', cmap='coolwarm', center=0)
    plt.title('特徵相關性矩陣')
    plt.tight_layout()
    plt.savefig('feature_correlation.png', dpi=150)
    print("✅ 相關性熱力圖已保存: feature_correlation.png")

def train_model(X_train, y_train):
    """訓練邏輯回歸模型"""
    print("\n🤖 開始訓練邏輯回歸模型...")
    
    # 🔧 使用 class_weight='balanced' 處理數據不平衡
    # 原因: 真音符樣本只有 12.8%,模型傾向永遠預測 Label=0
    model = LogisticRegression(
        penalty='l2',
        C=1.0,  # 正則化強度 (越小越強)
        class_weight='balanced',  # 自動調整權重,重視少數類
        max_iter=1000,
        random_state=42,
        solver='lbfgs'
    )
    
    model.fit(X_train, y_train)
    
    print("✅ 訓練完成!")
    return model

def evaluate_model(model, X_test, y_test, scaler):
    """評估模型性能"""
    print("\n📊 評估模型性能...")
    
    # 預測
    y_pred = model.predict(X_test)
    y_proba = model.predict_proba(X_test)[:, 1]
    
    # 分類報告
    print("\n📋 分類報告:")
    print(classification_report(y_test, y_pred, target_names=['雜訊 (0)', '真音符 (1)']))
    
    # 混淆矩陣
    print("\n🔍 混淆矩陣:")
    cm = confusion_matrix(y_test, y_pred)
    print(cm)
    print(f"   真陰性 (TN): {cm[0, 0]}")
    print(f"   假陽性 (FP): {cm[0, 1]}")
    print(f"   假陰性 (FN): {cm[1, 0]}")
    print(f"   真陽性 (TP): {cm[1, 1]}")
    
    # ROC AUC
    auc = roc_auc_score(y_test, y_proba)
    print(f"\n🎯 ROC AUC Score: {auc:.4f}")
    
    # 交叉驗證
    print("\n🔄 執行 5-Fold 交叉驗證...")
    cv_scores = cross_val_score(model, X_test, y_test, cv=5, scoring='f1')
    print(f"   F1 Scores: {cv_scores}")
    print(f"   平均 F1: {cv_scores.mean():.4f} (+/- {cv_scores.std() * 2:.4f})")
    
    # 繪製混淆矩陣
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                xticklabels=['雜訊 (0)', '真音符 (1)'],
                yticklabels=['雜訊 (0)', '真音符 (1)'])
    plt.ylabel('實際標籤')
    plt.xlabel('預測標籤')
    plt.title('混淆矩陣')
    plt.tight_layout()
    plt.savefig('confusion_matrix.png', dpi=150)
    print("\n✅ 混淆矩陣圖已保存: confusion_matrix.png")

def export_to_dart(model, scaler, feature_names):
    """匯出為 Dart 程式碼"""
    print("\n🚀 匯出 Dart 程式碼...")
    
    # 取得權重和偏置
    weights = model.coef_[0]
    bias = model.intercept_[0]
    
    # 標準化參數 (用於部署時的特徵縮放)
    means = scaler.mean_
    stds = scaler.scale_
    
    # 產生 Dart 程式碼
    dart_code = f"""
/// 🤖 ML 音符分類器 (自動產生)
/// 訓練日期: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}
/// 模型: Logistic Regression with L2 Regularization
class MLNoteClassifier {{
  // 特徵標準化參數
  static const List<double> featureMeans = {list(means)};
  static const List<double> featureStds = {list(stds)};
  
  // 邏輯回歸權重
  static const List<double> weights = {list(weights)};
  static const double bias = {bias};
  
  /// 判斷候選音符是否為真實音符
  /// 
  /// 輸入: DetectedNote (包含 5 個 ML 特徵)
  /// 輸出: true (真音符) / false (雜訊)
  static bool isRealNote(DetectedNote note) {{
    // 提取特徵向量
    final features = [
      note.peakEnergy,
      note.harmonicRatio,
      note.onsetStrength,
      note.spectralFlatness,
      note.durationFrames.toDouble(),
    ];
    
    // 特徵標準化 (z-score normalization)
    final normalizedFeatures = <double>[];
    for (int i = 0; i < features.length; i++) {{
      final normalized = (features[i] - featureMeans[i]) / featureStds[i];
      normalizedFeatures.add(normalized);
    }}
    
    // 計算邏輯回歸分數
    double score = bias;
    for (int i = 0; i < weights.length; i++) {{
      score += weights[i] * normalizedFeatures[i];
    }}
    
    // Sigmoid 函數: prob = 1 / (1 + e^(-score))
    final probability = 1.0 / (1.0 + exp(-score));
    
    // 閾值 0.5 (可調整以平衡 Precision/Recall)
    return probability > 0.5;
  }}
  
  /// 取得預測機率 (用於調試)
  static double getProbability(DetectedNote note) {{
    final features = [
      note.peakEnergy,
      note.harmonicRatio,
      note.onsetStrength,
      note.spectralFlatness,
      note.durationFrames.toDouble(),
    ];
    
    final normalizedFeatures = <double>[];
    for (int i = 0; i < features.length; i++) {{
      final normalized = (features[i] - featureMeans[i]) / featureStds[i];
      normalizedFeatures.add(normalized);
    }}
    
    double score = bias;
    for (int i = 0; i < weights.length; i++) {{
      score += weights[i] * normalizedFeatures[i];
    }}
    
    return 1.0 / (1.0 + exp(-score));
  }}
}}

// ═══════════════════════════════════════════════════════════════
// 📊 特徵重要性分析
// ═══════════════════════════════════════════════════════════════
// 特徵名稱: {feature_names}
// 權重係數: {[f'{w:.4f}' for w in weights]}
// 偏置項: {bias:.4f}
//
// 權重解讀:
// - 正值: 該特徵越大，越可能是真音符
// - 負值: 該特徵越大，越可能是雜訊
// - 絕對值: 特徵重要性 (越大越重要)
"""
    
    # 保存到檔案
    with open('ml_note_classifier.dart', 'w', encoding='utf-8') as f:
        f.write(dart_code)
    
    print("✅ Dart 程式碼已保存: ml_note_classifier.dart")
    
    # 輸出特徵重要性排名
    print("\n🏆 特徵重要性排名:")
    importance = list(zip(feature_names, weights))
    importance.sort(key=lambda x: abs(x[1]), reverse=True)
    for rank, (name, weight) in enumerate(importance, 1):
        direction = "正相關 ↑" if weight > 0 else "負相關 ↓"
        print(f"   #{rank}: {name:20s} {weight:+.4f} ({direction})")

def main():
    """主程式"""
    print("=" * 70)
    print("🤖 ML 音符分類器訓練管線")
    print("=" * 70)
    
    # 1. 載入數據
    df = load_data()
    
    # 2. 視覺化
    visualize_features(df)
    
    # 3. 準備訓練數據
    feature_names = ['PeakEnergy', 'HarmonicRatio', 'OnsetStrength', 'SpectralFlatness', 'DurationFrames']
    X = df[feature_names].values
    y = df['Label'].values
    
    # 4. 特徵標準化
    print("\n🔧 執行特徵標準化...")
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    # 5. 分割訓練集與測試集
    print("\n✂️ 分割訓練集與測試集 (80/20)...")
    X_train, X_test, y_train, y_test = train_test_split(
        X_scaled, y, test_size=0.2, random_state=42, stratify=y
    )
    print(f"   訓練集: {len(X_train)} 筆")
    print(f"   測試集: {len(X_test)} 筆")
    
    # 6. 訓練模型
    model = train_model(X_train, y_train)
    
    # 7. 評估模型
    evaluate_model(model, X_test, y_test, scaler)
    
    # 8. 匯出 Dart 程式碼
    export_to_dart(model, scaler, feature_names)
    
    print("\n" + "=" * 70)
    print("✅ 訓練完成!")
    print("=" * 70)
    print("\n📋 產生的檔案:")
    print("   - feature_distribution.png (特徵分佈圖)")
    print("   - feature_correlation.png (相關性熱力圖)")
    print("   - confusion_matrix.png (混淆矩陣)")
    print("   - ml_note_classifier.dart (Dart 分類器)")
    print("\n🚀 下一步:")
    print("   1. 將 ml_note_classifier.dart 複製到專案中")
    print("   2. 在 note_detector_service_optimized.dart 中整合")
    print("   3. 執行 accuracy_evaluation_test.dart 驗證效果")
    print("   4. 目標: F1 Score 從 17% → 50%+")

if __name__ == '__main__':
    main()

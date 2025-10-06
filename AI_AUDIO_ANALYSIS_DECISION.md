# 🎵 演奏錄音分析系統 - 最終技術決策書

> **決策日期**: 2025年10月6日  
> **決策者**: 開發團隊 + 三方AI諮詢 (Claude, Gemini, ChatGPT)  
> **狀態**: ✅ 已批准,準備實施

---

## 📌 問題背景

### 當前痛點
- **問題描述**: AI音頻轉MIDI功能產生隨機、不準確的音符偵測
- **用戶反饋**: "音符亂偵測的問題,偵測完全不准,比較像隨機彈出來的"
- **失敗方案**: 
  - Basic Pitch TFLite模型 (缺乏完整後處理邏輯)
  - 多策略閾值調整 (v6.2) - 仍然無效
  - 分塊處理 (1秒區塊) - 破壞時間上下文

### 核心需求
✅ **離線分析**: 演奏後用錄音檔進行偵錯  
✅ **準確比對**: 判斷是否符合MIDI標準答案  
✅ **多音支援**: 處理鋼琴和弦 (Polyphonic)  
✅ **錯誤分類**: 區分錯音/漏音/節奏問題  

---

## 🔍 三方AI諮詢結果

### 方案比較表

| AI助理 | 核心技術 | 優勢 | 劣勢 | 推薦度 |
|--------|---------|------|------|--------|
| **Claude** | FFT頻譜分析 + 能量比對 | 穩定可控、完全離線、低資源 | 需理解DSP基礎 | ⭐⭐⭐⭐⭐ |
| **Gemini** | YIN音高偵測 + 起音對齊 | 架構清晰、快速實作 | 多音準確度差 | ⭐⭐⭐☆☆ |
| **ChatGPT** | 混合架構 + 頻譜模板驗證 | 高準確度、可擴展ML | 理論偏重 | ⭐⭐⭐⭐⭐ |

### 關鍵洞見

#### 💡 三方共識
1. **問題根源**: 當前方案是「盲目轉譯」,應該改為「目標驗證」
2. **技術路線**: 頻譜模板驗證是最佳解決方案
3. **數據格式**: 必須使用WAV無損格式 (44100Hz, PCM16)
4. **備用方案**: YIN算法適合作為輔助/備用

#### 🎯 ChatGPT核心觀點
> "不要問『這裡是什麼音符?』,而要問『這個特定音符在這個時間點存在嗎?』"

這個「目標導向」思維徹底改變了我們的技術路線。

---

## ✅ 最終決策方案

### 主方案: **分層式頻譜驗證引擎**

#### 技術架構
```
┌─────────────────────────────────────────┐
│  UI層: AnalysisPage                     │
│  - 觸發分析 / 顯示報告                   │
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│  協調層: PerformanceAnalysisService     │
│  - 整合各服務 / 錯誤分類 / 報告生成       │
└─────────────────────────────────────────┘
          ↓                    ↓
┌──────────────────┐  ┌──────────────────┐
│ MidiParserService│  │ AudioAnalyzer    │
│ (標準答案解析)    │  │ Service          │
│                  │  │ (STFT頻譜分析)    │
└──────────────────┘  └──────────────────┘
          ↓                    ↓
┌─────────────────────────────────────────┐
│  核心層: NoteVerificationService         │
│  - 頻譜模板匹配                          │
│  - 諧波驗證 (f0, 2f0, 3f0)               │
│  - 節奏對齊 (DTW/Onset Detection)        │
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│  ErrorClassificationService             │
│  - 正確/錯音/漏音/搶拍/拖拍               │
└─────────────────────────────────────────┘
```

#### 核心算法

**1. 頻譜分析 (STFT)**
```dart
// 參數配置
const int sampleRate = 44100;
const int fftSize = 2048;      // 頻率解析度 ~21.5Hz
const int hopSize = 512;       // 時間解析度 ~11.6ms

// 生成時間-頻率譜圖
Spectrogram generateSpectrogram(Uint8List wavData);
```

**2. 音符驗證 (Spectral Template Matching)**
```dart
bool verifyNoteAtTime({
  required int midiNote,
  required double startTime,
  required Spectrogram spectrogram,
}) {
  // Step 1: 計算目標頻率
  double f0 = 440 * pow(2, (midiNote - 69) / 12);
  
  // Step 2: 檢查基頻與諧波能量
  double score = 
    1.0 * energy[f0] +        // 基頻
    0.5 * energy[2 * f0] +    // 第一泛音
    0.25 * energy[3 * f0];    // 第二泛音
  
  // Step 3: 判斷是否超過閾值
  return score > threshold;
}
```

**3. 錯誤分類**
```dart
enum ErrorType {
  correct,      // ✅ 正確
  wrongNote,    // ❌ 錯音 (彈了不該彈的)
  missedNote,   // ⚠️ 漏音 (該彈沒彈)
  earlyTiming,  // ⏩ 搶拍 (提前 >100ms)
  lateTiming,   // ⏸️ 拖拍 (延遲 >100ms)
}
```

#### 技術優勢
✅ **多音支援**: 可同時驗證和弦中的多個音符  
✅ **準確率高**: 諧波驗證區分真實鋼琴音與噪音  
✅ **完全離線**: 不依賴外部API或黑盒子模型  
✅ **可控可調**: 所有參數透明,可根據實測調整  
✅ **可擴展性**: 未來可引入ML模型進一步優化  

---

### 備用方案: **YIN音高序列比對**

#### 啟用條件
- ⚠️ FFT實作遇到技術瓶頸 (>3天未解決)
- 📊 頻譜驗證準確率 <60%
- 🎵 單音旋律片段的輔助驗證

#### 實作策略
```dart
// 使用 pitch_detector_dart 套件
import 'package:pitch_detector_dart/pitch_detector.dart';

// 提取音高序列
List<PitchResult> extractPitchSequence(Uint8List audioData);

// 與MIDI時間軸對齊
AlignmentResult alignWithMidi(
  List<PitchResult> detected,
  List<NoteEvent> midiEvents,
);
```

#### 角色定位
- 🧪 **早期原型**: 快速驗證錄音分析流程
- 🔄 **交叉驗證**: 輔助頻譜驗證模糊判斷
- 📈 **單音優化**: 處理單音旋律線

---

## 📅 實施計劃

### 第1週: 基礎建設 (Foundation)

#### 任務1.1: 錄音格式升級 ⏱️ 1-2天
**目標**: 將AAC格式改為WAV無損格式

**修改文件**: `lib/pages/practice_page.dart`
```dart
// 舊配置 (AAC)
RecordConfig(
  encoder: AudioEncoder.aacLc,
  bitRate: 128000,
  sampleRate: 44100,
)

// 新配置 (WAV)
RecordConfig(
  encoder: AudioEncoder.wav,
  sampleRate: 44100,
  numChannels: 1,  // 單聲道
)
```

**驗證標準**: 
- ✅ 錄音文件為.wav格式
- ✅ 採樣率確認為44100Hz
- ✅ 文件大小合理 (~5MB/分鐘)

#### 任務1.2: FFT套件選型 ⏱️ 2-3天
**候選套件**:
1. **fft** (推薦) - 純Dart實現,跨平台
2. **fftea** (備選) - 性能優化版本

**測試項目**:
```dart
// 測試代碼
import 'package:fft/fft.dart';

void testFFT() {
  final fft = FFT();
  List<double> samples = [...]; // 測試數據
  
  // 驗證FFT輸出
  var spectrum = fft.realFft(samples);
  
  // 檢查頻率解析度
  double freqResolution = 44100 / 2048;
  assert(freqResolution < 25); // 應 ~21.5Hz
}
```

**交付物**:
- ✅ 確定FFT套件並添加至`pubspec.yaml`
- ✅ 能正確生成頻譜數據
- ✅ 性能測試報告 (處理1分鐘音頻耗時)

#### 任務1.3: 服務架構建立 ⏱️ 1天
**新建文件**:
```
lib/services/audio_analysis/
├── audio_analyzer_service.dart
├── note_verification_service.dart
├── performance_analysis_service.dart
├── error_classification_service.dart
└── models/
    ├── spectrogram.dart
    ├── note_event.dart
    ├── performance_error.dart
    └── analysis_report.dart
```

**基礎介面定義**:
```dart
abstract class IAudioAnalyzer {
  Future<Spectrogram> analyze(String wavFilePath);
}

abstract class INoteVerifier {
  Future<bool> verifyNote(int midiNote, double time, Spectrogram spec);
}

abstract class IPerformanceAnalyzer {
  Future<AnalysisReport> analyze(String wavPath, String midiPath);
}
```

**第1週交付物總結**:
- ✅ WAV錄音功能正常運作
- ✅ FFT套件可生成頻譜圖
- ✅ 服務架構檔案結構完成

---

### 第2週: 核心驗證算法 (Core Algorithm)

#### 任務2.1: MIDI時間軸解析 ⏱️ 1天
**擴展現有MidiParser**:
```dart
class MidiTimeline {
  final List<NoteEvent> events;
  final Map<int, List<int>> harmonics; // 預計算諧波頻率
  
  MidiTimeline.fromMidi(Uint8List midiData) {
    // 解析MIDI事件
    events = _parseNoteEvents(midiData);
    
    // 預計算每個音符的諧波頻率
    harmonics = _calculateHarmonics(events);
  }
  
  List<int> _calculateHarmonics(int midiNote) {
    double f0 = 440 * pow(2, (midiNote - 69) / 12);
    return [
      f0.round(),
      (f0 * 2).round(),
      (f0 * 3).round(),
    ];
  }
}
```

#### 任務2.2: 頻譜模板生成 ⏱️ 2-3天
**AudioAnalyzerService實現**:
```dart
class AudioAnalyzerService implements IAudioAnalyzer {
  @override
  Future<Spectrogram> analyze(String wavFilePath) async {
    // 1. 讀取WAV文件
    final wavData = await _readWavFile(wavFilePath);
    
    // 2. 執行STFT
    final frames = _performSTFT(
      wavData,
      fftSize: 2048,
      hopSize: 512,
    );
    
    // 3. 轉換為時間-頻率矩陣
    return Spectrogram(
      timeFrames: frames.length,
      freqBins: 1025, // fftSize/2 + 1
      data: frames,
      sampleRate: 44100,
    );
  }
  
  List<List<double>> _performSTFT(
    Uint8List audio, {
    required int fftSize,
    required int hopSize,
  }) {
    // 使用Hanning窗函數
    final window = _hanningWindow(fftSize);
    final fft = FFT();
    List<List<double>> result = [];
    
    for (int i = 0; i < audio.length - fftSize; i += hopSize) {
      // 提取窗口
      final frame = audio.sublist(i, i + fftSize);
      
      // 應用窗函數
      final windowed = _applyWindow(frame, window);
      
      // FFT
      final spectrum = fft.realFft(windowed);
      
      // 計算功率譜
      final magnitudes = _calculateMagnitudes(spectrum);
      result.add(magnitudes);
    }
    
    return result;
  }
}
```

#### 任務2.3: 單音符驗證函數 ⏱️ 2天
**NoteVerificationService核心**:
```dart
class NoteVerificationService implements INoteVerifier {
  static const double energyThreshold = 0.3;
  static const List<double> harmonicWeights = [1.0, 0.5, 0.25];
  
  @override
  Future<bool> verifyNote(
    int midiNote,
    double time,
    Spectrogram spec,
  ) async {
    // 1. 計算目標頻率
    final frequencies = _calculateHarmonics(midiNote);
    
    // 2. 定位時間幀
    final frameIndex = _timeToFrame(time, spec);
    if (frameIndex < 0 || frameIndex >= spec.timeFrames) {
      return false;
    }
    
    // 3. 提取頻譜切片
    final spectrum = spec.data[frameIndex];
    
    // 4. 諧波驗證
    double harmonicScore = 0.0;
    for (int i = 0; i < frequencies.length; i++) {
      final freqBin = _freqToBin(frequencies[i], spec);
      final energy = spectrum[freqBin];
      harmonicScore += harmonicWeights[i] * energy;
    }
    
    // 5. 閾值判斷
    return harmonicScore > energyThreshold;
  }
  
  List<double> _calculateHarmonics(int midiNote) {
    double f0 = 440 * pow(2, (midiNote - 69) / 12);
    return [f0, f0 * 2, f0 * 3];
  }
  
  int _freqToBin(double freq, Spectrogram spec) {
    final freqResolution = spec.sampleRate / (2 * spec.freqBins);
    return (freq / freqResolution).round();
  }
  
  int _timeToFrame(double time, Spectrogram spec) {
    final hopSize = 512;
    return (time * spec.sampleRate / hopSize).round();
  }
}
```

**第2週交付物總結**:
- ✅ 能正確解析MIDI標準答案
- ✅ 能生成完整時頻譜圖
- ✅ 能驗證單個音符是否存在
- ✅ 通過至少5個單音測試案例

---

### 第3週: 完整比對與錯誤分類 (Full Matching)

#### 任務3.1: 節奏對齊算法 ⏱️ 2天
**起音偵測 (Onset Detection)**:
```dart
class OnsetDetector {
  static List<double> detect(Uint8List wavData) {
    List<double> onsets = [];
    const int windowSize = 2048;
    double prevEnergy = 0;
    
    for (int i = 0; i < wavData.length - windowSize; i += 512) {
      // 計算當前窗口能量
      double energy = _calculateRMSEnergy(
        wavData.sublist(i, i + windowSize),
      );
      
      // 檢測能量突增
      if (energy > prevEnergy * 1.5 && energy > 0.1) {
        double time = i / 44100.0;
        onsets.add(time);
      }
      
      prevEnergy = energy;
    }
    
    return onsets;
  }
  
  static double _calculateRMSEnergy(List<int> samples) {
    double sum = 0;
    for (var sample in samples) {
      sum += sample * sample;
    }
    return sqrt(sum / samples.length);
  }
}
```

**動態時間規整 (DTW)**:
```dart
class TempoAligner {
  AlignmentResult align(
    List<double> midiTimes,
    List<double> userOnsets,
  ) {
    // 簡化版DTW: 找到最佳時間偏移
    double bestOffset = 0;
    double minError = double.infinity;
    
    // 嘗試不同偏移量
    for (double offset = -1.0; offset <= 1.0; offset += 0.01) {
      double error = _calculateAlignmentError(
        midiTimes,
        userOnsets,
        offset,
      );
      
      if (error < minError) {
        minError = error;
        bestOffset = offset;
      }
    }
    
    return AlignmentResult(
      timeOffset: bestOffset,
      alignmentError: minError,
    );
  }
}
```

#### 任務3.2: 錯誤分類邏輯 ⏱️ 2天
**ErrorClassificationService**:
```dart
class ErrorClassificationService {
  List<PerformanceError> classify(
    MidiTimeline standard,
    Map<NoteEvent, bool> verificationResults,
    AlignmentResult alignment,
  ) {
    List<PerformanceError> errors = [];
    
    for (var noteEvent in standard.events) {
      final verified = verificationResults[noteEvent] ?? false;
      final adjustedTime = noteEvent.startTime + alignment.timeOffset;
      
      if (!verified) {
        // 漏音
        errors.add(PerformanceError(
          type: ErrorType.missedNote,
          expectedNote: noteEvent.midiNote,
          expectedTime: noteEvent.startTime,
          message: '漏彈了音符 ${_noteToString(noteEvent.midiNote)}',
        ));
      } else {
        // 檢查節奏
        final timingError = _calculateTimingError(
          expected: noteEvent.startTime,
          actual: adjustedTime,
        );
        
        if (timingError.abs() > 0.1) {
          errors.add(PerformanceError(
            type: timingError > 0 
              ? ErrorType.lateTiming 
              : ErrorType.earlyTiming,
            expectedNote: noteEvent.midiNote,
            expectedTime: noteEvent.startTime,
            actualTime: adjustedTime,
            timingOffset: timingError,
            message: timingError > 0 
              ? '拖拍 ${(timingError * 1000).toInt()}ms'
              : '搶拍 ${(-timingError * 1000).toInt()}ms',
          ));
        }
      }
    }
    
    return errors;
  }
  
  String _noteToString(int midiNote) {
    const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 
                   'F#', 'G', 'G#', 'A', 'A#', 'B'];
    int octave = (midiNote ~/ 12) - 1;
    String noteName = notes[midiNote % 12];
    return '$noteName$octave';
  }
}
```

#### 任務3.3: 整合測試 ⏱️ 1天
**測試案例準備**:
```dart
void runIntegrationTests() async {
  // 測試案例1: 完美演奏
  await testCase('perfect_performance.wav', expectedAccuracy: 1.0);
  
  // 測試案例2: 一個錯音
  await testCase('one_wrong_note.wav', expectedWrongNotes: 1);
  
  // 測試案例3: 兩個漏音
  await testCase('two_missed_notes.wav', expectedMissedNotes: 2);
  
  // 測試案例4: 節奏問題
  await testCase('timing_issues.wav', expectedTimingErrors: 3);
  
  // 測試案例5: 和弦演奏
  await testCase('chord_performance.wav', hasChords: true);
}
```

**準確率目標**: >80%

**第3週交付物總結**:
- ✅ 完整的比對流程可運行
- ✅ 能正確分類5種錯誤類型
- ✅ 測試案例準確率達標 (>80%)
- ✅ 和弦(多音)偵測正常運作

---

### 第4週: UI整合與優化 (Integration & Polish)

#### 任務4.1: 報告生成器 ⏱️ 2天
**AnalysisReport Model**:
```dart
class AnalysisReport {
  final int totalNotes;
  final int correctNotes;
  final int wrongNotes;
  final int missedNotes;
  final int earlyNotes;
  final int lateNotes;
  
  final double accuracy;        // 音準正確率
  final double rhythmScore;     // 節奏分數
  final double overallScore;    // 總分
  
  final List<PerformanceError> errors;
  final Duration processingTime;
  
  // 統計圖表數據
  Map<String, int> get errorDistribution => {
    '正確': correctNotes,
    '錯音': wrongNotes,
    '漏音': missedNotes,
    '搶拍': earlyNotes,
    '拖拍': lateNotes,
  };
  
  String get grade {
    if (overallScore >= 90) return 'A';
    if (overallScore >= 80) return 'B';
    if (overallScore >= 70) return 'C';
    if (overallScore >= 60) return 'D';
    return 'F';
  }
  
  String generateTextReport() {
    return '''
=== 演奏分析報告 ===
總音符數: $totalNotes
正確: $correctNotes (${(accuracy * 100).toStringAsFixed(1)}%)
錯音: $wrongNotes
漏音: $missedNotes
節奏問題: ${earlyNotes + lateNotes}

音準分數: ${(accuracy * 100).toStringAsFixed(1)}
節奏分數: ${rhythmScore.toStringAsFixed(1)}
總評分數: ${overallScore.toStringAsFixed(1)} ($grade)

處理時間: ${processingTime.inMilliseconds}ms
''';
  }
}
```

#### 任務4.2: 視覺化呈現 ⏱️ 2天
**AnalysisResultPage UI**:
```dart
class AnalysisResultPage extends StatelessWidget {
  final AnalysisReport report;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('演奏分析報告')),
      body: ListView(
        children: [
          // 總分卡片
          _buildScoreCard(),
          
          // 統計圖表
          _buildPieChart(),  // 正確/錯誤分布
          
          // 時間軸視圖
          _buildTimelineView(),  // 標記錯誤位置
          
          // 錯誤列表
          _buildErrorList(),
          
          // 建議區塊
          _buildSuggestions(),
        ],
      ),
    );
  }
  
  Widget _buildErrorList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: report.errors.length,
      itemBuilder: (context, index) {
        final error = report.errors[index];
        return ListTile(
          leading: _getErrorIcon(error.type),
          title: Text(error.message),
          subtitle: Text(
            '位置: ${error.expectedTime.toStringAsFixed(2)}s',
          ),
          tileColor: _getErrorColor(error.type).withOpacity(0.1),
        );
      },
    );
  }
  
  Icon _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.wrongNote:
        return Icon(Icons.clear, color: Colors.red);
      case ErrorType.missedNote:
        return Icon(Icons.warning, color: Colors.orange);
      case ErrorType.earlyTiming:
        return Icon(Icons.fast_forward, color: Colors.blue);
      case ErrorType.lateTiming:
        return Icon(Icons.slow_motion_video, color: Colors.purple);
      default:
        return Icon(Icons.check, color: Colors.green);
    }
  }
}
```

#### 任務4.3: 效能優化 ⏱️ 1天
**異步處理**:
```dart
class PerformanceAnalysisService {
  Future<AnalysisReport> analyze(
    String wavPath,
    String midiPath, {
    void Function(double progress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    // Step 1: 解析MIDI (10%)
    onProgress?.call(0.1);
    final midiTimeline = await _parseMidi(midiPath);
    
    // Step 2: 生成頻譜 (40%)
    onProgress?.call(0.4);
    final spectrogram = await _analyzeAudio(wavPath);
    
    // Step 3: 驗證音符 (70%)
    onProgress?.call(0.7);
    final verifications = await _verifyAllNotes(
      midiTimeline,
      spectrogram,
    );
    
    // Step 4: 分類錯誤 (90%)
    onProgress?.call(0.9);
    final errors = await _classifyErrors(
      midiTimeline,
      verifications,
    );
    
    // Step 5: 生成報告 (100%)
    onProgress?.call(1.0);
    stopwatch.stop();
    
    return AnalysisReport(
      errors: errors,
      processingTime: stopwatch.elapsed,
      // ... 其他統計數據
    );
  }
}
```

**第4週交付物總結**:
- ✅ 完整的分析報告頁面
- ✅ 視覺化錯誤標記與統計圖表
- ✅ 流暢的使用體驗 (進度條,異步處理)
- ✅ 效能優化完成 (1分鐘音頻<3秒處理)

---

## 🎯 成功指標

### 功能性指標
- ✅ **準確率**: 音符驗證準確率 >80%
- ✅ **多音支援**: 能正確處理2-4音和弦
- ✅ **節奏偵測**: 時間誤差 <100ms視為正確
- ✅ **錯誤分類**: 能區分5種錯誤類型

### 性能指標
- ✅ **處理速度**: 1分鐘音頻 <5秒分析時間
- ✅ **記憶體使用**: <200MB峰值
- ✅ **離線運作**: 不需要網路連接

### 使用者體驗
- ✅ **即時反饋**: 顯示分析進度
- ✅ **清晰報告**: 視覺化錯誤標記
- ✅ **可操作性**: 提供改進建議

---

## 🚨 風險管理

### 技術風險

| 風險項目 | 可能性 | 影響 | 應對策略 |
|---------|--------|------|---------|
| FFT套件性能不足 | 中 | 高 | 測試多個套件,必要時使用原生代碼 |
| 諧波驗證誤判 | 中 | 中 | 調整閾值參數,引入機器學習模型 |
| WAV文件過大 | 低 | 低 | 限制錄音長度,提示壓縮選項 |
| 多音偵測準確度低 | 中 | 高 | 啟用YIN備用方案輔助 |

### 時程風險

**緩衝策略**:
- 每週預留1天緩衝時間
- 優先實現核心功能,裝飾性功能可延後
- 如第2週超時,可暫緩起音偵測功能

**決策點**:
- **第1週結束**: FFT測試未通過 → 切換至備用方案
- **第2週結束**: 準確率<60% → 重新評估算法參數
- **第3週結束**: 整合失敗 → 降級至單音驗證版本

---

## 📚 技術參考資料

### 學術資源
- 📄 **STFT基礎**: [Understanding the Short-Time Fourier Transform](https://en.wikipedia.org/wiki/Short-time_Fourier_transform)
- 📄 **音高偵測**: [A Smarter Way to Find Pitch - McLeod Pitch Method](https://www.cs.otago.ac.nz/tartini/papers/A_Smarter_Way_to_Find_Pitch.pdf)
- 📄 **起音偵測**: [Onset Detection Revisited](http://www.eecs.qmul.ac.uk/~simond/pub/2006/dafx.pdf)

### 開源專案
- 🔗 **Basic Pitch**: [spotify/basic-pitch](https://github.com/spotify/basic-pitch)
- 🔗 **Pitch Detection**: [sevagh/pitch-detection](https://github.com/sevagh/pitch-detection)
- 🔗 **Aubio**: [aubio/aubio](https://github.com/aubio/aubio) (C庫,可參考算法)

### Flutter套件
- 📦 **fft**: [pub.dev/packages/fft](https://pub.dev/packages/fft)
- 📦 **pitch_detector_dart**: [pub.dev/packages/pitch_detector_dart](https://pub.dev/packages/pitch_detector_dart)
- 📦 **record**: [pub.dev/packages/record](https://pub.dev/packages/record)

---

## 📝 決策歷程記錄

### 2025-10-06: 多方諮詢階段
- **諮詢對象**: Claude, Gemini, ChatGPT
- **核心問題**: Basic Pitch產生隨機音符,準確度極低
- **關鍵發現**: 
  - 問題根源是「盲目轉譯」而非「目標驗證」
  - TFLite版本缺乏Python實現的完整後處理
  - 分塊處理破壞了模型需要的時間上下文
- **一致結論**: 頻譜模板驗證是最佳解決方案

### 2025-10-06: 最終決策
- **主設計師**: Claude (綜合分析)
- **採用方案**: 分層式頻譜驗證引擎
- **理由**: 
  1. 融合三方優勢 (Gemini架構 + ChatGPT算法 + Claude穩定性)
  2. 準確度最高 (諧波驗證 + 目標導向)
  3. 完全可控 (無黑盒子依賴)
  4. 可漸進實現 (4週分階段開發)

---

## ✅ 批准簽核

- [x] 技術方案已審核
- [x] 時程規劃已確認
- [x] 風險應對已備妥
- [x] 備用方案已準備

**批准日期**: 2025年10月6日  
**執行狀態**: 🟢 準備開始實施  
**預計完成**: 2025年11月3日 (4週後)

---

## 🔄 版本歷史

| 版本 | 日期 | 變更內容 | 備註 |
|------|------|---------|------|
| v1.0 | 2025-10-06 | 初始決策文檔 | 三方AI諮詢結果整合 |

---

**文檔維護者**: 開發團隊  
**下次審查日期**: 每週五進行進度審查  
**相關文檔**: `AI_WORK_LOG.md` (詳細工作記錄)

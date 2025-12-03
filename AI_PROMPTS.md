# 音樂練習 App - AI 提示詞集合

這是針對「音樂練習 App (Music Practice App)」開發的 AI 提示詞集合。

分為「圖像素材生成」與「Flutter 程式開發」兩大類。

---

## 1. 圖像生成提示詞 (Image Generation Prompts)

**適用於:** Midjourney, DALL-E 3, Stable Diffusion

**目標:** 生成 App 中的 Icon、背景或 UI 素材

### A. 生成步驟指示器圖標 (Step Indicator Icons)

```
Prompt: "Set of 3 minimalist icons for music practice app: 
1) Settings gear icon, 
2) Speed/metronome icon with motion lines, 
3) Trophy/achievement icon. 
Flat design, rounded style, teal and white color scheme (#81C7D4), 
transparent background, high quality vector, suitable for mobile UI."
```

**中文釋義:** 
一組 3 個極簡圖標用於音樂練習 App：1) 設定齒輪圖標，2) 速度/節拍器圖標帶動態線條，3) 獎盃/成就圖標。扁平設計，圓潤風格，青藍與白色配色，透明背景，高品質向量圖，適合手機 UI。

### B. 生成 BPM 圓環進度指示器 (Circular BPM Progress Ring)

```
Prompt: "Circular progress ring UI element for music tempo display. 
Dark navy blue (#1E293B) ring on light background, 
clean minimal design, showing 65% progress, 
large BPM number in center, 
modern app interface style, high fidelity mockup."
```

**中文釋義:**
圓形進度環 UI 元素用於顯示音樂速度。深海軍藍色環在淺色背景上，乾淨極簡設計，顯示 65% 進度，中央有大的 BPM 數字，現代 App 介面風格，高保真模型。

### C. 生成連續成功指示燈 (Success Streak Lights)

```
Prompt: "Set of 3 small circular indicator lights for game UI, 
soft green (#66BB6A) when active with subtle glow effect, 
transparent when inactive with white border, 
minimal design, suitable for mobile game interface."
```

**中文釋義:**
一組 3 個小圓形指示燈用於遊戲 UI，啟動時為柔和綠色帶微光效果，未啟動時透明帶白色邊框，極簡設計，適合手機遊戲介面。

### D. App 整體 UI 設計靈感

```
Prompt: "Mobile app UI design for music practice tracker, 
pastel teal background (#BDE0E6), 
central circular BPM display with dark ring progress indicator, 
3 success indicator lights below, 
two large action buttons (red 'fail' and green 'success'), 
clean modern layout, gamification elements, professional music app aesthetic."
```

**中文釋義:**
音樂練習追蹤手機 App UI 設計，粉藍綠背景，中央圓形 BPM 顯示帶深色環形進度指示器，下方 3 個成功指示燈，兩個大動作按鈕（紅色「失敗」與綠色「成功」），乾淨現代排版，遊戲化元素，專業音樂 App 美學。

---

## 2. Flutter 程式開發提示詞 (Coding Prompts)

**適用於:** ChatGPT, Claude, Gemini, GitHub Copilot

**目標:** 生成類似功能的 Flutter 程式碼或優化現有代碼

### A. 生成動態速度級距系統 (Dynamic Speed Steps Generator)

```dart
Prompt: "Create a Flutter function that generates dynamic speed progression steps for music practice.

Requirements:
- Input: initial speed percentage (30-80%) and target BPM
- Output: List of speed percentages from initial to 100%
- Step increment: always 5%
- Ensure the last step is always 100%
- Return List<int> of percentage values

Example: if initial is 40%, return [40, 45, 50, 55, ..., 95, 100]"
```

### B. 生成 CustomPainter 圓環進度指示器

```dart
Prompt: "Write a Flutter CustomPainter class that draws a circular progress ring.

Requirements:
- Draw a background track (light color with opacity)
- Draw progress arc based on progress value (0.0 to 1.0)
- Use strokeWidth of 12 pixels
- Start angle at -90 degrees (top of circle)
- Use strokeCap: StrokeCap.round for rounded ends
- Provide smooth animation support
- Accept trackColor and progressColor as parameters"
```

### C. 生成連續成功計數邏輯 (Consecutive Success Tracking)

```dart
Prompt: "Create Flutter state management logic for a 'consecutive success' mechanism in a practice app.

Rules:
- User needs 3 consecutive successes to advance to next speed level
- Two actions: recordSuccess() and recordFailure()
- recordSuccess() increments consecutiveSuccessCount
- When count reaches 3, trigger advancement with 500ms delay (to show 3rd light)
- recordFailure() resets count to 0
- Update UI immediately but delay advancement for visual feedback
- Use setState() for state management"
```

### D. 生成步驟指示器 UI 組件

```dart
Prompt: "Build a Flutter widget for a horizontal step indicator with 3 steps.

Requirements:
- Display icons and labels for each step
- Highlight active step with colored background (#81C7D4)
- Inactive steps have semi-transparent white background
- Arrow icons between steps
- Responsive sizing (52x52 icon containers, 26px icons, 13pt labels)
- Use Row with MainAxisAlignment.spaceBetween
- Add shadow to active step only
- Make it reusable with step data passed as parameters"
```

### E. 生成動作按鈕與波紋效果

```dart
Prompt: "Create a Flutter custom action button widget for gamified interactions.

Features:
- Custom height (80px), rounded corners (20px radius)
- Icon in white circle container at top
- Label text below icon
- Accept color, backgroundColor, icon, label, and onTap callback
- Use GestureDetector for tap handling
- Apply InkWell or similar for ripple effect on tap
- Support different colors for success (green) and failure (red) variants"
```

### F. 優化 - 防止重複動畫觸發

```dart
Prompt: "I have a Flutter app where clicking 'Success' 3 times should:
1. Show the 3rd success light illuminated
2. Wait 500ms
3. Then advance to next level and reset lights to 0

Problem: The lights reset immediately, users don't see the 3rd light.

Current code uses Future.delayed inside setState().

How should I structure this to:
- Update UI immediately (show 3rd light)
- Save state to service
- Wait 500ms
- Then trigger advancement

Provide best practice Flutter code."
```

### G. 生成 SharedPreferences 數據持久化

```dart
Prompt: "Create a Flutter service class for persisting practice task data using SharedPreferences.

Requirements:
- Model class: SlowPracticeTask with fields (id, targetBpm, currentBpm, initialSpeedPercent, currentStep, consecutiveSuccessCount, etc.)
- Implement toJson() and fromJson() methods
- Service methods: saveTask(), loadTask(), updateTask(), deleteTask()
- Store as JSON string in SharedPreferences
- Handle null cases gracefully
- Support list of tasks (save/load multiple tasks)
- Use async/await pattern"
```

---

## 3. UI/UX 優化提示詞

### A. 解決垂直置中問題

```
Prompt: "In Flutter, I have a Column inside SingleChildScrollView. 
The content should be vertically centered when it doesn't fill the screen, 
but still scrollable when content overflows. 
How do I achieve this? Provide code with ConstrainedBox or similar solution."
```

### B. 字體大小最佳化

```
Prompt: "My Flutter app has multiple text elements (titles, body text, BPM display, labels). 
Suggest optimal font sizes for:
- Page title
- Step title  
- Large numeric display (BPM value)
- Body text
- Button labels
- Small helper text

Consider mobile readability and Material Design guidelines."
```

### C. 間距與排版優化

```
Prompt: "Review this Flutter layout structure and suggest spacing improvements:
- Header to content spacing
- Between different sections
- Around buttons
- Step indicator to bottom edge
- Content to screen edges (horizontal padding)

Goal: Balanced, breathable layout without manual scrolling for main content."
```

---

## 使用建議

### 對於圖像生成:
1. 根據需要調整顏色代碼以匹配您的主題
2. 可添加 `--ar 1:1` (Midjourney) 或指定尺寸以獲得正方形圖標
3. 使用 `--style raw` 獲得更真實的渲染

### 對於程式開發:
1. 將提示詞複製到您的 AI 助手
2. 根據返回的代碼調整以匹配您的專案結構
3. 測試並迭代優化
4. 結合多個提示詞構建完整功能

---

## 專案技術棧

- **框架:** Flutter
- **狀態管理:** StatefulWidget + setState()
- **數據持久化:** SharedPreferences
- **UI 風格:** Material Design with custom colors
- **主題色:** 
  - 背景: `#BDE0E6`
  - 主色調: `#56A0AD`, `#81C7D4`
  - 深色: `#37474F`, `#1E293B`
  - 成功: `#66BB6A`, `#558B2F`
  - 失敗: `#C62828`, `#FFCDD2`

---

**最後更新:** 2025年12月2日

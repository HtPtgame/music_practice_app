# 🧪 執行所有測試案例
# 音樂練習 App - 階段 2.3 完整測試套件

Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       🎼 階段 2.3: 完整測試套件                           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 檢查測試檔案是否存在
$testFiles = @(
    "assets\test_voice\測試音檔(midi轉檔).wav",
    "assets\test_voice\測試音檔(環境).wav",
    "assets\test_voice\小星星(環境).wav",
    "assets\test_voice\環境背景.wav"
)

Write-Host "📂 檢查測試檔案..." -ForegroundColor Yellow
$allFilesExist = $true
foreach ($file in $testFiles) {
    if (Test-Path $file) {
        Write-Host "   ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "   ❌ 找不到: $file" -ForegroundColor Red
        $allFilesExist = $false
    }
}
Write-Host ""

if (-not $allFilesExist) {
    Write-Host "❌ 部分測試檔案不存在,請檢查 assets/test_voice/ 資料夾" -ForegroundColor Red
    exit 1
}

# 測試結果記錄
$results = @()

# 執行測試案例 1: MIDI轉檔基準測試
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🧪 測試案例 1: MIDI轉檔基準測試" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""
dart test_week3.dart 1
$test1Result = $LASTEXITCODE
Write-Host ""
Start-Sleep -Seconds 2

# 執行測試案例 2: 真實環境測試
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🧪 測試案例 2: 真實環境錄製測試" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""
dart test_week3.dart 2
$test2Result = $LASTEXITCODE
Write-Host ""
Start-Sleep -Seconds 2

# 執行測試案例 3: 小星星測試
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🧪 測試案例 3: 小星星實際演奏測試" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""
dart test_week3.dart 3
$test3Result = $LASTEXITCODE
Write-Host ""
Start-Sleep -Seconds 2

# 執行測試案例 4: 背景噪音測試
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🧪 測試案例 4: 背景噪音抑制測試" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""
dart test_week3.dart 4
$test4Result = $LASTEXITCODE
Write-Host ""
Start-Sleep -Seconds 2

# 總結報告
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                     📊 測試總結                           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$passCount = 0
$totalTests = 4

Write-Host "測試結果:" -ForegroundColor Yellow
Write-Host ""

if ($test1Result -eq 0) {
    Write-Host "   ✅ 案例 1: MIDI轉檔基準測試 - PASS" -ForegroundColor Green
    $passCount++
} else {
    Write-Host "   ❌ 案例 1: MIDI轉檔基準測試 - FAIL" -ForegroundColor Red
}

if ($test2Result -eq 0) {
    Write-Host "   ✅ 案例 2: 真實環境測試 - PASS" -ForegroundColor Green
    $passCount++
} else {
    Write-Host "   ❌ 案例 2: 真實環境測試 - FAIL" -ForegroundColor Red
}

if ($test3Result -eq 0) {
    Write-Host "   ✅ 案例 3: 小星星測試 - PASS" -ForegroundColor Green
    $passCount++
} else {
    Write-Host "   ❌ 案例 3: 小星星測試 - FAIL" -ForegroundColor Red
}

if ($test4Result -eq 0) {
    Write-Host "   ✅ 案例 4: 背景噪音測試 - PASS" -ForegroundColor Green
    $passCount++
} else {
    Write-Host "   ❌ 案例 4: 背景噪音測試 - FAIL" -ForegroundColor Red
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "通過率: $passCount/$totalTests ($([math]::Round($passCount/$totalTests*100, 1))%)" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

if ($passCount -eq $totalTests) {
    Write-Host "🎉 恭喜!所有測試通過!" -ForegroundColor Green
    exit 0
} elseif ($passCount -ge $totalTests * 0.75) {
    Write-Host "👍 大部分測試通過,請檢查失敗的項目" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "⚠️  多個測試失敗,請檢查系統配置" -ForegroundColor Red
    exit 1
}

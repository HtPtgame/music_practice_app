# Week 3 測試輔助腳本
# 幫助您找到錄音文件並複製到正確位置

Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       🎵 Week 3 測試輔助工具                            ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 項目根目錄
$projectRoot = "D:\Flutter_project\music_practice_app"
$targetWav = Join-Path $projectRoot "performance.wav"

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "步驟 1: 檢查 MIDI 文件" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

$midiPath = Join-Path $projectRoot "assets\測試.mid"
if (Test-Path $midiPath) {
    $midiSize = (Get-Item $midiPath).Length / 1KB
    Write-Host "   ✅ MIDI 文件已就緒" -ForegroundColor Green
    Write-Host "      路徑: $midiPath" -ForegroundColor Gray
    Write-Host "      大小: $($midiSize.ToString('0.00')) KB" -ForegroundColor Gray
} else {
    Write-Host "   ❌ 找不到 MIDI 文件: $midiPath" -ForegroundColor Red
    Write-Host "      請確認文件存在!" -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "步驟 2: 搜索錄音文件" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# 可能的錄音文件位置
$possiblePaths = @(
    "$env:LOCALAPPDATA\music_practice_app\practice_record_alt.wav",
    "$env:LOCALAPPDATA\music_practice_app\practice_record.wav",
    "$env:TEMP\practice_record.wav",
    "$env:TEMP\practice_record_alt.wav",
    "$projectRoot\performance.wav"
)

Write-Host "   🔍 搜索常見位置..." -ForegroundColor Cyan
$foundFiles = @()

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $fileInfo = Get-Item $path
        $foundFiles += $fileInfo
        $sizeMB = $fileInfo.Length / 1MB
        $modified = $fileInfo.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        
        Write-Host "   ✅ 找到: $($fileInfo.Name)" -ForegroundColor Green
        Write-Host "      路徑: $($fileInfo.FullName)" -ForegroundColor Gray
        Write-Host "      大小: $($sizeMB.ToString('0.00')) MB" -ForegroundColor Gray
        Write-Host "      修改時間: $modified" -ForegroundColor Gray
        Write-Host ""
    }
}

if ($foundFiles.Count -eq 0) {
    Write-Host "   ⚠️  在常見位置沒有找到錄音文件" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   🔍 進行深度搜索 (可能需要幾分鐘)..." -ForegroundColor Cyan
    
    $searchResults = Get-ChildItem -Path $env:LOCALAPPDATA -Filter "practice_record*.wav" -Recurse -ErrorAction SilentlyContinue
    
    if ($searchResults) {
        foreach ($file in $searchResults) {
            $sizeMB = $file.Length / 1MB
            $modified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            
            Write-Host "   ✅ 找到: $($file.Name)" -ForegroundColor Green
            Write-Host "      路徑: $($file.FullName)" -ForegroundColor Gray
            Write-Host "      大小: $($sizeMB.ToString('0.00')) MB" -ForegroundColor Gray
            Write-Host "      修改時間: $modified" -ForegroundColor Gray
            $foundFiles += $file
            Write-Host ""
        }
    } else {
        Write-Host ""
        Write-Host "   ❌ 沒有找到任何錄音文件" -ForegroundColor Red
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        Write-Host "💡 下一步建議:" -ForegroundColor Yellow
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        Write-Host ""
        Write-Host "   1. 使用 App 錄製一個新的演奏:" -ForegroundColor White
        Write-Host "      flutter run -d windows" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   2. 或使用外部軟體 (Audacity) 錄製" -ForegroundColor White
        Write-Host "      - 採樣率: 44100 Hz" -ForegroundColor Gray
        Write-Host "      - 格式: WAV, 16-bit, Mono" -ForegroundColor Gray
        Write-Host "      - 保存為: $targetWav" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   3. 詳細指南請查看: TESTING_GUIDE_WEEK3.md" -ForegroundColor White
        Write-Host ""
        exit
    }
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "步驟 3: 選擇並複製文件" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

if ($foundFiles.Count -eq 1) {
    $selectedFile = $foundFiles[0]
    Write-Host "   📝 自動選擇唯一的錄音文件" -ForegroundColor Cyan
} else {
    Write-Host "   📝 找到多個錄音文件,請選擇:" -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $foundFiles.Count; $i++) {
        $file = $foundFiles[$i]
        $sizeMB = $file.Length / 1MB
        $modified = $file.LastWriteTime.ToString("MM-dd HH:mm")
        Write-Host "      [$($i+1)] $($file.Name) ($($sizeMB.ToString('0.00'))MB, $modified)" -ForegroundColor White
    }
    Write-Host ""
    
    do {
        $choice = Read-Host "   請輸入編號 (1-$($foundFiles.Count))"
        $choiceNum = [int]$choice - 1
    } while ($choiceNum -lt 0 -or $choiceNum -ge $foundFiles.Count)
    
    $selectedFile = $foundFiles[$choiceNum]
}

Write-Host ""
Write-Host "   選擇的文件: $($selectedFile.Name)" -ForegroundColor Green
Write-Host "   來源: $($selectedFile.FullName)" -ForegroundColor Gray
Write-Host "   目標: $targetWav" -ForegroundColor Gray
Write-Host ""

# 複製文件
try {
    Copy-Item -Path $selectedFile.FullName -Destination $targetWav -Force
    Write-Host "   ✅ 文件複製成功!" -ForegroundColor Green
    
    # 驗證
    $copiedFile = Get-Item $targetWav
    $sizeMB = $copiedFile.Length / 1MB
    Write-Host "   📊 已複製文件大小: $($sizeMB.ToString('0.00')) MB" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "✅ 準備就緒!" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host ""
    Write-Host "   現在可以運行測試:" -ForegroundColor White
    Write-Host ""
    Write-Host "   dart test_week3.dart" -ForegroundColor Cyan
    Write-Host ""
    
} catch {
    Write-Host "   ❌ 複製失敗: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "   請手動複製文件:" -ForegroundColor Yellow
    Write-Host "   來源: $($selectedFile.FullName)" -ForegroundColor Gray
    Write-Host "   目標: $targetWav" -ForegroundColor Gray
}

Write-Host ""
Write-Host "按任意鍵退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

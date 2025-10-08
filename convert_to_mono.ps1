# WAV 立體聲轉單聲道腳本
# 使用 NAudio.Wave (純 PowerShell,無需外部工具)

param(
    [string]$InputFile = "$env:USERPROFILE\Desktop\名偵探柯南 Detective Conan OP.wav",
    [string]$OutputFile = "$env:USERPROFILE\Desktop\名偵探柯南 Detective Conan OP_mono.wav"
)

Write-Host "🔧 WAV 聲道轉換工具" -ForegroundColor Cyan
Write-Host "═" * 70
Write-Host "輸入: $InputFile" -ForegroundColor Yellow
Write-Host "輸出: $OutputFile" -ForegroundColor Green
Write-Host ""

# 檢查輸入檔案
if (-not (Test-Path $InputFile)) {
    Write-Host "❌ 錯誤: 找不到輸入檔案!" -ForegroundColor Red
    exit 1
}

# 讀取 WAV 檔案頭 (44 bytes)
$bytes = [System.IO.File]::ReadAllBytes($InputFile)
$header = $bytes[0..43]

# 解析 WAV 格式
$channels = [BitConverter]::ToInt16($header, 22)
$sampleRate = [BitConverter]::ToInt32($header, 24)
$bitsPerSample = [BitConverter]::ToInt16($header, 34)

Write-Host "📊 原始格式:" -ForegroundColor Cyan
Write-Host "  聲道數: $channels"
Write-Host "  取樣率: $sampleRate Hz"
Write-Host "  位元深度: $bitsPerSample bits"
Write-Host ""

if ($channels -eq 1) {
    Write-Host "✅ 已經是單聲道,無需轉換!" -ForegroundColor Green
    exit 0
}

Write-Host "🔄 開始轉換 (立體聲 → 單聲道)..." -ForegroundColor Yellow

# 計算資料大小
$dataSize = $bytes.Length - 44
$samplesPerChannel = $dataSize / ($channels * ($bitsPerSample / 8))
$newDataSize = [int]($samplesPerChannel * ($bitsPerSample / 8))

# 創建新的 WAV 頭 (單聲道)
$newHeader = $header.Clone()
[BitConverter]::GetBytes([Int16]1).CopyTo($newHeader, 22)  # 聲道數 = 1
$byteRate = $sampleRate * 1 * ($bitsPerSample / 8)
[BitConverter]::GetBytes([Int32]$byteRate).CopyTo($newHeader, 28)  # ByteRate
$blockAlign = 1 * ($bitsPerSample / 8)
[BitConverter]::GetBytes([Int16]$blockAlign).CopyTo($newHeader, 32)  # BlockAlign
[BitConverter]::GetBytes([Int32]$newDataSize).CopyTo($newHeader, 40)  # Subchunk2Size
[BitConverter]::GetBytes([Int32]($newDataSize + 36)).CopyTo($newHeader, 4)  # ChunkSize

# 混音: 將雙聲道平均為單聲道
$newData = New-Object byte[] $newDataSize
$bytesPerSample = $bitsPerSample / 8

Write-Host "  處理樣本: 0 / $samplesPerChannel" -NoNewline

for ($i = 0; $i -lt $samplesPerChannel; $i++) {
    # 顯示進度
    if ($i % 10000 -eq 0) {
        $progress = [int](($i / $samplesPerChannel) * 100)
        Write-Host "`r  處理樣本: $i / $samplesPerChannel ($progress%)" -NoNewline
    }
    
    $srcOffset = 44 + ($i * $channels * $bytesPerSample)
    $dstOffset = $i * $bytesPerSample
    
    if ($bitsPerSample -eq 16) {
        # 16-bit PCM: 讀取左右聲道,平均後寫入
        $left = [BitConverter]::ToInt16($bytes, $srcOffset)
        $right = [BitConverter]::ToInt16($bytes, $srcOffset + 2)
        $mono = [int16](($left + $right) / 2)
        [BitConverter]::GetBytes($mono).CopyTo($newData, $dstOffset)
    }
    elseif ($bitsPerSample -eq 8) {
        # 8-bit PCM
        $left = $bytes[$srcOffset]
        $right = $bytes[$srcOffset + 1]
        $newData[$dstOffset] = [byte](($left + $right) / 2)
    }
}

Write-Host "`r  處理樣本: $samplesPerChannel / $samplesPerChannel (100%)" 
Write-Host ""

# 寫入輸出檔案
Write-Host "💾 寫入檔案..." -ForegroundColor Yellow
$output = $newHeader + $newData
[System.IO.File]::WriteAllBytes($OutputFile, $output)

# 顯示結果
$outputSize = (Get-Item $OutputFile).Length
Write-Host ""
Write-Host "✅ 轉換完成!" -ForegroundColor Green
Write-Host "═" * 70
Write-Host "輸出檔案: $OutputFile" -ForegroundColor Cyan
Write-Host "檔案大小: $([math]::Round($outputSize/1MB, 2)) MB" -ForegroundColor Yellow
Write-Host "聲道數: 1 (單聲道)" -ForegroundColor Green
Write-Host ""

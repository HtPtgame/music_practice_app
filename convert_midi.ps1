# MIDI 轉 WAV 腳本 (使用 FluidSynth)
# 使用方法: .\convert_midi.ps1

Write-Host "🎵 MIDI 轉 WAV 轉換器" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════" -ForegroundColor Blue

# 檢查 Chocolatey
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "❌ 需要先安裝 Chocolatey" -ForegroundColor Red
    Write-Host "請以管理員身份執行安裝命令 (見先前說明)" -ForegroundColor Yellow
    exit 1
}

# 安裝 FluidSynth
Write-Host "`n📦 安裝 FluidSynth..." -ForegroundColor Cyan
choco install fluidsynth -y

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ FluidSynth 安裝失敗" -ForegroundColor Red
    exit 1
}

# 檢查 SoundFont
$soundFont = "assets\TimGM6mb.sf2"
if (-not (Test-Path $soundFont)) {
    Write-Host "❌ 找不到 SoundFont: $soundFont" -ForegroundColor Red
    Write-Host "請確保 TimGM6mb.sf2 存在於 assets 目錄" -ForegroundColor Yellow
    exit 1
}

# 轉換 MIDI
$midiFile = "assets\測試.mid"
$outputFile = "performance_fluidsynth.wav"

Write-Host "`n🔄 轉換 MIDI 到 WAV..." -ForegroundColor Cyan
fluidsynth -ni $soundFont $midiFile -F $outputFile -r 44100

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ 轉換成功!" -ForegroundColor Green
    Write-Host "輸出檔案: $outputFile" -ForegroundColor Yellow
    
    # 轉換為單聲道
    Write-Host "`n🔄 轉換為單聲道..." -ForegroundColor Cyan
    $ffmpegExe = "C:\Users\Perry\ffmpeg\ffmpeg-master-latest-win64-gpl\bin\ffmpeg.exe"
    & $ffmpegExe -i $outputFile -ac 1 performance.wav -y
    
    if ($LASTEXITCODE -eq 0) {
        Remove-Item $outputFile
        Write-Host "✅ 完成! 已儲存為 performance.wav" -ForegroundColor Green
    }
} else {
    Write-Host "❌ 轉換失敗" -ForegroundColor Red
    exit 1
}

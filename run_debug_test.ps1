# 偵錯系統準確度測試腳本
# 使用方式: .\run_debug_test.ps1 [模式]
# 模式: 0=全部, 1=第一輪, 2=第二輪, 3=第三輪, 4=第四輪

param(
    [Parameter(Position=0)]
    [ValidateRange(0,4)]
    [int]$Mode = 0
)

$modeName = switch ($Mode) {
    0 { "全部測試" }
    1 { "第一輪（生日快樂）" }
    2 { "第二輪（測試音檔）" }
    3 { "第三輪（小星星）" }
    4 { "第四輪（名偵探柯南）" }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎯 偵錯系統準確度測試" -ForegroundColor Cyan
Write-Host "   模式: $modeName ($Mode)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 設定環境變數並執行測試
$env:TEST_MODE = $Mode
flutter test test/integration/debug_accuracy_test.dart

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✅ 測試完成！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "❌ 測試失敗！" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    exit 1
}

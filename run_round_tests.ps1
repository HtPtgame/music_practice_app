# Round 11 動態參數測試執行腳本
# 使用方式: .\run_round_tests.ps1 [round_number]
# 範例: .\run_round_tests.ps1 1  (執行第1輪)
#       .\run_round_tests.ps1     (執行全部4輪)

param(
    [int]$Round = 0  # 0 = 全部, 1-4 = 指定輪次
)

$ErrorActionPreference = "Continue"

Write-Host "`n════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Round 11 動態參數系統測試" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

if ($Round -eq 0) {
    Write-Host "📋 執行完整測試 (4輪共32個案例)`n" -ForegroundColor Yellow
    
    # 執行完整測試
    flutter test test/integration/performance_test.dart
    
} elseif ($Round -ge 1 -and $Round -le 4) {
    Write-Host "📋 執行第 $Round 輪測試`n" -ForegroundColor Yellow
    
    # 設定測試過濾器
    $roundNames = @{
        1 = "生日快樂"
        2 = "測試音檔"
        3 = "小星星"
        4 = "名偵探柯南"
    }
    
    $testName = $roundNames[$Round]
    Write-Host "🎯 測試目標: $testName`n" -ForegroundColor Green
    
    # 執行指定輪次
    flutter test test/integration/performance_test.dart --name "第 $Round 輪"
    
} else {
    Write-Host "❌ 錯誤: 無效的輪次編號 '$Round'" -ForegroundColor Red
    Write-Host "`n使用方式:" -ForegroundColor Yellow
    Write-Host "  .\run_round_tests.ps1        # 執行全部4輪" -ForegroundColor White
    Write-Host "  .\run_round_tests.ps1 1      # 執行第1輪 (生日快樂)" -ForegroundColor White
    Write-Host "  .\run_round_tests.ps1 2      # 執行第2輪 (測試音檔)" -ForegroundColor White
    Write-Host "  .\run_round_tests.ps1 3      # 執行第3輪 (小星星)" -ForegroundColor White
    Write-Host "  .\run_round_tests.ps1 4      # 執行第4輪 (名偵探柯南)" -ForegroundColor White
    exit 1
}

Write-Host "`n════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   測試完成" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

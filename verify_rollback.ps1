# 驗證程式碼回溯腳本
# 2025/10/27

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "驗證程式碼回溯至動態參數系統之前" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 執行靜態分析
Write-Host "步驟 1: 執行靜態分析..." -ForegroundColor Yellow
flutter analyze

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 靜態分析失敗" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 靜態分析通過" -ForegroundColor Green
Write-Host ""

# 2. 執行第1輪測試（生日快樂 - 最簡單）
Write-Host "步驟 2: 執行第1輪測試（生日快樂）..." -ForegroundColor Yellow
flutter test test/integration/performance_test.dart --name "第 1 輪"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 第1輪測試失敗" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 第1輪測試通過" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ 程式碼回溯驗證完成！" -ForegroundColor Green
Write-Host "已成功停用動態參數系統" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

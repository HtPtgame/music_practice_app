@echo off
chcp 65001 >nul
setlocal

REM 設定環境變數
if "%1"=="" (
    set TEST_MODE=0
) else (
    set TEST_MODE=%1
)

REM 執行測試（不顯示額外訊息）
flutter test test/integration/debug_accuracy_test.dart

endlocal

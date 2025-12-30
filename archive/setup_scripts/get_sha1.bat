@echo off
echo ===== 正在獲取 Debug Keystore 的 SHA-1 憑證 =====
echo.

REM 嘗試使用 Flutter 內建的 Java
if exist "%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin\keytool.bat" (
    "%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin\keytool.bat" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
    goto :end
)

REM 嘗試使用系統的 Java
where keytool >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
    goto :end
)

REM 嘗試從常見的 Java 安裝路徑
if exist "C:\Program Files\Java\jdk*\bin\keytool.exe" (
    for /d %%i in ("C:\Program Files\Java\jdk*") do (
        if exist "%%i\bin\keytool.exe" (
            "%%i\bin\keytool.exe" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
            goto :end
        )
    )
)

echo 錯誤: 找不到 keytool 工具
echo 請確認已安裝 Java JDK，或使用 Android Studio 的 Gradle signingReport
echo.
echo 替代方案：
echo 1. 打開 Android Studio
echo 2. 點擊右側 Gradle 面板
echo 3. 展開 Tasks → android → 雙擊 signingReport
echo 4. 在 Run 面板中找到 SHA1 和 SHA-256

:end
echo.
echo ===== 完成 =====
pause

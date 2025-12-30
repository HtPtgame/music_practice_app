# Firebase 自動設定腳本 (Windows PowerShell)

Write-Host "🔥 開始設定 Firebase..." -ForegroundColor Cyan

# 1. 檢查 FlutterFire CLI 是否已安裝
Write-Host "`n📦 檢查 FlutterFire CLI..." -ForegroundColor Yellow
$flutterfire = Get-Command flutterfire -ErrorAction SilentlyContinue
if (-not $flutterfire) {
    Write-Host "⚠️  FlutterFire CLI 未安裝，正在安裝..." -ForegroundColor Yellow
    dart pub global activate flutterfire_cli
} else {
    Write-Host "✅ FlutterFire CLI 已安裝" -ForegroundColor Green
}

# 2. 配置 Firebase 專案
Write-Host "`n⚙️  配置 Firebase 專案..." -ForegroundColor Yellow
Write-Host "提示：如果這是第一次使用，請選擇 'Create a new project' 或選擇現有專案" -ForegroundColor Cyan
flutterfire configure

# 3. 安裝相依套件
Write-Host "`n📦 安裝 Flutter 套件..." -ForegroundColor Yellow
flutter pub get

# 4. 完成
Write-Host "`n✅ Firebase 設定完成！" -ForegroundColor Green
Write-Host "`n📋 下一步：" -ForegroundColor Cyan
Write-Host "1. 前往 Firebase Console: https://console.firebase.google.com/"
Write-Host "2. 選擇你的專案"
Write-Host "3. 啟用 Authentication (Email/密碼 和 Google 登入)"
Write-Host "4. 建立 Firestore Database (選擇測試模式)"
Write-Host "5. 執行 'flutter run' 啟動應用程式"
Write-Host ""

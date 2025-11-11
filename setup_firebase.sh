#!/bin/bash
# Firebase 自動設定腳本

echo "🔥 開始設定 Firebase..."

# 1. 檢查 FlutterFire CLI 是否已安裝
echo "📦 檢查 FlutterFire CLI..."
if ! command -v flutterfire &> /dev/null
then
    echo "⚠️  FlutterFire CLI 未安裝，正在安裝..."
    dart pub global activate flutterfire_cli
else
    echo "✅ FlutterFire CLI 已安裝"
fi

# 2. 登入 Firebase（如果尚未登入）
echo "🔐 檢查 Firebase 登入狀態..."
firebase login --reauth

# 3. 配置 Firebase 專案
echo "⚙️  配置 Firebase 專案..."
flutterfire configure

# 4. 安裝相依套件
echo "📦 安裝 Flutter 套件..."
flutter pub get

# 5. 完成
echo ""
echo "✅ Firebase 設定完成！"
echo ""
echo "📋 下一步："
echo "1. 前往 Firebase Console: https://console.firebase.google.com/"
echo "2. 選擇你的專案"
echo "3. 啟用 Authentication (Email/密碼 和 Google 登入)"
echo "4. 建立 Firestore Database (選擇測試模式)"
echo "5. 執行 'flutter run' 啟動應用程式"
echo ""

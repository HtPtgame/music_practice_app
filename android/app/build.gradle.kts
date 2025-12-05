plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.music_practice_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // 啟用 core library desugaring (flutter_local_notifications 需要)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.music_practice_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24  // flutter_sound 套件需要 Android 7.0 以上
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // 支援多語言
        resConfigs("zh-rTW", "zh-rCN", "en")
        
        // 【FFmpeg 修正 1/2】強制包含特定的原生架構
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    // 【FFmpeg 修正 2/2】允許打包 FFmpeg 的大型 .so 檔案，避免構建失敗
    packagingOptions {
        doNotStrip("**/armeabi-v7a/libffmpegkit.so")
        doNotStrip("**/arm64-v8a/libffmpegkit.so") 
        doNotStrip("**/x86_64/libffmpegkit.so")
    }

    buildTypes {
        release {
            // 啟用代碼混淆和資源壓縮
            isMinifyEnabled = true
            isShrinkResources = true
            
            // 使用 ProGuard 規則
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
        
        debug {
            // Debug 版本配置
            isMinifyEnabled = false
            // applicationIdSuffix = ".debug"  // 已移除，避免 Firebase 配置問題
            versionNameSuffix = "-DEBUG"
        }
    }
    
    // 優化 APK 大小
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring (flutter_local_notifications 需要)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

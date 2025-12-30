# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class com.google.firebase.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# MIDI 相關
-keep class com.example.music_practice_app.** { *; }
-keep class jp.kshoji.** { *; }

# 音頻處理
-keep class com.github.hiteshsondhi88.** { *; }
-keep class cafe.adriel.** { *; }

# Dart 反射
-keep class **.dart.** { *; }

# 保留泛型
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# 保留行號用於調試
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# 移除日誌
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

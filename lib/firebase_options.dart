// Firebase 配置檔案範本
//
// 此檔案會在執行 'flutterfire configure' 後自動生成
// 請勿手動編輯此檔案
//
// 如果你尚未執行配置，請執行：
// 1. dart pub global activate flutterfire_cli
// 2. flutterfire configure
//
// 配置完成後，此範本檔案會被實際的 firebase_options.dart 取代

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// 範例：此檔案將包含你的 Firebase 專案配置
///
/// 執行 'flutterfire configure' 後，此檔案會自動生成正確的配置
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA8pw3464Z9IkD_WN0WOdFhVLG6KsFx8jo',
    appId: '1:927535785315:web:5fcd3e8e455bf905c31f56',
    messagingSenderId: '927535785315',
    projectId: 'sound-spirit-detective',
    authDomain: 'sound-spirit-detective.firebaseapp.com',
    storageBucket: 'sound-spirit-detective.firebasestorage.app',
    measurementId: 'G-LE4G02T438',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC8eXmmBqYSAe3-_Hhs1ssCfI9H6YF1eEg',
    appId: '1:927535785315:android:7a2b437ba33252efc31f56',
    messagingSenderId: '927535785315',
    projectId: 'sound-spirit-detective',
    storageBucket: 'sound-spirit-detective.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAzh9bWLLUbniOiDTRE_uyYsq728Idjhq4',
    appId: '1:927535785315:ios:39efe05c63a4f51ac31f56',
    messagingSenderId: '927535785315',
    projectId: 'sound-spirit-detective',
    storageBucket: 'sound-spirit-detective.firebasestorage.app',
    iosBundleId: 'com.example.musicPracticeApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAzh9bWLLUbniOiDTRE_uyYsq728Idjhq4',
    appId: '1:927535785315:ios:39efe05c63a4f51ac31f56',
    messagingSenderId: '927535785315',
    projectId: 'sound-spirit-detective',
    storageBucket: 'sound-spirit-detective.firebasestorage.app',
    iosBundleId: 'com.example.musicPracticeApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA8pw3464Z9IkD_WN0WOdFhVLG6KsFx8jo',
    appId: '1:927535785315:web:a1e1c26c816365b5c31f56',
    messagingSenderId: '927535785315',
    projectId: 'sound-spirit-detective',
    authDomain: 'sound-spirit-detective.firebaseapp.com',
    storageBucket: 'sound-spirit-detective.firebasestorage.app',
    measurementId: 'G-23J6PGMNQE',
  );
}

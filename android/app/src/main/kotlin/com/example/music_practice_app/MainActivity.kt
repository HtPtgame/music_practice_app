package com.example.music_practice_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "external_storage_permission"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		
		// 配置螢幕常亮（練習時不休眠）
		window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
		
		// 設置 MethodChannel 處理儲存權限
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"requestManageExternalStorage" -> {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
						if (!Environment.isExternalStorageManager()) {
							try {
								val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
								intent.data = Uri.parse("package:$packageName")
								startActivity(intent)
								result.success(false)
							} catch (e: Exception) {
								// 如果無法打開設置頁面，嘗試通用設置
								val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
								startActivity(intent)
								result.success(false)
							}
						} else {
							result.success(true)
						}
					} else {
						// Android 10 及以下版本不需要此權限
						result.success(true)
					}
				}
				"isExternalStorageManager" -> {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
						result.success(Environment.isExternalStorageManager())
					} else {
						result.success(true)
					}
				}
				else -> {
					result.notImplemented()
				}
			}
		}
	}
	
	override fun onResume() {
		super.onResume()
		// 恢復螢幕常亮
		window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
	}
}

package com.example.app_locker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.app_locker/native_bridge"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateLockedApps" -> {
                    @Suppress("UNCHECKED_CAST")
                    val list = call.arguments as? List<String>
                    if (list != null) {
                        val prefs = getSharedPreferences("app_locker_prefs", MODE_PRIVATE)
                        prefs.edit().putStringSet(ForegroundLockService.PREF_LOCKED_APPS, list.toSet()).apply()
                        // Notify service to refresh list
                        val intent = Intent(this, ForegroundLockService::class.java).apply {
                            putExtra(ForegroundLockService.EXTRA_REFRESH_LIST, true)
                        }
                        startForegroundService(intent)
                        result.success(null)
                    } else {
                        result.error("INVALID", "Expected list of strings", null)
                    }
                }
                "updatePin" -> {
                    val pin = call.arguments as? String
                    val prefs = getSharedPreferences("app_locker_prefs", MODE_PRIVATE)
                    prefs.edit().putString(LockScreenActivity.PREF_PIN, pin).apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
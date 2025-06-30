package com.example.app_locker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.content.ComponentName
import android.content.pm.PackageManager
import android.app.admin.DevicePolicyManager
import android.content.Context
import com.example.app_locker.IntruderSelfie

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.app_locker/native_bridge"
    private val THEME_CHANNEL = "app.locker/native"

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
                "setAppAlias" -> {
                    val alias = (call.argument<String>("alias")) ?: run {
                        result.error("INVALID", "alias missing", null)
                        return@setMethodCallHandler
                    }
                    val aliases = listOf(
                        "com.example.app_locker.alias.DefaultAlias",
                        "com.example.app_locker.alias.CompassAlias",
                        "com.example.app_locker.alias.CameraAlias",
                        "com.example.app_locker.alias.ClockAlias",
                        "com.example.app_locker.alias.CalendarAlias"
                    )
                    val pm = packageManager
                    for (name in aliases) {
                        val state = if (name == alias) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                                    else PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                        pm.setComponentEnabledSetting(
                            ComponentName(this, name),
                            state,
                            PackageManager.DONT_KILL_APP
                        )
                    }
                    result.success(null)
                }
                "updatePattern" -> {
                    val pattern = call.arguments as? String
                    val prefs = getSharedPreferences("app_locker_prefs", MODE_PRIVATE)
                    prefs.edit().putString("app_lock_pattern", pattern).apply()
                    result.success(null)
                }
                "updateLockType" -> {
                    val lockType = call.arguments as? String
                    val prefs = getSharedPreferences("app_locker_prefs", MODE_PRIVATE)
                    prefs.edit().putString("lock_type", lockType).apply()
                    result.success(null)
                }
                "setThemeIndex" -> {
                    val idx = (call.arguments as? Int) ?: 0
                    val prefs = getSharedPreferences("app_locker_prefs", MODE_PRIVATE)
                    prefs.edit().putInt("selected_theme", idx).apply()
                    result.success(null)
                }
                "getIntruderPhotos" -> {
                    val dir = IntruderSelfie.getImagesDir(this)
                    val list = dir.listFiles()?.map { it.absolutePath } ?: emptyList()
                    result.success(list)
                }
                "deleteIntruderPhoto" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("INVALID", "path missing", null)
                    } else {
                        val deleted = java.io.File(path).delete()
                        result.success(deleted)
                    }
                }
                "getIntruderConfig" -> {
                    val prefs = getSharedPreferences("app_locker_prefs", MODE_PRIVATE)
                    val enabled = prefs.getBoolean(LockScreenActivity.PREF_INTRUDER_ENABLED, true)
                    val threshold = prefs.getInt(LockScreenActivity.PREF_INTRUDER_THRESHOLD, LockScreenActivity.DEFAULT_THRESHOLD)
                    result.success(mapOf("enabled" to enabled, "threshold" to threshold))
                }
                "setIntruderConfig" -> {
                    val args = call.arguments as? Map<*, *>
                    if (args == null) {
                        result.error("INVALID", "map expected", null)
                    } else {
                        val prefs = getSharedPreferences("app_locker_prefs", MODE_PRIVATE)
                        val ed = prefs.edit()
                        if (args.containsKey("enabled")) {
                            ed.putBoolean(LockScreenActivity.PREF_INTRUDER_ENABLED, args["enabled"] as Boolean)
                        }
                        if (args.containsKey("threshold")) {
                            ed.putInt(LockScreenActivity.PREF_INTRUDER_THRESHOLD, (args["threshold"] as Number).toInt())
                        }
                        ed.apply()
                        result.success(null)
                    }
                }
                "isAdmin" -> {
                    val active = AdminUtil.isActive(this)
                    result.success(active)
                }
                "enableAdmin" -> {
                    AdminUtil.requestActivation(this)
                    result.success(null)
                }
                "disableAdmin" -> {
                    AdminUtil.disableAdministration(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Theme change channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, THEME_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "themeChanged") {
                val intent = Intent("com.example.app_locker.ACTION_CLOSE_LOCK_SCREEN")
                sendBroadcast(intent)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
package com.example.local_foreground_app

import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** LocalForegroundAppPlugin */
class LocalForegroundAppPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.app_locker/foreground_app")
    channel.setMethodCallHandler(this)
  }

  @RequiresApi(Build.VERSION_CODES.LOLLIPOP_MR1)
  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getForegroundApp") {
      val foregroundApp = getForegroundApp()
      if (foregroundApp != null) {
        result.success(foregroundApp)
      } else {
        result.error("UNAVAILABLE", "Foreground app not available.", null)
      }
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  @RequiresApi(Build.VERSION_CODES.LOLLIPOP_MR1)
  private fun getForegroundApp(): String? {
    var currentApp: String? = null
    try {
      val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
      val time = System.currentTimeMillis()
      val appList = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, time - 1000 * 60, time)
      if (appList != null && appList.isNotEmpty()) {
        val sortedMap = sortedMapOf<Long, String>()
        for (usageStats in appList) {
          if (usageStats.lastTimeUsed > 0) {
            sortedMap[usageStats.lastTimeUsed] = usageStats.packageName
          }
        }
        if (sortedMap.isNotEmpty()) {
          currentApp = sortedMap[sortedMap.lastKey()]
        }
      }
    } catch (e: Exception) {
      e.printStackTrace()
    }
    return currentApp
  }
}

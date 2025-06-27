package com.example.app_locker

import android.app.*
import android.content.Context
import android.content.Intent
import android.app.usage.UsageStatsManager
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import java.util.*
import android.content.BroadcastReceiver
import android.content.IntentFilter

class ForegroundLockService : Service() {

    private val timer = Timer()
    private val checkIntervalMs = 500L
    private val prefs by lazy {
        getSharedPreferences("app_locker_prefs", Context.MODE_PRIVATE)
    }
    private val lockedApps: MutableSet<String> = mutableSetOf()
    private var unlockedPackage: String? = null
    private val unlockReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_UNLOCKED) {
                val pkg = intent.getStringExtra(EXTRA_PACKAGE) ?: return
                // Mark this package as unlocked until user leaves it
                unlockedPackage = pkg
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        startInForeground()
        loadLockedApps()
        scheduleChecker()
        registerReceiver(unlockReceiver, IntentFilter(ACTION_UNLOCKED))
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Refresh locked list if caller passed extras
        if (intent?.hasExtra(EXTRA_REFRESH_LIST) == true) {
            loadLockedApps()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        timer.cancel()
        unregisterReceiver(unlockReceiver)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun scheduleChecker() {
        timer.scheduleAtFixedRate(object : TimerTask() {
            @RequiresApi(Build.VERSION_CODES.LOLLIPOP_MR1)
            override fun run() {
                checkForegroundApp()
            }
        }, 0, checkIntervalMs)
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP_MR1)
    private fun checkForegroundApp() {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        val appList = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, time - 1000 * 60, time)
        if (appList.isNullOrEmpty()) return
        val currentApp = appList.maxByOrNull { it.lastTimeUsed }?.packageName ?: return

        if (currentApp == unlockedPackage) {
            // User already authenticated for this session
            return
        } else {
            // User has switched apps — reset session
            unlockedPackage = null
        }

        if (lockedApps.contains(currentApp)) {
            launchLockScreen(currentApp)
        }
    }

    private fun launchLockScreen(pkg: String) {
        val lockIntent = Intent(this, LockScreenActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
            putExtra(LockScreenActivity.EXTRA_PACKAGE, pkg)
        }
        startActivity(lockIntent)
    }

    private fun loadLockedApps() {
        lockedApps.clear()
        lockedApps.addAll(prefs.getStringSet(PREF_LOCKED_APPS, emptySet())!!)
    }

    private fun startInForeground() {
        val channelId = "lock_service_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val chan = NotificationChannel(channelId, "App Locker Service", NotificationManager.IMPORTANCE_LOW)
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(chan)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("App Locker running")
            .setContentText("Monitoring apps")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .build()

        startForeground(1, notification)
    }

    companion object {
        const val PREF_LOCKED_APPS = "locked_apps"
        const val EXTRA_REFRESH_LIST = "refresh_locked_list"
        const val ACTION_UNLOCKED = "com.example.app_locker.UNLOCKED"
        const val EXTRA_PACKAGE = "package"
    }
} 
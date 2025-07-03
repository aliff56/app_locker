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
import android.app.usage.UsageEvents

class ForegroundLockService : Service() {

    private val timer = Timer()
    private val checkIntervalMs = 200L
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
                // Also set last lock time to now so we don't immediately relaunch
                lastLockTime[pkg] = System.currentTimeMillis()
            }
        }
    }
    private val lastLockTime: MutableMap<String, Long> = mutableMapOf()
    private val lockCooldownMs = 2000L // 2 seconds
    private var lastForegroundApp: String? = null

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

    private fun getForegroundAppPackage(usm: UsageStatsManager): String? {
        val endTime = System.currentTimeMillis()
        val beginTime = endTime - 2000 // look at last 2 seconds of events
        val usageEvents = usm.queryEvents(beginTime, endTime)
        val event = UsageEvents.Event()
        var recentPkg: String? = null
        var recentTimestamp = 0L
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND && event.timeStamp > recentTimestamp) {
                recentTimestamp = event.timeStamp
                recentPkg = event.packageName
            }
        }
        return recentPkg
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP_MR1)
    private fun checkForegroundApp() {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val currentApp = getForegroundAppPackage(usm) ?: return

        val launcherPkgs = getLauncherPackages()
        val now = System.currentTimeMillis()

        // If we have previously unlocked a locked app and now truly left it
        // (current foreground pkg is different), clear the marker so next time
        // we enter that app we will lock again. We only clear when the last
        // foreground was the unlocked package to avoid clearing during rapid
        // System UI transitions.
        if (unlockedPackage != null && currentApp != unlockedPackage && lastForegroundApp == unlockedPackage) {
            unlockedPackage = null
        }

        // Ignore if launcher or system UI
        if (launcherPkgs.contains(currentApp) || currentApp == "com.android.systemui") {
            lastForegroundApp = currentApp
            return
        }

        // If current app is not locked, nothing to do.
        if (!lockedApps.contains(currentApp)) {
            lastForegroundApp = currentApp
            return
        }

        // If still in same foreground app, do nothing
        if (currentApp == lastForegroundApp) return

        // Debounce lock per app
        if (lastLockTime.containsKey(currentApp) && now - lastLockTime[currentApp]!! < lockCooldownMs) {
            lastForegroundApp = currentApp
            return
        }

        // If we already unlocked this package and user hasn't left it for at least cooldown period, skip
        if (currentApp == unlockedPackage) {
            lastForegroundApp = currentApp
            return
        }

        // Entering locked app – launch lock screen
        unlockedPackage = null
        lastLockTime[currentApp] = now
        lastForegroundApp = currentApp
        launchLockScreen(currentApp)
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

    private fun getLauncherPackages(): Set<String> {
        val intent = Intent(Intent.ACTION_MAIN, null)
        intent.addCategory(Intent.CATEGORY_HOME)
        val pm = packageManager
        val resolveInfos = pm.queryIntentActivities(intent, 0)
        return resolveInfos.map { it.activityInfo.packageName }.toSet()
    }

    companion object {
        const val PREF_LOCKED_APPS = "locked_apps"
        const val EXTRA_REFRESH_LIST = "refresh_locked_list"
        const val ACTION_UNLOCKED = "com.example.app_locker.UNLOCKED"
        const val EXTRA_PACKAGE = "package"
    }
} 
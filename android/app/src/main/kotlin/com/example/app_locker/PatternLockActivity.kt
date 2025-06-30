package com.example.app_locker

import android.os.Bundle
import android.view.WindowManager
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.itsxtt.patternlock.PatternLockView
import com.example.app_locker.IntruderSelfie

class PatternLockActivity : AppCompatActivity() {

    private lateinit var patternView: PatternLockView
    private val prefs by lazy {
        getSharedPreferences("app_locker_prefs", MODE_PRIVATE)
    }

    private val closeReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: android.content.Context?, intent: android.content.Intent?) {
            finish()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_FULLSCREEN)
        setContentView(R.layout.activity_pattern_lock)

        // Set gradient background based on selected theme
        val themeIdx = prefs.getInt("selected_theme", 0)
        val gradients = arrayOf(
            intArrayOf(0xFFB16CEA.toInt(), 0xFFFF5E69.toInt()),
            intArrayOf(0xFFFF5E69.toInt(), 0xFFFFA07A.toInt()),
            intArrayOf(0xFF92FE9D.toInt(), 0xFF00C9FF.toInt()),
            intArrayOf(0xFFB1B5EA.toInt(), 0xFFB993D6.toInt()),
            intArrayOf(0xFF43E97B.toInt(), 0xFF38F9D7.toInt()),
            intArrayOf(0xFF667EEA.toInt(), 0xFF64B6FF.toInt()),
            intArrayOf(0xFF868686.toInt(), 0xFFA3A3A3.toInt()),
            intArrayOf(0xFFF797A6.toInt(), 0xFFF9A8D4.toInt())
        )
        val root = findViewById<android.view.View>(android.R.id.content)
        val gradient = android.graphics.drawable.GradientDrawable(
            android.graphics.drawable.GradientDrawable.Orientation.TL_BR,
            gradients[themeIdx % gradients.size]
        )
        root.background = gradient

        patternView = findViewById(R.id.patternView)
        patternView.setOnPatternListener(object : PatternLockView.OnPatternListener {
            override fun onStarted() {}

            override fun onProgress(ids: ArrayList<Int>) {}

            override fun onComplete(ids: ArrayList<Int>): Boolean {
                val entered = ids.joinToString("-")
                val stored = prefs.getString("app_lock_pattern", "")
                val correct = entered == stored
                if (correct) {
                    prefs.edit().putInt(LockScreenActivity.PREF_FAILED_ATTEMPTS, 0).apply()
                    sendUnlockedBroadcast()
                    finish()
                } else {
                    Toast.makeText(this@PatternLockActivity, "Incorrect pattern", Toast.LENGTH_SHORT).show()

                    val attempts = prefs.getInt(LockScreenActivity.PREF_FAILED_ATTEMPTS, 0) + 1
                    prefs.edit().putInt(LockScreenActivity.PREF_FAILED_ATTEMPTS, attempts).apply()

                    val enabled = prefs.getBoolean(LockScreenActivity.PREF_INTRUDER_ENABLED, true)
                    val threshold = prefs.getInt(LockScreenActivity.PREF_INTRUDER_THRESHOLD, LockScreenActivity.DEFAULT_THRESHOLD)

                    if (enabled && attempts >= threshold) {
                        prefs.edit().putInt(LockScreenActivity.PREF_FAILED_ATTEMPTS, 0).apply()
                        IntruderSelfie.capture(this@PatternLockActivity)
                    }
                }
                return correct // tells view to show correct/error state
            }
        })
    }

    override fun onResume() {
        super.onResume()
        registerReceiver(closeReceiver, android.content.IntentFilter("com.example.app_locker.ACTION_CLOSE_LOCK_SCREEN"))
    }

    override fun onPause() {
        super.onPause()
        unregisterReceiver(closeReceiver)
    }

    private fun sendUnlockedBroadcast() {
        val pkg = intent.getStringExtra(LockScreenActivity.EXTRA_PACKAGE)
        val b = android.content.Intent(ForegroundLockService.ACTION_UNLOCKED).apply {
            putExtra(ForegroundLockService.EXTRA_PACKAGE, pkg)
        }
        sendBroadcast(b)
    }
} 
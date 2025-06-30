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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_FULLSCREEN)
        setContentView(R.layout.activity_pattern_lock)

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
                    if (attempts >= LockScreenActivity.MAX_FAILED_ATTEMPTS) {
                        prefs.edit().putInt(LockScreenActivity.PREF_FAILED_ATTEMPTS, 0).apply()
                        IntruderSelfie.capture(this@PatternLockActivity)
                    }
                }
                return correct // tells view to show correct/error state
            }
        })
    }

    private fun sendUnlockedBroadcast() {
        val pkg = intent.getStringExtra(LockScreenActivity.EXTRA_PACKAGE)
        val b = android.content.Intent(ForegroundLockService.ACTION_UNLOCKED).apply {
            putExtra(ForegroundLockService.EXTRA_PACKAGE, pkg)
        }
        sendBroadcast(b)
    }
} 
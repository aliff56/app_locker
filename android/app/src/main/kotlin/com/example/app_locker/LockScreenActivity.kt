package com.example.app_locker

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import com.example.app_locker.IntruderSelfie
import android.widget.GridLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.view.Gravity
import android.graphics.Typeface

class LockScreenActivity : AppCompatActivity() {

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
        setContentView(R.layout.activity_lock_screen)

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

        // Custom PIN dots and keypad logic
        val pinDotsLayout = findViewById<LinearLayout>(R.id.pinDotsLayout)
        val keypadGrid = findViewById<GridLayout>(R.id.keypadGrid)

        val pinLength = 4
        var enteredPin = ""

        fun updateDots() {
            pinDotsLayout.removeAllViews()
            for (i in 0 until pinLength) {
                val dot = TextView(this)
                val size = (resources.displayMetrics.density * 18).toInt()
                val params = LinearLayout.LayoutParams(size, size)
                params.setMargins(12, 0, 12, 0)
                dot.layoutParams = params
                dot.background = resources.getDrawable(android.R.drawable.presence_online, null)
                dot.background.setTint(if (i < enteredPin.length) 0xFFFFFFFF.toInt() else 0x33FFFFFF)
                dot.text = ""
                pinDotsLayout.addView(dot)
            }
        }

        fun handlePinComplete() {
            val storedPin = prefs.getString(PREF_PIN, "")
            if (storedPin == enteredPin) {
                prefs.edit().putInt(PREF_FAILED_ATTEMPTS, 0).apply()
                sendUnlockedBroadcast()
                finish()
            } else {
                Toast.makeText(this, "Incorrect PIN", Toast.LENGTH_SHORT).show()
                enteredPin = ""
                updateDots()
                val attempts = prefs.getInt(PREF_FAILED_ATTEMPTS, 0) + 1
                prefs.edit().putInt(PREF_FAILED_ATTEMPTS, attempts).apply()
                val enabled = prefs.getBoolean(PREF_INTRUDER_ENABLED, true)
                val threshold = prefs.getInt(PREF_INTRUDER_THRESHOLD, DEFAULT_THRESHOLD)
                if (enabled && attempts >= threshold) {
                    prefs.edit().putInt(PREF_FAILED_ATTEMPTS, 0).apply()
                    IntruderSelfie.capture(this)
                }
            }
        }

        // Build keypad
        val keys = listOf(
            "1", "2", "3",
            "4", "5", "6",
            "7", "8", "9",
            "",  "0", "<"
        )
        keypadGrid.removeAllViews()
        for ((i, key) in keys.withIndex()) {
            val btn = TextView(this)
            val size = (resources.displayMetrics.density * 64).toInt()
            val params = GridLayout.LayoutParams().apply {
                width = size
                height = size
                setMargins(16, 16, 16, 16)
                rowSpec = GridLayout.spec(i / 3)
                columnSpec = GridLayout.spec(i % 3)
            }
            btn.layoutParams = params
            btn.textSize = 28f
            btn.textAlignment = TextView.TEXT_ALIGNMENT_CENTER
            btn.gravity = Gravity.CENTER
            btn.setTypeface(null, Typeface.BOLD)
            btn.setTextColor(0xFF162C65.toInt())
            // Create a circular white background
            val bg = android.graphics.drawable.GradientDrawable()
            bg.shape = android.graphics.drawable.GradientDrawable.OVAL
            bg.setColor(0xFFFFFFFF.toInt())
            btn.background = bg
            btn.isClickable = key.isNotEmpty()
            btn.isFocusable = false
            btn.text = when (key) {
                "<" -> "⌫"
                else -> key
            }
            btn.setOnClickListener {
                if (key == "<") {
                    if (enteredPin.isNotEmpty()) {
                        enteredPin = enteredPin.substring(0, enteredPin.length - 1)
                        updateDots()
                    }
                } else if (key.isNotEmpty() && enteredPin.length < pinLength) {
                    enteredPin += key
                    updateDots()
                    if (enteredPin.length == pinLength) handlePinComplete()
                }
            }
            keypadGrid.addView(btn)
        }

        updateDots()

        // Biometric fallback
        if (BiometricManager.from(this).canAuthenticate() == BiometricManager.BIOMETRIC_SUCCESS) {
            val prompt = BiometricPrompt(this, ContextCompat.getMainExecutor(this), object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(result)
                    sendUnlockedBroadcast()
                    finish()
                }
            })
            prompt.authenticate(BiometricPrompt.PromptInfo.Builder()
                .setTitle("Unlock App")
                .setNegativeButtonText("Cancel")
                .build())
        }

        val lockType = prefs.getString("lock_type", "pin")
        if (lockType == "pattern") {
            val forward = Intent(this, PatternLockActivity::class.java).apply {
                putExtra(EXTRA_PACKAGE, intent.getStringExtra(EXTRA_PACKAGE))
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            startActivity(forward)
            finish()
            return
        }
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
        val b = Intent(ForegroundLockService.ACTION_UNLOCKED).apply {
            putExtra(ForegroundLockService.EXTRA_PACKAGE, getIntent().getStringExtra(EXTRA_PACKAGE))
        }
        sendBroadcast(b)
    }

    companion object {
        const val EXTRA_PACKAGE = "locked_package"
        const val PREF_PIN = "user_pin"
        const val PREF_FAILED_ATTEMPTS = "failed_attempts"
        const val PREF_INTRUDER_ENABLED = "intruder_enabled"
        const val PREF_INTRUDER_THRESHOLD = "intruder_threshold"
        const val DEFAULT_THRESHOLD = 3
    }
} 
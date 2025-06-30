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

class LockScreenActivity : AppCompatActivity() {

    private val prefs by lazy {
        getSharedPreferences("app_locker_prefs", MODE_PRIVATE)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_FULLSCREEN)
        setContentView(R.layout.activity_lock_screen)

        val pinEdit: EditText = findViewById(R.id.pinEdit)
        val unlockBtn: Button = findViewById(R.id.unlockBtn)

        unlockBtn.setOnClickListener {
            val storedPin = prefs.getString(PREF_PIN, "")
            if (storedPin == pinEdit.text.toString()) {
                // Correct PIN – reset failed attempts counter
                prefs.edit().putInt(PREF_FAILED_ATTEMPTS, 0).apply()
                sendUnlockedBroadcast()
                finish()
            } else {
                Toast.makeText(this, "Incorrect PIN", Toast.LENGTH_SHORT).show()
                pinEdit.text.clear()

                // Count failed attempts and capture intruder selfie if necessary
                val attempts = prefs.getInt(PREF_FAILED_ATTEMPTS, 0) + 1
                prefs.edit().putInt(PREF_FAILED_ATTEMPTS, attempts).apply()
                if (attempts >= MAX_FAILED_ATTEMPTS) {
                    prefs.edit().putInt(PREF_FAILED_ATTEMPTS, 0).apply()
                    IntruderSelfie.capture(this)
                }
            }
        }

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
        const val MAX_FAILED_ATTEMPTS = 3
    }
} 
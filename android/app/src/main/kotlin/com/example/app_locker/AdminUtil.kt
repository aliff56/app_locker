package com.example.app_locker

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent

object AdminUtil {

    private fun component(context: Context) = ComponentName(context, AdminReceiver::class.java)

    fun isActive(context: Context): Boolean {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        return dpm.isAdminActive(component(context))
    }

    fun requestActivation(activity: Activity) {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, component(activity))
            putExtra(
                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "Grant device administrator permission so App Locker can prevent uninstallation."
            )
        }
        activity.startActivityForResult(intent, 8989)
    }

    fun disableAdministration(context: Context) {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        dpm.removeActiveAdmin(component(context))
    }
} 
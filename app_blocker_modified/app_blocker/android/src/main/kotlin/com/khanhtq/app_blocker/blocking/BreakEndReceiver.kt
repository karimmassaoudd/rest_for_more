package com.khanhtq.app_blocker.blocking

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Woken by Android's AlarmManager exactly when a break ends.
 * Asks the running blocker service to check which app is on screen.
 * If the service isn't running, there is nothing to block, so it does nothing.
 */
class BreakEndReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AppBlockerAccessibilityService.instance?.onBreakEndAlarm()
    }
}
package com.khanhtq.app_blocker.blocking

import android.accessibilityservice.AccessibilityService
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.khanhtq.app_blocker.event.BlockEventStreamHandler
import com.khanhtq.app_blocker.persistence.BlockerPreferences

/**
 * Accessibility service that detects foreground app changes and triggers the
 * block screen when a blocked app comes to the foreground.
 *
 * **Battery efficiency:** Reacts to [AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED]
 * events fired by Android exactly when the foreground window changes — zero idle CPU cost.
 *
 * **Block flow (mirrors the digipaws pattern):**
 * 1. Blocked app detected → [performGlobalAction] HOME (sends user away immediately)
 * 2. [lastPackage] reset so the next round of events is processed cleanly
 * 3. After [BLOCK_LAUNCH_DELAY_MS] the [BlockedAppActivity] is launched
 *
 * This avoids the ghost-event re-show bugs that plagued the previous overlay approach:
 * - No system overlay that could be spuriously re-triggered after dismissal
 * - Own-package events (from the block Activity) are already filtered, so no
 *   race between "overlay just hidden" and "next blocked-app event"
 *
 * **Break end:** when a break ends, Android's AlarmManager wakes the service at
 * the exact moment ([BreakEndReceiver]). An in-app Handler timer runs as a backup.
 *
 * **Setup:** The user must enable this service in Settings → Accessibility → App Blocker.
 */
class AppBlockerAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AppBlockerService"

        /** Events we care about — window transitions and content changes. */
        private const val TARGET_EVENTS =
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED

        /** System packages we never want to block. */
        private const val SYSTEM_UI_PACKAGE = "com.android.systemui"

        /**
         * Delay between pressing HOME and launching [BlockedAppActivity].
         * Gives the home screen time to settle so the activity appears cleanly.
         */
        private const val BLOCK_LAUNCH_DELAY_MS = 150L

        /** Extra time after the break end before checking, so Flutter's state is settled. */
        private const val BREAK_END_MARGIN_MS = 300L

        /** Request code for the break-end alarm's PendingIntent. */
        private const val BREAK_END_REQUEST_CODE = 4711

        /**
         * The running service instance, or null if the service is not connected.
         * Used by [BlockingServiceManager] to trigger an immediate block check
         * when blocking state changes (e.g. a schedule activates), and by
         * [BreakEndReceiver] when a break ends.
         */
        @Volatile
        var instance: AppBlockerAccessibilityService? = null
            private set
    }

    private lateinit var preferences: BlockerPreferences
    private val handler = Handler(Looper.getMainLooper())

    /**
     * Last package seen in the foreground. Used to skip duplicate events for
     * the same app — the accessibility subsystem fires multiple events per
     * window transition.
     *
     * Reset to `""` whenever blocking is triggered so the next round of
     * events (home screen, then block activity) is processed fresh.
     */
    @Volatile
    private var lastPackage: String = ""

    /** Most recent foreground package, including our own app. */
    @Volatile
    private var currentPackage: String = ""

    /** When the last block was triggered; prevents double blocks from duplicate events. */
    private var lastBlockAt = 0L

    // ------------------------------------------------------------------
    // Lifecycle
    // ------------------------------------------------------------------

    override fun onServiceConnected() {
        super.onServiceConnected()
        preferences = BlockerPreferences(this)
        instance = this
    }

    override fun onInterrupt() {
        // Required override; nothing to clean up since the Activity manages itself.
    }

    override fun onDestroy() {
        instance = null
        handler.removeCallbacksAndMessages(null)
        cancelBreakEndAlarm()
        super.onDestroy()
    }

    // ------------------------------------------------------------------
    // Immediate block check (called when blocking state changes externally)
    // ------------------------------------------------------------------

    /**
     * Blocks the app that is on screen right now, if it is blocked.
     * Called by [BlockingServiceManager] right after blocking switches on,
     * so an app that is already open (e.g. when a schedule starts) is
     * blocked without waiting for the next window change.
     *
     * Uses the real foreground window, not [lastPackage]: when a session is
     * started from our own app, [lastPackage] still holds the app used
     * before it, which would wrongly be blocked.
     */
    fun checkCurrentForegroundApp() {
        val pkg = foregroundPackage() ?: currentPackage
        if (pkg.isEmpty() || pkg == packageName || pkg == SYSTEM_UI_PACKAGE) return
        checkAndBlock(pkg)
    }

    /** Called by [BreakEndReceiver] when Android's break-end alarm fires. */
    fun onBreakEndAlarm() {
        Log.d(TAG, "break end alarm fired")
        recheckAfterBreak()
    }

    // ------------------------------------------------------------------
    // Event handling
    // ------------------------------------------------------------------

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return

        if ((event.eventType and TARGET_EVENTS) == 0) return
        if (packageName == SYSTEM_UI_PACKAGE) return

        currentPackage = packageName

        // Events from our own package (the host Flutter app and BlockedAppActivity)
        // must never trigger a block — the block screen IS our package.
        if (packageName == this.packageName) {
            // Back in our own app: forget the last app, so opening any app
            // after this (even the same one as before) is checked again.
            lastPackage = ""
            return
        }

        if (packageName == lastPackage) return

        Log.d(TAG, "EVENT pkg=$packageName lastPkg=$lastPackage")
        lastPackage = packageName
        checkAndBlock(packageName)
    }

    // ------------------------------------------------------------------
    // Blocking logic
    // ------------------------------------------------------------------

    private fun checkAndBlock(packageName: String) {
        if (!preferences.isBlocking()) {
            Log.d(TAG, "skip $packageName: blocking is off")
            return
        }

        if (isSessionExpired()) {
            Log.d(TAG, "skip $packageName: session expired")
            preferences.setIsBlocking(false)
            preferences.setBlockedApps(emptySet())
            preferences.setBlockAll(false)
            return
        }

        if (isOnBreak()) {
            Log.d(TAG, "skip $packageName: on break")
            scheduleBreakEndCheck()
            return
        }

        val blockAll = preferences.isBlockAll()
        val blockedApps = preferences.getBlockedApps()
        val shouldBlock = when {
            blockAll -> isUserApp(packageName)
            else -> blockedApps.contains(packageName)
        }

        Log.d(TAG, "checkAndBlock: pkg=$packageName blockAll=$blockAll shouldBlock=$shouldBlock")

        if (!shouldBlock) return

        // Don't re-launch if the block screen is already in the foreground.
        if (BlockedAppActivity.isVisible) return

        // Two triggers within half a second (duplicate events, alarm + backup) → block once.
        val now = SystemClock.elapsedRealtime()
        if (now - lastBlockAt < 500L) {
            lastPackage = ""  // so the next event for this app is checked again
            return
        }
        lastBlockAt = now

        // Press home immediately so the blocked app is no longer visible,
        // then show the block screen after a short settling delay.
        lastPackage = ""
        performGlobalAction(GLOBAL_ACTION_HOME)
        handler.postDelayed({
            startActivity(Intent(this, BlockedAppActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                putExtra(BlockedAppActivity.EXTRA_BLOCKED_PACKAGE, packageName)
            })
        }, BLOCK_LAUNCH_DELAY_MS)

        Log.d(TAG, "checkAndBlock: BLOCK pkg=$packageName")
        BlockEventStreamHandler.sendEvent(
            mapOf(
                "type" to "attemptedAccess",
                "packageName" to packageName,
                "timestamp" to System.currentTimeMillis(),
            )
        )
    }

    /**
     * True if a session end time was saved by the Flutter app and has passed.
     * Flutter's SharedPreferences live in "FlutterSharedPreferences" with a "flutter." key prefix.
     */
    private fun isSessionExpired(): Boolean {
        val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val endTime = flutterPrefs.getLong("flutter.sessionEndTimeMillis", 0L)
        return endTime > 0L && System.currentTimeMillis() >= endTime
    }

    // ------------------------------------------------------------------
    // Breaks
    // ------------------------------------------------------------------

    private val breakEndCheck = Runnable { recheckAfterBreak() }

    private fun breakEndMillis(): Long =
        getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            .getLong("flutter.sessionBreakEndMillis", 0L)

    private fun isOnBreak(): Boolean =
        System.currentTimeMillis() < breakEndMillis()

    /** PendingIntent that wakes [BreakEndReceiver]; the same one is reused so it can be replaced or cancelled. */
    private fun breakEndPendingIntent(): PendingIntent =
        PendingIntent.getBroadcast(
            this,
            BREAK_END_REQUEST_CODE,
            Intent(this, BreakEndReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    /**
     * One check right after the break ends (replaces any earlier one).
     *
     * Main: Android's AlarmManager wakes us at the exact moment, even when
     * Samsung's battery saving holds the app back.
     * Backup: an in-app Handler timer, 2 s after the alarm (only matters if the alarm doesn't arrive).
     */
    private fun scheduleBreakEndCheck() {
        val triggerAt = breakEndMillis() + BREAK_END_MARGIN_MS
        val delay = triggerAt - System.currentTimeMillis()

        // Backup timer (2 s after the alarm; only matters if the alarm doesn't arrive).
        handler.removeCallbacks(breakEndCheck)
        handler.postDelayed(breakEndCheck, (delay + 2000L).coerceAtLeast(0L))

        // Exact alarm (falls back to an inexact one if the permission is missing).
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            alarmManager.canScheduleExactAlarms()
        try {
            if (exact) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP, triggerAt, breakEndPendingIntent(),
                )
            } else {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP, triggerAt, breakEndPendingIntent(),
                )
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "break: could not set alarm, using backup timer only", e)
        }

        Log.d(TAG, "break: recheck scheduled in ${delay / 1000}s (exact alarm=$exact)")
    }

    private fun cancelBreakEndAlarm() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(breakEndPendingIntent())
    }

    /** The app that is really on screen right now, or null if Android can't tell us. */
    private fun foregroundPackage(): String? =
        try {
            rootInActiveWindow?.packageName?.toString()
        } catch (_: Exception) {
            null
        }

    /** The break is over: block whatever app is on screen, if it is blocked. */
    private fun recheckAfterBreak() {
        // Whichever fired first (alarm or backup timer), cancel the other one.
        handler.removeCallbacks(breakEndCheck)
        cancelBreakEndAlarm()

        val pkg = foregroundPackage() ?: currentPackage
        Log.d(TAG, "break over: recheck foreground=$pkg (last event: $currentPackage)")
        if (pkg.isEmpty() || pkg == packageName || pkg == SYSTEM_UI_PACKAGE) return
        checkAndBlock(pkg)
    }

    /**
     * Returns true if [packageName] belongs to a user-installed app (not a
     * system app). Used when blocking all apps to avoid blocking system components.
     */
    private fun isUserApp(packageName: String): Boolean {
        return try {
            val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getApplicationInfo(
                    packageName,
                    android.content.pm.PackageManager.ApplicationInfoFlags.of(0),
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getApplicationInfo(packageName, 0)
            }
            (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0
        } catch (_: Exception) {
            false
        }
    }
}
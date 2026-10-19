package com.khanhtq.app_blocker.blocking

import android.annotation.SuppressLint
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.ColorDrawable
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.Window
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.view.View
import android.widget.ImageView
import com.khanhtq.app_blocker.R
import android.graphics.Paint
import androidx.core.content.ContextCompat
import com.khanhtq.app_blocker.persistence.BlockerPreferences
import org.json.JSONObject
import com.khanhtq.app_blocker.event.BlockEventStreamHandler

/**
 * Full-screen activity shown when a blocked app is detected in the foreground.
 *
 * Launched by [AppBlockerAccessibilityService] after pressing home, with a short
 * delay to let the system settle before the screen appears. Unlike the previous
 * overlay approach, this is a proper Android Activity which avoids:
 * - Spurious re-shows caused by ghost accessibility events after overlay dismissal
 * - The overlay remaining visible when the host app is brought to the foreground
 *
 * The close button and hardware back button both navigate explicitly to the
 * home screen before finishing, so the user is never returned to the blocked app.
 *
 * Send [ACTION_DISMISS] broadcast to close this activity programmatically
 * (e.g., when blocking is stopped from the Flutter side).
 */
class BlockedAppActivity : Activity() {

    companion object {
        const val ACTION_DISMISS = "com.khanhtq.app_blocker.DISMISS_BLOCK_SCREEN"
        const val EXTRA_BLOCKED_PACKAGE = "blocked_package"

        /** `true` while this activity is in the resumed state. */
        @Volatile
        var isVisible: Boolean = false
    }

    private val dismissReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_DISMISS) finish()
        }
    }

    private var blockedPackage: String? = null

    private val timerHandler = Handler(Looper.getMainLooper())
    private var timerTextView: TextView? = null
    private var timerRunnable: Runnable? = null
    private var screenConfig: BlockScreenConfig? = null
    private var profileName: String = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
        window.setBackgroundDrawable(ColorDrawable(Color.BLACK))

        blockedPackage = intent.getStringExtra(EXTRA_BLOCKED_PACKAGE)
        val appName = resolveAppName(blockedPackage)

        val prefs = BlockerPreferences(this)
        val rawConfig = parseConfig(prefs.overlayConfig)
        val config = rawConfig.copy(
            title = applyPlaceholders(rawConfig.title, appName),
            subtitle = applyPlaceholders(rawConfig.subtitle, appName),
            message = applyPlaceholders(rawConfig.message, appName),
        )

        screenConfig = config
        profileName = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getString("flutter.sessionProfileName", null) ?: ""
        showBlocked()
        screenConfig = config
    }

    @SuppressLint("UnspecifiedRegisterReceiverFlag")
    override fun onResume() {
        super.onResume()
        isVisible = true

        // Close immediately if blocking was deactivated while we were in the background.
        if (!BlockerPreferences(this).isBlocking()) {
            finish()
            return
        }

        val filter = IntentFilter(ACTION_DISMISS)
        ContextCompat.registerReceiver(
            this,
            dismissReceiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED
        )
        screenConfig?.let { startTimerUpdates(it) }
    }

    override fun onPause() {
        super.onPause()
        isVisible = false
        stopTimerUpdates()
        runCatching { unregisterReceiver(dismissReceiver) }
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        openRestForMore()
    }

    // ------------------------------------------------------------------
    // Private helpers
    // ------------------------------------------------------------------

    private fun goHome() {
        startActivity(Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        })
        finish()
    }

    /** Opens Rest For More (it comes back to the timer if the app is still open). */
    private fun openRestForMore() {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        if (launchIntent != null) {
            launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(launchIntent)
            finish()
        } else {
            goHome() // fallback if the app can't be launched
        }
    }

    private fun parseConfig(json: String): BlockScreenConfig {
        return try {
            val obj = JSONObject(json)
            BlockScreenConfig(
                title = if (obj.has("title") && !obj.isNull("title")) obj.getString("title") else "App Blocked",
                subtitle = if (obj.has("subtitle") && !obj.isNull("subtitle")) obj.getString("subtitle") else "This app is currently blocked.",
                message = if (obj.has("message") && !obj.isNull("message")) obj.getString("message") else "",
                backgroundColor = if (obj.has("backgroundColor") && !obj.isNull("backgroundColor")) obj.getLong("backgroundColor").toInt() else Color.BLACK,
                returnHomeButtonText = if (obj.has("returnHomeButtonText") && !obj.isNull("returnHomeButtonText")) obj.getString("returnHomeButtonText") else "Return to home",
                emergencyButtonText = if (obj.has("emergencyButtonText") && !obj.isNull("emergencyButtonText")) obj.getString("emergencyButtonText") else "Emergency Unlock",
                timerLabel = if (obj.has("timerLabel") && !obj.isNull("timerLabel")) obj.getString("timerLabel") else "{timeLeft} remaining",
            )
        } catch (_: Exception) {
            BlockScreenConfig()
        }
    }

    private data class BlockScreenConfig(
        val title: String = "App Blocked",
        val subtitle: String = "This app is currently blocked.",
        val message: String = "",
        val backgroundColor: Int = Color.BLACK,
        val returnHomeButtonText: String = "Return to home",
        val emergencyButtonText: String = "Emergency Unlock",
        val timerLabel: String = "{timeLeft} remaining",
    )


    /** Remaining time = session end time - now. Null if no session end is saved. */
    private fun getRemainingSessionMillis(): Long? {
        val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val endTime = flutterPrefs.getLong("flutter.sessionEndTimeMillis", 0L)
        if (endTime == 0L) return null
        return (endTime - System.currentTimeMillis()).coerceAtLeast(0L)
    }

    private fun formatRemaining(millis: Long): String {
        val totalSeconds = millis / 1000
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return String.format("%02d:%02d", minutes, seconds)
    }

    /** Session time is up: stop blocking and open the app the user wanted. */
    private fun endSession() {
        val prefs = BlockerPreferences(this)
        prefs.setIsBlocking(false)
        prefs.setBlockedApps(emptySet())
        prefs.setBlockAll(false)

        val launchIntent = blockedPackage?.let { packageManager.getLaunchIntentForPackage(it) }
        if (launchIntent != null) {
            launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(launchIntent)
            finish()
        } else {
            goHome()
        }
    }

    private fun startTimerUpdates(config: BlockScreenConfig) {
        stopTimerUpdates() // avoid two timers running at once
        val tick = object : Runnable {
            override fun run() {
                val remaining = getRemainingSessionMillis()
                when {
                    remaining == null -> timerTextView?.text = ""
                    remaining <= 0L -> endSession()
                    else -> {
                        timerTextView?.text =
                            config.timerLabel.replace("{timeLeft}", formatRemaining(remaining))
                        timerHandler.postDelayed(this, 1000)
                    }
                }
            }
        }
        timerRunnable = tick
        timerHandler.post(tick)
    }

    private fun stopTimerUpdates() {
        timerRunnable?.let { timerHandler.removeCallbacks(it) }
    }


    private fun buildLayout(config: BlockScreenConfig): FrameLayout {
        val root = FrameLayout(this).apply {
            setBackgroundColor(config.backgroundColor)
        }

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
        }

        val horizontalMargin = dpToPx(32f).toInt()
        root.addView(content, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.WRAP_CONTENT,
        ).apply {
            gravity = Gravity.CENTER
            setMargins(horizontalMargin, 0, horizontalMargin, 0)
        })

          content.addView(
            buildImage(R.drawable.happy_sheep),
            LinearLayout.LayoutParams(dpToPx(140f).toInt(), dpToPx(140f).toInt())
                .apply { bottomMargin = dpToPx(16f).toInt() }
        )

        content.addView(
            buildTextView(config.title, 28f, Typeface.BOLD),
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { bottomMargin = dpToPx(12f).toInt() }
        )

        content.addView(
            buildTextView(config.subtitle, 18f, Typeface.NORMAL),
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { bottomMargin = dpToPx(8f).toInt() }
        )

        if (config.message.isNotEmpty()) {
            content.addView(
                buildTextView(config.message, 14f, Typeface.NORMAL),
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                )
            )
        }

        val timerView = buildTextView("", 20f, Typeface.BOLD).apply {
            setTextColor(Color.WHITE)
        }
        timerTextView = timerView
        content.addView(
            timerView,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { bottomMargin = dpToPx(8f).toInt() }
        )

        content.addView(
            buildReturnHomeButton(config),
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dpToPx(24f).toInt() }
        )

        content.addView(
            buildEmergencyButton(config),
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dpToPx(24f).toInt() }
        )
        
        return root
    }

    private fun buildTextView(text: String, spSize: Float, style: Int): TextView {
        return TextView(this).apply {
            this.text = text
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, spSize)
            setTypeface(null, style)
            gravity = Gravity.CENTER
        }
    }

    private fun buildReturnHomeButton(config: BlockScreenConfig): TextView {
        return TextView(this).apply {
            text = config.returnHomeButtonText
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setTypeface(null, Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(dpToPx(16f).toInt(), dpToPx(8f).toInt(), dpToPx(16f).toInt(), dpToPx(8f).toInt())
            background = android.graphics.drawable.GradientDrawable().apply {
                setColor(Color.parseColor("#7B563D"))
                cornerRadius = dpToPx(24f)
            }
            setOnClickListener { openRestForMore() }
        }
    }

    private fun buildEmergencyButton(config: BlockScreenConfig): TextView {
        return TextView(this).apply {
            text = config.emergencyButtonText
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            paintFlags = paintFlags or Paint.UNDERLINE_TEXT_FLAG
            gravity = Gravity.CENTER
            setPadding(dpToPx(16f).toInt(), dpToPx(8f).toInt(), dpToPx(16f).toInt(), dpToPx(8f).toInt())
            setOnClickListener { onEmergencyUnlock() }
        }
    }

      private fun onEmergencyUnlock() {
        showConfirm()
    }

    private fun resolveAppName(packageName: String?): String {
        if (packageName == null) return ""
        return try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            appInfo.loadLabel(packageManager).toString()
        } catch (_: Exception) {
            packageName // fallback: show the raw package name if lookup fails
        }
    }

    private fun applyPlaceholders(text: String, appName: String): String {
        return text.replace("{appName}", appName)
    }


    private fun showBlocked() {
        val config = screenConfig ?: return
        setContentView(buildLayout(config))
        startTimerUpdates(config)
    }

    private fun showConfirm() {
        val config = screenConfig ?: return
        val label = if (profileName.isNotEmpty()) "$profileName session" else "session"
        setContentView(
            buildMessageScreen(
                config,
                R.drawable.surprized_sheep,
                "End your session early?",
                "This will end your $label early. Blocked apps will be available again immediately.",
                listOf(
                    buildButton("Never mind, stay focused", true) { showBlocked() },
                    buildButton("End session", false) { endSessionEarly() },
                ),
            )
        )
    }

    private fun showEnded() {
        val config = screenConfig ?: return
        val title = if (profileName.isNotEmpty()) "$profileName session ended early" else "Session ended early"
        setContentView(
            buildMessageScreen(
                config,
                R.drawable.dazed_sheep,
                title,
                "You can start a new session anytime.",
                listOf(buildButton("Back to profiles", true) { openRestForMore() }),
            )
        )
    }

    /** Emergency unlock: ends the WHOLE session, not just one app. */
    private fun endSessionEarly() {
        stopTimerUpdates()
        val prefs = BlockerPreferences(this)
        prefs.setIsBlocking(false)
        prefs.setBlockedApps(emptySet())
        prefs.setBlockAll(false)

        getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).edit()
            .remove("flutter.sessionEndTimeMillis")
            .remove("flutter.sessionProfileName")
            .remove("flutter.sessionProfileName")
            .remove("flutter.sessionProfileId")
            .remove("flutter.sessionBreakEndMillis")
            .remove("flutter.sessionPausesUsed")
            .remove("flutter.sessionPausesAllowed")
            .apply()

        blockedPackage?.let {
            BlockEventStreamHandler.sendEvent(
                mapOf("type" to "unblocked", "packageName" to it, "timestamp" to System.currentTimeMillis())
            )
        }
        showEnded()
    }

    private fun buildImage(resId: Int): ImageView = ImageView(this).apply {
        setImageResource(resId)
        adjustViewBounds = true
    }

    private fun buildButton(label: String, filled: Boolean, onClick: () -> Unit): TextView {
        return TextView(this).apply {
            text = label
            setTextColor(if (filled) Color.WHITE else Color.parseColor("#4E3B31"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setTypeface(null, Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(dpToPx(20f).toInt(), dpToPx(10f).toInt(), dpToPx(20f).toInt(), dpToPx(10f).toInt())
            background = android.graphics.drawable.GradientDrawable().apply {
                setColor(Color.parseColor(if (filled) "#7B563D" else "#D8B8A4"))
                cornerRadius = dpToPx(24f)
            }
            setOnClickListener { onClick() }
        }
    }

    private fun buildMessageScreen(
        config: BlockScreenConfig,
        imageRes: Int,
        title: String,
        body: String,
        buttons: List<View>,
    ): FrameLayout {
        timerTextView = null // no timer on these screens
        val root = FrameLayout(this).apply { setBackgroundColor(config.backgroundColor) }
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
        }
        val margin = dpToPx(32f).toInt()
        root.addView(content, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.WRAP_CONTENT,
        ).apply {
            gravity = Gravity.CENTER
            setMargins(margin, 0, margin, 0)
        })

        val size = dpToPx(140f).toInt()
        content.addView(buildImage(imageRes), LinearLayout.LayoutParams(size, size)
            .apply { bottomMargin = dpToPx(16f).toInt() })
        content.addView(buildTextView(title, 24f, Typeface.BOLD), LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT,
        ).apply { bottomMargin = dpToPx(12f).toInt() })
        content.addView(buildTextView(body, 16f, Typeface.NORMAL), LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT,
        ))
        buttons.forEach {
            content.addView(it, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dpToPx(20f).toInt() })
        }
        return root
    }

    private fun dpToPx(dp: Float): Float = dp * resources.displayMetrics.density
}

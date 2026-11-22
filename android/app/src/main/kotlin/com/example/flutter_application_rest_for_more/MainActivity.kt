package com.example.flutter_application_rest_for_more

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Draws the focus / break / routine countdown notification with our own
 * layout, so the time can be big. Flutter (TimerNotificationService) calls
 * show / cancel over a method channel; a tap goes back to Flutter with the
 * notification's link, also when the tap started the app.
 */
class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "rest_for_more/countdown_notification"

        // Same channel and id as the old notification, so it replaces it.
        private const val NOTIFICATION_CHANNEL_ID = "focus_countdown"
        private const val NOTIFICATION_ID = 100
        private const val EXTRA_LINK = "countdown_link"
    }

    private var channel: MethodChannel? = null

    /** The link of a tap that started the app; Flutter asks for it once. */
    private var launchLink: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        launchLink = intent?.getStringExtra(EXTRA_LINK)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "show" -> {
                    show(
                        title = call.argument<String>("title") ?: "",
                        subtitle = call.argument<String>("subtitle") ?: "",
                        endAtMillis = call.argument<Number>("endAtMillis")?.toLong() ?: 0L,
                        showTimer = call.argument<Boolean>("showTimer") ?: true,
                        link = call.argument<String>("link") ?: "",
                    )
                    result.success(null)
                }
                "cancel" -> {
                    notificationManager().cancel(NOTIFICATION_ID)
                    result.success(null)
                }
                "takeLaunchLink" -> {
                    result.success(launchLink)
                    launchLink = null
                }
                else -> result.notImplemented()
            }
        }
    }

    // A tap on the notification while the app is open or in the background.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.getStringExtra(EXTRA_LINK)?.let { channel?.invokeMethod("tapped", it) }
    }

    private fun notificationManager() = getSystemService(NotificationManager::class.java)

    private fun show(
        title: String,
        subtitle: String,
        endAtMillis: Long,
        showTimer: Boolean,
        link: String,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notificationManager().createNotificationChannel(
                NotificationChannel(
                    NOTIFICATION_CHANNEL_ID,
                    "Focus countdown",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "Shows the time left in a focus session, break or routine."
                    setShowBadge(false)
                }
            )
        }

        // The Chronometer counts against the phone's uptime clock.
        val remaining = endAtMillis - System.currentTimeMillis()
        val base = SystemClock.elapsedRealtime() + remaining

        fun views(layout: Int) = RemoteViews(packageName, layout).apply {
            setTextViewText(R.id.title, title)
            setTextViewText(R.id.subtitle, subtitle)
            if (showTimer) {
                setViewVisibility(R.id.timer, View.VISIBLE)
                setChronometer(R.id.timer, base, null, true)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    setChronometerCountDown(R.id.timer, true)
                }
            } else {
                // e.g. "Apps blocked until 8:15": just the text.
                setViewVisibility(R.id.timer, View.GONE)
            }
        }

        val tap = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(EXTRA_LINK, link)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setColor(0xFF9F755C.toInt()) // AppColors.lightBrown
            // Plain text for the lock screen, watches and older phones.
            .setContentTitle(title)
            .setContentText(subtitle)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(views(R.layout.countdown_notification_small))
            .setCustomBigContentView(views(R.layout.countdown_notification_big))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setShowWhen(false)
            .setContentIntent(tap)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            // Disappears 1 s after the end; the alarm takes over.
            .setTimeoutAfter(maxOf(1000L, remaining + 1000L))
            .build()

        notificationManager().notify(NOTIFICATION_ID, notification)
    }
}
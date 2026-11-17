package com.khanhtq.app_blocker.persistence

import android.content.Context

/**
 * End time of whatever is blocking right now, read from the Flutter app's
 * SharedPreferences ("FlutterSharedPreferences", keys prefixed "flutter.").
 *
 * - A focus session saves "sessionEndTimeMillis".
 * - A morning/evening routine saves "routineBlockedUntilMillis"
 *   (and "routineBlockName", e.g. "Morning routine").
 * They never run at the same time; focus wins if both are set.
 */
object SessionTimes {
    private const val PREFS = "FlutterSharedPreferences"
    private const val FOCUS_END = "flutter.sessionEndTimeMillis"
    private const val ROUTINE_END = "flutter.routineBlockedUntilMillis"
    private const val ROUTINE_NAME = "flutter.routineBlockName"
    private const val ROUTINE_STATE = "flutter.routineSession"

    /** Focus end time, otherwise the routine end time; 0 if neither. */
    fun endMillis(context: Context): Long {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val focus = prefs.getLong(FOCUS_END, 0L)
        return if (focus > 0L) focus else prefs.getLong(ROUTINE_END, 0L)
    }

    /** "Morning routine" while a routine blocks, otherwise null. */
    fun routineName(context: Context): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(ROUTINE_NAME, null)

    /** Emergency unlock: forget the routine, so the app sees it ended. */
    fun clearRoutine(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .remove(ROUTINE_END)
            .remove(ROUTINE_NAME)
            .remove(ROUTINE_STATE)
            .apply()
    }
}
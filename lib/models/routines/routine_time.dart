import 'package:flutter/material.dart';

// Small helpers for the times and durations used in routines.
// Times are stored as "HH:mm" (24-hour), durations as text like "15 min".

/// "21:30" → 21:30. Missing or broken parts become 0.
TimeOfDay parseTime24h(String value) {
  final parts = value.split(':');
  return TimeOfDay(
    hour: int.tryParse(parts.first) ?? 0,
    minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
  );
}

/// 9:05 → "09:05".
String formatTime24h(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Minutes since midnight, for comparing two times.
int minutesOfDay(TimeOfDay time) => time.hour * 60 + time.minute;

/// The first number in a duration text ("15 min" → 15), or null if there is none.
int? minutesInDuration(String duration) =>
    int.tryParse(RegExp(r'\d+').firstMatch(duration)?.group(0) ?? '');

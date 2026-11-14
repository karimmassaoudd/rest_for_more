import 'package:flutter/material.dart';

/// One activity in the evening routine editor, e.g. "Lezen" at 22:05 for 25 min.
///
/// Mutable on purpose: the editor changes the bedtime activity's [time]
/// in place when the user picks a new bedtime.
class Activity {
  Activity({
    required this.time,
    required this.name,
    required this.duration,
    required this.icon,
  });

  /// Start time, "HH:mm" (24-hour).
  String time;
  String name;

  /// Text like "15 min".
  String duration;
  IconData icon;
}

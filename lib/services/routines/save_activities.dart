import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/routines/activity.dart';
import '../../models/routines/default_evening_activities.dart';

// Re-exported so the routine editor can keep importing it from here.
export '../../models/routines/default_evening_activities.dart'
    show defaultRoutineSleepTime;

/// Storage for the routine editor: saves the chosen bedtime and hands out
/// the default evening activities.
class SaveActivities {
  const SaveActivities();

  static const _routineSleepTimeKey = 'routine_sleep_time';
  static const _activitiesKey = 'routine_evening_activities_v1';

  /// The saved bedtime ("HH:mm"), or [defaultRoutineSleepTime].
  Future<String> loadRoutineSleepTime() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_routineSleepTimeKey) ??
        defaultRoutineSleepTime;
  }

  Future<void> saveRoutineSleepTime(String time) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_routineSleepTimeKey, time);
  }

  /// Loads the user's saved activities, falling back to the starter routine.
  Future<List<Activity>> loadActivities() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_activitiesKey);
    if (raw == null) return defaultEveningActivities();
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((item) => _activityFromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return defaultEveningActivities();
    }
  }

  Future<void> saveActivities(Iterable<Activity> activities) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _activitiesKey,
      jsonEncode(activities.map(_activityToJson).toList()),
    );
  }

  Map<String, Object> _activityToJson(Activity activity) => {
    'time': activity.time,
    'name': activity.name,
    'duration': activity.duration,
    'iconCodePoint': activity.icon.codePoint,
  };

  Activity _activityFromJson(Map<String, dynamic> json) => Activity(
    time: json['time'] as String? ?? '00:00',
    name: json['name'] as String? ?? '',
    duration: json['duration'] as String? ?? '5 min',
    icon: _iconFor(json['iconCodePoint'] as int?),
  );

  IconData _iconFor(int? codePoint) {
    const icons = [
      Icons.self_improvement_outlined,
      Icons.menu_book_outlined,
      Icons.cleaning_services_outlined,
      Icons.shower_outlined,
      Icons.music_note_outlined,
      Icons.phone_disabled_outlined,
      Icons.directions_run_outlined,
      Icons.edit_outlined,
      Icons.sentiment_satisfied_alt_outlined,
      Icons.bed_outlined,
      Icons.checklist_rounded,
    ];
    return icons.firstWhere(
      (icon) => icon.codePoint == codePoint,
      orElse: () => Icons.self_improvement_outlined,
    );
  }

  /// A fresh copy of the default evening routine (the editor may change it).
  List<Activity> getActivities() => defaultEveningActivities();
}

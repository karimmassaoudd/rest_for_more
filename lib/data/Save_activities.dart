import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity.dart';

const defaultRoutineSleepTime = '22:30';

/// Loads and saves the sleep time and provides the default evening activities.
class SaveActivities {
  const SaveActivities();

  static const _routineSleepTimeKey = 'routine_sleep_time';

  Future<String> loadRoutineSleepTime() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_routineSleepTimeKey) ??
        defaultRoutineSleepTime;
  }

  Future<void> saveRoutineSleepTime(String time) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_routineSleepTimeKey, time);
  }

  List<Activity> getActivities() => [
    Activity(
      time: '21:30',
      name: 'Telefoon wegleggen',
      duration: '5 min',
      icon: Icons.phone_disabled_outlined,
    ),
    Activity(
      time: '21:35',
      name: 'Opruimen',
      duration: '10 min',
      icon: Icons.cleaning_services_outlined,
    ),
    Activity(
      time: '21:45',
      name: 'Douchen',
      duration: '15 min',
      icon: Icons.shower_outlined,
    ),
    Activity(
      time: '22:00',
      name: 'Tandenpoetsen',
      duration: '5 min',
      icon: Icons.sentiment_satisfied_alt_outlined,
    ),
    Activity(
      time: '22:05',
      name: 'Lezen',
      duration: '25 min',
      icon: Icons.menu_book_outlined,
    ),
    Activity(
      time: defaultRoutineSleepTime,
      name: 'Slapen',
      duration: '0 min',
      icon: Icons.bed_outlined,
    ),
  ];
}

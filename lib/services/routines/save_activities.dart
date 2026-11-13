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

  /// A fresh copy of the default evening routine (the editor may change it).
  List<Activity> getActivities() => defaultEveningActivities();
}

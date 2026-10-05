import 'package:shared_preferences/shared_preferences.dart';

import '../models/routine_step.dart';

class RoutineProgressStorage {
  const RoutineProgressStorage();

  static const _morningKey = 'routine_progress_morning';
  static const _eveningKey = 'routine_progress_evening';

  String _keyFor(RoutinePeriod period) => switch (period) {
    RoutinePeriod.morning => _morningKey,
    RoutinePeriod.evening => _eveningKey,
  };

  Future<Set<String>?> loadCompletedTasks(RoutinePeriod period) async {
    final preferences = await SharedPreferences.getInstance();
    final savedTitles = preferences.getStringList(_keyFor(period));
    return savedTitles?.toSet();
  }

  Future<void> saveCompletedTasks(
    RoutinePeriod period,
    Iterable<RoutineStep> steps,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final completedTitles = steps
        .where((step) => step.isCompleted)
        .map((step) => step.title)
        .toList();
    await preferences.setStringList(_keyFor(period), completedTitles);
  }
}

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/routines/routine_step.dart';

/// Remembers which routine steps the user ticked off, separately for the
/// morning and the evening routine.
///
/// Steps are saved by their title, so renaming a step "unticks" it.
class RoutineProgressStorage {
  const RoutineProgressStorage();

  static const _morningKey = 'routine_progress_morning';
  static const _eveningKey = 'routine_progress_evening';

  String _keyFor(RoutinePeriod period) => switch (period) {
    RoutinePeriod.morning => _morningKey,
    RoutinePeriod.evening => _eveningKey,
  };

  /// Titles of the completed steps, or null if nothing was saved yet.
  Future<Set<String>?> loadCompletedTasks(RoutinePeriod period) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_keyFor(period))?.toSet();
  }

  /// Saves the titles of the completed [steps] (replaces what was saved).
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

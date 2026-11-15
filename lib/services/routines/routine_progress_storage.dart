import 'dart:convert';

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
  static const _historyKey = 'routine_history_v1';

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

  Future<List<RoutineDayRecord>> loadHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_historyKey);
    if (raw == null) return [];
    try {
      final records = (jsonDecode(raw) as List<dynamic>)
          .map(
            (value) => RoutineDayRecord.fromJson(value as Map<String, dynamic>),
          )
          .toList();
      records.sort((a, b) => a.date.compareTo(b.date));
      return records;
    } on FormatException {
      return [];
    }
  }

  Future<void> saveToday({
    required Iterable<RoutineStep> morningSteps,
    required Iterable<RoutineStep> eveningSteps,
    DateTime? now,
  }) => saveDay(
    RoutineDayRecord(
      date: _dateKey(now ?? DateTime.now()),
      morningCompleted: morningSteps.where((step) => step.isCompleted).length,
      morningTotal: morningSteps.length,
      eveningCompleted: eveningSteps.where((step) => step.isCompleted).length,
      eveningTotal: eveningSteps.length,
    ),
  );

  Future<void> saveDay(RoutineDayRecord record) async {
    final records = await loadHistory();
    records.removeWhere((item) => item.date == record.date);
    records.add(record);
    records.sort((a, b) => a.date.compareTo(b.date));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _historyKey,
      jsonEncode(records.map((item) => item.toJson()).toList()),
    );
  }

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

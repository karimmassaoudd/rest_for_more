import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/routines/routine_step.dart';

/// Remembers which routine steps the user ticked off today, separately for
/// the morning and the evening routine, and keeps one history record per day.
///
/// A "routine day" starts at 04:00 ([progressDay]), so an evening routine
/// that runs past midnight still counts for the evening it started. The
/// ticks are saved together with their day; RoutineScreen clears them when
/// a new day has started.
///
/// Steps are saved by their title, so renaming a step "unticks" it.
class RoutineProgressStorage {
  const RoutineProgressStorage();

  static const _morningKey = 'routine_progress_morning';
  static const _eveningKey = 'routine_progress_evening';
  static const _dayKey = 'routine_progress_day';
  static const _historyKey = 'routine_history_v1';

  /// Hour at which a new routine day starts.
  static const dayStartHour = 4;

  String _keyFor(RoutinePeriod period) => switch (period) {
    RoutinePeriod.morning => _morningKey,
    RoutinePeriod.evening => _eveningKey,
  };

  /// "2026-11-17" for [time]; before 04:00 it's still the previous day.
  String progressDay(DateTime time) =>
      _dateKey(time.subtract(const Duration(hours: dayStartHour)));

  /// The routine day the saved ticks belong to, or null if none were saved.
  Future<String?> savedDay() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_dayKey);
  }

  /// Titles of the completed steps, or null if nothing was saved yet.
  Future<Set<String>?> loadCompletedTasks(RoutinePeriod period) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_keyFor(period))?.toSet();
  }

  /// Saves the titles of the completed [steps] (replaces what was saved),
  /// for today's routine day.
  Future<void> saveCompletedTasks(
    RoutinePeriod period,
    Iterable<RoutineStep> steps, {
    DateTime? now,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final completedTitles = steps
        .where((step) => step.isCompleted)
        .map((step) => step.title)
        .toList();
    await preferences.setStringList(_keyFor(period), completedTitles);
    await preferences.setString(_dayKey, progressDay(now ?? DateTime.now()));
  }

  /// A new day started: forget both routines' ticks. The previous day is
  /// already in the history, because [saveToday] runs on every change.
  Future<void> clearTicks({DateTime? now}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_morningKey);
    await preferences.remove(_eveningKey);
    await preferences.setString(_dayKey, progressDay(now ?? DateTime.now()));
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

  /// Writes today's record: the counts, plus every step and whether it was
  /// done (so the Progress tab can later show which steps, and when a
  /// routine changed).
  Future<void> saveToday({
    required Iterable<RoutineStep> morningSteps,
    required Iterable<RoutineStep> eveningSteps,
    DateTime? now,
  }) => saveDay(
    RoutineDayRecord(
      date: progressDay(now ?? DateTime.now()),
      morningCompleted: morningSteps.where((step) => step.isCompleted).length,
      morningTotal: morningSteps.length,
      eveningCompleted: eveningSteps.where((step) => step.isCompleted).length,
      eveningTotal: eveningSteps.length,
      morningSteps: _results(morningSteps),
      eveningSteps: _results(eveningSteps),
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

  static List<RoutineStepResult> _results(Iterable<RoutineStep> steps) => [
    for (final step in steps)
      RoutineStepResult(title: step.title, done: step.isCompleted),
  ];

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

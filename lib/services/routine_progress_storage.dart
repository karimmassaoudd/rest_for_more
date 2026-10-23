import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/routine_step.dart';

class RoutineProgressStorage {
  const RoutineProgressStorage();

  static const _morningKey = 'routine_progress_morning';
  static const _eveningKey = 'routine_progress_evening';
  static const _morningStepsKey = 'routine_steps_morning_v1';
  static const _eveningStepsKey = 'routine_steps_evening_v1';
  static const _historyKey = 'routine_history_v1';

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

  String _stepsKeyFor(RoutinePeriod period) => switch (period) {
    RoutinePeriod.morning => _morningStepsKey,
    RoutinePeriod.evening => _eveningStepsKey,
  };

  Future<List<RoutineStep>?> loadSteps(RoutinePeriod period) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_stepsKeyFor(period));
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => RoutineStep.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSteps(RoutinePeriod period, List<RoutineStep> steps) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _stepsKeyFor(period),
      jsonEncode(steps.map((step) => step.toJson()).toList()),
    );
  }

  Future<List<RoutineDayRecord>> loadHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_historyKey);
    if (raw == null) return <RoutineDayRecord>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    final records = decoded
        .map((item) => RoutineDayRecord.fromJson(item as Map<String, dynamic>))
        .toList();
    records.sort((a, b) => a.date.compareTo(b.date));
    return records;
  }

  Future<void> saveToday({
    required List<RoutineStep> morningSteps,
    required List<RoutineStep> eveningSteps,
    DateTime? now,
  }) async {
    final date = _dateKey(now ?? DateTime.now());
    final records = await loadHistory();
    records.removeWhere((record) => record.date == date);
    records.add(
      RoutineDayRecord(
        date: date,
        morningCompleted: morningSteps.where((step) => step.isCompleted).length,
        morningTotal: morningSteps.length,
        eveningCompleted: eveningSteps.where((step) => step.isCompleted).length,
        eveningTotal: eveningSteps.length,
      ),
    );
    records.sort((a, b) => a.date.compareTo(b.date));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _historyKey,
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

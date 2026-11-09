import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/routine_step.dart';
import 'routine_cloud_storage.dart';

class RoutineProgressStorage {
  const RoutineProgressStorage({
    this.cloudStorage = const RoutineCloudStorage(),
  });

  final RoutineCloudStorage cloudStorage;

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
    final local = raw == null
        ? null
        : (jsonDecode(raw) as List<dynamic>)
              .map((item) => RoutineStep.fromJson(item as Map<String, dynamic>))
              .toList();
    try {
      final cloud = await cloudStorage.loadSteps(period);
      if (cloud != null) {
        await _saveStepsLocally(period, cloud);
        return cloud;
      }
    } catch (_) {
      // The local copy keeps the routine available while Firebase is offline.
    }
    return local;
  }

  Future<void> saveSteps(RoutinePeriod period, List<RoutineStep> steps) async {
    await _saveStepsLocally(period, steps);
    try {
      await cloudStorage.saveSteps(period, steps);
    } catch (_) {
      // Local persistence is the offline fallback.
    }
  }

  Future<void> _saveStepsLocally(
    RoutinePeriod period,
    List<RoutineStep> steps,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _stepsKeyFor(period),
      jsonEncode(steps.map((step) => step.toJson()).toList()),
    );
  }

  Future<List<RoutineDayRecord>> loadHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_historyKey);
    final local = raw == null
        ? <RoutineDayRecord>[]
        : (jsonDecode(raw) as List<dynamic>)
              .map(
                (item) =>
                    RoutineDayRecord.fromJson(item as Map<String, dynamic>),
              )
              .toList();
    try {
      final cloud = await cloudStorage.loadHistory();
      if (cloud.isNotEmpty) {
        await _saveHistoryLocally(cloud);
        return cloud;
      }
    } catch (_) {
      // Return the device copy if cloud sync is unavailable.
    }
    local.sort((a, b) => a.date.compareTo(b.date));
    return local;
  }

  Future<void> saveToday({
    required List<RoutineStep> morningSteps,
    required List<RoutineStep> eveningSteps,
    DateTime? now,
  }) async {
    final date = _dateKey(now ?? DateTime.now());
    final records = await loadHistory();
    records.removeWhere((record) => record.date == date);
    final record = RoutineDayRecord(
      date: date,
      morningCompleted: morningSteps.where((step) => step.isCompleted).length,
      morningTotal: morningSteps.length,
      eveningCompleted: eveningSteps.where((step) => step.isCompleted).length,
      eveningTotal: eveningSteps.length,
    );
    records.add(record);
    records.sort((a, b) => a.date.compareTo(b.date));
    await _saveHistoryLocally(records);
    try {
      await cloudStorage.saveDay(record);
    } catch (_) {
      // The record remains saved on this device and can be retried later.
    }
  }

  Future<void> saveDay(RoutineDayRecord record) async {
    final records = await loadHistory();
    records.removeWhere((item) => item.date == record.date);
    records.add(record);
    records.sort((a, b) => a.date.compareTo(b.date));
    await _saveHistoryLocally(records);
    try {
      await cloudStorage.saveDay(record);
    } catch (_) {
      // The record remains available locally when cloud sync is unavailable.
    }
  }

  Future<void> _saveHistoryLocally(List<RoutineDayRecord> records) async {
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

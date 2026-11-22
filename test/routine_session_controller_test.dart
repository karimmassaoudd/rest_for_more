import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_rest_for_more/models/routines/routine_step.dart';
import 'package:flutter_application_rest_for_more/services/routines/routine_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The running routine: activity timer, pause/resume, the blocking end time,
/// and saving/restoring. The app_blocker plugin isn't there in tests, so no
/// profile is found and nothing gets blocked (isBlockingApps stays false).
void main() {
  final session = RoutineSessionController.instance;
  const minute = 60000;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    session.resetForTest();
  });
  tearDown(session.resetForTest);

  /// A context for startStep (it only needs one to ask for permission).
  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    return context;
  }

  /// Runs with real time, because the controller saves and reads the clock.
  Future<RoutineStartResult> start(
    WidgetTester tester,
    BuildContext context, {
    RoutinePeriod period = RoutinePeriod.morning,
    String step = 'Stretch',
    int stepMinutes = 10,
    int openMinutes = 30,
  }) async {
    final result = await tester.runAsync(
      () => session.startStep(
        context,
        period: period,
        step: step,
        stepMinutes: stepMinutes,
        openMinutes: openMinutes,
      ),
    );
    return result!;
  }

  testWidgets('starting an activity starts the routine and its timer', (
    tester,
  ) async {
    final context = await pumpContext(tester);
    final before = DateTime.now();
    final result = await start(tester, context);
    final after = DateTime.now();

    expect(result, RoutineStartResult.started);
    expect(session.isRunningFor(RoutinePeriod.morning), isTrue);
    expect(session.isRunningFor(RoutinePeriod.evening), isFalse);
    expect(session.activeStep, 'Stretch');
    expect(session.isPaused, isFalse);
    expect(session.stepTotalMillis, 10 * minute);
    expect(session.stepRemainingMillis, closeTo(10 * minute, 2000));

    // 30 open minutes + 30 phone-free minutes.
    final until = session.blockedUntil!;
    expect(until.isBefore(before.add(const Duration(minutes: 60))), isFalse);
    expect(until.isAfter(after.add(const Duration(minutes: 60))), isFalse);

    // No profile with apps in tests, so nothing is blocked.
    expect(session.isBlockingApps, isFalse);
  });

  testWidgets('the blocking end time only ever moves later', (tester) async {
    final context = await pumpContext(tester);

    await start(tester, context, step: 'A', openMinutes: 45);
    final first = session.blockedUntil!;

    // Fewer open minutes left: the end time stays.
    await start(tester, context, step: 'B', openMinutes: 5);
    expect(session.blockedUntil, first);
    expect(session.activeStep, 'B');

    // More open minutes: the end time moves later.
    await start(tester, context, step: 'C', openMinutes: 120);
    expect(session.blockedUntil!.isAfter(first), isTrue);
  });

  testWidgets('opening the running activity again keeps its timer', (
    tester,
  ) async {
    final context = await pumpContext(tester);
    await start(tester, context);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1200)),
    );

    await start(tester, context);
    expect(session.stepRemainingMillis, lessThan(10 * minute - 1000));
  });

  testWidgets('pausing keeps the time left; resuming continues', (
    tester,
  ) async {
    final context = await pumpContext(tester);
    await start(tester, context);

    await tester.runAsync(session.pauseStep);
    expect(session.isPaused, isTrue);
    final left = session.stepRemainingMillis;

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    expect(session.stepRemainingMillis, left);

    await tester.runAsync(session.resumeStep);
    expect(session.isPaused, isFalse);
    expect(session.stepRemainingMillis, closeTo(left, 1000));
  });

  testWidgets('completing an activity stops its timer, not the routine', (
    tester,
  ) async {
    final context = await pumpContext(tester);
    await start(tester, context);

    // Another activity's title: nothing changes.
    await tester.runAsync(() => session.completeStep('Shower'));
    expect(session.activeStep, 'Stretch');

    await tester.runAsync(() => session.completeStep('Stretch'));
    expect(session.activeStep, isNull);
    expect(session.stepRemainingMillis, 0);
    // The phone-free time keeps going.
    expect(session.isRunningFor(RoutinePeriod.morning), isTrue);
  });

  testWidgets('done when the routine screen reports nothing left', (
    tester,
  ) async {
    final context = await pumpContext(tester);
    await start(tester, context);

    session.reportStepsLeft(RoutinePeriod.evening, 0); // other routine
    expect(session.isDone, isFalse);
    session.reportStepsLeft(RoutinePeriod.morning, 1);
    expect(session.isDone, isFalse);
    session.reportStepsLeft(RoutinePeriod.morning, 0);
    expect(session.isDone, isTrue);
  });

  testWidgets("doesn't start while a focus session runs", (tester) async {
    SharedPreferences.setMockInitialValues({
      'sessionEndTimeMillis': DateTime.now()
          .add(const Duration(minutes: 10))
          .millisecondsSinceEpoch,
    });
    final context = await pumpContext(tester);

    expect(await start(tester, context), RoutineStartResult.focusRunning);
    expect(session.isActive, isFalse);
  });

  testWidgets("doesn't start while the other routine runs", (tester) async {
    final context = await pumpContext(tester);
    await start(tester, context, period: RoutinePeriod.morning);

    expect(
      await start(tester, context, period: RoutinePeriod.evening),
      RoutineStartResult.otherRoutineRunning,
    );
    expect(session.isRunningFor(RoutinePeriod.morning), isTrue);
  });

  testWidgets('a running routine is restored after a restart', (tester) async {
    final context = await pumpContext(tester);
    await start(tester, context);

    // Forget everything in memory, like closing the app. The save stays.
    session.resetForTest();
    expect(session.isActive, isFalse);

    await tester.runAsync(session.restore);
    expect(session.isRunningFor(RoutinePeriod.morning), isTrue);
    expect(session.activeStep, 'Stretch');
  });

  testWidgets('a routine whose time is over is cleaned up on restore', (
    tester,
  ) async {
    final past = DateTime.now().millisecondsSinceEpoch - 1000;
    SharedPreferences.setMockInitialValues({
      'routineSession': jsonEncode({
        'period': 'morning',
        'blockedUntil': past,
        'blocking': true,
      }),
      'routineBlockedUntilMillis': past,
      'routineBlockName': 'Morning routine',
    });

    await tester.runAsync(session.restore);

    expect(session.isActive, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('routineSession'), isNull);
    expect(prefs.getInt('routineBlockedUntilMillis'), isNull);
    expect(prefs.getString('routineBlockName'), isNull);
  });

  testWidgets('Emergency Unlock (save removed by the plugin) ends it', (
    tester,
  ) async {
    final context = await pumpContext(tester);
    await start(tester, context);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('routineSession');
    await tester.runAsync(session.restore);

    expect(session.isActive, isFalse);
    expect(session.activeStep, isNull);
  });
}

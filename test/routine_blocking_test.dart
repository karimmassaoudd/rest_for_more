import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_rest_for_more/models/routines/routine_step.dart';
import 'package:flutter_application_rest_for_more/services/routines/routine_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_app_blocker.dart';

/// Blocking during a routine, with a fake app_blocker plugin: which apps
/// get blocked, what the plugin is told, and when they're unblocked.
void main() {
  final session = RoutineSessionController.instance;
  final blocker = FakeAppBlocker();
  const youtube = 'com.google.android.youtube';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    session.resetForTest();
    blocker.install();
  });
  tearDown(() {
    session.resetForTest();
    blocker.uninstall();
  });

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

  Future<void> startMorning(
    WidgetTester tester,
    BuildContext context, {
    String step = 'Stretch',
  }) async {
    await tester.runAsync(
      () => session.startStep(
        context,
        period: RoutinePeriod.morning,
        step: step,
        stepMinutes: 10,
        openMinutes: 30,
      ),
    );
  }

  /// A saved morning routine whose time ran out a second ago.
  void savedExpiredRoutine() {
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
  }

  testWidgets("the first activity blocks the morning profile's apps", (
    tester,
  ) async {
    blocker.profiles['morning'] = [youtube];
    final context = await pumpContext(tester);

    await startMorning(tester, context);

    expect(session.isBlockingApps, isTrue);
    expect(blocker.lastArguments('blockApps')?['identifiers'], [youtube]);
    expect(
      blocker.lastArguments('setBlockScreenConfig')?['subtitle'],
      'Morning routine in progress',
    );

    // What the plugin reads for the countdown and Emergency Unlock.
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getInt('routineBlockedUntilMillis'),
      session.blockedUntil!.millisecondsSinceEpoch,
    );
    expect(prefs.getString('routineBlockName'), 'Morning routine');
  });

  testWidgets('no apps in the profile: no permission asked, nothing blocked', (
    tester,
  ) async {
    blocker.profiles['morning'] = [];
    final context = await pumpContext(tester);

    await startMorning(tester, context);

    expect(session.isRunningFor(RoutinePeriod.morning), isTrue);
    expect(session.isBlockingApps, isFalse);
    expect(blocker.methods, isNot(contains('checkPermission')));
    expect(blocker.methods, isNot(contains('blockApps')));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('routineBlockedUntilMillis'), isNull);
  });

  testWidgets('permission refused: the routine runs without blocking', (
    tester,
  ) async {
    blocker.profiles['morning'] = [youtube];
    blocker.permissionGranted = false;
    final context = await pumpContext(tester);

    await startMorning(tester, context);

    expect(session.isRunningFor(RoutinePeriod.morning), isTrue);
    expect(session.isBlockingApps, isFalse);
    expect(blocker.methods, isNot(contains('blockApps')));
  });

  testWidgets('Turn on later blocks for the rest of the routine', (
    tester,
  ) async {
    blocker.profiles['morning'] = [];
    final context = await pumpContext(tester);
    await startMorning(tester, context);
    expect(session.isBlockingApps, isFalse);

    // The user chose apps from the "No apps are blocked" hint.
    blocker.profiles['morning'] = [youtube];
    await tester.runAsync(() => session.retryBlocking(context));

    expect(session.isBlockingApps, isTrue);
    expect(blocker.lastArguments('blockApps')?['identifiers'], [youtube]);
  });

  testWidgets("ticking every activity doesn't unblock early", (tester) async {
    blocker.profiles['morning'] = [youtube];
    final context = await pumpContext(tester);
    await startMorning(tester, context);

    await tester.runAsync(() => session.completeStep('Stretch'));
    session.reportStepsLeft(RoutinePeriod.morning, 0);

    expect(session.isDone, isTrue);
    expect(session.isBlockingApps, isTrue);
    expect(blocker.methods, isNot(contains('unblockAll')));
  });

  testWidgets('the next activity keeps blocking and updates the block screen', (
    tester,
  ) async {
    blocker.profiles['morning'] = [youtube];
    final context = await pumpContext(tester);
    await startMorning(tester, context, step: 'Stretch');
    blocker.calls.clear();

    await startMorning(tester, context, step: 'Shower');

    expect(session.isBlockingApps, isTrue);
    expect(blocker.methods, contains('setBlockScreenConfig'));
    // Already blocking: no second permission check or block call.
    expect(blocker.methods, isNot(contains('checkPermission')));
    expect(blocker.methods, isNot(contains('blockApps')));
  });

  testWidgets('unblocks once the time is over', (tester) async {
    savedExpiredRoutine();

    await tester.runAsync(session.restore);

    expect(blocker.methods, contains('unblockAll'));
    expect(session.isActive, isFalse);
  });

  testWidgets("doesn't unblock while a focus session runs", (tester) async {
    savedExpiredRoutine();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'sessionEndTimeMillis',
      DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
    );

    await tester.runAsync(session.restore);

    expect(blocker.methods, isNot(contains('unblockAll')));
    expect(session.isActive, isFalse);
  });
}

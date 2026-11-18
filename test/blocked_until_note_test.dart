import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_rest_for_more/models/routines/routine_step.dart';
import 'package:flutter_application_rest_for_more/services/routines/routine_session_controller.dart';
import 'package:flutter_application_rest_for_more/theme/app_theme.dart';
import 'package:flutter_application_rest_for_more/widgets/routines/blocked_until_note.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final session = RoutineSessionController.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    session.resetForTest();
  });
  tearDown(session.resetForTest);

  Future<void> pumpNote(WidgetTester tester, RoutinePeriod period) =>
      tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(body: BlockedUntilNote(period: period)),
        ),
      );

  /// A morning routine that runs for another 45 minutes, loaded like after
  /// a restart.
  Future<void> runMorningRoutine(
    WidgetTester tester, {
    required bool blocking,
  }) async {
    SharedPreferences.setMockInitialValues({
      'routineSession': jsonEncode({
        'period': 'morning',
        'blockedUntil': DateTime.now()
            .add(const Duration(minutes: 45))
            .millisecondsSinceEpoch,
        'blocking': blocking,
      }),
    });
    await tester.runAsync(session.restore);
    await tester.pump();
  }

  testWidgets('hidden when no routine runs', (tester) async {
    await pumpNote(tester, RoutinePeriod.morning);
    expect(find.byKey(const Key('blocked-until-note')), findsNothing);
    expect(find.byKey(const Key('blocking-off-note')), findsNothing);
  });

  testWidgets('hidden on the other routine', (tester) async {
    await pumpNote(tester, RoutinePeriod.evening);
    await runMorningRoutine(tester, blocking: true);
    expect(find.byKey(const Key('blocked-until-note')), findsNothing);
  });

  testWidgets('says so and offers Turn on when nothing is blocked', (
    tester,
  ) async {
    await pumpNote(tester, RoutinePeriod.morning);
    await runMorningRoutine(tester, blocking: false);

    expect(find.byKey(const Key('blocking-off-note')), findsOneWidget);
    expect(
      find.text('No apps are blocked during this routine.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('turn-on-blocking-button')), findsOneWidget);
  });

  testWidgets('shows until when apps stay blocked', (tester) async {
    await pumpNote(tester, RoutinePeriod.morning);
    await runMorningRoutine(tester, blocking: true);

    expect(find.byKey(const Key('blocked-until-note')), findsOneWidget);
    expect(find.textContaining('Apps stay blocked until'), findsOneWidget);
    expect(
      find.textContaining('so you can start your day without your phone.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('turn-on-blocking-button')), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_rest_for_more/models/routines/routine_step.dart';
import 'package:flutter_application_rest_for_more/screens/routines/routine_screen.dart';
import 'package:flutter_application_rest_for_more/services/routines/routine_progress_storage.dart';
import 'package:flutter_application_rest_for_more/services/routines/routine_session_controller.dart';
import 'package:flutter_application_rest_for_more/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // The default morning routine has 5 steps; none start done.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RoutineSessionController.instance.resetForTest();
  });

  Future<void> pumpMorning(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const RoutineScreen(period: RoutinePeriod.morning),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> swipeRight(WidgetTester tester, String title) async {
    final card = find.text(title);
    await tester.ensureVisible(card);
    await tester.drag(card, const Offset(500, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('a new user starts with nothing ticked', (tester) async {
    await pumpMorning(tester);
    expect(find.text('0/5'), findsOneWidget);
  });

  testWidgets('tapping a step opens it without ticking it', (tester) async {
    await pumpMorning(tester);

    final step = find.text('Matcha & Intention Journal');
    await tester.ensureVisible(step);
    await tester.tap(step);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // page transition

    final title = tester.widget<Text>(
      find.byKey(const Key('routine-flow-step-title')),
    );
    expect(title.data, 'Matcha & Intention Journal');
    expect(find.text('0/5', skipOffstage: false), findsOneWidget);
  });

  testWidgets('swiping ticks a step and Undo reverts it', (tester) async {
    await pumpMorning(tester);

    await swipeRight(tester, 'Matcha & Intention Journal');
    expect(find.text('1/5'), findsOneWidget);
    final undo = find.widgetWithText(SnackBarAction, 'Undo');
    expect(undo, findsOneWidget);

    await tester.tap(undo);
    await tester.pumpAndSettle();
    expect(find.text('0/5'), findsOneWidget);
  });

  testWidgets('swiping a done step unticks it', (tester) async {
    await pumpMorning(tester);

    await swipeRight(tester, 'Cold Water & Electrolytes');
    expect(find.text('1/5'), findsOneWidget);
    // The other direction works too.
    final card = find.text('Cold Water & Electrolytes');
    await tester.drag(card, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('0/5'), findsOneWidget);
  });

  testWidgets('ticks from an earlier day are cleared', (tester) async {
    SharedPreferences.setMockInitialValues({
      'routine_progress_morning': ['Cold Water & Electrolytes'],
      'routine_progress_day': '2000-01-01',
    });
    await pumpMorning(tester);
    expect(find.text('0/5'), findsOneWidget);
  });

  testWidgets('ticks from today are kept', (tester) async {
    SharedPreferences.setMockInitialValues({
      'routine_progress_morning': ['Cold Water & Electrolytes'],
      'routine_progress_day': const RoutineProgressStorage().progressDay(
        DateTime.now(),
      ),
    });
    await pumpMorning(tester);
    expect(find.text('1/5'), findsOneWidget);
  });

  testWidgets('tapping the circle ticks a step', (tester) async {
    await pumpMorning(tester);
    final circle = find.byKey(const Key('routine-step-done-3'));
    await tester.ensureVisible(circle);
    await tester.tap(circle);
    await tester.pumpAndSettle();
    expect(find.text('1/5'), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, 'Undo'), findsOneWidget);
  });
}

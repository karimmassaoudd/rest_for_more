import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_rest_for_more/models/routines/routine_step.dart';
import 'package:flutter_application_rest_for_more/screens/routines/routine_screen.dart';
import 'package:flutter_application_rest_for_more/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_rest_for_more/services/routines/routine_session_controller.dart';

void main() {
  // The default morning routine has 5 steps; the first 3 start done.
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

  testWidgets('tapping a step opens it without ticking it', (tester) async {
    await pumpMorning(tester);
    expect(find.text('3/5'), findsOneWidget);

    final step = find.text('Matcha & Intention Journal');
    await tester.ensureVisible(step);
    await tester.tap(step);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // page transition

    final title = tester.widget<Text>(
      find.byKey(const Key('routine-flow-step-title')),
    );
    expect(title.data, 'Matcha & Intention Journal');
    expect(find.text('3/5', skipOffstage: false), findsOneWidget);
  });

  testWidgets('swiping ticks a step and Undo reverts it', (tester) async {
    await pumpMorning(tester);

    await swipeRight(tester, 'Matcha & Intention Journal');
    expect(find.text('4/5'), findsOneWidget);
    final undo = find.widgetWithText(SnackBarAction, 'Undo');
    expect(undo, findsOneWidget);

    await tester.tap(undo);
    await tester.pumpAndSettle();
    expect(find.text('3/5'), findsOneWidget);
  });

  testWidgets('swiping a done step unticks it', (tester) async {
    await pumpMorning(tester);

    await swipeRight(tester, 'Cold Water & Electrolytes');
    expect(find.text('2/5'), findsOneWidget);
  });
}

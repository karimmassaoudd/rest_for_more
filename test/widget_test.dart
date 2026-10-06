import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest_for_more/main.dart';
import 'package:rest_for_more/models/routine_step.dart';
import 'package:rest_for_more/screens/focus_mode_screen.dart';
import 'package:rest_for_more/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('morning progress updates when active step is checked', (
    tester,
  ) async {
    await tester.pumpWidget(const RestForMeApp());

    expect(find.byKey(const ValueKey('header-morning')), findsOneWidget);
    expect(find.text('Your morning'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('2 steps remaining'), findsOneWidget);

    final activeCheck = find.byKey(const Key('check-button-3'));
    await tester.ensureVisible(activeCheck);
    await tester.tap(activeCheck);
    await tester.pumpAndSettle();

    expect(find.text('4/5'), findsOneWidget);
    expect(find.text('1 step remaining'), findsOneWidget);
    expect(find.text('Done'), findsNWidgets(4));
  });

  testWidgets('evening mode has independent routine state', (tester) async {
    await tester.pumpWidget(const RestForMeApp());

    final eveningSwitch = find.byKey(const Key('evening-switch'));
    await tester.ensureVisible(eveningSwitch);
    await tester.tap(eveningSwitch);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('header-evening')), findsOneWidget);
    expect(find.text('I WANT TO SLEEP AT'), findsOneWidget);
    expect(find.text('10:30 PM'), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);
    expect(find.text('5 steps remaining'), findsOneWidget);

    final firstEveningStep = find.byKey(const Key('routine-toggle-0'));
    await tester.ensureVisible(firstEveningStep);
    await tester.tap(firstEveningStep);
    await tester.pumpAndSettle();

    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('4 steps remaining'), findsOneWidget);
  });

  testWidgets('morning and evening progress persists independently', (
    tester,
  ) async {
    await tester.pumpWidget(const RestForMeApp());
    await tester.pumpAndSettle();

    final morningTask = find.byKey(const Key('check-button-3'));
    await tester.ensureVisible(morningTask);
    await tester.tap(morningTask);
    await tester.pumpAndSettle();
    final restoredEveningSwitch = find.byKey(const Key('evening-switch'));
    await tester.ensureVisible(restoredEveningSwitch);
    await tester.tap(restoredEveningSwitch);
    await tester.pumpAndSettle();
    final eveningTask = find.byKey(const Key('routine-toggle-0'));
    await tester.ensureVisible(eveningTask);
    await tester.tap(eveningTask);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const RestForMeApp());
    await tester.pumpAndSettle();

    expect(find.text('4/5'), findsOneWidget);
    final savedEveningSwitch = find.byKey(const Key('evening-switch'));
    await tester.ensureVisible(savedEveningSwitch);
    await tester.tap(savedEveningSwitch);
    await tester.pumpAndSettle();
    expect(find.text('1/5'), findsOneWidget);
  });

  testWidgets('current and next tasks update after completion', (tester) async {
    await tester.pumpWidget(const RestForMeApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('current-task')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('current-task'))).data,
      'Matcha & Intention Journal',
    );
    expect(find.byKey(const Key('next-task')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('next-task'))).data,
      'Daily Priority Alignment',
    );

    final activeTask = find.byKey(const Key('check-button-3'));
    await tester.ensureVisible(activeTask);
    await tester.tap(activeTask);
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('current-task'))).data,
      'Daily Priority Alignment',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('next-task'))).data,
      'Routine complete',
    );
  });

  testWidgets('finishing morning automatically opens evening routine', (
    tester,
  ) async {
    await tester.pumpWidget(const RestForMeApp());

    final fourthStep = find.byKey(const Key('routine-toggle-3'));
    await tester.ensureVisible(fourthStep);
    await tester.tap(fourthStep);
    await tester.pumpAndSettle();
    final fifthStep = find.byKey(const Key('routine-toggle-4'));
    await tester.ensureVisible(fifthStep);
    await tester.tap(fifthStep);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('5/5'), findsOneWidget);
    expect(find.text('0 steps remaining'), findsOneWidget);
    expect(find.text('Morning Routine Complete'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('header-evening')), findsOneWidget);
    expect(find.text('I WANT TO SLEEP AT'), findsOneWidget);
  });

  testWidgets('focus mode opens and completes the active step', (tester) async {
    await tester.pumpWidget(const RestForMeApp());

    final focusButton = find.byKey(const Key('focus-mode-button'));
    await tester.ensureVisible(focusButton);
    await tester.tap(focusButton);
    await tester.pumpAndSettle();

    expect(find.text('FOCUS MODE'), findsOneWidget);
    expect(find.text('Matcha & Intention Journal'), findsOneWidget);
    expect(find.text('Next task: Daily Priority Alignment'), findsOneWidget);
    expect(find.byKey(const Key('focus-timer')), findsOneWidget);

    await tester.tap(find.byKey(const Key('complete-focus-step-button')));
    await tester.pumpAndSettle();

    expect(find.text('4/5'), findsOneWidget);
    expect(find.text('1 step remaining'), findsOneWidget);
  });

  testWidgets('focus timer clearly waits for confirmation at 00:00', (
    tester,
  ) async {
    const palette = RoutinePalette(
      background: Color(0xFFFFFFFF),
      surface: Color(0xFFF5F5F5),
      card: Color(0xFFFFFFFF),
      text: Color(0xFF000000),
      muted: Color(0xFF666666),
      accent: Color(0xFF006600),
      accentSoft: Color(0xFFE6F4E6),
      border: Color(0xFFCCCCCC),
      button: Color(0xFF006600),
      buttonText: Color(0xFFFFFFFF),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: FocusModeScreen(
          period: RoutinePeriod.morning,
          step: RoutineStep(
            title: 'Short task',
            time: '7:00 AM',
            duration: '0 min',
          ),
          nextStep: RoutineStep(
            title: 'Following task',
            time: '7:05 AM',
            duration: '5 min',
          ),
          palette: palette,
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Task finished'), findsOneWidget);
    expect(find.text('Complete task'), findsOneWidget);
    expect(find.text('Next task: Following task'), findsOneWidget);
  });

  testWidgets('reference-style routine actions are shown', (tester) async {
    await tester.pumpWidget(const RestForMeApp());

    expect(find.byKey(const Key('add-step-button')), findsOneWidget);
    expect(find.text('Add step'), findsOneWidget);
    expect(find.text('Start your morning'), findsOneWidget);
    expect(find.byKey(const Key('focus-mode-button')), findsOneWidget);
  });
}

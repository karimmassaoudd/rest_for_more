import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest_for_more/main.dart';

void main() {
  testWidgets('morning progress updates when active step is checked', (
    tester,
  ) async {
    await tester.pumpWidget(const RestForMeApp());

    expect(find.text('Good morning,\nElena'), findsOneWidget);
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

    await tester.tap(find.byKey(const Key('evening-switch')));
    await tester.pumpAndSettle();

    expect(find.text('Good evening,\nElena'), findsOneWidget);
    expect(find.text('Restorative\nWind-Down'), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);
    expect(find.text('5 steps remaining'), findsOneWidget);

    final firstEveningStep = find.byKey(const Key('routine-toggle-0'));
    await tester.ensureVisible(firstEveningStep);
    await tester.tap(firstEveningStep);
    await tester.pumpAndSettle();

    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('4 steps remaining'), findsOneWidget);
  });

  testWidgets('finishing all morning steps shows completion', (tester) async {
    await tester.pumpWidget(const RestForMeApp());

    final fourthStep = find.byKey(const Key('routine-toggle-3'));
    await tester.ensureVisible(fourthStep);
    await tester.tap(fourthStep);
    await tester.pumpAndSettle();
    final fifthStep = find.byKey(const Key('routine-toggle-4'));
    await tester.ensureVisible(fifthStep);
    await tester.tap(fifthStep);
    await tester.pumpAndSettle();

    expect(find.text('5/5'), findsOneWidget);
    expect(find.text('0 steps remaining'), findsOneWidget);
    expect(find.text('Morning Routine Complete'), findsOneWidget);
  });
}

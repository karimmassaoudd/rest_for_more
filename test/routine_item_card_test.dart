import 'package:flutter/material.dart';
import 'package:flutter_application_rest_for_more/models/routines/routine_step.dart';
import 'package:flutter_application_rest_for_more/theme/app_colors.dart';
import 'package:flutter_application_rest_for_more/theme/app_theme.dart';
import 'package:flutter_application_rest_for_more/widgets/routines/routine_item_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const open = RoutineStep(
    title: 'Sensory Shower',
    time: '7:15 AM',
    duration: '15 min',
  );
  final done = open.copyWith(isCompleted: true);

  late int opened;
  late int toggled;

  setUp(() {
    opened = 0;
    toggled = 0;
  });

  Future<void> pumpCard(WidgetTester tester, RoutineStep step) =>
      tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: RoutineItemCard(
                step: step,
                index: 0,
                isActive: !step.isCompleted,
                period: RoutinePeriod.morning,
                palette: RoutinePalette.of(context),
                onOpen: () => opened++,
                onToggle: () => toggled++,
              ),
            ),
          ),
        ),
      );

  TextDecoration? titleDecoration(WidgetTester tester) =>
      tester.widget<Text>(find.text(open.title)).style?.decoration;

  testWidgets('tapping the row opens the activity', (tester) async {
    await pumpCard(tester, open);
    await tester.tap(find.text(open.title));
    expect((opened, toggled), (1, 0));
  });

  testWidgets('tapping the circle ticks it', (tester) async {
    await pumpCard(tester, open);
    await tester.tap(find.byKey(const Key('routine-step-done-0')));
    expect((opened, toggled), (0, 1));
  });

  testWidgets('swiping either way ticks it and the card stays', (
    tester,
  ) async {
    await pumpCard(tester, open);

    await tester.drag(find.text(open.title), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(toggled, 1);
    expect(find.text(open.title), findsOneWidget);

    await tester.drag(find.text(open.title), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(toggled, 2);
    expect(opened, 0);
  });

  testWidgets('open: empty circle, no strikethrough', (tester) async {
    await pumpCard(tester, open);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(titleDecoration(tester), isNot(TextDecoration.lineThrough));
  });

  testWidgets('done: filled check and strikethrough', (tester) async {
    await pumpCard(tester, done);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNothing);
    expect(titleDecoration(tester), TextDecoration.lineThrough);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_rest_for_more/models/routines/routine_step.dart';
import 'package:flutter_application_rest_for_more/screens/routines/routine_flow_screen.dart';
import 'package:flutter_application_rest_for_more/theme/app_theme.dart';

void main() {
  Widget buildSubject({
    required List<RoutineStep> steps,
    required Future<void> Function(int) onStepCompleted,
  }) {
    return MaterialApp(
      theme: buildAppTheme(),
      home: RoutineFlowScreen(
        period: RoutinePeriod.morning,
        steps: steps,
        onStepCompleted: onStepCompleted,
      ),
    );
  }

  const steps = [
    RoutineStep(title: 'First activity', time: '07:00', duration: '5 min'),
    RoutineStep(title: 'Second activity', time: '07:05', duration: '10 min'),
  ];

  testWidgets('persists each activity then continues to the next one', (
    tester,
  ) async {
    final savedIndexes = <int>[];
    await tester.pumpWidget(
      buildSubject(
        steps: steps,
        onStepCompleted: (index) async => savedIndexes.add(index),
      ),
    );

    expect(find.text('First activity'), findsOneWidget);
    expect(find.text('Next: Second activity'), findsOneWidget);

    await tester.tap(find.byKey(const Key('complete-routine-step-button')));
    await tester.pump();

    expect(savedIndexes, [0]);
    expect(find.text('Second activity'), findsOneWidget);
    expect(find.text('This is your final activity.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('complete-routine-step-button')));
    await tester.pump();

    expect(savedIndexes, [0, 1]);
    expect(find.text('Beautifully done.'), findsOneWidget);
  });

  testWidgets('starts at the first unfinished activity', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        steps: [steps.first.copyWith(isCompleted: true), steps.last],
        onStepCompleted: (_) async {},
      ),
    );

    expect(find.text('Second activity'), findsOneWidget);
    expect(find.text('Activity 2 of 2'), findsOneWidget);
  });

  testWidgets('handles empty and already-completed routines', (tester) async {
    await tester.pumpWidget(buildSubject(steps: const [], onStepCompleted: (_) async {}));
    expect(find.text('No activities yet'), findsOneWidget);

    await tester.pumpWidget(
      buildSubject(
        steps: steps.map((step) => step.copyWith(isCompleted: true)).toList(),
        onStepCompleted: (_) async {},
      ),
    );
    expect(find.text('Beautifully done.'), findsOneWidget);
  });

  testWidgets('does not advance when saving an activity fails', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        steps: steps,
        onStepCompleted: (_) async => throw StateError('storage unavailable'),
      ),
    );

    await tester.tap(find.byKey(const Key('complete-routine-step-button')));
    await tester.pump();

    expect(find.text('First activity'), findsOneWidget);
    expect(find.text('Could not save routine progress. Please try again.'), findsOneWidget);
  });
}

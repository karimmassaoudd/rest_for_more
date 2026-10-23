import 'package:flutter_test/flutter_test.dart';
import 'package:rest_for_more/models/routine_step.dart';
import 'package:rest_for_more/services/routine_progress_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const storage = RoutineProgressStorage();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('custom routine tasks persist separately by period', () async {
    const morning = [
      RoutineStep(
        id: 'custom-morning',
        title: 'Open the curtains',
        time: '7:00 AM',
        duration: '5 min',
        isCompleted: true,
      ),
    ];
    const evening = [
      RoutineStep(
        id: 'custom-evening',
        title: 'Prepare tomorrow',
        time: '9:30 PM',
        duration: '15 min',
      ),
    ];

    await storage.saveSteps(RoutinePeriod.morning, morning);
    await storage.saveSteps(RoutinePeriod.evening, evening);

    expect(
      (await storage.loadSteps(RoutinePeriod.morning))!.single.title,
      'Open the curtains',
    );
    expect(
      (await storage.loadSteps(RoutinePeriod.evening))!.single.duration,
      '15 min',
    );
  });

  test('daily history stores morning and evening chart data', () async {
    const morning = [
      RoutineStep(
        title: 'One',
        time: '7:00 AM',
        duration: '5 min',
        isCompleted: true,
      ),
      RoutineStep(title: 'Two', time: '7:05 AM', duration: '5 min'),
    ];
    const evening = [
      RoutineStep(
        title: 'Three',
        time: '9:00 PM',
        duration: '5 min',
        isCompleted: true,
      ),
    ];

    await storage.saveToday(
      morningSteps: morning,
      eveningSteps: evening,
      now: DateTime(2026, 10, 23),
    );

    final record = (await storage.loadHistory()).single;
    expect(record.date, '2026-10-23');
    expect(record.morningCompleted, 1);
    expect(record.morningTotal, 2);
    expect(record.eveningProgress, 1);
  });
}

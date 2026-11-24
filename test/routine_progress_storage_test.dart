import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_rest_for_more/models/routines/routine_step.dart';
import 'package:flutter_application_rest_for_more/services/routines/routine_progress_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const storage = RoutineProgressStorage();

  test('daily history records counts and which steps were done', () async {
    await storage.saveToday(
      morningSteps: const [
        RoutineStep(
          title: 'Water',
          time: '07:00',
          duration: '5 min',
          isCompleted: true,
        ),
        RoutineStep(title: 'Stretch', time: '07:05', duration: '10 min'),
      ],
      eveningSteps: const [
        RoutineStep(title: 'Read', time: '21:00', duration: '10 min'),
      ],
      now: DateTime(2026, 11, 15, 9),
    );
    final record = (await storage.loadHistory()).single;
    expect(record.date, '2026-11-15');
    expect(record.morningProgress, 0.5);
    expect(record.eveningProgress, 0);
    expect(
      [for (final step in record.morningSteps) '${step.title}:${step.done}'],
      ['Water:true', 'Stretch:false'],
    );
  });

  test('a routine day starts at 04:00', () {
    expect(storage.progressDay(DateTime(2026, 11, 16, 1, 30)), '2026-11-15');
    expect(storage.progressDay(DateTime(2026, 11, 16, 4)), '2026-11-16');
  });

  test('ticks are saved with their day and can be cleared', () async {
    await storage.saveCompletedTasks(RoutinePeriod.morning, const [
      RoutineStep(
        title: 'Water',
        time: '07:00',
        duration: '5 min',
        isCompleted: true,
      ),
    ], now: DateTime(2026, 11, 15, 8));
    expect(await storage.savedDay(), '2026-11-15');
    expect(await storage.loadCompletedTasks(RoutinePeriod.morning), {'Water'});

    await storage.clearTicks(now: DateTime(2026, 11, 16, 8));
    expect(await storage.loadCompletedTasks(RoutinePeriod.morning), isNull);
    expect(await storage.savedDay(), '2026-11-16');
  });

  test('old history records without step lists still load', () async {
    SharedPreferences.setMockInitialValues({
      'routine_history_v1':
          '[{"date":"2026-11-10","morningCompleted":2,"morningTotal":5,'
          '"eveningCompleted":0,"eveningTotal":5}]',
    });
    final record = (await storage.loadHistory()).single;
    expect(record.morningCompleted, 2);
    expect(record.morningSteps, isEmpty);
  });

  test('03:59 still belongs to the day before', () {
    expect(storage.progressDay(DateTime(2026, 11, 16, 3, 59)), '2026-11-15');
  });
}

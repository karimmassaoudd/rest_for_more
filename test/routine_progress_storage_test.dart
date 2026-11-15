import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_rest_for_more/models/routines/routine_step.dart';
import 'package:flutter_application_rest_for_more/services/routines/routine_progress_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('daily history records morning and evening routine completion', () async {
    const storage = RoutineProgressStorage();
    await storage.saveToday(
      morningSteps: const [RoutineStep(title: 'Water', time: '07:00', duration: '5 min', isCompleted: true)],
      eveningSteps: const [RoutineStep(title: 'Read', time: '21:00', duration: '10 min')],
      now: DateTime(2026, 11, 15),
    );
    final record = (await storage.loadHistory()).single;
    expect(record.date, '2026-11-15');
    expect(record.morningProgress, 1);
    expect(record.eveningProgress, 0);
  });
}

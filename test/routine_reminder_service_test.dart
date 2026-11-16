import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_rest_for_more/services/routines/routine_reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('uses the intended default routine reminder preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = await RoutineReminderService().loadSettings();

    expect(settings.enabled, isFalse);
    expect(settings.morningHour, 7);
    expect(settings.morningMinute, 0);
    expect(settings.eveningHour, 21);
    expect(settings.eveningMinute, 40);
  });

  test('loads persisted reminder preferences after restart', () async {
    SharedPreferences.setMockInitialValues({
      'routine_reminders_enabled': true,
      'routine_reminder_morning_hour': 6,
      'routine_reminder_morning_minute': 45,
      'routine_reminder_evening_hour': 22,
      'routine_reminder_evening_minute': 15,
    });
    final settings = await RoutineReminderService().loadSettings();

    expect(settings.enabled, isTrue);
    expect(settings.morningHour, 6);
    expect(settings.morningMinute, 45);
    expect(settings.eveningHour, 22);
    expect(settings.eveningMinute, 15);
  });
}

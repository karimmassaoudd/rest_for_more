import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_rest_for_more/models/routines/activity.dart';
import 'package:flutter_application_rest_for_more/services/routines/save_activities.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('evening activities persist independently from the starter routine', () async {
    const storage = SaveActivities();
    final activities = [
      Activity(
        time: '21:00',
        name: 'Prepare tomorrow',
        duration: '10 min',
        icon: Icons.checklist_rounded,
      ),
    ];

    await storage.saveActivities(activities);
    final restored = await storage.loadActivities();

    expect(restored, hasLength(1));
    expect(restored.single.name, 'Prepare tomorrow');
    expect(restored.single.icon.codePoint, Icons.checklist_rounded.codePoint);
  });
}

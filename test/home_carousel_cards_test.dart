import 'package:flutter/material.dart';
import 'package:flutter_application_rest_for_more/models/home/home_card.dart';
import 'package:flutter_application_rest_for_more/models/routines/routine_step.dart';
import 'package:flutter_application_rest_for_more/theme/app_theme.dart';
import 'package:flutter_application_rest_for_more/widgets/home/home_carousel_cards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// The button labels of the morning (1) and evening (2) cards.
  Future<(String, String)> routineLabels(
    WidgetTester tester, {
    RoutinePeriod? running,
    bool done = false,
  }) async {
    late List<HomeCard> cards;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) {
            cards = buildHomeCarouselCards(
              context: context,
              onStartFocus: () {},
              onMorningRoutine: () {},
              onEveningRoutine: () {},
              onStartPlan: () {},
              runningRoutine: running,
              routineDone: done,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    return (cards[1].buttonLabel, cards[2].buttonLabel);
  }

  testWidgets('no routine running: View', (tester) async {
    expect(await routineLabels(tester), (
      'View morning routine',
      'View evening routine',
    ));
  });

  testWidgets('running routine: Continue, the other stays View', (
    tester,
  ) async {
    expect(await routineLabels(tester, running: RoutinePeriod.morning), (
      'Continue morning routine',
      'View evening routine',
    ));
    expect(await routineLabels(tester, running: RoutinePeriod.evening), (
      'View morning routine',
      'Continue evening routine',
    ));
  });

  testWidgets('every activity ticked: … routine done', (tester) async {
    expect(
      await routineLabels(tester, running: RoutinePeriod.morning, done: true),
      ('Morning routine done', 'View evening routine'),
    );
  });

  group('homeCarouselIndexFor', () {
    DateTime at(int hour, [int minute = 0]) =>
        DateTime(2026, 11, 18, hour, minute);

    test('morning card 07:00–08:59', () {
      expect(homeCarouselIndexFor(at(6, 59)), 0);
      expect(homeCarouselIndexFor(at(7)), 1);
      expect(homeCarouselIndexFor(at(8, 59)), 1);
      expect(homeCarouselIndexFor(at(9)), 0);
    });

    test('evening card 20:00–20:59', () {
      expect(homeCarouselIndexFor(at(19, 59)), 0);
      expect(homeCarouselIndexFor(at(20)), 2);
      expect(homeCarouselIndexFor(at(20, 59)), 2);
      expect(homeCarouselIndexFor(at(21)), 0);
    });

    test('a running routine wins at any time', () {
      expect(
        homeCarouselIndexFor(at(22), runningRoutine: RoutinePeriod.morning),
        1,
      );
      expect(
        homeCarouselIndexFor(at(8), runningRoutine: RoutinePeriod.evening),
        2,
      );
    });
  });
}

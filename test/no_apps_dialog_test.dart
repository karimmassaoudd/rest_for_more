import 'package:flutter/material.dart';
import 'package:flutter_application_rest_for_more/theme/app_theme.dart';
import 'package:flutter_application_rest_for_more/widgets/focus/no_apps_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/fake_app_blocker.dart';

/// "No apps blocked yet": shown before a session or routine whose profile
/// doesn't block any apps.
void main() {
  final blocker = FakeAppBlocker();
  setUp(blocker.install);
  tearDown(blocker.uninstall);

  /// What confirmBlockedApps returned (null: not finished yet).
  bool? result;

  /// A Start button that asks confirmBlockedApps for the morning profile,
  /// and a stand-in for Edit blocked apps that saves [appsChosenThere].
  Future<void> pumpApp(
    WidgetTester tester, {
    List<String> appsChosenThere = const [],
  }) async {
    result = null;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await confirmBlockedApps(
                    context,
                    'morning',
                    sessionName: 'Morning routine',
                  );
                },
                child: const Text('Start'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/settings/focus-profiles/detail/blocked-apps',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  blocker.profiles['morning'] = appsChosenThere;
                  context.pop(true);
                },
                child: const Text('Save apps'),
              ),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
    );
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('a profile with apps starts without asking', (tester) async {
    blocker.profiles['morning'] = ['com.google.android.youtube'];
    await pumpApp(tester);

    await tapAndSettle(tester, find.text('Start'));

    expect(find.text('No apps blocked yet'), findsNothing);
    expect(result, isTrue);
  });

  testWidgets("starts when the profile can't be loaded", (tester) async {
    await pumpApp(tester); // no 'morning' profile at all

    await tapAndSettle(tester, find.text('Start'));

    expect(find.text('No apps blocked yet'), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('no apps: says so, and Start anyway starts', (tester) async {
    blocker.profiles['morning'] = [];
    await pumpApp(tester);

    await tapAndSettle(tester, find.text('Start'));
    expect(find.text('No apps blocked yet'), findsOneWidget);
    expect(
      find.textContaining("Your Morning routine doesn't block any apps yet"),
      findsOneWidget,
    );

    await tapAndSettle(tester, find.byKey(const Key('no-apps-start-anyway')));
    expect(find.text('No apps blocked yet'), findsNothing);
    expect(result, isTrue);
  });

  testWidgets("no apps: closing the dialog doesn't start", (tester) async {
    blocker.profiles['morning'] = [];
    await pumpApp(tester);

    await tapAndSettle(tester, find.text('Start'));
    await tester.tapAt(const Offset(5, 5)); // outside the dialog
    await tester.pumpAndSettle();

    expect(find.text('No apps blocked yet'), findsNothing);
    expect(result, isFalse);
  });

  testWidgets('Choose apps, then saving some apps starts', (tester) async {
    blocker.profiles['morning'] = [];
    await pumpApp(tester, appsChosenThere: ['com.google.android.youtube']);

    await tapAndSettle(tester, find.text('Start'));
    await tapAndSettle(tester, find.byKey(const Key('no-apps-choose')));
    await tapAndSettle(tester, find.text('Save apps'));

    expect(result, isTrue);
  });

  testWidgets("Choose apps, then coming back without apps doesn't start", (
    tester,
  ) async {
    blocker.profiles['morning'] = [];
    await pumpApp(tester);

    await tapAndSettle(tester, find.text('Start'));
    await tapAndSettle(tester, find.byKey(const Key('no-apps-choose')));
    await tapAndSettle(tester, find.text('Save apps'));

    expect(result, isFalse);
  });
}

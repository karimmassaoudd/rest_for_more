import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_rest_for_more/screens/home/home_screen.dart';
import 'package:flutter_application_rest_for_more/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('home screen renders the current focus section', (tester) async {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
    );
    await tester.pump(const Duration(seconds: 11));

    expect(find.text('What do you want to focus on?'), findsOneWidget);
  });
}

// Feature branch silvio init

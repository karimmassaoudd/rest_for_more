import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_rest_for_more/main.dart';

void main() {
  testWidgets('home screen renders the focus prompt', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('What do you want to focus on?'), findsOneWidget);
  });
}

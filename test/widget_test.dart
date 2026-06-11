import 'package:flutter_test/flutter_test.dart';

import 'package:hearing_aid/main.dart';

void main() {
  testWidgets('renders the hearing assessment start screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Hearing Assessment'), findsOneWidget);
    expect(find.text('Guided PTA'), findsOneWidget);
    expect(find.text('Word recognition test'), findsOneWidget);
  });
}

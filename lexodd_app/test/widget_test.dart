import 'package:flutter_test/flutter_test.dart';
import 'package:lexood/main.dart';

void main() {
  testWidgets('shows the Lexodd splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Lexodd'), findsOneWidget);
    expect(find.text('Lexodd Hypernova System'), findsOneWidget);
  });
}

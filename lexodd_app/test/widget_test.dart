import 'package:flutter_test/flutter_test.dart';
import 'package:lexood/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the Lexodd splash screen then navigates to login',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());

    // Splash screen content shows immediately
    expect(find.text('Lexodd'), findsOneWidget);
    expect(find.text('Lexodd Hypernova System'), findsOneWidget);

    // Drain the splash screen's 3-second navigation timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // With no stored session the app lands on the login screen
    expect(find.text('Welcome Back!'), findsOneWidget);
  });
}

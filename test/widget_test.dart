import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiangqi_mobile/main.dart';
import 'package:xiangqi_mobile/views/login_view.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for splash screen to complete (3 seconds timer)
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // After splash, it should show LoginView since no token is stored
    expect(find.byType(LoginView), findsOneWidget);
  });
}

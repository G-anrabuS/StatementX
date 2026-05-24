import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend/main.dart';
import 'package:flutter_frontend/screens/home_screen.dart';

void main() {
  testWidgets('StatementXApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StatementXApp(initialRoute: HomeScreen()));
    expect(find.byType(StatementXApp), findsOneWidget);
  });
}

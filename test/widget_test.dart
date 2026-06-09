import 'package:flutter_test/flutter_test.dart';
import 'package:mobilepos/main.dart';

void main() {
  testWidgets('App renders login page', (WidgetTester tester) async {
    await tester.pumpWidget(const MobilePosApp());
    await tester.pump();

    expect(find.text('Masuk'), findsOneWidget);
  });
}
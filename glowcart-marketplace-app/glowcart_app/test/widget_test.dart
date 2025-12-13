import 'package:flutter_test/flutter_test.dart';
import 'package:glowcart_app/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const GlowCartApp());
    expect(find.text('Home'), findsOneWidget);
  });
}

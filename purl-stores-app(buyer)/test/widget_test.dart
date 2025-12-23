import 'package:flutter_test/flutter_test.dart';
import 'package:purl_stores/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PurlStoresApp());
    expect(find.text('Home'), findsOneWidget);
  });
}

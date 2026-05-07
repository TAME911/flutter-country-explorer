import 'package:flutter_test/flutter_test.dart';
import 'package:country_explorer/main.dart';

void main() {
  testWidgets('App launches and shows AppBar title', (WidgetTester tester) async {
    await tester.pumpWidget(const CountryExplorerApp());
    expect(find.text('🌍 Country Explorer'), findsOneWidget);
  });
}

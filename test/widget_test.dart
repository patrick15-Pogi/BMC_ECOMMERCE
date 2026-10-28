
import 'package:flutter_test/flutter_test.dart';
import 'package:blvk_ecommerce/main.dart';

void main() {
  testWidgets('BLVK app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const BlvkApp());

    expect(find.text('BLVK'), findsWidgets);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muhammad_discount_pharmacy/screens/pharmacy_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the shop banner and inventory categories', (tester) async {
    await tester.pumpWidget(const PharmacyApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Muhammad Discount Pharmacy - Chakdara'),
      findsOneWidget,
    );
    expect(find.text('Tablets'), findsOneWidget);
    expect(find.text('Syrups'), findsOneWidget);
    expect(find.text('Your inventory is ready'), findsOneWidget);
  });

  testWidgets('adds a medicine to inventory and bills at its listed price',
      (tester) async {
    await tester.pumpWidget(const PharmacyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add medicine'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Medicine name'), 'Test tablets');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Company'), 'Sample company');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Price (PKR)'), '125');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock quantity'), '4');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Rack number'), 'A-1');
    await tester.tap(find.text('Save medicine'));
    await tester.pumpAndSettle();

    expect(find.text('Test tablets'), findsOneWidget);
    expect(find.text('PKR 125.00'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -450));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('add-to-bill')));
    await tester.tap(find.byKey(const Key('add-to-bill')));
    await tester.pumpAndSettle();
    expect(find.text('Current bill'), findsOneWidget);
    expect(find.text('PKR 125.00'), findsNWidgets(2));
    expect(find.text('Total due'), findsOneWidget);
    expect(find.text('PKR 0.00'), findsNothing);
    expect(find.textContaining('default is 0%'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('manual-discount-field')),
      '2.01',
    );
    await tester.tap(find.text('Complete sale & view bill'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a discount from 0% to 2%.'), findsOneWidget);
    expect(find.text('Bill ready'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('manual-discount-field')),
      '0',
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Complete sale & view bill'));
    await tester.tap(find.text('Complete sale & view bill'));
    await tester.pumpAndSettle();
    expect(find.text('Bill ready'), findsOneWidget);
    expect(find.text('Subtotal · original prices'), findsNWidgets(2));
    expect(find.text('PKR 125.00'), findsNWidgets(3));
    expect(find.text('Total due'), findsNWidgets(2));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inventory').last);
    await tester.pumpAndSettle();
    expect(find.text('Low stock · 3'), findsOneWidget);
  });
}

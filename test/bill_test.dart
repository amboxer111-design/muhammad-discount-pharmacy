import 'package:flutter_test/flutter_test.dart';
import 'package:muhammad_discount_pharmacy/models/bill.dart';
import 'package:muhammad_discount_pharmacy/models/medicine.dart';
import 'package:muhammad_discount_pharmacy/models/shop_details.dart';

void main() {
  group('manual discount validation', () {
    test('defaults an empty optional value to zero', () {
      expect(Bill.validateDiscount(''), 0);
      expect(Bill.validateDiscount('0'), 0);
    });

    test('accepts the allowed maximum', () {
      expect(Bill.validateDiscount('2'), 2);
    });

    test('rejects values outside the allowed range', () {
      expect(() => Bill.validateDiscount('-0.1'), throwsFormatException);
      expect(() => Bill.validateDiscount('2.01'), throwsFormatException);
      expect(
          () => Bill.validateDiscount('not a number'), throwsFormatException);
    });
  });

  test('bill retains original prices and applies only its entered discount',
      () {
    final medicine = Medicine(
      id: '1',
      name: 'Sample medicine',
      company: 'Sample company',
      category: 'Tablets',
      price: 100,
      stock: 5,
      expiry: DateTime(2027, 1, 1),
      rackNumber: 'A-1',
    );
    final bill = Bill(
      lines: [BillLine(medicine: medicine, quantity: 2)],
      shop: const ShopDetails(),
      createdAt: DateTime(2026),
      discountPercent: 0,
    );
    expect(bill.subtotal, 200);
    expect(bill.discountAmount, 0);
    expect(bill.total, 200);
  });

  test('applies the optional 2 percent discount only when requested', () {
    final medicine = Medicine(
      id: '2',
      name: 'Sample medicine',
      company: 'Sample company',
      category: 'Tablets',
      price: 100,
      stock: 5,
      expiry: DateTime(2027, 1, 1),
      rackNumber: 'A-1',
    );
    final bill = Bill(
      lines: [BillLine(medicine: medicine, quantity: 2)],
      shop: const ShopDetails(),
      createdAt: DateTime(2026),
      discountPercent: 2,
    );

    expect(bill.subtotal, 200);
    expect(bill.discountAmount, 4);
    expect(bill.total, 196);
  });
}

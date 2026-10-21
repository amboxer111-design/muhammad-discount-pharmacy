import 'package:muhammad_discount_pharmacy/models/medicine.dart';
import 'package:muhammad_discount_pharmacy/models/shop_details.dart';

class BillLine {
  const BillLine({required this.medicine, required this.quantity});

  final Medicine medicine;
  final int quantity;

  double get total => medicine.price * quantity;
}

class Bill {
  const Bill({
    required this.lines,
    required this.shop,
    required this.createdAt,
    required this.discountPercent,
  });

  final List<BillLine> lines;
  final ShopDetails shop;
  final DateTime createdAt;
  final double discountPercent;

  double get subtotal => lines.fold(0, (sum, line) => sum + line.total);
  double get discountAmount => subtotal * discountPercent / 100;
  double get total => subtotal - discountAmount;

  static double validateDiscount(String input) {
    final double? value =
        input.trim().isEmpty ? 0 : double.tryParse(input.trim());
    if (value == null || !value.isFinite || value < 0 || value > 2) {
      throw const FormatException('Enter a discount from 0% to 2%.');
    }
    return value;
  }
}

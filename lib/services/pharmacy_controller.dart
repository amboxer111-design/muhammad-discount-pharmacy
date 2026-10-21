import 'package:flutter/foundation.dart';

import 'package:muhammad_discount_pharmacy/models/bill.dart';
import 'package:muhammad_discount_pharmacy/models/medicine.dart';
import 'package:muhammad_discount_pharmacy/models/shop_details.dart';
import 'package:muhammad_discount_pharmacy/services/pharmacy_store.dart';

class PharmacyController extends ChangeNotifier {
  PharmacyController(this._store);

  final PharmacyStore _store;
  List<Medicine> medicines = [];
  ShopDetails shopDetails = const ShopDetails();
  bool isLoading = true;
  Object? loadError;

  Future<void> load() async {
    try {
      final results = await Future.wait<Object>([
        _store.loadMedicines(),
        _store.loadShopDetails(),
      ]);
      medicines = results[0] as List<Medicine>;
      shopDetails = results[1] as ShopDetails;
    } catch (error) {
      loadError = error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveMedicine(Medicine medicine) async {
    final updated = [...medicines];
    final existingIndex =
        updated.indexWhere((current) => current.id == medicine.id);
    if (existingIndex == -1) {
      updated.add(medicine);
    } else {
      updated[existingIndex] = medicine;
    }
    await _store.saveMedicines(updated);
    medicines = updated;
    notifyListeners();
  }

  Future<void> saveShopDetails(ShopDetails details) async {
    await _store.saveShopDetails(details);
    shopDetails = details;
    notifyListeners();
  }

  Future<Bill> checkout(
    Map<String, int> quantities, {
    required double discountPercent,
  }) async {
    if (!discountPercent.isFinite ||
        discountPercent < 0 ||
        discountPercent > 2) {
      throw const FormatException('Enter a discount from 0% to 2%.');
    }
    if (quantities.isEmpty) {
      throw StateError('Add at least one medicine to the bill.');
    }

    final byId = {for (final medicine in medicines) medicine.id: medicine};
    final lines = <BillLine>[];
    final updated = [...medicines];
    for (final entry in quantities.entries) {
      final medicine = byId[entry.key];
      if (medicine == null || entry.value < 1) {
        throw StateError('The cart contains an unavailable medicine.');
      }
      if (medicine.stock < entry.value) {
        throw StateError('Not enough stock for ${medicine.name}.');
      }
      if (medicine.isExpired) {
        throw StateError('${medicine.name} is expired and cannot be sold.');
      }
      lines.add(BillLine(medicine: medicine, quantity: entry.value));
      final index = updated.indexWhere((item) => item.id == medicine.id);
      updated[index] = medicine.copyWith(stock: medicine.stock - entry.value);
    }

    final bill = Bill(
      lines: List.unmodifiable(lines),
      shop: shopDetails,
      createdAt: DateTime.now(),
      discountPercent: discountPercent,
    );
    await _store.saveMedicines(updated);
    medicines = updated;
    notifyListeners();
    return bill;
  }
}

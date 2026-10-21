import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:muhammad_discount_pharmacy/models/medicine.dart';
import 'package:muhammad_discount_pharmacy/models/shop_details.dart';

class PharmacyStore {
  static const _medicinesKey = 'pharmacy.medicines.v1';
  static const _shopDetailsKey = 'pharmacy.shop_details.v1';

  Future<List<Medicine>> loadMedicines() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_medicinesKey);
    if (encoded == null) return [];
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded
        .map(
            (item) => Medicine.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> saveMedicines(List<Medicine> medicines) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _medicinesKey,
      jsonEncode(medicines.map((medicine) => medicine.toJson()).toList()),
    );
    if (!saved) throw StateError('Could not persist the medicine inventory.');
  }

  Future<ShopDetails> loadShopDetails() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_shopDetailsKey);
    if (encoded == null) return const ShopDetails();
    return ShopDetails.fromJson(
      Map<String, dynamic>.from(jsonDecode(encoded) as Map),
    );
  }

  Future<void> saveShopDetails(ShopDetails details) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _shopDetailsKey,
      jsonEncode(details.toJson()),
    );
    if (!saved) throw StateError('Could not persist the shop details.');
  }
}

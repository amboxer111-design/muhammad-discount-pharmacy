import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:muhammad_discount_pharmacy/models/bill.dart';
import 'package:muhammad_discount_pharmacy/models/medicine.dart';
import 'package:muhammad_discount_pharmacy/models/shop_details.dart';
import 'package:muhammad_discount_pharmacy/services/pharmacy_controller.dart';
import 'package:muhammad_discount_pharmacy/services/pharmacy_store.dart';

class PharmacyApp extends StatefulWidget {
  const PharmacyApp({super.key, this.store});

  final PharmacyStore? store;

  @override
  State<PharmacyApp> createState() => _PharmacyAppState();
}

class _PharmacyAppState extends State<PharmacyApp> {
  late final PharmacyController _controller;
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  int _selectedPage = 0;
  final Map<String, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _controller = PharmacyController(widget.store ?? PharmacyStore())..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    _messengerKey.currentState!
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openEditor([Medicine? medicine]) async {
    final saved = await showDialog<Medicine>(
      context: _navigatorKey.currentContext!,
      builder: (_) => MedicineEditorDialog(medicine: medicine),
    );
    if (saved == null) return;
    try {
      await _controller.saveMedicine(saved);
      if (mounted) _showMessage('${saved.name} saved to inventory.');
    } catch (error) {
      if (mounted) _showMessage('Could not save medicine: $error');
    }
  }

  Future<void> _finishSale(double discountPercent) async {
    try {
      final bill = await _controller.checkout(
        Map<String, int>.from(_cart),
        discountPercent: discountPercent,
      );
      if (!mounted) return;
      setState(_cart.clear);
      await showDialog<void>(
        context: _navigatorKey.currentContext!,
        builder: (_) => BillDialog(bill: bill),
      );
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Bad state: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isWide = MediaQuery.sizeOf(context).width >= 900;
        return MaterialApp(
          navigatorKey: _navigatorKey,
          scaffoldMessengerKey: _messengerKey,
          title: 'Muhammad Discount Pharmacy - Chakdara',
          debugShowCheckedModeBanner: false,
          theme: _pharmacyTheme(),
          home: Scaffold(
            appBar: AppBar(
              title: const Text(
                'Muhammad Discount Pharmacy',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              actions: [
                if (_selectedPage == 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: FilledButton.icon(
                      onPressed:
                          _controller.isLoading ? null : () => _openEditor(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add medicine'),
                    ),
                  ),
              ],
            ),
            body: _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _controller.loadError != null
                    ? _LoadError(error: _controller.loadError!)
                    : Row(
                        children: [
                          if (isWide)
                            NavigationRail(
                              selectedIndex: _selectedPage,
                              onDestinationSelected: _selectPage,
                              labelType: NavigationRailLabelType.all,
                              destinations: _railDestinations,
                            ),
                          Expanded(child: _pageContent()),
                        ],
                      ),
            bottomNavigationBar:
                isWide || _controller.isLoading || _controller.loadError != null
                    ? null
                    : NavigationBar(
                        selectedIndex: _selectedPage,
                        onDestinationSelected: _selectPage,
                        destinations: _destinations,
                      ),
          ),
        );
      },
    );
  }

  List<NavigationDestination> get _destinations => [
        const NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2_rounded),
          label: 'Inventory',
        ),
        NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long_rounded),
          label: _cart.isEmpty
              ? 'Bill'
              : 'Bill (${_cart.values.fold<int>(0, (a, b) => a + b)})',
        ),
        const NavigationDestination(
          icon: Icon(Icons.tune_rounded),
          label: 'Settings',
        ),
      ];

  List<NavigationRailDestination> get _railDestinations => [
        const NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2_rounded),
          label: Text('Inventory'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: Text('Bill'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.tune_rounded),
          label: Text('Settings'),
        ),
      ];

  void _selectPage(int page) => setState(() => _selectedPage = page);

  Widget _pageContent() {
    switch (_selectedPage) {
      case 1:
        return BillingPage(
          medicines: _controller.medicines,
          cart: _cart,
          onCartChanged: () => setState(() {}),
          onCheckout: _finishSale,
        );
      case 2:
        return SettingsPage(
          details: _controller.shopDetails,
          onSave: _controller.saveShopDetails,
        );
      default:
        return InventoryPage(
          medicines: _controller.medicines,
          cartQuantities: _cart,
          onAdd: (medicine) {
            setState(() => _cart.update(
                  medicine.id,
                  (quantity) => quantity + 1,
                  ifAbsent: () => 1,
                ));
            _showMessage('${medicine.name} added to bill.');
          },
          onEdit: _openEditor,
          onOpenBilling: () => _selectPage(1),
        );
    }
  }
}

ThemeData _pharmacyTheme() {
  const green = Color(0xFF176B52);
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      primary: green,
      surface: const Color(0xFFF7F9F6),
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F9F6),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF7F9F6),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE8EDE8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDDE5DE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDDE5DE)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({
    super.key,
    required this.medicines,
    required this.cartQuantities,
    required this.onAdd,
    required this.onEdit,
    required this.onOpenBilling,
  });

  final List<Medicine> medicines;
  final Map<String, int> cartQuantities;
  final ValueChanged<Medicine> onAdd;
  final ValueChanged<Medicine> onEdit;
  final VoidCallback onOpenBilling;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  static const _categories = [
    'All',
    'Tablets',
    'Syrups',
    'Injections',
    'Drops',
    'Capsules',
    'Creams',
    'Other',
  ];

  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.medicines.where((medicine) {
      final matchesName =
          medicine.name.toLowerCase().contains(_query.trim().toLowerCase());
      return matchesName &&
          (_category == 'All' || medicine.category == _category);
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final lowStock = widget.medicines.where((item) => item.stock <= 5).length;
    final expiredOrNear = widget.medicines
        .where((item) => item.isExpired || item.expiresWithinMonth)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
      children: [
        const _ShopBanner(),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 580;
            final cards = [
              _StatCard(
                label: 'Medicines',
                value: '${widget.medicines.length}',
                icon: Icons.medication_outlined,
                tint: const Color(0xFFEAF3EE),
              ),
              _StatCard(
                label: 'Low stock',
                value: '$lowStock',
                icon: Icons.inventory_outlined,
                tint: const Color(0xFFFFF4DF),
              ),
              _StatCard(
                label: 'Expiry watch',
                value: '$expiredOrNear',
                icon: Icons.event_busy_outlined,
                tint: const Color(0xFFFCECE8),
              ),
            ];
            if (compact) {
              return Column(
                children: [
                  Row(children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1])
                  ]),
                  const SizedBox(height: 12),
                  cards[2],
                ],
              );
            }
            return Row(
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  if (index > 0) const SizedBox(width: 14),
                  Expanded(child: cards[index]),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text('Medicine inventory',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Text('${filtered.length} items',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('medicine-search'),
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Search medicines by name',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          _EmptyInventory(hasItems: widget.medicines.isNotEmpty)
        else
          ...filtered.map(
            (medicine) => _MedicineCard(
              medicine: medicine,
              cartQuantity: widget.cartQuantities[medicine.id] ?? 0,
              onAdd: () => widget.onAdd(medicine),
              onEdit: () => widget.onEdit(medicine),
              onOpenBilling: widget.onOpenBilling,
            ),
          ),
      ],
    );
  }
}

class _ShopBanner extends StatelessWidget {
  const _ShopBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF155E49), Color(0xFF278366)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.local_pharmacy_rounded,
                color: Colors.white, size: 31),
          ),
          const SizedBox(width: 17),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Muhammad Discount Pharmacy - Chakdara',
                  key: Key('shop-name-banner'),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 7),
                Text('PHARMACY INVENTORY & BILLING',
                    style: TextStyle(
                        color: Color(0xFFD3EEE3),
                        letterSpacing: 1.1,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                  color: tint, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: const Color(0xFF176B52)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({required this.hasItems});

  final bool hasItems;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
        child: Column(
          children: [
            const Icon(Icons.medication_liquid_outlined,
                size: 43, color: Color(0xFF759184)),
            const SizedBox(height: 12),
            Text(
                hasItems ? 'No matching medicines' : 'Your inventory is ready'),
            const SizedBox(height: 5),
            Text(
              hasItems
                  ? 'Try another name or category.'
                  : 'Add your first medicine to get started.',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.medicine,
    required this.cartQuantity,
    required this.onAdd,
    required this.onEdit,
    required this.onOpenBilling,
  });

  final Medicine medicine;
  final int cartQuantity;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onOpenBilling;

  @override
  Widget build(BuildContext context) {
    final isExpired = medicine.isExpired;
    final nearExpiry = medicine.expiresWithinMonth;
    final stockText = medicine.stock == 0
        ? 'Out of stock'
        : medicine.stock <= 5
            ? 'Low stock · ${medicine.stock}'
            : '${medicine.stock} in stock';
    final stockColor = medicine.stock == 0 || medicine.stock <= 5
        ? const Color(0xFFB65A1E)
        : const Color(0xFF337A58);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 500;
            final detail = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicine.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('${medicine.company}  ·  ${medicine.category}',
                    style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 7,
                  children: [
                    _IconLabel(
                        icon: Icons.inventory_2_outlined,
                        text: stockText,
                        color: stockColor),
                    _IconLabel(
                        icon: Icons.event_outlined,
                        text:
                            'Exp ${DateFormat('MMM yyyy').format(medicine.expiry)}',
                        color: isExpired || nearExpiry
                            ? const Color(0xFFB34F37)
                            : Colors.black54),
                    _IconLabel(
                        icon: Icons.location_on_outlined,
                        text: 'Rack ${medicine.rackNumber}'),
                  ],
                ),
                if (isExpired || nearExpiry)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                        isExpired
                            ? 'Expired — do not sell'
                            : 'Expires within 30 days',
                        style: const TextStyle(
                            color: Color(0xFFB34F37),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            );
            final actions = Column(
              crossAxisAlignment:
                  compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Text(_money(medicine.price),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      tooltip: 'Edit ${medicine.name}',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    FilledButton.tonalIcon(
                      key: const Key('add-to-bill'),
                      onPressed: medicine.stock == 0 ||
                              cartQuantity >= medicine.stock ||
                              isExpired
                          ? null
                          : () {
                              onAdd();
                              onOpenBilling();
                            },
                      icon:
                          const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
              ],
            );
            return compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [detail, const SizedBox(height: 14), actions],
                  )
                : Row(
                    children: [
                      Expanded(child: detail),
                      const SizedBox(width: 18),
                      actions,
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  const _IconLabel({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color ?? Colors.black45),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(fontSize: 12, color: color ?? Colors.black54)),
        ],
      );
}

class MedicineEditorDialog extends StatefulWidget {
  const MedicineEditorDialog({super.key, this.medicine});

  final Medicine? medicine;

  @override
  State<MedicineEditorDialog> createState() => _MedicineEditorDialogState();
}

class _MedicineEditorDialogState extends State<MedicineEditorDialog> {
  static const _categories = [
    'Tablets',
    'Syrups',
    'Injections',
    'Drops',
    'Capsules',
    'Creams',
    'Other'
  ];
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _company;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _rack;
  late String _category;
  late DateTime _expiry;

  @override
  void initState() {
    super.initState();
    final medicine = widget.medicine;
    _name = TextEditingController(text: medicine?.name ?? '');
    _company = TextEditingController(text: medicine?.company ?? '');
    _price = TextEditingController(text: medicine?.price.toString() ?? '');
    _stock = TextEditingController(text: medicine?.stock.toString() ?? '');
    _rack = TextEditingController(text: medicine?.rackNumber ?? '');
    _category = medicine?.category ?? _categories.first;
    _expiry = medicine?.expiry ?? DateTime.now().add(const Duration(days: 365));
  }

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _price.dispose();
    _stock.dispose();
    _rack.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _positivePrice(String? value) {
    if (_required(value) != null) return 'Enter a price.';
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      return 'Enter a valid price of 0 or more.';
    }
    return null;
  }

  String? _stockValue(String? value) {
    if (_required(value) != null) return 'Enter a stock quantity.';
    final parsed = int.tryParse(value!.trim());
    if (parsed == null || parsed < 0) {
      return 'Enter a whole number of 0 or more.';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final medicine = Medicine(
      id: widget.medicine?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      company: _company.text.trim(),
      category: _category,
      price: double.parse(_price.text.trim()),
      stock: int.parse(_stock.text.trim()),
      expiry: _expiry,
      rackNumber: _rack.text.trim(),
    );
    Navigator.of(context).pop(medicine);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.medicine == null ? 'Add medicine' : 'Edit medicine'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Medicine name'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _company,
                  decoration: const InputDecoration(labelText: 'Company'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .map((category) => DropdownMenuItem(
                          value: category, child: Text(category)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}$'))
                        ],
                        decoration:
                            const InputDecoration(labelText: 'Price (PKR)'),
                        validator: _positivePrice,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stock,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration:
                            const InputDecoration(labelText: 'Stock quantity'),
                        validator: _stockValue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'Expiry date'),
                        child: Text(DateFormat('dd MMM yyyy').format(_expiry)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Choose expiry date',
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _expiry,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) setState(() => _expiry = date);
                      },
                      icon: const Icon(Icons.calendar_month_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rack,
                  decoration: const InputDecoration(labelText: 'Rack number'),
                  validator: _required,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save medicine')),
      ],
    );
  }
}

class BillingPage extends StatefulWidget {
  const BillingPage({
    super.key,
    required this.medicines,
    required this.cart,
    required this.onCartChanged,
    required this.onCheckout,
  });

  final List<Medicine> medicines;
  final Map<String, int> cart;
  final VoidCallback onCartChanged;
  final ValueChanged<double> onCheckout;

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final _formKey = GlobalKey<FormState>();
  final _discountController = TextEditingController(text: '0');

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  double get _subtotal {
    final byId = {
      for (final medicine in widget.medicines) medicine.id: medicine
    };
    return widget.cart.entries.fold(0, (sum, entry) {
      final medicine = byId[entry.key];
      return sum + (medicine?.price ?? 0) * entry.value;
    });
  }

  String? _validateDiscount(String? input) {
    try {
      Bill.validateDiscount(input ?? '');
      return null;
    } on FormatException catch (error) {
      return error.message;
    }
  }

  void _checkout() {
    if (widget.cart.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;
    widget.onCheckout(Bill.validateDiscount(_discountController.text));
  }

  @override
  Widget build(BuildContext context) {
    final byId = {
      for (final medicine in widget.medicines) medicine.id: medicine
    };
    final entries = widget.cart.entries
        .map((entry) => (medicine: byId[entry.key], quantity: entry.value))
        .where((entry) => entry.medicine != null)
        .toList();
    final discount = double.tryParse(_discountController.text) ?? 0;
    final total = _subtotal * (1 - discount.clamp(0, 2) / 100);

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text('Current bill',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        const Text('Review items and confirm the original listed prices.',
            style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 20),
        if (entries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 18),
              child: Column(
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 42, color: Color(0xFF759184)),
                  const SizedBox(height: 12),
                  const Text('Your bill is empty'),
                  const SizedBox(height: 5),
                  const Text('Add medicines from Inventory to get started.',
                      style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      final ancestor =
                          context.findAncestorStateOfType<_PharmacyAppState>();
                      ancestor?._selectPage(0);
                    },
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Browse inventory'),
                  ),
                ],
              ),
            ),
          )
        else
          ...entries.map((entry) {
            final medicine = entry.medicine!;
            final quantity = entry.quantity;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(medicine.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                              '${_money(medicine.price)} each  ·  ${_money(medicine.price * quantity)}',
                              style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove one ${medicine.name}',
                      onPressed: () {
                        if (quantity <= 1) {
                          widget.cart.remove(medicine.id);
                        } else {
                          widget.cart[medicine.id] = quantity - 1;
                        }
                        widget.onCartChanged();
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$quantity',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    IconButton(
                      tooltip: 'Add one ${medicine.name}',
                      onPressed: quantity >= medicine.stock
                          ? null
                          : () {
                              widget.cart[medicine.id] = quantity + 1;
                              widget.onCartChanged();
                            },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    IconButton(
                      tooltip: 'Remove ${medicine.name}',
                      onPressed: () {
                        widget.cart.remove(medicine.id);
                        widget.onCartChanged();
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment summary',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  _AmountRow(
                      label: 'Subtotal · original prices',
                      amount: _money(_subtotal)),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('manual-discount-field'),
                    controller: _discountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}$'))
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Optional manual discount',
                      helperText:
                          'Admin-entered only · 0% to 2% · default is 0%',
                      suffixText: '%',
                    ),
                    validator: _validateDiscount,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  if (discount > 0)
                    _AmountRow(
                      label:
                          'Manual discount (${discount.toStringAsFixed(2)}%)',
                      amount: '- ${_money(_subtotal * discount / 100)}',
                      color: const Color(0xFF176B52),
                    ),
                  if (discount > 0) const Divider(height: 22),
                  _AmountRow(
                      label: 'Total due',
                      amount: _money(total),
                      emphasize: true),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: entries.isEmpty ? null : _checkout,
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text('Complete sale & view bill'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.color,
    this.emphasize = false,
  });

  final String label;
  final String amount;
  final Color? color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color ?? (emphasize ? Colors.black87 : Colors.black54),
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
          Text(amount,
              style: TextStyle(
                  fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
                  fontSize: emphasize ? 18 : 14)),
        ],
      );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.details, required this.onSave});

  final ShopDetails details;
  final Future<void> Function(ShopDetails details) onSave;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _address;
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _address = TextEditingController(text: widget.details.address);
    _phone = TextEditingController(text: widget.details.phone);
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(ShopDetails(
        address: _address.text.trim(),
        phone: _phone.text.trim(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop contact details saved.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save shop details: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text('Shop settings',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        const Text('Set contact details shown on printed bills.',
            style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Muhammad Discount Pharmacy - Chakdara',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                    '“Discount” is the shop name; no discount is applied automatically.',
                    style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 22),
                TextField(
                  controller: _address,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Shop address',
                    hintText: 'Enter your shop address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: 'Enter your shop phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save shop details'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BillDialog extends StatelessWidget {
  const BillDialog({super.key, required this.bill});

  final Bill bill;

  Future<void> _print(BuildContext context) async {
    try {
      final document = pw.Document();
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Muhammad Discount Pharmacy - Chakdara',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                  'Address: ${bill.shop.address.isEmpty ? 'Address not set' : bill.shop.address}'),
              pw.Text(
                  'Phone: ${bill.shop.phone.isEmpty ? 'Phone not set' : bill.shop.phone}'),
              pw.SizedBox(height: 10),
              pw.Text(
                  'Bill date: ${DateFormat('dd MMM yyyy, hh:mm a').format(bill.createdAt)}'),
              pw.Divider(),
              pw.TableHelper.fromTextArray(
                headers: ['Medicine', 'Qty', 'Unit price', 'Line total'],
                data: bill.lines
                    .map((line) => [
                          line.medicine.name,
                          '${line.quantity}',
                          _money(line.medicine.price),
                          _money(line.total),
                        ])
                    .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 18),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                        'Subtotal (original prices): ${_money(bill.subtotal)}'),
                    if (bill.discountPercent > 0)
                      pw.Text(
                          'Manual discount (${bill.discountPercent.toStringAsFixed(2)}%): - ${_money(bill.discountAmount)}'),
                    pw.SizedBox(height: 5),
                    pw.Text('Total due: ${_money(bill.total)}',
                        style: pw.TextStyle(
                            fontSize: 15, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Center(child: pw.Text('Thank you for your visit.')),
            ],
          ),
        ),
      );
      await Printing.layoutPdf(
        name: 'pharmacy-bill-${bill.createdAt.millisecondsSinceEpoch}.pdf',
        onLayout: (_) async => document.save(),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not print bill: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bill ready'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Muhammad Discount Pharmacy - Chakdara',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(bill.shop.address.isEmpty
                  ? 'Address not set'
                  : bill.shop.address),
              Text(bill.shop.phone.isEmpty ? 'Phone not set' : bill.shop.phone),
              const SizedBox(height: 4),
              Text(DateFormat('dd MMM yyyy, hh:mm a').format(bill.createdAt),
                  style: const TextStyle(color: Colors.black54)),
              const Divider(height: 25),
              ...bill.lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      Expanded(
                          child:
                              Text('${line.medicine.name} × ${line.quantity}')),
                      Text(_money(line.total)),
                    ],
                  ),
                ),
              ),
              const Divider(height: 20),
              _AmountRow(
                  label: 'Subtotal · original prices',
                  amount: _money(bill.subtotal)),
              if (bill.discountPercent > 0) ...[
                const SizedBox(height: 9),
                _AmountRow(
                  label:
                      'Manual discount (${bill.discountPercent.toStringAsFixed(2)}%)',
                  amount: '- ${_money(bill.discountAmount)}',
                  color: const Color(0xFF176B52),
                ),
              ],
              const SizedBox(height: 12),
              _AmountRow(
                  label: 'Total due',
                  amount: _money(bill.total),
                  emphasize: true),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Done')),
        FilledButton.icon(
          onPressed: () => _print(context),
          icon: const Icon(Icons.print_outlined),
          label: const Text('Print bill'),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              const Text('Could not load saved pharmacy data.'),
              const SizedBox(height: 6),
              Text('$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
}

String _money(double value) => 'PKR ${value.toStringAsFixed(2)}';

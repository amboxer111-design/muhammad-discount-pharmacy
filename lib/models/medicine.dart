class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.company,
    required this.category,
    required this.price,
    required this.stock,
    required this.expiry,
    required this.rackNumber,
  });

  final String id;
  final String name;
  final String company;
  final String category;
  final double price;
  final int stock;
  final DateTime expiry;
  final String rackNumber;

  bool get isExpired {
    final today = DateTime.now();
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    return expiryDay.isBefore(DateTime(today.year, today.month, today.day));
  }

  bool get expiresWithinMonth {
    if (isExpired) return false;
    final today = DateTime.now();
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    return expiryDay.isBefore(
      DateTime(today.year, today.month, today.day)
          .add(const Duration(days: 31)),
    );
  }

  Medicine copyWith({
    String? id,
    String? name,
    String? company,
    String? category,
    double? price,
    int? stock,
    DateTime? expiry,
    String? rackNumber,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      expiry: expiry ?? this.expiry,
      rackNumber: rackNumber ?? this.rackNumber,
    );
  }

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'company': company,
        'category': category,
        'price': price,
        'stock': stock,
        'expiry': expiry.toIso8601String(),
        'rackNumber': rackNumber,
      };

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      name: json['name'] as String,
      company: json['company'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      expiry: DateTime.parse(json['expiry'] as String),
      rackNumber: json['rackNumber'] as String,
    );
  }
}

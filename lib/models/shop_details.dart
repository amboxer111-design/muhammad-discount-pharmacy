class ShopDetails {
  const ShopDetails({
    this.address = '',
    this.phone = '',
  });

  final String address;
  final String phone;

  ShopDetails copyWith({String? address, String? phone}) {
    return ShopDetails(
      address: address ?? this.address,
      phone: phone ?? this.phone,
    );
  }

  Map<String, String> toJson() => {'address': address, 'phone': phone};

  factory ShopDetails.fromJson(Map<String, dynamic> json) => ShopDetails(
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
      );
}

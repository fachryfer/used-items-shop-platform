class ShippingAddress {
  final String fullName;
  final String phoneNumber;
  final String address;
  final String city;
  final String province;
  final String postalCode;
  final String? notes;

  ShippingAddress({
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.province,
    required this.postalCode,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'city': city,
      'province': province,
      'postalCode': postalCode,
      'notes': notes,
    };
  }

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      province: map['province'] ?? '',
      postalCode: map['postalCode'] ?? '',
      notes: map['notes'],
    );
  }
} 
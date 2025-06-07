import 'package:cloud_firestore/cloud_firestore.dart';
import 'shipping_address.dart';

class UserAddress {
  final String id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String address;
  final String city;
  final String province;
  final String postalCode;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserAddress({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.province,
    required this.postalCode,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'city': city,
      'province': province,
      'postalCode': postalCode,
      'isDefault': isDefault,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory UserAddress.fromMap(Map<String, dynamic> map) {
    return UserAddress(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      province: map['province'] ?? '',
      postalCode: map['postalCode'] ?? '',
      isDefault: map['isDefault'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  ShippingAddress toShippingAddress() {
    return ShippingAddress(
      fullName: fullName,
      phoneNumber: phoneNumber,
      address: address,
      city: city,
      province: province,
      postalCode: postalCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAddress && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
} 
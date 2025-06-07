import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String itemId;
  final String itemName;
  final double itemPrice;
  final int quantity;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String? itemImageUrl;
  final String status; // e.g., 'pending', 'completed', 'cancelled'
  final DateTime? orderDate;

  Order({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.itemPrice,
    required this.quantity,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    this.itemImageUrl,
    this.status = 'pending',
    this.orderDate,
  });

  factory Order.fromFirestore(Map<String, dynamic> data, String id) {
    return Order(
      id: id,
      itemId: data['itemId'] ?? '',
      itemName: data['itemName'] ?? '',
      itemPrice: (data['itemPrice'] ?? 0.0).toDouble(),
      quantity: (data['quantity'] ?? 0).toInt(),
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      itemImageUrl: data['itemImageUrl'],
      status: data['status'] ?? 'pending',
      orderDate: (data['orderDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'itemPrice': itemPrice,
      'quantity': quantity,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'itemImageUrl': itemImageUrl,
      'status': status,
      'orderDate': orderDate != null ? Timestamp.fromDate(orderDate!) : FieldValue.serverTimestamp(),
    };
  }
} 
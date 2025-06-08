import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edar_shop/models/cart_item.dart';

class Order {
  final String id;
  final List<CartItem> cartItems;
  final double totalAmount;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName; // This might become less relevant for multi-item orders
  final String status; // e.g., 'pending', 'completed', 'cancelled'
  final DateTime? orderDate;
  final Map<String, dynamic>? shippingAddress;
  final String? paymentMethod;
  final Map<String, dynamic>? paymentDetails;
  final String? transferProofImageUrl;

  Order({
    required this.id,
    required this.cartItems,
    required this.totalAmount,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    this.status = 'pending',
    this.orderDate,
    this.shippingAddress,
    this.paymentMethod,
    this.paymentDetails,
    this.transferProofImageUrl,
  });

  factory Order.fromFirestore(Map<String, dynamic> data, String id) {
    var itemsData = data['cartItems'] as List<dynamic>?;
    List<CartItem> items = itemsData != null
        ? itemsData.map((itemData) => CartItem.fromFirestore(itemData as Map<String, dynamic>)).toList()
        : [];

    return Order(
      id: id,
      cartItems: items,
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      sellerId: data['sellerId'] ?? '', // Consider how to handle multiple sellers if items are from different sellers
      sellerName: data['sellerName'] ?? '',
      status: data['status'] ?? 'pending',
      orderDate: (data['orderDate'] as Timestamp?)?.toDate(),
      shippingAddress: data['shippingAddress'] as Map<String, dynamic>?,
      paymentMethod: data['paymentMethod'] as String?,
      paymentDetails: data['paymentDetails'] as Map<String, dynamic>?,
      transferProofImageUrl: data['transferProofImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cartItems': cartItems.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'status': status,
      'orderDate': orderDate != null ? Timestamp.fromDate(orderDate!) : FieldValue.serverTimestamp(),
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'paymentDetails': paymentDetails,
      'transferProofImageUrl': transferProofImageUrl,
    };
  }
} 
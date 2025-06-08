import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CartItem {
  final String itemId;
  final String name;
  final String imageUrl;
  final double price;
  int quantity;

  CartItem({
    required this.itemId,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.quantity = 1,
  });

  // Method to convert CartItem to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
    };
  }

  // Factory method to create CartItem from Firestore DocumentSnapshot
  factory CartItem.fromFirestore(Map<String, dynamic> data) {
    return CartItem(
      itemId: data['itemId'] as String,
      name: data['name'] as String,
      imageUrl: data['imageUrl'] as String,
      price: (data['price'] as num).toDouble(),
      quantity: data['quantity'] as int,
    );
  }
} 
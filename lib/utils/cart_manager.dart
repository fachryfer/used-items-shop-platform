import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartManager extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  void addItem(CartItem item) {
    if (_items.containsKey(item.itemId)) {
      _items[item.itemId]!.quantity++;
    } else {
      _items[item.itemId] = item;
    }
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.remove(itemId);
    notifyListeners();
  }

  void updateItemQuantity(String itemId, int newQuantity) {
    if (_items.containsKey(itemId)) {
      if (newQuantity <= 0) {
        _items.remove(itemId);
      } else {
        _items[itemId]!.quantity = newQuantity;
      }
      notifyListeners();
    }
  }

  double get totalPrice {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  int get totalItems {
    int total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.quantity;
    });
    return total;
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
} 
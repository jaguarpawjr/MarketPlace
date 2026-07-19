import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:marketplace/models/user_profile.dart' as user_profile;



class Product {
  final String name;
  final String category;
  final String location;
  final String price;
  final double priceValue;
  final String freshness;
  final double rating;
  final String badge;
  final bool highlight;
  final Color imageColor;
  final String farmerName;

  const Product({
    required this.name,
    required this.category,
    required this.location,
    required this.price,
    required this.priceValue,
    required this.freshness,
    required this.rating,
    required this.badge,
    required this.highlight,
    required this.imageColor,
    required this.farmerName,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.priceValue * quantity;
}

class Order {
  final int id;
  final DateTime date;
  final List<CartItem> items;
  final double totalPrice;
  final String status;

  Order({
    required this.id,
    required this.date,
    required this.items,
    required this.totalPrice,
    required this.status,
  });
}

class UserSession {
  static user_profile.UserRole currentRole = user_profile.UserRole.buyer;
  static final List<Product> products = [
    Product(
      name: 'Avocado Bundle',
      category: 'Fruits',
      location: 'Nakuru, Kenya',
      price: 'Ksh 120/kg',
      priceValue: 120,
      freshness: 'Fresh today',
      rating: 4.8,
      badge: 'Best seller',
      highlight: true,
      imageColor: Color(0xFF8CCF75),
      farmerName: 'Monday Farm',
    ),
    Product(
      name: 'Tomato Basket',
      category: 'Vegetables',
      location: 'Uasin Gishu, Kenya',
      price: 'Ksh 45/kg',
      priceValue: 45,
      freshness: 'Just harvested',
      rating: 4.6,
      badge: 'Seasonal',
      highlight: false,
      imageColor: Color(0xFFEB6A5F),
      farmerName: 'Green Valley',
    ),
    Product(
      name: 'Organic Eggs',
      category: 'Dairy',
      location: 'Baringo, Kenya',
      price: 'Ksh 350/box',
      priceValue: 350,
      freshness: 'Farm fresh',
      rating: 4.9,
      badge: 'Local',
      highlight: false,
      imageColor: Color(0xFFF2D479),
      farmerName: 'Lakeview Farm',
    ),
    Product(
      name: 'Thyme Bundle',
      category: 'Herbs',
      location: 'Meru, Kenya',
      price: 'Ksh 80/bunch',
      priceValue: 80,
      freshness: 'Picked today',
      rating: 4.7,
      badge: 'Aromatic',
      highlight: false,
      imageColor: Color(0xFF78B8A4),
      farmerName: 'Herb Haven',
    ),
  ];
  static final List<Product> myListings = [];
  static final List<CartItem> cart = [];
  static final List<Order> orders = [];
  static int _nextOrderId = 1;

  static bool get isFarmer => currentRole == user_profile.UserRole.farmer;
  static bool get isBuyer => currentRole == user_profile.UserRole.buyer;

  static CollectionReference<Map<String, dynamic>> get _usersCollection =>
      FirebaseFirestore.instance.collection('users');

  static void setRole(user_profile.UserRole role) {
    currentRole = role;
  }

  static Future<void> saveRoleForUser(String uid, user_profile.UserRole role) async {
    await _usersCollection.doc(uid).set({
      'role': role.name,
    }, SetOptions(merge: true));
  }

  static Future<user_profile.UserRole?> loadRoleForUser(String uid) async {
    final snapshot = await _usersCollection.doc(uid).get();
    if (!snapshot.exists) return null;

    final roleString = snapshot.data()?['role'] as String?;
    if (roleString == 'farmer') {
      return user_profile.UserRole.farmer;
    }
    return user_profile.UserRole.buyer;
  }

  static void addToCart(Product product) {
    final existing = cart
        .where((item) => item.product.name == product.name)
        .toList();
    if (existing.isNotEmpty) {
      existing.first.quantity += 1;
      return;
    }
    cart.add(CartItem(product: product));
  }

  static void removeFromCart(Product product) {
    cart.removeWhere((item) => item.product.name == product.name);
  }

  static void updateCartQuantity(Product product, int quantity) {
    final item = cart.firstWhere(
      (entry) => entry.product.name == product.name,
      orElse: () => throw StateError('Product not in cart'),
    );
    if (quantity <= 0) {
      removeFromCart(product);
      return;
    }
    item.quantity = quantity;
  }

  static double get cartTotal =>
      cart.fold(0.0, (total, item) => total + item.totalPrice);

  static void placeOrder() {
    if (cart.isEmpty) return;
    orders.add(
      Order(
        id: _nextOrderId++,
        date: DateTime.now(),
        items: cart
            .map(
              (item) =>
                  CartItem(product: item.product, quantity: item.quantity),
            )
            .toList(),
        totalPrice: cartTotal,
        status: 'Processing',
      ),
    );
    cart.clear();
  }

  static void addListing(Product product) {
    products.add(product);
    myListings.add(product);
  }
}

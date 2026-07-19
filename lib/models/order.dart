import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;
  final String farmerId;
  final String buyerId;
  final int quantity;
  final double price;
  final String orderStatus;
  final DateTime timestamp;

  OrderModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.farmerId,
    required this.buyerId,
    required this.quantity,
    required this.price,
    required this.orderStatus,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'farmerId': farmerId,
      'buyerId': buyerId,
      'quantity': quantity,
      'price': price,
      'orderStatus': orderStatus,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory OrderModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return OrderModel(
      id: doc.id,
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? 'Unknown',
      productImageUrl: data['productImageUrl'] as String? ?? '',
      farmerId: data['farmerId'] as String? ?? '',
      buyerId: data['buyerId'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      orderStatus: data['orderStatus'] as String? ?? 'Pending',
      timestamp: _parseTimestamp(data['timestamp']),
    );
  }

  static DateTime _parseTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}

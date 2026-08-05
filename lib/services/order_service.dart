import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marketplace/models/order.dart';

class OrderService {
  static final _ordersRef = FirebaseFirestore.instance.collection('orders');

  static Future<void> createOrder(OrderModel order) async {
    final doc = _ordersRef.doc();
    await doc.set(order.toMap());
  }

  static Stream<List<OrderModel>> streamBuyerOrders(String buyerId) {
    return _ordersRef
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromDocument(doc)).toList());
  }

  static Stream<List<OrderModel>> streamFarmerOrders(String farmerId) {
    return _ordersRef
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromDocument(doc)).toList());
  }

  static Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _ordersRef.doc(orderId).update({'status': newStatus});
  }
}

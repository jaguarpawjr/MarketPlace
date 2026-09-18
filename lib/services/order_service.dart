import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marketplace/models/order.dart';
import 'package:marketplace/services/notification_service.dart';

class OrderService {
  static final _ordersRef = FirebaseFirestore.instance.collection('orders');

  static Future<String> createOrder(OrderModel order) async {
    final doc = _ordersRef.doc();
    await doc.set(order.toMap());
    return doc.id;
  }

  static Stream<List<OrderModel>> streamBuyerOrders(String buyerId) {
    return _ordersRef
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => OrderModel.fromDocument(doc)).toList(),
        );
  }

  static Stream<List<OrderModel>> streamFarmerOrders(String farmerId) {
    return _ordersRef
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => OrderModel.fromDocument(doc)).toList(),
        );
  }

  static Future<void> updateOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    final orderSnapshot = await _ordersRef.doc(orderId).get();
    final order = orderSnapshot.exists
        ? OrderModel.fromDocument(orderSnapshot)
        : null;
    await _ordersRef.doc(orderId).update({'orderStatus': newStatus});

    if (order != null && newStatus == 'Accepted') {
      await NotificationService.addNotification(
        userId: order.buyerId,
        title: 'Order approved',
        body: '${order.productName} was approved. You can now pay for it.',
        type: 'order_approved',
        data: {'orderId': orderId},
      );
    }
  }
}

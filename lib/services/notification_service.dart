import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return AppNotification(
      id: doc.id,
      title: data['title'] as String? ?? 'Notification',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? 'general',
      read: data['read'] as bool? ?? false,
      createdAt: _parseCreatedAt(data['createdAt']),
    );
  }

  static DateTime _parseCreatedAt(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

class NotificationService {
  static Future<void> registerCurrentUserToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      await messaging.subscribeToTopic(_topicForUser(user.uid));
      if (token == null || token.isEmpty) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Token registration is best-effort.
    }
  }

  static Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final payload = data ?? <String, dynamic>{};
    final topic = _topicForUser(userId);

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'topic': topic,
      'title': title,
      'body': body,
      'type': type,
      'data': payload,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtMillis': DateTime.now().millisecondsSinceEpoch,
    });

    await FirebaseFirestore.instance.collection('notificationOutbox').add({
      'targetUserId': userId,
      'topic': topic,
      'title': title,
      'body': body,
      'type': type,
      'data': payload,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtMillis': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Stream<List<AppNotification>> streamCurrentUserNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(const <AppNotification>[]);

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => AppNotification.fromDocument(doc))
          .toList();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  static String _topicForUser(String userId) {
    return 'user_$userId';
  }
}

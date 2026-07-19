import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FavoriteService {
  static final _favoritesRef = FirebaseFirestore.instance.collection('favorites');

  static Future<void> toggleFavorite(String buyerId, String farmerId, String farmerName, bool isFavorite) async {
    final docId = '${buyerId}_$farmerId';
    final docRef = _favoritesRef.doc(docId);

    if (isFavorite) {
      await docRef.set({
        'buyerId': buyerId,
        'farmerId': farmerId,
        'farmerName': farmerName,
        'timestamp': FieldValue.serverTimestamp(),
      });
      try {
        await FirebaseMessaging.instance.subscribeToTopic('farmer_$farmerId');
      } catch (e) {
        // Handle gracefully if FCM is not supported (e.g. web or missing credentials)
        print('Error subscribing to topic: $e');
      }
    } else {
      await docRef.delete();
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic('farmer_$farmerId');
      } catch (e) {
        print('Error unsubscribing from topic: $e');
      }
    }
  }

  static Stream<bool> isFavoriteStream(String buyerId, String farmerId) {
    final docId = '${buyerId}_$farmerId';
    return _favoritesRef.doc(docId).snapshots().map((snapshot) => snapshot.exists);
  }

  static Stream<List<Map<String, dynamic>>> streamFavoriteFarmers(String buyerId) {
    return _favoritesRef
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MarketProduct {
  final String id;
  final String name;
  final String category;
  final String location;
  final String price;
  final String freshness;
  final double rating;
  final String badge;
  final bool highlight;
  final int imageColorValue;
  final List<String> mediaUrls;
  final String farmerId;
  final String farmerName;
  final DateTime createdAt;

  MarketProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.price,
    required this.freshness,
    required this.rating,
    required this.badge,
    required this.highlight,
    required this.imageColorValue,
    required this.mediaUrls,
    required this.farmerId,
    required this.farmerName,
    required this.createdAt,
  });

  Color get imageColor => Color(imageColorValue);

  bool get hasMedia => mediaUrls.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'location': location,
      'price': price,
      'freshness': freshness,
      'rating': rating,
      'badge': badge,
      'highlight': highlight,
      'imageColorValue': imageColorValue,
      'mediaUrls': mediaUrls,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MarketProduct.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return MarketProduct(
      id: doc.id,
      name: data['name'] as String? ?? 'Unknown',
      category: data['category'] as String? ?? 'Unknown',
      location: data['location'] as String? ?? 'Unknown',
      price: data['price'] as String? ?? 'Ksh 0',
      freshness: data['freshness'] as String? ?? 'Fresh',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      badge: data['badge'] as String? ?? 'New',
      highlight: data['highlight'] as bool? ?? false,
      imageColorValue: data['imageColorValue'] as int? ?? 0xFF8CCF75,
      mediaUrls: List<String>.from(data['mediaUrls'] as List<dynamic>? ?? []),
      farmerId: data['farmerId'] as String? ?? '',
      farmerName: data['farmerName'] as String? ?? 'Farmer',
      createdAt: _parseCreatedAt(data['createdAt']),
    );
  }

  static DateTime _parseCreatedAt(Object? value) {
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

  MarketProduct copyWith({
    String? id,
    String? name,
    String? category,
    String? location,
    String? price,
    String? freshness,
    double? rating,
    String? badge,
    bool? highlight,
    int? imageColorValue,
    List<String>? mediaUrls,
    String? farmerId,
    String? farmerName,
    DateTime? createdAt,
  }) {
    return MarketProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      price: price ?? this.price,
      freshness: freshness ?? this.freshness,
      rating: rating ?? this.rating,
      badge: badge ?? this.badge,
      highlight: highlight ?? this.highlight,
      imageColorValue: imageColorValue ?? this.imageColorValue,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MarketService {
  static final _productsRef = FirebaseFirestore.instance.collection('products');
  static final _storage = FirebaseStorage.instance;

  static Stream<List<MarketProduct>> streamProducts({
    bool featuredOnly = false,
  }) {
    final query = _productsRef.orderBy('createdAt', descending: true);
    return query.snapshots().map((snapshot) {
      final docs = snapshot.docs
          .map((doc) => MarketProduct.fromDocument(doc))
          .toList();
      if (featuredOnly) {
        final featured = docs.where((product) => product.highlight).toList();
        if (featured.isNotEmpty) {
          return featured;
        }
        return docs.take(4).toList();
      }
      // Sort by highlight first (featured items appear first), then by creation time
      if (!featuredOnly) {
        docs.sort((a, b) {
          if (a.highlight != b.highlight) {
            return b.highlight ? 1 : -1;
          }
          return b.createdAt.compareTo(a.createdAt);
        });
      }
      return docs;
    });
  }

  static Stream<List<MarketProduct>> streamProductsForFarmer(String farmerId) {
    return _productsRef
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MarketProduct.fromDocument(doc))
              .toList();
        });
  }

  static Future<void> saveProduct(MarketProduct product) async {
    final doc = product.id.isNotEmpty
        ? _productsRef.doc(product.id)
        : _productsRef.doc();
    await doc.set(product.copyWith(id: doc.id).toMap());
  }

  static Future<void> deleteProduct(String productId) async {
    await _productsRef.doc(productId).delete();
  }

  static Future<void> updateProductRating({
    required String productId,
    required double rating,
  }) async {
    await _productsRef.doc(productId).update({'rating': rating});
  }

  static Future<String> uploadMediaFile(XFile file) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User must be signed in to upload media.');
    }
    final name = file.name.replaceAll(' ', '_');
    final storagePath =
        'product_media/${currentUser.uid}/${DateTime.now().millisecondsSinceEpoch}_$name';
    final ref = _storage.ref().child(storagePath);
    final metadata = SettableMetadata(contentType: file.mimeType);
    final uploadTask = ref.putData(await file.readAsBytes(), metadata);
    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }

  static Future<List<String>> uploadMediaFiles(List<XFile> files) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(await uploadMediaFile(file));
    }
    return urls;
  }
}

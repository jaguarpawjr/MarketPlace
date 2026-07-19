import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { farmer, buyer }

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.farmer:
        return 'Farmer';
      case UserRole.buyer:
        return 'Buyer';
    }
  }

  String get description {
    switch (this) {
      case UserRole.farmer:
        return 'FarmerSell agricultural products, manage listings, and use farm tools.';
      case UserRole.buyer:
        return 'BuyerBrowse products, purchase produce, and contact farmers.';
    }
  }

  static UserRole? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'farmer':
        return UserRole.farmer;
      case 'buyer':
        return UserRole.buyer;
      default:
        return null;
    }
  }
}

class UserProfile {
  final String uid;
  final String? displayName;
  final String? email;
  final String? phoneNumber;
  final String? photoURL;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  UserProfile({
    required this.uid,
    required this.role,
    this.displayName,
    this.email,
    this.phoneNumber,
    this.photoURL,
    this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'role': role.label.toLowerCase(),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'lastLogin': lastLogin == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(lastLogin!),
    };
  }

  factory UserProfile.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      photoURL: data['photoURL'] as String?,
      role:
          UserRoleExtension.fromString(data['role'] as String?) ??
          UserRole.buyer,
      createdAt: _parseTimestamp(data['createdAt']),
      lastLogin: _parseTimestamp(data['lastLogin']),
    );
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? phoneNumber,
    String? photoURL,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

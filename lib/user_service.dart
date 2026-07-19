import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marketplace/models/user_profile.dart';

class UserService {
  static final _usersRef = FirebaseFirestore.instance.collection('users');

  static Future<UserProfile?> getUserProfile(String uid) async {
    final snapshot = await _usersRef.doc(uid).get();
    if (!snapshot.exists) return null;

    return UserProfile.fromDocument(snapshot);
  }

  static Future<UserRole?> resolveUserRole(User user) async {
    final profile = await getUserProfile(user.uid);
    if (profile == null) return null;

    await _usersRef.doc(user.uid).set({
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return profile.role;
  }

  static Future<UserProfile> saveUserProfile(User user, UserRole role) async {
    final profile = UserProfile(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      phoneNumber: user.phoneNumber,
      photoURL: user.photoURL,
      role: role,
      createdAt: null,
      lastLogin: null,
    );

    final data = {
      'uid': user.uid,
      'displayName': user.displayName,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'photoURL': user.photoURL,
      'role': role.label.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    };

    await _usersRef.doc(user.uid).set(data, SetOptions(merge: true));
    return profile;
  }

  static Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    await _usersRef.doc(uid).set(updates, SetOptions(merge: true));
  }
}

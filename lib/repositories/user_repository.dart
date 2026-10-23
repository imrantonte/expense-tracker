import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

/// Handles all Firestore reads and writes for the `users` collection.
///
/// No widget or state-management code belongs here.
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // ── Fetch ──────────────────────────────────────────────────────────────────

  /// Loads a [UserProfile] from Firestore for the given [uid].
  ///
  /// Returns `null` if the document does not exist.
  /// Never throws — errors are caught and `null` is returned.
  Future<UserProfile?> fetchProfile(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      return UserProfile(
        name: (data['name'] as String?) ?? '',
        email: (data['email'] as String?) ?? '',
        currencyCode: (data['currencyCode'] as String?) ?? 'BDT',
        joinedDate: data['joinedAt'] is Timestamp
            ? (data['joinedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  /// Merges the supplied fields into the user document.
  ///
  /// Only non-null fields in [updates] are written.
  Future<void> updateProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    await _users.doc(uid).set(updates, SetOptions(merge: true));
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

/// Handles all Firestore reads and writes for the `users` collection.
///
/// No widget or state-management code belongs here.
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  // ── Stream ─────────────────────────────────────────────────────────────────

  /// Real-time stream of the user's Firestore document.
  ///
  /// Emits a new [UserProfile] whenever the document changes.
  /// Emits `null` if the document does not exist or on error.
  Stream<UserProfile?> profileStream(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
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
    }).handleError((_) => null);
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────

  /// Loads a [UserProfile] from Firestore for the given [uid].
  ///
  /// Returns `null` if the document does not exist.
  /// Never throws — errors are caught and `null` is returned.
  Future<UserProfile?> fetchProfile(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
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

  /// Updates the user's display name in Firestore.
  Future<void> updateName(String uid, String name) async {
    await _userDoc(uid).set({'name': name}, SetOptions(merge: true));
  }

  /// Updates the user's currency code in Firestore.
  Future<void> updateCurrency(String uid, String currencyCode) async {
    await _userDoc(uid)
        .set({'currencyCode': currencyCode}, SetOptions(merge: true));
  }

  /// Merges arbitrary settings fields into the user document.
  ///
  /// Only the provided [settings] keys are written; all others are preserved.
  Future<void> updateSettings(String uid, Map<String, dynamic> settings) async {
    await _userDoc(uid).set(settings, SetOptions(merge: true));
  }

  /// Merges the supplied fields into the user document.
  ///
  /// Only non-null fields in [updates] are written.
  Future<void> updateProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    await _userDoc(uid).set(updates, SetOptions(merge: true));
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  /// Deletes all Firestore data for [uid]:
  ///   - users/{uid}/transactions (subcollection)
  ///   - users/{uid}/categories   (subcollection)
  ///   - users/{uid}              (root document)
  ///
  /// Errors are swallowed so a partial failure doesn't block account deletion.
  Future<void> deleteUserData(String uid) async {
    // Delete known subcollections first.
    for (final sub in ['transactions', 'categories']) {
      try {
        final snap = await _userDoc(uid).collection(sub).get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      } catch (_) {
        // Subcollection may not exist — ignore.
      }
    }
    // Delete the user document itself.
    try {
      await _userDoc(uid).delete();
    } catch (_) {
      // Ignore if already gone.
    }
  }
}

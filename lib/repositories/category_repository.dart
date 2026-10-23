import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/mock_data.dart' as mock;

/// Handles Firestore reads and writes for `users/{uid}/categories`.
///
/// On first login, seeds the design's default expense + income categories
/// if none yet exist.
class CategoryRepository {
  CategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _catCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('categories');

  // ── Seed ───────────────────────────────────────────────────────────────────

  /// Seeds default categories for [uid] if `users/{uid}/categories` is empty.
  ///
  /// Uses a batch write so it's atomic. Safe to call on every login —
  /// it's a no-op when docs already exist.
  Future<void> seedIfEmpty(String uid) async {
    try {
      final snap = await _catCol(uid).limit(1).get();
      if (snap.docs.isNotEmpty) return; // already seeded

      final batch = _firestore.batch();

      for (final cat in [
        ...mock.expenseCategories,
        ...mock.incomeCategories,
      ]) {
        final ref = _catCol(uid).doc(cat.id);
        batch.set(ref, {
          'name': cat.name,
          'isIncome': cat.isIncome,
          'colorValue': cat.color.toARGB32(),
          // We store the icon code-point so it can be restored later.
          'iconCodePoint': cat.icon.codePoint,
          'iconFontFamily': cat.icon.fontFamily ?? 'MaterialIcons',
        });
      }

      await batch.commit();
    } catch (_) {
      // Seeding is best-effort — the app works fine with static categories.
    }
  }
}

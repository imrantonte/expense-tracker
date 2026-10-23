import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/managed_category.dart';

/// Handles Firestore reads and writes for `users/{uid}/categories`.
///
/// On first login, seeds the design's default expense + income categories
/// if none yet exist.  After that, all CRUD is driven by this repository.
class CategoryRepository {
  CategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _catCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('categories');

  CollectionReference<Map<String, dynamic>> _txCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('transactions');

  // ── Seed ──────────────────────────────────────────────────────────────────

  /// Seeds default categories for [uid] if the subcollection is empty.
  ///
  /// Uses a batch write. Safe to call on every login — no-op when docs exist.
  Future<void> seedIfEmpty(String uid) async {
    try {
      final snap = await _catCol(uid).limit(1).get();
      if (snap.docs.isNotEmpty) return; // already seeded

      final batch = _firestore.batch();
      for (final catMap in _buildDefaults()) {
        final id = catMap['id'] as String;
        final data = Map<String, dynamic>.from(catMap)..remove('id');
        batch.set(_catCol(uid).doc(id), data);
      }
      await batch.commit();
    } catch (_) {
      // Seeding is best-effort.
    }
  }

  // ── Stream ────────────────────────────────────────────────────────────────

  /// Real-time stream of all managed categories for [uid].
  Stream<List<ManagedCategory>> watchCategories(String uid) {
    return _catCol(uid).snapshots().map((snap) {
      return snap.docs
          .map((doc) => ManagedCategory.fromMap(doc.id, doc.data()))
          .whereType<ManagedCategory>()
          .toList();
    }).handleError((_) => <ManagedCategory>[]);
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns true if any transaction references [categoryId].
  Future<bool> isCategoryInUse(String uid, String categoryId) async {
    try {
      final snap = await _txCol(uid)
          .where('categoryId', isEqualTo: categoryId)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      // If we can't check, be safe and say it might be in use.
      return true;
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Creates a new category.  Returns the stored doc id.
  Future<String> add(String uid, ManagedCategory cat) async {
    if (cat.id.isEmpty) {
      final ref = await _catCol(uid).add(cat.toMap());
      return ref.id;
    }
    await _catCol(uid).doc(cat.id).set(cat.toMap());
    return cat.id;
  }

  /// Updates an existing category document.
  Future<void> update(String uid, ManagedCategory cat) async {
    await _catCol(uid).doc(cat.id).set(cat.toMap());
  }

  /// Deletes a category.
  ///
  /// Callers should call [isCategoryInUse] first and block deletion if true.
  Future<void> delete(String uid, String categoryId) async {
    await _catCol(uid).doc(categoryId).delete();
  }

  // ── Default categories ────────────────────────────────────────────────────
  // Built at runtime so we can use regular Maps without const restrictions.

  static List<Map<String, dynamic>> _buildDefaults() => [
        // Expenses
        _cat('food', 'Food', 0xe533, 0xFFFF7043, false, 'Meals and groceries'),
        _cat('transport', 'Transport', 0xe1d5, 0xFF42A5F5, false, 'Getting around'),
        _cat('bills', 'Bills', 0xe4d2, 0xFFAB47BC, false, 'Utilities and subscriptions'),
        _cat('entertainment', 'Entertainment', 0xe40c, 0xFF5C6BC0, false, 'Fun and leisure'),
        _cat('shopping', 'Shopping', 0xe59c, 0xFFEC407A, false, 'Retail purchases'),
        _cat('health', 'Health', 0xe3f3, 0xFF26A69A, false, 'Medical and wellness'),
        _cat('education', 'Education', 0xe59e, 0xFF78909C, false, 'Courses and books'),
        _cat('rent', 'Rent', 0xe318, 0xFF8D6E63, false, 'Housing cost'),
        _cat('other_expense', 'Other', 0xe1b8, 0xFF90A4AE, false, 'Miscellaneous expenses'),
        // Income
        _cat('salary', 'Salary', 0xe06f, 0xFF00897B, true, 'Monthly salary'),
        _cat('tutoring', 'Tutoring', 0xe3d5, 0xFF42A5F5, true, 'Teaching income'),
        _cat('freelance', 'Freelance', 0xe3c4, 0xFF5C6BC0, true, 'Contract work'),
        _cat('allowance', 'Allowance', 0xe2a9, 0xFFFF7043, true, 'Family support'),
        _cat('scholarship', 'Scholarship', 0xe224, 0xFFFFB300, true, 'Academic grant'),
        _cat('gift', 'Gift', 0xe1a5, 0xFFEC407A, true, 'Received gifts'),
        _cat('business', 'Business', 0xe14e, 0xFF2E9E5B, true, 'Business income'),
        _cat('other_income', 'Other', 0xe1b8, 0xFF90A4AE, true, 'Miscellaneous income'),
      ];

  static Map<String, dynamic> _cat(
    String id,
    String name,
    int iconCodePoint,
    int colorValue,
    bool isIncome,
    String description,
  ) =>
      {
        'id': id,
        'name': name,
        'iconCodePoint': iconCodePoint,
        'iconFontFamily': 'MaterialIcons',
        'colorValue': colorValue,
        'isIncome': isIncome,
        'description': description,
      };
}

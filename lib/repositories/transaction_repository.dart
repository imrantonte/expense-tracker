import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transaction_item.dart';

/// Handles all Firestore reads and writes for `users/{uid}/transactions`.
///
/// No widget or state-management code belongs here.
class TransactionRepository {
  TransactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _txCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('transactions');

  // ── Stream ─────────────────────────────────────────────────────────────────

  /// Real-time stream of all transactions for [uid], ordered newest-first.
  ///
  /// Each Firestore snapshot includes metadata so callers can detect
  /// pending writes (offline edits not yet synced).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchRaw(String uid) =>
      _txCol(uid)
          .orderBy('date', descending: true)
          .snapshots(includeMetadataChanges: true);

  /// Convenience stream that maps raw snapshots to [TransactionItem] lists.
  ///
  /// Documents that fail to parse are skipped (never throws).
  Stream<List<TransactionItem>> watchTransactions(String uid) {
    return watchRaw(uid).map((snap) {
      return snap.docs
          .map(_fromDoc)
          .whereType<TransactionItem>() // removes nulls from failed parses
          .toList();
    });
  }

  // ── Conversions ────────────────────────────────────────────────────────────

  TransactionItem? _fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final d = doc.data();
      return TransactionItem(
        id: doc.id,
        title: (d['title'] as String?) ?? '',
        note: d['note'] as String?,
        categoryId: (d['categoryId'] as String?) ?? '',
        amount: ((d['amount'] as num?) ?? 0).toDouble(),
        isIncome: (d['isIncome'] as bool?) ?? false,
        date: d['date'] is Timestamp
            ? (d['date'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _toMap(TransactionItem tx) => {
        'title': tx.title,
        'note': tx.note,
        'categoryId': tx.categoryId,
        'amount': tx.amount,
        'isIncome': tx.isIncome,
        'date': Timestamp.fromDate(tx.date),
        'createdAt': FieldValue.serverTimestamp(),
      };

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Adds a new transaction. Returns the auto-generated Firestore doc id.
  Future<String> add(String uid, TransactionItem tx) async {
    final ref = await _txCol(uid).add(_toMap(tx));
    return ref.id;
  }

  /// Overwrites the transaction document identified by [tx.id].
  Future<void> update(String uid, TransactionItem tx) async {
    await _txCol(uid).doc(tx.id).set(_toMap(tx));
  }

  /// Deletes the transaction with [id].
  Future<void> delete(String uid, String id) async {
    await _txCol(uid).doc(id).delete();
  }
}

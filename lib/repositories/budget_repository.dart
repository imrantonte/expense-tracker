import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/budget.dart';

/// Handles all Firestore reads and writes for `users/{uid}/budgets/{yyyy-MM}`.
///
/// Each month gets its own document so history is preserved.
class BudgetRepository {
  BudgetRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ── Path helpers ─────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _budgetCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('budgets');

  /// Doc id is `yyyy-MM`, e.g. `2026-10`.
  static String monthKey(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  DocumentReference<Map<String, dynamic>> _budgetDoc(
          String uid, int year, int month) =>
      _budgetCol(uid).doc(monthKey(year, month));

  // ── Conversion ────────────────────────────────────────────────────────────

  Budget? _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) return null;
    final d = doc.data()!;
    return Budget(
      limit: ((d['limit'] as num?) ?? 0).toDouble(),
      alertThreshold:
          ((d['alertThreshold'] as num?) ?? 0.80).toDouble().clamp(0.0, 1.0),
      notifyEnabled: (d['notifyEnabled'] as bool?) ?? true,
    );
  }

  // ── Stream ────────────────────────────────────────────────────────────────

  /// Real-time stream for the current-month budget doc.
  ///
  /// Emits `null` when no budget has been set for this month.
  Stream<Budget?> watchBudget(String uid, int year, int month) {
    return _budgetDoc(uid, year, month)
        .snapshots()
        .map(_fromDoc)
        .handleError((_) => null);
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Fetches the budget document for a given month.
  ///
  /// Returns `null` if no budget has been set or on error.
  Future<Budget?> fetchBudget(String uid, int year, int month) async {
    try {
      final doc = await _budgetDoc(uid, year, month).get();
      return _fromDoc(doc);
    } catch (_) {
      return null;
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Creates or updates the budget for the given month.
  Future<void> saveBudget(
    String uid,
    int year,
    int month,
    Budget budget,
  ) async {
    await _budgetDoc(uid, year, month).set({
      'limit': budget.limit,
      'alertThreshold': budget.alertThreshold,
      'notifyEnabled': budget.notifyEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Alert-state flags ─────────────────────────────────────────────────────
  // We store two boolean flags in the budget doc to avoid sending duplicate
  // threshold / over-limit notifications in the same month.

  /// Returns true if the `alertSent` flag is set in the current-month doc.
  Future<bool> wasAlertSent(String uid, int year, int month) async {
    try {
      final doc = await _budgetDoc(uid, year, month).get();
      return (doc.data()?['alertSent'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the `overLimitSent` flag is set.
  Future<bool> wasOverLimitSent(String uid, int year, int month) async {
    try {
      final doc = await _budgetDoc(uid, year, month).get();
      return (doc.data()?['overLimitSent'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sets `alertSent = true` without touching other fields.
  Future<void> markAlertSent(String uid, int year, int month) async {
    try {
      await _budgetDoc(uid, year, month)
          .set({'alertSent': true}, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Sets `overLimitSent = true` without touching other fields.
  Future<void> markOverLimitSent(String uid, int year, int month) async {
    try {
      await _budgetDoc(uid, year, month)
          .set({'overLimitSent': true}, SetOptions(merge: true));
    } catch (_) {}
  }
}

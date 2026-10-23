import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';

/// Handles Firestore reads and writes for `users/{uid}/notifications`.
///
/// Notifications are created by the app (budget alerts) and read here.
class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _notifCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  // ── Conversion ────────────────────────────────────────────────────────────

  static NotificationType _typeFrom(String? s) {
    switch (s) {
      case 'budgetOver':
        return NotificationType.budgetOver;
      case 'budgetWarning':
        return NotificationType.budgetWarning;
      case 'budgetSet':
        return NotificationType.budgetSet;
      default:
        return NotificationType.general;
    }
  }

  static String _typeName(NotificationType t) {
    switch (t) {
      case NotificationType.budgetOver:
        return 'budgetOver';
      case NotificationType.budgetWarning:
        return 'budgetWarning';
      case NotificationType.budgetSet:
        return 'budgetSet';
      case NotificationType.general:
        return 'general';
    }
  }

  AppNotification? _fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final d = doc.data();
      return AppNotification(
        id: doc.id,
        title: (d['title'] as String?) ?? '',
        body: (d['body'] as String?) ?? '',
        time: d['createdAt'] is Timestamp
            ? (d['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        type: _typeFrom(d['type'] as String?),
        unread: (d['unread'] as bool?) ?? true,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Stream ────────────────────────────────────────────────────────────────

  /// Real-time stream of all notifications for [uid], newest first.
  Stream<List<AppNotification>> watchNotifications(String uid) {
    return _notifCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(_fromDoc)
            .whereType<AppNotification>()
            .toList())
        .handleError((_) => <AppNotification>[]);
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Creates a new notification document. Returns the generated doc id.
  Future<String?> addNotification({
    required String uid,
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    try {
      final ref = await _notifCol(uid).add({
        'title': title,
        'body': body,
        'type': _typeName(type),
        'unread': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  /// Marks a single notification as read.
  Future<void> markRead(String uid, String notifId) async {
    try {
      await _notifCol(uid).doc(notifId).set(
        {'unread': false},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  /// Marks every notification as read using a batched write.
  Future<void> markAllRead(String uid) async {
    try {
      final snap = await _notifCol(uid)
          .where('unread', isEqualTo: true)
          .get();
      if (snap.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'unread': false});
      }
      await batch.commit();
    } catch (_) {}
  }
}

import 'package:flutter/foundation.dart';

/// Semantic type for an [AppNotification], used to drive colour in the UI.
enum NotificationType {
  /// Budget exceeded — displayed in expense red.
  budgetOver,

  /// Budget threshold warning — displayed in amber.
  budgetWarning,

  /// Budget configured / informational — displayed in teal.
  budgetSet,

  /// Generic notification — displayed in secondary text colour.
  general,
}

/// A single in-app notification item.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.unread = true,
  });

  final String id;
  final String title;
  final String body;
  final DateTime time;
  final NotificationType type;

  /// Whether the user has seen / dismissed this notification.
  final bool unread;

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? time,
    NotificationType? type,
    bool? unread,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      type: type ?? this.type,
      unread: unread ?? this.unread,
    );
  }

  @override
  String toString() => 'AppNotification($id, $title, unread: $unread)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppNotification && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

import 'package:flutter/foundation.dart';

/// Monthly spending budget configuration.
@immutable
class Budget {
  const Budget({
    required this.limit,
    required this.alertThreshold,
    this.notifyEnabled = true,
  });

  /// The total monthly spending ceiling (e.g. ৳10,000).
  final double limit;

  /// Fraction (0–1) at which an alert notification is triggered.
  /// e.g. 0.80 means alert when 80 % of [limit] is spent.
  final double alertThreshold;

  /// Whether budget alert notifications are enabled for this month.
  final bool notifyEnabled;

  /// Returns a copy with the specified fields replaced.
  Budget copyWith({
    double? limit,
    double? alertThreshold,
    bool? notifyEnabled,
  }) {
    return Budget(
      limit: limit ?? this.limit,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      notifyEnabled: notifyEnabled ?? this.notifyEnabled,
    );
  }

  @override
  String toString() =>
      'Budget(limit: $limit, alertThreshold: ${(alertThreshold * 100).toStringAsFixed(0)}%, notifyEnabled: $notifyEnabled)';
}

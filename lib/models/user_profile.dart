import 'package:flutter/foundation.dart';

/// The signed-in user's profile information.
@immutable
class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.currencyCode,
    required this.joinedDate,
  });

  final String name;
  final String email;

  /// ISO 4217 currency code (e.g. 'BDT', 'USD', 'EUR').
  /// Changing this only swaps the displayed symbol — no conversion is applied.
  final String currencyCode;

  final DateTime joinedDate;

  UserProfile copyWith({
    String? name,
    String? email,
    String? currencyCode,
    DateTime? joinedDate,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      currencyCode: currencyCode ?? this.currencyCode,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }

  @override
  String toString() => 'UserProfile($name, $email, $currencyCode)';
}

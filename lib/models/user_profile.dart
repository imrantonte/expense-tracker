import 'package:flutter/foundation.dart';

/// The signed-in user's profile information.
@immutable
class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.currencyCode,
    required this.joinedDate,
    this.photoBase64,
    this.avatarId,
  });

  final String name;
  final String email;

  /// ISO 4217 currency code (e.g. 'BDT', 'USD', 'EUR').
  /// Changing this only swaps the displayed symbol — no conversion is applied.
  final String currencyCode;

  final DateTime joinedDate;

  /// Base64-encoded JPEG bytes of the user's custom photo (stored in Firestore).
  /// Priority 1 for [UserAvatar].
  final String? photoBase64;

  /// ID of a built-in illustrated avatar chosen by the user.
  /// Priority 2 for [UserAvatar] (after [photoBase64]).
  final String? avatarId;

  UserProfile copyWith({
    String? name,
    String? email,
    String? currencyCode,
    DateTime? joinedDate,
    Object? photoBase64 = _absent,
    Object? avatarId = _absent,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      currencyCode: currencyCode ?? this.currencyCode,
      joinedDate: joinedDate ?? this.joinedDate,
      photoBase64: photoBase64 == _absent
          ? this.photoBase64
          : photoBase64 as String?,
      avatarId:
          avatarId == _absent ? this.avatarId : avatarId as String?,
    );
  }

  static const Object _absent = Object();

  @override
  String toString() => 'UserProfile($name, $email, $currencyCode)';
}

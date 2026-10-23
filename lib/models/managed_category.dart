import 'package:flutter/material.dart';

/// A user-managed category stored in `users/{uid}/categories`.
///
/// Intentionally separate from [Category] (which drives transactions) so that
/// the two can evolve independently without breaking existing mock data.
@immutable
class ManagedCategory {
  const ManagedCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isIncome = false,
    this.description = '',
  });

  final String id;
  final String name;

  /// Material icon representing this category.
  final IconData icon;

  /// Accent colour used for badges.
  final Color color;

  /// `true` for income categories, `false` for expense categories.
  final bool isIncome;

  /// Short subtitle shown under the category name in the list.
  final String description;

  // ── Firestore conversion ──────────────────────────────────────────────────

  /// Key used to reconstruct the icon from its code-point.
  int get iconCodePoint => icon.codePoint;

  /// Creates a [ManagedCategory] from a Firestore document map.
  static ManagedCategory? fromMap(String id, Map<String, dynamic> d) {
    try {
      final codePoint = (d['iconCodePoint'] as num?)?.toInt() ?? Icons.category_rounded.codePoint;
      return ManagedCategory(
        id: id,
        name: (d['name'] as String?) ?? '',
        // ignore: non_const_argument_for_const_parameter
        icon: IconData(codePoint, fontFamily: 'MaterialIcons'),
        color: Color((d['colorValue'] as num?)?.toInt() ?? 0xFF00897B),
        isIncome: (d['isIncome'] as bool?) ?? false,
        description: (d['description'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'iconCodePoint': icon.codePoint,
        'iconFontFamily': icon.fontFamily ?? 'MaterialIcons',
        'colorValue': color.toARGB32(),
        'isIncome': isIncome,
        'description': description,
      };

  // ── Equality ──────────────────────────────────────────────────────────────

  ManagedCategory copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    bool? isIncome,
    String? description,
  }) =>
      ManagedCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        isIncome: isIncome ?? this.isIncome,
        description: description ?? this.description,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ManagedCategory && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

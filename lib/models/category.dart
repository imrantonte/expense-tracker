import 'package:flutter/material.dart';

/// A single expense or income category.
@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isIncome,
  });

  final String id;
  final String name;

  /// Material icon representing this category.
  final IconData icon;

  /// Accent colour used for badges and chips.
  final Color color;

  /// `true` for income categories, `false` for expense categories.
  final bool isIncome;

  @override
  String toString() => 'Category($id, $name, isIncome: $isIncome)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Category && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

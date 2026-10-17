import 'package:flutter/material.dart';

/// A user-managed category shown on the Manage Categories screen.
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
    this.description = '',
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;

  /// Short subtitle shown under the category name in the list.
  final String description;

  ManagedCategory copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    String? description,
  }) =>
      ManagedCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        description: description ?? this.description,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ManagedCategory && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

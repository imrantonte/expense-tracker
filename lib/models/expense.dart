import 'package:flutter/foundation.dart' hide Category;
import 'category.dart';

/// Represents a single expense transaction.
@immutable
class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.note,
  });

  final String id;
  final String title;

  /// Amount in the user's local currency (positive value).
  final double amount;

  final DateTime date;
  final Category category;

  /// Optional note / description.
  final String? note;

  /// Returns a copy of this expense with the specified fields replaced.
  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    Category? category,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      note: note ?? this.note,
    );
  }

  @override
  String toString() => 'Expense($id, $title, $amount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Expense && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

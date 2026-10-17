import 'package:flutter/foundation.dart' hide Category;

/// A single financial transaction (income or expense).
@immutable
class TransactionItem {
  const TransactionItem({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.amount,
    required this.date,
    required this.isIncome,
    this.note,
  });

  final String id;
  final String title;

  /// Optional free-text note / description.
  final String? note;

  /// References [Category.id] for look-up in [AppState.categories].
  final String categoryId;

  /// Always a positive number. Use [isIncome] to determine the sign.
  final double amount;

  final DateTime date;

  /// `true` → income (green +); `false` → expense (red −).
  final bool isIncome;

  /// Signed amount: positive for income, negative for expense.
  double get signedAmount => isIncome ? amount : -amount;

  TransactionItem copyWith({
    String? id,
    String? title,
    String? note,
    String? categoryId,
    double? amount,
    DateTime? date,
    bool? isIncome,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
    );
  }

  @override
  String toString() =>
      'TransactionItem($id, $title, ${isIncome ? '+' : '-'}$amount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

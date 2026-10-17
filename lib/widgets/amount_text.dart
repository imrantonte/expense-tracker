import 'package:flutter/material.dart';
import '../core/app_theme_ext.dart';
import '../core/app_typography.dart';

/// Displays a monetary amount with the ৳ symbol:
/// - Expense (negative) → expense red with a leading "−"
/// - Income (positive)  → income green with a leading "+"
/// - Neutral            → primary text colour, no sign prefix
///
/// ```dart
/// AmountText(amount: -450.00)  // → "−৳450.00" in red
/// AmountText(amount: 1200.00)  // → "+৳1200.00" in green
/// AmountText.large(amount: -450.00)  // 40 sp hero variant
/// ```
class AmountText extends StatelessWidget {
  const AmountText({
    super.key,
    required this.amount,
    this.large = false,
    this.neutral = false,
  });

  /// 40 sp bold hero variant.
  const AmountText.large({
    super.key,
    required this.amount,
    this.neutral = false,
  }) : large = true;

  final double amount;
  final bool large;

  /// When true, shows no +/− prefix and uses primary text colour.
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;

    Color color;
    String prefix;
    if (neutral) {
      color = ext.textPrimary;
      prefix = '';
    } else if (amount < 0) {
      color = ext.expense;
      prefix = '−';
    } else {
      color = ext.income;
      prefix = '+';
    }

    final style = large
        ? AppTypography.amountLg(color: color)
        : AppTypography.amountSm(color: color);

    return Text(
      '$prefix৳${amount.abs().toStringAsFixed(2)}',
      style: style,
    );
  }
}

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Custom semantic colors that live outside the standard [ColorScheme].
///
/// Attach via [ThemeData.extensions]. Widgets access it with:
/// ```dart
/// final ext = Theme.of(context).extension<AppThemeExt>()!;
/// ```
@immutable
class AppThemeExt extends ThemeExtension<AppThemeExt> {
  const AppThemeExt({
    required this.income,
    required this.expense,
    required this.warning,
    required this.tint,
    required this.cardBorder,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBackground,
  });

  /// Positive-amount / credit colour.
  final Color income;

  /// Negative-amount / debit colour.
  final Color expense;

  /// Warning / amber colour.
  final Color warning;

  /// Soft teal tint (icon badges, selected chip background).
  final Color tint;

  /// 1 px card border colour.
  final Color cardBorder;

  /// Horizontal divider / separator colour.
  final Color divider;

  /// Primary text colour.
  final Color textPrimary;

  /// Secondary / caption text colour.
  final Color textSecondary;

  /// Card fill colour.
  final Color cardBackground;

  // ─── Prebuilt instances ───────────────────────────────────────────────────

  static const AppThemeExt light = AppThemeExt(
    income: AppColors.lightIncome,
    expense: AppColors.lightExpense,
    warning: AppColors.lightWarning,
    tint: AppColors.lightTint,
    cardBorder: AppColors.lightCardBorder,
    divider: AppColors.lightDivider,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    cardBackground: AppColors.lightCard,
  );

  static const AppThemeExt dark = AppThemeExt(
    income: AppColors.darkIncome,
    expense: AppColors.darkExpense,
    warning: AppColors.darkWarning,
    tint: AppColors.darkTint,
    cardBorder: AppColors.darkCardBorder,
    divider: AppColors.darkDivider,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    cardBackground: AppColors.darkCard,
  );

  // ─── ThemeExtension overrides ─────────────────────────────────────────────

  @override
  AppThemeExt copyWith({
    Color? income,
    Color? expense,
    Color? warning,
    Color? tint,
    Color? cardBorder,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? cardBackground,
  }) {
    return AppThemeExt(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      tint: tint ?? this.tint,
      cardBorder: cardBorder ?? this.cardBorder,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      cardBackground: cardBackground ?? this.cardBackground,
    );
  }

  @override
  AppThemeExt lerp(AppThemeExt? other, double t) {
    if (other == null) return this;
    return AppThemeExt(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      tint: Color.lerp(tint, other.tint, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
    );
  }
}

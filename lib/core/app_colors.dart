import 'package:flutter/material.dart';

/// Raw color tokens for the "Where Did It Go?" design system.
///
/// These are never used directly in widgets — always read via [AppThemeExt]
/// or [ColorScheme] so that light/dark switching is automatic.
abstract final class AppColors {
  // ─── Light palette ──────────────────────────────────────────────────────────
  static const Color lightPrimary = Color(0xFF00897B);
  static const Color lightWarning = Color(0xFFFFB300);
  static const Color lightExpense = Color(0xFFE53935);
  static const Color lightIncome = Color(0xFF2E9E5B);
  static const Color lightBackground = Color(0xFFF7F9FA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFDCE6E4);
  static const Color lightTextPrimary = Color(0xFF12302D);
  static const Color lightTextSecondary = Color(0xFF5F7A76);
  static const Color lightTint = Color(0xFFE3F1EF);
  static const Color lightDivider = Color(0xFFE6EEEC);

  // ─── Dark palette ───────────────────────────────────────────────────────────
  static const Color darkPrimary = Color(0xFF26A69A);
  static const Color darkWarning = Color(0xFFFFCA28);
  static const Color darkExpense = Color(0xFFEF5350);
  static const Color darkIncome = Color(0xFF66BB6A);
  static const Color darkBackground = Color(0xFF0F1716);
  static const Color darkCard = Color(0xFF1A2625);
  static const Color darkCardBorder = Color(0xFF263634);
  static const Color darkTextPrimary = Color(0xFFE6F0EE);
  static const Color darkTextSecondary = Color(0xFF9DB3AF);
  static const Color darkTint = Color(0xFF1F3331);
  // dark divider: same as dark card border
  static const Color darkDivider = Color(0xFF263634);
}

import 'package:flutter/material.dart';

import 'constants.dart';

/// Noto Sans–based text theme for the design system.
///
/// Uses the bundled NotoSans-Regular/Bold TTFs (Latin) with NotoSansBengali
/// as a fallback so that ৳ and Bengali text render correctly without network.
///
/// Call [AppTypography.textTheme] with the platform brightness to get the
/// correct colour-aware TextTheme.
abstract final class AppTypography {
  static TextStyle _ns({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    Color? color,
    List<String> fontFamilyFallback = const ['NotoSansBengali'],
  }) => TextStyle(
    fontFamily: 'NotoSans',
    fontFamilyFallback: fontFamilyFallback,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    color: color,
  );

  /// Builds a full [TextTheme] using the bundled Noto Sans font.
  static TextTheme textTheme(Brightness brightness) {
    final base = ThemeData(brightness: brightness).textTheme;
    final defaultColor = base.bodyMedium?.color;

    TextStyle ns(double size, FontWeight weight, {double? ls}) => _ns(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: ls,
      color: defaultColor,
    );

    return base.copyWith(
      // Screen title — 22 bold
      titleLarge: ns(kFontScreenTitle, FontWeight.w700, ls: -0.3),
      // Section title — 16 semibold
      titleMedium: ns(kFontSectionTitle, FontWeight.w600, ls: -0.1),
      // Sub-section / card label — 14 semibold
      titleSmall: ns(kFontBody, FontWeight.w600),
      // Body — 14 regular
      bodyLarge: ns(kFontBody, FontWeight.w400),
      bodyMedium: ns(kFontBody, FontWeight.w400),
      // Caption — 12 regular
      bodySmall: ns(kFontCaption, FontWeight.w400),
      labelLarge: ns(kFontBody, FontWeight.w600),
      labelMedium: ns(kFontCaption, FontWeight.w500),
      labelSmall: ns(11, FontWeight.w500, ls: 0.2),
    );
  }

  // ─── Named styles used directly in widgets ────────────────────────────────

  /// Big amount — 28 bold.
  static TextStyle amountSm({Color? color}) => _ns(
    fontSize: kFontAmountSm,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: color,
  );

  /// Hero amount — 40 bold.
  static TextStyle amountLg({Color? color}) => _ns(
    fontSize: kFontAmountLg,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    color: color,
  );

  /// Button label — 16 semibold.
  static TextStyle button({Color? color}) => _ns(
    fontSize: kFontSectionTitle,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: color,
  );
}

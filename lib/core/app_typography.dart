import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

/// Inter-based text theme for the design system.
///
/// Call [AppTypography.textTheme] with the platform brightness to get the
/// correct colour-aware TextTheme.
abstract final class AppTypography {
  /// Builds a full [TextTheme] using the Inter font from google_fonts.
  ///
  /// [brightness] controls the default text colour used by Flutter's
  /// TextTheme; widgets always override colour from the theme extension anyway.
  static TextTheme textTheme(Brightness brightness) {
    return GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).copyWith(
      // Screen title — 22 bold
      titleLarge: GoogleFonts.inter(
        fontSize: kFontScreenTitle,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      // Section title — 16 semibold
      titleMedium: GoogleFonts.inter(
        fontSize: kFontSectionTitle,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      // Sub-section / card label — 14 semibold
      titleSmall: GoogleFonts.inter(
        fontSize: kFontBody,
        fontWeight: FontWeight.w600,
      ),
      // Body — 14 regular
      bodyLarge: GoogleFonts.inter(
        fontSize: kFontBody,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: kFontBody,
        fontWeight: FontWeight.w400,
      ),
      // Caption — 12 regular
      bodySmall: GoogleFonts.inter(
        fontSize: kFontCaption,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: kFontBody,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: kFontCaption,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );
  }

  // ─── Named styles used directly in widgets ────────────────────────────────

  /// Big amount — 28 bold.
  static TextStyle amountSm({Color? color}) => GoogleFonts.inter(
        fontSize: kFontAmountSm,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color,
      );

  /// Hero amount — 40 bold.
  static TextStyle amountLg({Color? color}) => GoogleFonts.inter(
        fontSize: kFontAmountLg,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: color,
      );

  /// Button label — 16 semibold.
  static TextStyle button({Color? color}) => GoogleFonts.inter(
        fontSize: kFontSectionTitle,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
      );
}

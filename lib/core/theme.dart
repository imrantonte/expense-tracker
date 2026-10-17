import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_theme_ext.dart';
import 'app_typography.dart';
import 'constants.dart';

/// Builds the [ThemeData] objects (light + dark) for the app.
///
/// All components are configured here so that individual widgets never need
/// to hard-code colours.
abstract final class AppTheme {
  // ─── Public entry points ───────────────────────────────────────────────────

  static ThemeData get light => _build(
        brightness: Brightness.light,
        primary: AppColors.lightPrimary,
        background: AppColors.lightBackground,
        ext: AppThemeExt.light,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        background: AppColors.darkBackground,
        ext: AppThemeExt.dark,
      );

  // ─── Shared builder ────────────────────────────────────────────────────────

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color background,
    required AppThemeExt ext,
  }) {
    final isDark = brightness == Brightness.dark;
    final textTheme = AppTypography.textTheme(brightness);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      surface: background,
      onSurface: ext.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: ext.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme(brightness).titleLarge?.copyWith(
              color: ext.textPrimary,
            ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),

      // ── Card ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: ext.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusCard),
          side: BorderSide(color: ext.cardBorder),
        ),
        // margin is managed per-widget
        margin: EdgeInsets.zero,
      ),

      // ── Divider ─────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: ext.divider,
        thickness: 1,
        space: 0,
      ),

      // ── Input / TextField ───────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ext.cardBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: kSp16,
          vertical: kSp16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusField),
          borderSide: BorderSide(color: ext.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusField),
          borderSide: BorderSide(color: ext.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusField),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusField),
          borderSide: BorderSide(color: ext.expense),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusField),
          borderSide: BorderSide(color: ext.expense, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: ext.textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: ext.textSecondary),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(color: primary),
      ),

      // ── FilledButton (primary) ──────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, kButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusButton),
          ),
          textStyle: AppTypography.button(color: Colors.white),
          elevation: 0,
        ),
      ),

      // ── OutlinedButton (secondary) ──────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          minimumSize: const Size(double.infinity, kButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusButton),
          ),
          textStyle: AppTypography.button(color: primary),
          elevation: 0,
        ),
      ),

      // ── TextButton ──────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.labelLarge?.copyWith(color: primary),
        ),
      ),

      // ── Chip ────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: background,
        selectedColor: ext.tint,
        side: BorderSide(color: ext.cardBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusChip),
        ),
        labelStyle: textTheme.labelMedium?.copyWith(color: ext.textSecondary),
        labelPadding: const EdgeInsets.symmetric(horizontal: kSp8),
        padding: const EdgeInsets.symmetric(horizontal: kSp4, vertical: kSp4),
        showCheckmark: true,
        checkmarkColor: primary,
      ),

      // ── BottomNavigationBar / NavigationBar ─────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ext.cardBackground,
        indicatorColor: ext.tint,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(color: primary);
          }
          return textTheme.labelSmall?.copyWith(color: ext.textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 22);
          }
          return IconThemeData(color: ext.textSecondary, size: 22);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 0,
      ),

      // ── FAB ─────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
        ),
      ),

      // ── BottomSheet ──────────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ext.cardBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(kRadiusSheet),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: ext.textSecondary.withAlpha(100),
        elevation: 0,
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightTextPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.darkTextPrimary : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusCard),
        ),
      ),

      // ─── Custom extension ────────────────────────────────────────────────────
      extensions: [ext],
    );
  }
}

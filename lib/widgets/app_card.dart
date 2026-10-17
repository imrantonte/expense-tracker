import 'package:flutter/material.dart';
import '../core/app_theme_ext.dart';
import '../core/constants.dart';

/// A styled card with a 1 px border, soft shadow, and radius-16 corners.
///
/// Uses theme colours exclusively — no hard-coded colours here.
///
/// ```dart
/// AppCard(
///   child: ListTile(title: Text('Hello')),
/// )
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
  });

  final Widget child;

  /// Inner padding. Defaults to [EdgeInsets.all(kSp16)].
  final EdgeInsetsGeometry? padding;

  /// Outer margin. Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry? margin;

  /// Optional tap handler — wraps content in [InkWell] when set.
  final VoidCallback? onTap;

  /// Override the card background colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cardColor = color ?? ext.cardBackground;

    final content = Padding(
      padding: padding ?? const EdgeInsets.all(kSp16),
      child: child,
    );

    return Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: ext.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(kRadiusCard),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(kRadiusCard),
                child: content,
              ),
            )
          : content,
    );
  }
}

import 'package:flutter/material.dart';
import '../core/app_theme_ext.dart';
import '../core/constants.dart';

/// A summary card displaying a label and prominent value.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final bgColor = highlight ? ext.tint : ext.cardBackground;
    final fgColor = highlight ? cs.primary : ext.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: ext.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: kSp16, vertical: kSp24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: fgColor),
            const SizedBox(height: kSp4),
          ],
          Text(
            label,
            style: tt.labelMedium?.copyWith(color: ext.textSecondary),
          ),
          const SizedBox(height: kSp4),
          Text(
            value,
            style: tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}

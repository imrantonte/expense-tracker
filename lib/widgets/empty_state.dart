import 'package:flutter/material.dart';
import '../core/app_theme_ext.dart';
import '../core/constants.dart';

/// Displays a centred illustration + headline + subtext when a list is empty.
///
/// ```dart
/// EmptyState(
///   icon: Icons.receipt_long_outlined,
///   title: 'No transactions yet',
///   subtitle: 'Tap + to add your first expense.',
/// )
/// ```
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.savings_outlined,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Optional call-to-action widget shown below the subtitle.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kSp32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 72,
              color: ext.textSecondary.withAlpha(100),
            ),
            const SizedBox(height: kSp16),
            Text(
              title,
              style: tt.titleMedium?.copyWith(color: ext.textPrimary),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: kSp8),
              Text(
                subtitle!,
                style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: kSp24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

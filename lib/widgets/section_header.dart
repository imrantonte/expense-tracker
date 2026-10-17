import 'package:flutter/material.dart';
import '../core/app_theme_ext.dart';
import '../core/constants.dart';

/// A section header row with a title and an optional trailing action widget.
///
/// ```dart
/// SectionHeader(title: 'Recent Transactions')
/// SectionHeader(
///   title: 'Categories',
///   trailing: TextButton(onPressed: _seeAll, child: Text('See all')),
/// )
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
  });

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: kSp16, vertical: kSp8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: tt.titleMedium?.copyWith(color: ext.textPrimary),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

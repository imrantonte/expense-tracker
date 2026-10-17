import 'package:flutter/material.dart';
import '../core/app_theme_ext.dart';
import '../core/constants.dart';

/// A pill-shaped filter chip (height 36, radius 18).
///
/// Selected state: teal-tint background + teal border + check icon.
/// Unselected state: default background + muted border.
///
/// ```dart
/// FilterChipPill(
///   label: 'Food',
///   selected: _selected == 'Food',
///   onSelected: (_) => setState(() => _selected = 'Food'),
/// )
/// ```
class FilterChipPill extends StatelessWidget {
  const FilterChipPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.leadingEmoji,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  /// Optional emoji or short text shown before the label.
  final String? leadingEmoji;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final primary = Theme.of(context).colorScheme.primary;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: kChipHeight,
        padding: const EdgeInsets.symmetric(horizontal: kSp12),
        decoration: BoxDecoration(
          color: selected ? ext.tint : Colors.transparent,
          borderRadius: BorderRadius.circular(kRadiusChip),
          border: Border.all(
            color: selected ? primary : ext.cardBorder,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check, size: 14, color: primary),
              const SizedBox(width: kSp4),
            ] else if (leadingEmoji != null) ...[
              Text(leadingEmoji!, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: kSp4),
            ],
            Text(
              label,
              style: tt.labelMedium?.copyWith(
                color: selected ? primary : ext.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

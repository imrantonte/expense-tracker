import 'package:flutter/material.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PreviewNavBar
// Lightweight static nav bar for state preview screens (no real routing).
// ─────────────────────────────────────────────────────────────────────────────

class PreviewNavBar extends StatelessWidget {
  const PreviewNavBar({super.key, this.selectedIndex = 0});
  final int selectedIndex;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.receipt_long_outlined, label: 'Transactions'),
    (icon: Icons.bar_chart_rounded, label: 'Reports'),
    (icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: ext.cardBackground,
        border: Border(top: BorderSide(color: ext.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(kSp8, kSp8, kSp8, kSp12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < _items.length; i++)
            _NavItem(
              icon: _items[i].icon,
              label: _items[i].label,
              selected: i == selectedIndex,
              ext: ext,
              cs: cs,
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.ext,
    required this.cs,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final AppThemeExt ext;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final color = selected ? cs.primary : ext.textSecondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: kSp16, vertical: kSp4),
          decoration: selected
              ? BoxDecoration(
                  color: ext.tint,
                  borderRadius: BorderRadius.circular(kRadiusButton),
                )
              : null,
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: kSp2),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}

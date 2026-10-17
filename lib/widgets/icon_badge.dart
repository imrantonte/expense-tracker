import 'package:flutter/material.dart';
import '../core/app_theme_ext.dart';
import '../core/constants.dart';

/// A 40×40 rounded-12 square badge with a teal-tint background and a 20px
/// teal icon — used to represent expense categories.
///
/// ```dart
/// IconBadge(icon: Icons.fastfood_outlined)
/// IconBadge.emoji(emoji: '🍔')
/// ```
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.size = kBadgeSize,
  }) : emoji = null;

  const IconBadge.emoji({
    super.key,
    required this.emoji,
    this.size = kBadgeSize,
  }) : icon = null;

  final IconData? icon;
  final String? emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ext.tint,
        borderRadius: BorderRadius.circular(kRadiusBadge),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: kBadgeIconSize, color: primary)
          : Text(
              emoji!,
              style: TextStyle(fontSize: size * 0.5),
            ),
    );
  }
}

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_theme_ext.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Built-in illustrated avatars
// ─────────────────────────────────────────────────────────────────────────────

/// Catalogue of built-in avatar IDs (8 total).
const List<String> kAvatarIds = [
  'av_plant',
  'av_rocket',
  'av_gem',
  'av_star',
  'av_leaf',
  'av_flame',
  'av_wave',
  'av_bolt',
];

/// Returns the [IconData] and background [Color] for a built-in avatar [id].
/// Falls back to a default if the [id] is unknown.
(IconData, Color) avatarStyle(String id) {
  switch (id) {
    case 'av_plant':
      return (Icons.local_florist_rounded, const Color(0xFF43A047));
    case 'av_rocket':
      return (Icons.rocket_launch_rounded, const Color(0xFF1E88E5));
    case 'av_gem':
      return (Icons.diamond_rounded, const Color(0xFF8E24AA));
    case 'av_star':
      return (Icons.star_rounded, const Color(0xFFFB8C00));
    case 'av_leaf':
      return (Icons.eco_rounded, const Color(0xFF00897B));
    case 'av_flame':
      return (Icons.local_fire_department_rounded, const Color(0xFFE53935));
    case 'av_wave':
      return (Icons.water_rounded, const Color(0xFF039BE5));
    case 'av_bolt':
      return (Icons.bolt_rounded, const Color(0xFFFDD835));
    default:
      return (Icons.person_rounded, const Color(0xFF00897B));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UserAvatar
// ─────────────────────────────────────────────────────────────────────────────

/// Reusable circular avatar that resolves photo priority:
///
/// 1. [photoBase64] – base64-encoded JPEG from Firestore (highest priority)
/// 2. [avatarId]    – built-in illustrated icon
/// 3. FirebaseAuth [photoURL] – e.g. Google profile photo (network image)
/// 4. Default person icon on a teal-tint circle
///
/// The small amber dot badge (indicating a pending action) is shown when
/// [showDot] is `true` (default).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.radius = 30,
    this.photoBase64,
    this.avatarId,
    this.showDot = true,
    this.onTap,
  });

  /// Circle radius in logical pixels.
  final double radius;

  /// Base64-encoded JPEG bytes (from Firestore `photoBase64` field).
  final String? photoBase64;

  /// ID of a built-in illustrated avatar (from Firestore `avatarId` field).
  final String? avatarId;

  /// Whether to show the small amber dot badge (bottom-right).
  final bool showDot;

  /// Optional tap callback — wraps the widget in a [GestureDetector].
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;

    Widget circle = _buildCircle(context, ext, cs);
    if (showDot) {
      circle = Stack(
        clipBehavior: Clip.none,
        children: [
          circle,
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: ext.warning,
                shape: BoxShape.circle,
                border: Border.all(color: ext.cardBackground, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: circle);
    }
    return circle;
  }

  Widget _buildCircle(
      BuildContext context, AppThemeExt ext, ColorScheme cs) {
    // Priority 1: custom base64 photo
    if (photoBase64 != null && photoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(photoBase64!);
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(bytes),
          backgroundColor: ext.tint,
        );
      } catch (_) {
        // Fall through to next priority on decode error.
      }
    }

    // Priority 2: built-in illustrated avatar
    if (avatarId != null && avatarId!.isNotEmpty) {
      final (icon, bgColor) = avatarStyle(avatarId!);
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Icon(icon, color: Colors.white, size: radius * 1.1),
      );
    }

    // Priority 3: FirebaseAuth photoURL (Google / social login)
    final authPhotoUrl =
        FirebaseAuth.instance.currentUser?.photoURL;
    if (authPhotoUrl != null && authPhotoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: ext.tint,
        backgroundImage: NetworkImage(authPhotoUrl),
        onBackgroundImageError: (Object e, StackTrace? s) {}, // graceful failure
        child: null,
      );
    }

    // Priority 4: default person icon
    return CircleAvatar(
      radius: radius,
      backgroundColor: ext.tint,
      child: Icon(Icons.person_rounded, color: cs.primary, size: radius * 1.1),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AvatarPickerGrid  (8 built-in avatars)
// ─────────────────────────────────────────────────────────────────────────────

/// 2×4 grid of built-in avatar options.
/// Calls [onSelected] with the chosen [avatarId].
class AvatarPickerGrid extends StatelessWidget {
  const AvatarPickerGrid({
    super.key,
    required this.onSelected,
    this.selectedId,
  });

  final void Function(String avatarId) onSelected;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: kAvatarIds.length,
      itemBuilder: (ctx, i) {
        final id = kAvatarIds[i];
        final (icon, bgColor) = avatarStyle(id);
        final selected = id == selectedId;

        return GestureDetector(
          onTap: () => onSelected(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: cs.primary, width: 3)
                  : Border.all(color: Colors.transparent, width: 3),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: cs.primary.withAlpha(60),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: CircleAvatar(
              backgroundColor: bgColor,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }
}


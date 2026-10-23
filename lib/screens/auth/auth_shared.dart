import 'dart:math' show pi;
import 'package:flutter/material.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../widgets/wallet_logo_badge.dart';

// Re-export so existing call-sites (login, register) need no change.
export '../../core/validators.dart' show isValidEmail;

// ─────────────────────────────────────────────────────────────────────────────
// Auth header row (logo badge + app name)
// ─────────────────────────────────────────────────────────────────────────────

/// Top row shared by both Register and Login screens.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    return Row(
      children: [
        const WalletLogoBadge(size: 40),
        const SizedBox(width: kSp12),
        Text(
          'Where Did It Go?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "── or ──" divider
// ─────────────────────────────────────────────────────────────────────────────

class AuthDividerOr extends StatelessWidget {
  const AuthDividerOr({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(child: Divider(color: ext.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSp16),
          child: Text(
            'or',
            style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
          ),
        ),
        Expanded(child: Divider(color: ext.divider)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Continue with Google" outlined button
// ─────────────────────────────────────────────────────────────────────────────

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      height: kButtonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: ext.cardBorder, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusButton),
          ),
          backgroundColor: ext.cardBackground,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(painter: _GoogleGPainter()),
            ),
            const SizedBox(width: kSp12),
            Text(
              'Continue with Google',
              style: tt.labelLarge?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer link row  e.g. "Already have an account?  Log in"
// ─────────────────────────────────────────────────────────────────────────────

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prefix,
    required this.linkLabel,
    required this.onTap,
  });

  final String prefix;
  final String linkLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$prefix ',
          style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            linkLabel,
            style: tt.bodyMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google "G" custom painter
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleGPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width * 0.21;
    final r = (size.width / 2) - sw * 0.5;
    final c = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: c, radius: r);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;

    // Arc segments (0° = 3 o'clock, clockwise positive).
    // The G has a gap at the upper-right (330° – 30°).
    // Arc spans 30° → 330° clockwise (300° total).
    const d = pi / 180;

    // Yellow — lower-right  (30° → 90°)
    arc.color = _yellow;
    canvas.drawArc(rect, 30 * d, 60 * d, false, arc);

    // Green — bottom-left transition  (90° → 120°)
    arc.color = _green;
    canvas.drawArc(rect, 90 * d, 30 * d, false, arc);

    // Blue — main arc  (120° → 300°)
    arc.color = _blue;
    canvas.drawArc(rect, 120 * d, 180 * d, false, arc);

    // Red — upper-right  (300° → 330°)
    arc.color = _red;
    canvas.drawArc(rect, 300 * d, 30 * d, false, arc);

    // Horizontal blue bar — the middle crossbar of the G
    final barY = c.dy + r * 0.06;
    final barH = sw * 0.88;
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _blue;
    canvas.drawRect(
      Rect.fromLTRB(c.dx, barY - barH / 2, c.dx + r + sw * 0.5, barY + barH / 2),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a SnackBar with [message] using the scaffold messenger.
void showAuthSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kSp12),
        ),
      ),
    );
}

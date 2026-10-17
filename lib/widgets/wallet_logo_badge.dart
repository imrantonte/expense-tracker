import 'package:flutter/material.dart';

/// The app's brand logo badge: a teal rounded square with a wallet
/// icon and a "?" overlay.
///
/// Two canonical sizes:
/// - **40 × 40** — onboarding header (default)
/// - **60 × 60** — inside the splash halo card
///
/// The color always comes from [ColorScheme.primary] so it respects
/// light/dark mode automatically.
class WalletLogoBadge extends StatelessWidget {
  const WalletLogoBadge({super.key, this.size = 40.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(size * 0.275),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wallet icon
          Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: size * 0.52,
          ),
          // "?" badge — pinned to lower-right of the icon
          Positioned(
            right: size * 0.13,
            bottom: size * 0.09,
            child: Text(
              '?',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.22,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

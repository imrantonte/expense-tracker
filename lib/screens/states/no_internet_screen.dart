import 'package:flutter/material.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '_preview_nav_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NoInternetScreen
// ─────────────────────────────────────────────────────────────────────────────

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── App header row ──────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(kSp16, kSp16, kSp16, 0),
              child: Row(
                children: [
                  // Logo badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius:
                          BorderRadius.circular(kRadiusBadge),
                    ),
                    child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 18),
                  ),
                  const SizedBox(width: kSp8),
                  Text(
                    'Where Did It Go?',
                    style: tt.titleMedium?.copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.notifications_outlined,
                      color: ext.textPrimary, size: 24),
                ],
              ),
            ),

            // ── Illustration + content ──────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSp24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),

                    // Wallet illustration
                    Center(child: _WalletOfflineIllustration(ext: ext, cs: cs)),
                    const SizedBox(height: kSp32),

                    // Title
                    Text(
                      'No internet connection',
                      textAlign: TextAlign.center,
                      style: tt.titleLarge?.copyWith(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: kSp10),

                    // Body
                    Text(
                      "Looks like you're offline. Check your Wi-Fi or mobile data, then try again.",
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
                    ),
                    const Spacer(),

                    // Retry button
                    SizedBox(
                      height: kButtonHeight,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(kRadiusButton)),
                        ),
                      ),
                    ),
                    const SizedBox(height: kSp12),

                    // Safety banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: kSp16, vertical: kSp14),
                      decoration: BoxDecoration(
                        color: ext.tint,
                        borderRadius: BorderRadius.circular(kRadiusCard),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined,
                              color: cs.primary, size: 18),
                          const SizedBox(width: kSp8),
                          Text(
                            'Your saved transactions are safe.',
                            style: tt.bodySmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: kSp24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PreviewNavBar(selectedIndex: 0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wallet offline illustration  (pure-widget, no images)
// ─────────────────────────────────────────────────────────────────────────────

class _WalletOfflineIllustration extends StatelessWidget {
  const _WalletOfflineIllustration(
      {required this.ext, required this.cs});
  final AppThemeExt ext;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Background teal-tint circle
          Container(
            width: 188,
            height: 188,
            decoration:
                BoxDecoration(color: ext.tint, shape: BoxShape.circle),
          ),

          // Wallet body
          Positioned(
            top: 72,
            child: Container(
              width: 124,
              height: 84,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  // Card sticking out of wallet
                  Positioned(
                    left: 10,
                    top: -18,
                    child: Container(
                      width: 80,
                      height: 30,
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha(180),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                      ),
                    ),
                  ),
                  // Clasp circle
                  Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Wifi-off white badge (top-right)
          Positioned(
            right: 8,
            top: 16,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: ext.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(28),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Icon(Icons.wifi_off_rounded,
                  color: ext.textSecondary, size: 28),
            ),
          ),

          // ৳ coin (bottom-left)
          Positioned(
            left: 12,
            bottom: 20,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                  color: Color(0xFFFFB300), shape: BoxShape.circle),
              child: const Center(
                child: Text('৳',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22)),
              ),
            ),
          ),

          // Decorative "+" (top-left of circle)
          Positioned(
            left: 22,
            top: 36,
            child: Icon(Icons.add_rounded,
                color: cs.primary.withAlpha(160), size: 20),
          ),

          // Small dot (right-mid)
          Positioned(
            right: 26,
            bottom: 60,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                  color: ext.income.withAlpha(100),
                  shape: BoxShape.circle),
            ),
          ),

          // Amber dot (top-left area)
          Positioned(
            left: 40,
            top: 56,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                  color: Color(0xFFFFB300), shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme_ext.dart';
import '../../core/app_typography.dart';
import '../../core/constants.dart';
import '../../widgets/auth_gate.dart';
import '../../widgets/wallet_logo_badge.dart';

/// Full-screen splash shown for ~2 s before fading to [OnboardingScreen].
///
/// Optional extra: three amber ৳ coins float up and fade behind the logo.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _exitCtrl;
  late final Animation<double> _exitFade;
  late final AnimationController _coinCtrl;

  // Coin start offsets relative to logo centre.
  static const List<Offset> _coinOffsets = [
    Offset(-62, 18),
    Offset(14, -32),
    Offset(66, 24),
  ];

  @override
  void initState() {
    super.initState();

    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeOut),
    );

    _coinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    Future.delayed(const Duration(milliseconds: 2100), _doExit);
  }

  Future<void> _doExit() async {
    if (!mounted) return;
    await _exitCtrl.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, _, a) => const AuthGate(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _exitCtrl.dispose();
    _coinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: FadeTransition(
        opacity: _exitFade,
        child: Scaffold(
          body: Stack(
            children: [
              // ── Floating amber coins (decorative) ────────────────────────
              ..._buildCoins(context, ext),

              // ── Centre column ─────────────────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SplashLogoHalo(ext: ext),
                    const SizedBox(height: kSp32),
                    Text(
                      'Where Did It Go?',
                      style: AppTypography.amountSm(color: ext.textPrimary)
                          .copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: kSp8),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: kSp40),
                      child: Text(
                        "Because 'money just disappeared' isn't an answer.",
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: ext.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCoins(BuildContext context, AppThemeExt ext) {
    final size = MediaQuery.sizeOf(context);
    // Logo centre is roughly at 35 % from top.
    final centreX = size.width / 2;
    final centreY = size.height * 0.35;

    return List.generate(3, (i) {
      final start = i * 0.14;
      final yAnim = Tween<double>(begin: 0, end: -96).animate(
        CurvedAnimation(
          parent: _coinCtrl,
          curve: Interval(start, start + 0.65, curve: Curves.easeOut),
        ),
      );
      final oAnim = Tween<double>(begin: 0.85, end: 0).animate(
        CurvedAnimation(
          parent: _coinCtrl,
          curve: Interval(start + 0.24, start + 0.78),
        ),
      );

      return AnimatedBuilder(
        animation: _coinCtrl,
        builder: (_, a) => Positioned(
          left: centreX + _coinOffsets[i].dx - 16,
          top: centreY + _coinOffsets[i].dy + yAnim.value - 16,
          child: Opacity(
            opacity: oAnim.value.clamp(0.0, 1.0),
            child: _AmberCoin(color: ext.warning),
          ),
        ),
      );
    });
  }
}

// ─── Logo halo ────────────────────────────────────────────────────────────────

class _SplashLogoHalo extends StatelessWidget {
  const _SplashLogoHalo({required this.ext});
  final AppThemeExt ext;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: 210,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Large teal-tint halo circle
          Container(
            width: 188,
            height: 188,
            decoration: BoxDecoration(
              color: ext.tint,
              shape: BoxShape.circle,
            ),
          ),
          // Decorative dot — top right
          Positioned(
            top: 22,
            right: 28,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Decorative dot — bottom left
          Positioned(
            bottom: 28,
            left: 18,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: primary.withAlpha(130),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // White card with soft shadow
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(child: WalletLogoBadge(size: 60)),
          ),
        ],
      ),
    );
  }
}

// ─── Amber coin decoration ─────────────────────────────────────────────────────

class _AmberCoin extends StatelessWidget {
  const _AmberCoin({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: const Text(
        '৳',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
    );
  }
}

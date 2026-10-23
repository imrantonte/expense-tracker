import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme_ext.dart';
import '../../core/app_typography.dart';
import '../../core/constants.dart';
import '../../screens/auth/login_screen.dart';
import '../../services/onboarding_prefs.dart';
import '../../widgets/app_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/wallet_logo_badge.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page data
// ─────────────────────────────────────────────────────────────────────────────

class _PageData {
  const _PageData({
    required this.kicker,
    required this.title,
    required this.body,
    required this.illustration,
  });
  final String kicker;
  final String title;
  final String body;
  final Widget illustration;
}

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Three-page onboarding flow shown once after the splash screen.
///
/// - Top bar: logo badge (left) + Skip button (right).
/// - PageView with animated illustration card, kicker, title, body.
/// - Animated page-dot indicator (active = teal pill, inactive = gray dot).
/// - Full-width pill button: "Next →" on pages 1–2, "Get Started →" on page 3.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOut,
      );
    } else {
      _goToApp();
    }
  }

  void _goToApp() {
    // Mark onboarding as seen so returning users skip it.
    OnboardingPrefs.markSeen();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  List<_PageData> _buildPages(BuildContext context) => [
        _PageData(
          kicker: 'A LITTLE CLARITY',
          title: 'Track every expense',
          body:
              'From your morning coffee to the big stuff. Every little spend, all in one place.',
          illustration: const _Page1Illustration(),
        ),
        _PageData(
          kicker: 'THE BIG PICTURE',
          title: 'See where your money goes with charts',
          body:
              'Turn your spending into a clear picture. Spot patterns, not mysteries.',
          illustration: const _Page2Illustration(),
        ),
        _PageData(
          kicker: "YOU'RE IN CONTROL",
          title: 'Set a budget and get alerts',
          body:
              'Give your money a plan. A friendly heads-up keeps you one step ahead.',
          illustration: const _Page3Illustration(),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = _buildPages(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: kSp16, vertical: kSp12),
                child: Row(
                  children: [
                    const WalletLogoBadge(size: 40),
                    const Spacer(),
                    TextButton(
                      onPressed: _goToApp,
                      style: TextButton.styleFrom(
                        foregroundColor: cs.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: kSp8, vertical: kSp4),
                        textStyle: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),

              // ── PageView ────────────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => _OnboardingPage(data: pages[i]),
                ),
              ),

              // ── Page dots ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: kSp16, bottom: kSp12),
                child: _PageDots(
                  count: pages.length,
                  current: _currentPage,
                ),
              ),

              // ── CTA button ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    kSp16, 0, kSp16, kSp16),
                child: PrimaryButton(
                  label: _currentPage < 2 ? 'Next  →' : 'Get Started  →',
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single onboarding page
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _PageData data;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSp16),
      child: Column(
        children: [
          // Takes all free height and scales down if the card is too tall
          Expanded(
            child: _IllustrationArea(ext: ext, child: data.illustration),
          ),
          const SizedBox(height: kSp16),
          Text(
            data.kicker,
            style: tt.labelSmall?.copyWith(
              color: cs.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: kSp10),
          Text(
            data.title,
            style: tt.headlineMedium?.copyWith(
              color: ext.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 26,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kSp12),
          Text(
            data.body,
            style: tt.bodyMedium?.copyWith(
              color: ext.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kSp8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Illustration area (blob + decorative dot + card)
// ─────────────────────────────────────────────────────────────────────────────

class _IllustrationArea extends StatelessWidget {
  const _IllustrationArea({required this.ext, required this.child});

  final AppThemeExt ext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final blob =
            (constraints.maxHeight * 0.85).clamp(120.0, 220.0).toDouble();
        return SizedBox(
          width: double.infinity,
          height: constraints.maxHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Teal-tint halo behind the card
              Container(
                width: blob,
                height: blob,
                decoration:
                    BoxDecoration(color: ext.tint, shape: BoxShape.circle),
              ),
              // Small decorative dot
              Positioned(
                right: 4,
                top: constraints.maxHeight * 0.3,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: primary, shape: BoxShape.circle),
                ),
              ),
              // Card: fixed 300 wide, scaled down if the space is smaller
              Padding(
                padding: const EdgeInsets.symmetric(vertical: kSp8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(width: 300, child: child),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page-dot indicator
// ─────────────────────────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final inactive = Theme.of(context).dividerColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: kSp4),
          width: isActive ? 24.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: isActive ? primary : inactive,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ILLUSTRATION WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// Page 1 — "Track every expense"
// ─────────────────────────────────────────────────────────────────────────────

class _Page1Illustration extends StatelessWidget {
  const _Page1Illustration();

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(kSp16, kSp14, kSp16, kSp10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Today's spending",
                  style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                ),
                const SizedBox(height: kSp4),
                Text(
                  '৳42.50',
                  style: AppTypography.amountSm(color: ext.textPrimary)
                      .copyWith(fontSize: 24),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: ext.divider),

          // ── Coffee row ──────────────────────────────────────────────────────
          _TxRow(
            icon: Icons.local_cafe_rounded,
            title: 'Coffee',
            subtitle: 'Today · 9:15 AM',
            amount: '৳4.50',
            ext: ext,
            primary: cs.primary,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: ext.divider,
            indent: kSp16 + 36 + kSp12,
          ),

          // ── Groceries row ───────────────────────────────────────────────────
          _TxRow(
            icon: Icons.shopping_basket_rounded,
            title: 'Groceries',
            subtitle: 'Today · 11:30 AM',
            amount: '৳38.00',
            ext: ext,
            primary: cs.primary,
          ),

          // ── Success chip ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(kSp16, kSp4, kSp16, kSp12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: kSp12, vertical: kSp10),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(kRadiusButton),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 16, color: Colors.white),
                  const SizedBox(width: kSp6),
                  Text(
                    'Expense added. Easy!',
                    style: tt.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact transaction row used inside illustration cards.
class _TxRow extends StatelessWidget {
  const _TxRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.ext,
    required this.primary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final AppThemeExt ext;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: kSp16, vertical: kSp10),
      child: Row(
        children: [
          // Icon badge (36 × 36)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ext.tint,
              borderRadius: BorderRadius.circular(kSp10),
            ),
            child: Icon(icon, size: 18, color: primary),
          ),
          const SizedBox(width: kSp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium
                      ?.copyWith(color: ext.textPrimary, fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: tt.bodyMedium?.copyWith(
              color: ext.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 2 — "See where your money goes"
// ─────────────────────────────────────────────────────────────────────────────

class _Page2Illustration extends StatelessWidget {
  const _Page2Illustration();

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final seg1 = cs.primary;                    // Food — teal
    final seg2 = cs.primary.withAlpha(155);     // Shopping — lighter teal
    final seg3 = ext.cardBorder;                // Other — neutral

    return AppCard(
      padding: const EdgeInsets.all(kSp14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spending breakdown',
                  style: tt.titleSmall?.copyWith(color: ext.textPrimary),
                ),
              ),
              Text(
                'This month',
                style: tt.bodySmall?.copyWith(color: ext.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: kSp10),

          // ── Donut chart ─────────────────────────────────────────────────────
          SizedBox(
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: 50,
                        color: seg1,
                        showTitle: false,
                        radius: 28,
                      ),
                      PieChartSectionData(
                        value: 30,
                        color: seg2,
                        showTitle: false,
                        radius: 28,
                      ),
                      PieChartSectionData(
                        value: 20,
                        color: seg3,
                        showTitle: false,
                        radius: 28,
                      ),
                    ],
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    startDegreeOffset: -90,
                  ),
                ),
                // Centre label
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '৳840',
                      style: AppTypography.amountSm(color: ext.textPrimary)
                          .copyWith(fontSize: 20),
                    ),
                    Text(
                      'this month',
                      style: tt.labelSmall
                          ?.copyWith(color: ext.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: kSp8),

          // ── Legend ──────────────────────────────────────────────────────────
          Row(
            children: [
              _LegendDot(color: seg1, label: 'Food', ext: ext),
              const SizedBox(width: kSp12),
              _LegendDot(color: seg2, label: 'Shopping', ext: ext),
              const SizedBox(width: kSp12),
              _LegendDot(color: seg3, label: 'Other', ext: ext),
            ],
          ),
          const SizedBox(height: kSp10),

          // ── Discovery chip ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: kSp12, vertical: kSp8),
            decoration: BoxDecoration(
              color: ext.tint,
              borderRadius: BorderRadius.circular(kRadiusChip),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insights_rounded,
                    size: 16, color: cs.primary),
                const SizedBox(width: kSp6),
                Text(
                  'Small spends. Big discoveries.',
                  style: tt.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.ext,
  });

  final Color color;
  final String label;
  final AppThemeExt ext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: kSp4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: ext.textSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 3 — "Set a budget and get alerts"
// ─────────────────────────────────────────────────────────────────────────────

class _Page3Illustration extends StatelessWidget {
  const _Page3Illustration();

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Main budget card ────────────────────────────────────────────────
        AppCard(
          padding: const EdgeInsets.all(kSp14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded,
                      size: 16, color: cs.primary),
                  const SizedBox(width: kSp6),
                  Text(
                    'Monthly budget',
                    style: tt.titleSmall?.copyWith(color: ext.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: kSp8),

              // Amount
              RichText(
                text: TextSpan(
                  style: AppTypography.amountSm(color: ext.textPrimary)
                      .copyWith(fontSize: 24),
                  children: const [
                    TextSpan(text: '৳840'),
                    TextSpan(text: ' / '),
                    TextSpan(text: '৳1,000'),
                  ],
                ),
              ),
              const SizedBox(height: kSp2),
              Text(
                '৳160 left to spend',
                style: tt.bodySmall?.copyWith(color: ext.textSecondary),
              ),
              const SizedBox(height: kSp10),

              // Amber progress bar (84 %)
              ClipRRect(
                borderRadius: BorderRadius.circular(kSp4),
                child: LinearProgressIndicator(
                  value: 0.84,
                  minHeight: 8,
                  backgroundColor: ext.warning.withAlpha(28),
                  valueColor: AlwaysStoppedAnimation<Color>(ext.warning),
                ),
              ),
              const SizedBox(height: kSp10),

              // Warning banner
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: kSp10, vertical: kSp8),
                decoration: BoxDecoration(
                  color: ext.warning.withAlpha(22),
                  borderRadius: BorderRadius.circular(kSp8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_outlined,
                        size: 15, color: ext.warning),
                    const SizedBox(width: kSp8),
                    Expanded(
                      child: Text(
                        "You've used 84% of your budget",
                        style: tt.labelMedium?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kSp8),

        // ── Shopping over-budget alert card ─────────────────────────────────
        AppCard(
          padding: const EdgeInsets.symmetric(
              horizontal: kSp12, vertical: kSp10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ext.expense.withAlpha(18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 17,
                  color: ext.expense,
                ),
              ),
              const SizedBox(width: kSp12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shopping budget',
                      style: tt.titleSmall?.copyWith(
                        color: ext.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '৳12 over · time to slow down',
                      style: tt.bodySmall?.copyWith(color: ext.expense),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private spacing constant used only in illustrations
// ─────────────────────────────────────────────────────────────────────────────


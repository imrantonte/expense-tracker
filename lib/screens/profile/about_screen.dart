import 'package:flutter/material.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../screens/states/dashboard_loading_screen.dart';
import '../../screens/states/dashboard_syncing_screen.dart';
import '../../screens/states/no_internet_screen.dart';
import '../../widgets/app_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AboutScreen
// ─────────────────────────────────────────────────────────────────────────────

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _links = [
    (icon: Icons.shield_outlined, label: 'Privacy Policy'),
    (icon: Icons.article_outlined, label: 'Terms of Use'),
    (icon: Icons.feedback_outlined, label: 'Send feedback'),
    (icon: Icons.code_rounded, label: 'Source code (GitHub)'),
  ];

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About',
          style: tt.titleLarge?.copyWith(
            color: ext.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: kFontScreenTitle,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(kSp16, kSp16, kSp16, 32),
        children: [
          // ── Centered logo ────────────────────────────────────────────────
          Center(
            child: _AppLogo(cs: cs),
          ),
          const SizedBox(height: kSp16),

          // ── App name ─────────────────────────────────────────────────────
          Center(
            child: Text(
              'Where Did It Go?',
              style: tt.titleLarge?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: kSp6),

          // ── Tagline ───────────────────────────────────────────────────────
          Center(
            child: Text(
              "Because 'money just disappeared' isn't an answer.",
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
            ),
          ),
          const SizedBox(height: kSp4),

          // ── Version ───────────────────────────────────────────────────────
          Center(
            child: Text(
              'Version 1.0.0',
              style: tt.bodySmall?.copyWith(color: ext.textSecondary),
            ),
          ),
          const SizedBox(height: kSp24),

          // ── What it does card ─────────────────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'What it does',
                  style: tt.titleSmall?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: kSp8),
                Text(
                  'Track your income and expenses, see where your money goes with simple charts, and get alerts before you pass your budget.',
                  style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: kSp12),

          // ── Made by card ──────────────────────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Made by',
                  style: tt.titleSmall?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: kSp12),

                // Imran
                _TeamMemberRow(
                    initial: 'I',
                    name: 'MD. Al Mujahid Imran',
                    cs: cs,
                    ext: ext,
                    tt: tt),
                const SizedBox(height: kSp10),

                // Rabeya
                _TeamMemberRow(
                    initial: 'R',
                    name: 'Rabeya Akter',
                    cs: cs,
                    ext: ext,
                    tt: tt),
                const SizedBox(height: kSp12),

                Text(
                  'CSE 3210 project, Shanto-Mariam University of Creative Technology',
                  style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: kSp12),

          // ── Links card ────────────────────────────────────────────────────
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < _links.length; i++) ...[
                  if (i > 0)
                    Divider(
                        height: 1, thickness: 1, color: ext.divider),
                  _LinkRow(
                    icon: _links[i].icon,
                    label: _links[i].label,
                    onTap: () => _snack(context, _links[i].label),
                    ext: ext,
                    cs: cs,
                    tt: tt,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: kSp24),

          // ── Footer ────────────────────────────────────────────────────────
          Center(
            child: Text(
              'Made with care in Bangladesh',
              style: tt.bodySmall?.copyWith(color: ext.textSecondary),
            ),
          ),
          const SizedBox(height: kSp24),

          // ── Developer preview (hidden at the bottom) ──────────────────────
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PreviewRow(
                  icon: Icons.wifi_off_rounded,
                  label: 'No internet state',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NoInternetScreen())),
                  ext: ext, cs: cs, tt: tt,
                ),
                Divider(height: 1, thickness: 1, color: ext.divider),
                _PreviewRow(
                  icon: Icons.hourglass_empty_rounded,
                  label: 'Loading skeleton',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const DashboardLoadingScreen())),
                  ext: ext, cs: cs, tt: tt,
                ),
                Divider(height: 1, thickness: 1, color: ext.divider),
                _PreviewRow(
                  icon: Icons.sync_rounded,
                  label: 'Syncing banner',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const DashboardSyncingScreen())),
                  ext: ext, cs: cs, tt: tt,
                ),
              ],
            ),
          ),
          const SizedBox(height: kSp8),
          Center(
            child: Text(
              'Preview UI states',
              style: tt.labelSmall?.copyWith(color: ext.textSecondary, letterSpacing: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
          content: Text('$label — coming soon.')));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App logo badge  (teal rounded square with wallet + "?" badge)
// ─────────────────────────────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  const _AppLogo({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 40,
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Team-member row  (initial circle + name)
// ─────────────────────────────────────────────────────────────────────────────

class _TeamMemberRow extends StatelessWidget {
  const _TeamMemberRow({
    required this.initial,
    required this.name,
    required this.cs,
    required this.ext,
    required this.tt,
  });
  final String initial;
  final String name;
  final ColorScheme cs;
  final AppThemeExt ext;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: ext.tint,
          child: Text(
            initial,
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: kSp12),
        Text(
          name,
          style:
              tt.bodyMedium?.copyWith(color: ext.textPrimary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Link row  (icon badge + label + chevron)
// ─────────────────────────────────────────────────────────────────────────────

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: kSp16, vertical: kSp14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ext.tint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: cs.primary, size: 20),
            ),
            const SizedBox(width: kSp12),
            Expanded(
              child: Text(
                label,
                style: tt.bodyMedium?.copyWith(color: ext.textPrimary),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: ext.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview row  (used in the "Preview UI states" developer section)
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: kSp16, vertical: kSp14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ext.tint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: cs.primary, size: 20),
            ),
            const SizedBox(width: kSp12),
            Expanded(
              child: Text(label,
                  style: tt.bodyMedium?.copyWith(color: ext.textPrimary)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: ext.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

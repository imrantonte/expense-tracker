import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../data/app_state.dart';
import '_preview_nav_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DashboardSyncingScreen
// Shows the real home summary data from AppState with a persistent
// "Syncing your data…" animated banner floating above the nav bar.
// ─────────────────────────────────────────────────────────────────────────────

class DashboardSyncingScreen extends StatefulWidget {
  const DashboardSyncingScreen({super.key});

  @override
  State<DashboardSyncingScreen> createState() =>
      _DashboardSyncingScreenState();
}

class _DashboardSyncingScreenState extends State<DashboardSyncingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  static final _nf = NumberFormat('#,##0');

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: const PreviewNavBar(selectedIndex: 0),
      body: SafeArea(
        child: Consumer<AppState>(builder: (ctx, state, _) {
          final sym = state.currencySymbol;
          final name = state.profile.name.split(' ').first;
          final txns = state.transactions.take(3).toList();

          return Stack(
            children: [
              // ── Scrollable content ──────────────────────────────────
              ListView(
                padding: const EdgeInsets.fromLTRB(kSp16, kSp16, kSp16, 80),
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
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
                      Text('Where Did It Go?',
                          style: tt.titleMedium?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Icon(Icons.notifications_outlined,
                          color: ext.textPrimary, size: 24),
                    ],
                  ),
                  const SizedBox(height: kSp16),

                  // Greeting
                  Text('Hi, $name',
                      style: tt.titleLarge?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 22)),
                  const SizedBox(height: kSp2),
                  Text('A little clarity, every day.',
                      style: tt.bodyMedium
                          ?.copyWith(color: ext.textSecondary)),
                  const SizedBox(height: kSp16),

                  // Balance card
                  Container(
                    padding: const EdgeInsets.all(kSp16),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(kRadiusCard),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total Balance',
                            style: tt.bodySmall?.copyWith(
                                color: Colors.white70)),
                        const SizedBox(height: kSp4),
                        Text(
                          '$sym${_nf.format((state.monthEarned - state.monthSpent).toInt())}',
                          style: tt.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 32),
                        ),
                        const SizedBox(height: kSp12),
                        Row(children: [
                          Expanded(
                              child: _MiniStat(
                                  icon: Icons.arrow_upward_rounded,
                                  label: 'Income',
                                  value:
                                      '$sym${_nf.format(state.monthEarned.toInt())}',
                                  tt: tt)),
                          Expanded(
                              child: _MiniStat(
                                  icon: Icons.arrow_downward_rounded,
                                  label: 'Expenses',
                                  value:
                                      '$sym${_nf.format(state.monthSpent.toInt())}',
                                  tt: tt)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: kSp12),

                  // Budget card
                  Container(
                    padding: const EdgeInsets.all(kSp16),
                    decoration: BoxDecoration(
                      color: ext.cardBackground,
                      borderRadius: BorderRadius.circular(kRadiusCard),
                      border: Border.all(color: ext.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [
                          Text('Monthly budget',
                              style: tt.titleSmall?.copyWith(
                                  color: ext.textPrimary,
                                  fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: kSp8, vertical: kSp4),
                            decoration: BoxDecoration(
                              color: ext.tint,
                              borderRadius:
                                  BorderRadius.circular(kRadiusChip),
                            ),
                            child: Text(
                              '${(state.budgetUsage * 100).toStringAsFixed(0)}%',
                              style: tt.labelSmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ]),
                        const SizedBox(height: kSp4),
                        Text(
                          '$sym${_nf.format(state.monthSpent.toInt())}',
                          style: tt.titleLarge?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: kSp20),

                  // Recent transactions header
                  Row(children: [
                    Text('Recent transactions',
                        style: tt.titleMedium?.copyWith(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('View all',
                        style: tt.bodySmall
                            ?.copyWith(color: cs.primary)),
                  ]),
                  const SizedBox(height: kSp12),

                  // Transaction rows
                  for (final t in txns) ...[
                    _TxnRow(
                      title: t.title,
                      subtitle: '${t.categoryId} · ${DateFormat('MMM d').format(t.date)}',
                      amount: '${t.isIncome ? '+' : '-'}$sym${_nf.format(t.amount.toInt())}',
                      isIncome: t.isIncome,
                      ext: ext,
                      cs: cs,
                      tt: tt,
                    ),
                    const SizedBox(height: kSp8),
                  ],
                ],
              ),

              // ── Syncing banner ──────────────────────────────────────
              Positioned(
                left: kSp16,
                right: kSp16,
                bottom: kSp16,
                child: _SyncingBar(spin: _spin, ext: ext, tt: tt),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Syncing your data…" banner
// ─────────────────────────────────────────────────────────────────────────────

class _SyncingBar extends StatelessWidget {
  const _SyncingBar(
      {required this.spin, required this.ext, required this.tt});
  final Animation<double> spin;
  final AppThemeExt ext;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E1B19) : const Color(0xFF1A2625);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: spin,
            builder: (_, child) => Transform.rotate(
              angle: spin.value * 6.2832,
              child: child,
            ),
            child: const Icon(Icons.sync_rounded,
                color: Colors.white70, size: 20),
          ),
          const SizedBox(width: kSp10),
          Text(
            'Syncing your data...',
            style: tt.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.icon,
      required this.label,
      required this.value,
      required this.tt});
  final IconData icon;
  final String label;
  final String value;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
            color: Colors.white12, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white70, size: 14),
      ),
      const SizedBox(width: kSp6),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: tt.bodySmall?.copyWith(color: Colors.white70, fontSize: 10)),
          Text(value,
              style: tt.bodyMedium?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    ]);
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow(
      {required this.title,
      required this.subtitle,
      required this.amount,
      required this.isIncome,
      required this.ext,
      required this.cs,
      required this.tt});
  final String title;
  final String subtitle;
  final String amount;
  final bool isIncome;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: ext.tint,
            borderRadius: BorderRadius.circular(kRadiusBadge),
          ),
          child: Icon(
              isIncome
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: cs.primary,
              size: 20),
        ),
        const SizedBox(width: kSp12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: tt.bodyMedium?.copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: tt.bodySmall
                      ?.copyWith(color: ext.textSecondary)),
            ],
          ),
        ),
        Text(
          amount,
          style: tt.bodyMedium?.copyWith(
            color: isIncome ? ext.income : ext.expense,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

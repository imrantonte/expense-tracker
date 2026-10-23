import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme_ext.dart';
import '../../core/app_typography.dart';
import '../../core/constants.dart';
import '../../data/app_state.dart';
import '../../models/transaction_item.dart';
import '../../screens/add_transaction/add_transaction_screen.dart';
import '../../screens/budget/set_budget_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/transaction_detail/transaction_detail_screen.dart';
import '../../widgets/app_card.dart';
import '../../widgets/month_picker_sheet.dart';
import '../../widgets/transaction_tile.dart';

// ── Number formatter (comma-separated, no decimals for whole numbers) ─────────
final _nf = NumberFormat('#,##0');

/// Home tab — scrollable summary of balance, budget, spending and
/// recent transactions.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            final sym = state.currencySymbol;
            final txns = state.transactions.take(5).toList();
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(kSp16, kSp16, kSp16, 0),
                    child: _HomeHeader(state: state),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(kSp16, kSp16, kSp16, 0),
                    child: _BalanceCard(state: state, sym: sym),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(kSp16, kSp16, kSp16, 0),
                    child: _BudgetCard(state: state, sym: sym),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(kSp16, kSp16, kSp16, 0),
                    child: _WhereItWentCard(state: state, sym: sym),
                  ),
                  const SizedBox(height: kSp16),
                  _RecentTransactionsSection(
                    state: state,
                    sym: sym,
                    txns: txns,
                  ),
                  const SizedBox(height: 92), // bottom-nav clearance
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header row
// ─────────────────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.state});
  final AppState state;

  String get _firstName => state.profile.name.split(' ').first;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final monthLabel = DateFormat('MMM yyyy')
        .format(DateTime(state.selectedYear, state.selectedMonth));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Greeting column ────────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hi, $_firstName',
                style: tt.titleLarge?.copyWith(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: kSp2),
              Text(
                'A little clarity, every day.',
                style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
              ),
            ],
          ),
        ),

        // ── Month picker pill ──────────────────────────────────────────────
        GestureDetector(
          onTap: () async {
            final result = await showMonthPickerSheet(
              context,
              initialMonth: state.selectedMonth,
              initialYear: state.selectedYear,
            );
            if (result != null && context.mounted) {
              context.read<AppState>().setSelectedMonth(
                  result.month, result.year);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: kSp12, vertical: kSp6),
            decoration: BoxDecoration(
              color: ext.cardBackground,
              borderRadius: BorderRadius.circular(kRadiusButton),
              border: Border.all(color: ext.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  monthLabel,
                  style: tt.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: kSp4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: cs.primary, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(width: kSp8),

        // ── Bell icon ──────────────────────────────────────────────────────
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const NotificationsScreen()),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_outlined,
                  color: ext.textPrimary, size: 26),
              if (state.unreadCount > 0)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
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
// Balance card  (solid teal, radius 20)
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.state, required this.sym});
  final AppState state;
  final String sym;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kSp20),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top row: label + wallet icon ───────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Balance',
                style: tt.bodySmall
                    ?.copyWith(color: Colors.white.withAlpha(180)),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(28),
                  borderRadius: BorderRadius.circular(kSp12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSp8),

          // ── Balance amount ─────────────────────────────────────────────
          Text(
            '$sym${_nf.format(state.monthLeft.toInt())}',
            style: AppTypography.amountSm(color: Colors.white)
                .copyWith(fontSize: 32),
          ),
          const SizedBox(height: kSp16),

          // ── Income + Expenses chips ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _BalanceChip(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Income',
                  value: '$sym${_nf.format(state.monthEarned.toInt())}',
                ),
              ),
              const SizedBox(width: kSp12),
              Expanded(
                child: _BalanceChip(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Expenses',
                  value: '$sym${_nf.format(state.monthSpent.toInt())}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: kSp12, vertical: kSp10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(kSp12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: kSp8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: tt.labelSmall
                      ?.copyWith(color: Colors.white.withAlpha(178)),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: tt.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Budget card
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.state, required this.sym});
  final AppState state;
  final String sym;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final tt = Theme.of(context).textTheme;

    if (!state.hasBudget) {
      final cs = Theme.of(context).colorScheme;
      return AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No budget set',
                    style: tt.titleSmall?.copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: kSp4),
                  Text(
                    'Set a monthly limit to track your spending.',
                    style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: kSp12),
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SetBudgetScreen()),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusButton),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: kSp14, vertical: kSp8),
              ),
              child: const Text('Set a budget',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
      );
    }

    final budget = state.budget!;
    final pct = (state.budgetUsage * 100).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Title + limit ─────────────────────────────────────────────
          Row(
            children: [
              Text(
                'Monthly Budget',
                style: tt.titleSmall?.copyWith(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$sym${_nf.format(budget.limit.toInt())}',
                style: tt.titleSmall?.copyWith(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSp12),

          // ── Amber progress bar ────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(kSp4),
            child: LinearProgressIndicator(
              value: state.budgetUsage.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: ext.warning.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(ext.warning),
            ),
          ),
          const SizedBox(height: kSp8),

          // ── Spent / remaining ─────────────────────────────────────────
          Row(
            children: [
              Text(
                '$sym${_nf.format(state.budgetSpent.toInt())} spent',
                style: tt.bodySmall?.copyWith(color: ext.textSecondary),
              ),
              const Spacer(),
              Text(
                '$pct% used · $sym${_nf.format(state.budgetRemaining.toInt())} left',
                style: tt.bodySmall?.copyWith(color: ext.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Where it went"  — donut chart + legend
// ─────────────────────────────────────────────────────────────────────────────

class _WhereItWentCard extends StatelessWidget {
  const _WhereItWentCard({required this.state, required this.sym});
  final AppState state;
  final String sym;

  List<PieChartSectionData> _sections() {
    return state.categoryBreakdown.entries.map((e) {
      final cat = state.findCategory(e.key);
      return PieChartSectionData(
        value: e.value,
        color: cat?.color ?? Colors.grey,
        showTitle: false,
        radius: 24,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final tt = Theme.of(context).textTheme;
    final breakdown = state.categoryBreakdown;
    final percents = state.categoryPercent;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Where it went',
            style: tt.titleMedium?.copyWith(
              color: ext.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kSp16),
          Row(
            children: [
              // ── Donut chart ─────────────────────────────────────────────
              SizedBox(
                width: 116,
                height: 116,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: _sections(),
                        centerSpaceRadius: 38,
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$sym${_nf.format(state.monthSpent.toInt())}',
                          style: tt.labelLarge?.copyWith(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'this month',
                          style: tt.labelSmall?.copyWith(
                            color: ext.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: kSp16),

              // ── Legend ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: breakdown.entries.map((e) {
                    final cat = state.findCategory(e.key);
                    final pct = percents[e.key] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: kSp4),
                      child: _LegendRow(
                        color: cat?.color ?? Colors.grey,
                        name: cat?.name ?? e.key,
                        amount: '$sym${_nf.format(e.value.toInt())}',
                        pct: '${pct.toInt()}%',
                        ext: ext,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.name,
    required this.amount,
    required this.pct,
    required this.ext,
  });

  final Color color;
  final String name;
  final String amount;
  final String pct;
  final AppThemeExt ext;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: kSp6),
        Expanded(
          child: Text(
            name,
            style: tt.bodySmall?.copyWith(color: ext.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          amount,
          style: tt.bodySmall?.copyWith(
            color: ext.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: kSp6),
        SizedBox(
          width: 32,
          child: Text(
            pct,
            style: tt.bodySmall?.copyWith(color: ext.textSecondary),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Recent Transactions"  — section header + transaction card
// ─────────────────────────────────────────────────────────────────────────────

class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({
    required this.state,
    required this.sym,
    required this.txns,
  });

  final AppState state;
  final String sym;
  final List<TransactionItem> txns;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header row ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSp16),
          child: Row(
            children: [
              Text(
                'Recent Transactions',
                style: tt.titleMedium?.copyWith(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _openAdd(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kSp12),

        // ── Transactions card ──────────────────────────────────────────────
        if (txns.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSp16),
            child: Text(
              'No transactions this month.',
              style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSp16),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < txns.length; i++)
                    TransactionTile(
                      transaction: txns[i],
                      category:
                          state.findCategory(txns[i].categoryId),
                      currencySymbol: sym,
                      showDivider: i < txns.length - 1,
                      onTap: () => _openDetail(context, txns[i]),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static void _openAdd(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const AddTransactionScreen()),
    );
  }

  static void _openDetail(BuildContext context, TransactionItem tx) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(transaction: tx)),
    );
  }
}

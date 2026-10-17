import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../data/app_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/month_picker_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ReportsScreen
// ─────────────────────────────────────────────────────────────────────────────

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _period = 'Monthly'; // Daily | Weekly | Monthly

  // ── Per-period summary figures ─────────────────────────────────────────────

  ({double earned, double spent, double left}) _summaryFor(AppState state) =>
      switch (_period) {
        'Daily' => (earned: 3000.0, spent: 420.0, left: 2580.0),
        'Weekly' => (earned: 5000.0, spent: 1800.0, left: 3200.0),
        _ => (
            earned: state.monthEarned,
            spent: state.monthSpent,
            left: state.monthLeft,
          ),
      };

  // ── Per-period bar-chart series ────────────────────────────────────────────

  ({List<double> income, List<double> expense, List<String> xLabels, double maxY, double interval})
      _barsFor(AppState state) => switch (_period) {
            'Daily' => (
                income: [0, 3000, 0, 0],
                expense: [180, 240, 0, 0],
                xLabels: ['9am', '12pm', '3pm', '6pm'],
                maxY: 5000.0,
                interval: 2500.0,
              ),
            'Weekly' => (
                income: [0, 3000, 0, 2000],
                expense: [120, 660, 0, 1020],
                xLabels: ['Mon', 'Tue', 'Wed', 'Thu'],
                maxY: 5000.0,
                interval: 2500.0,
              ),
            _ => (
                income: state.weeklyIncome,
                expense: state.weeklyExpenses,
                xLabels: const ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
                maxY: 10000.0,
                interval: 4000.0,
              ),
          };

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final nf = NumberFormat('#,##0');

    return Scaffold(
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (ctx, state, _) {
            final sym = state.currencySymbol;
            final summary = _summaryFor(state);
            final bars = _barsFor(state);

            // Donut fixed to monthly breakdown
            final breakdown = state.categoryBreakdown;
            final percent = state.categoryPercent;
            const donutIds = ['food', 'rent', 'transport', 'other_expense'];
            final donutColors = [
              cs.primary,
              ext.income,
              ext.warning,
              ext.textSecondary,
            ];

            final monthLabel =
                '${_monthAbbr(state.selectedMonth)} ${state.selectedYear}';

            return CustomScrollView(
              slivers: [
                // ── Header ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _Header(
                    monthLabel: monthLabel,
                    onMonthTap: () => _openMonthPicker(ctx, state),
                    ext: ext, cs: cs, tt: tt,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: kSp16)),

                // ── Period toggle ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: kSp16),
                    child: _PeriodToggle(
                      selected: _period,
                      onChanged: (p) => setState(() => _period = p),
                      ext: ext, cs: cs, tt: tt,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: kSp12)),

                // ── Summary row ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: kSp16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SummaryChip(
                            label: 'Earned',
                            amount: summary.earned,
                            color: ext.income,
                            icon: Icons.arrow_upward_rounded,
                            sym: sym, nf: nf, ext: ext, tt: tt,
                          ),
                        ),
                        const SizedBox(width: kSp8),
                        Expanded(
                          child: _SummaryChip(
                            label: 'Spent',
                            amount: summary.spent,
                            color: ext.expense,
                            icon: Icons.arrow_downward_rounded,
                            sym: sym, nf: nf, ext: ext, tt: tt,
                          ),
                        ),
                        const SizedBox(width: kSp8),
                        Expanded(
                          child: _SummaryChip(
                            label: 'Left',
                            amount: summary.left,
                            color: cs.primary,
                            icon: null,
                            sym: sym, nf: nf, ext: ext, tt: tt,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: kSp12)),

                // ── Income vs Expenses bar chart ───────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: kSp16),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Income vs Expenses',
                            style: tt.titleSmall?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: kSp8),
                          // Legend
                          Row(
                            children: [
                              _Dot(color: ext.income),
                              const SizedBox(width: kSp4),
                              Text('Income',
                                  style: tt.bodySmall?.copyWith(
                                      color: ext.textPrimary)),
                              const SizedBox(width: kSp12),
                              _Dot(color: ext.expense),
                              const SizedBox(width: kSp4),
                              Text('Expenses',
                                  style: tt.bodySmall?.copyWith(
                                      color: ext.textPrimary)),
                              const SizedBox(width: kSp12),
                              Text('in ৳',
                                  style: tt.bodySmall?.copyWith(
                                      color: ext.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: kSp12),
                          SizedBox(
                            height: 180,
                            child: BarChart(
                              _buildBarData(
                                income: bars.income,
                                expense: bars.expense,
                                xLabels: bars.xLabels,
                                maxY: bars.maxY,
                                interval: bars.interval,
                                ext: ext,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: kSp12)),

                // ── Spending by category donut ─────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: kSp16),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Spending by category',
                            style: tt.titleSmall?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: kSp12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Donut chart
                              SizedBox(
                                width: 140,
                                height: 140,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PieChart(
                                      PieChartData(
                                        sections: [
                                          for (int i = 0;
                                              i < donutIds.length;
                                              i++)
                                            PieChartSectionData(
                                              value: percent[donutIds[i]] ?? 0,
                                              color: donutColors[i],
                                              title: '',
                                              radius: 36,
                                            ),
                                        ],
                                        centerSpaceRadius: 50,
                                        sectionsSpace: 2,
                                        startDegreeOffset: -90,
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$sym${nf.format(summary.spent.toInt())}',
                                          style: tt.titleSmall?.copyWith(
                                            color: cs.primary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          'spent',
                                          style: tt.bodySmall?.copyWith(
                                              color: ext.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: kSp16),
                              // Legend
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (int i = 0;
                                        i < donutIds.length;
                                        i++) ...[
                                      if (i > 0)
                                        const SizedBox(height: kSp10),
                                      _DonutLegendRow(
                                        name: state
                                                .findCategory(donutIds[i])
                                                ?.name ??
                                            donutIds[i],
                                        color: donutColors[i],
                                        amount: breakdown[donutIds[i]] ?? 0,
                                        pct: percent[donutIds[i]] ?? 0,
                                        sym: sym,
                                        nf: nf,
                                        ext: ext,
                                        tt: tt,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: kSp12)),

                // ── Budget card ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: kSp16),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Budget',
                                style: tt.titleSmall?.copyWith(
                                  color: ext.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(state.budgetUsage * 100).round()}% used',
                                style: tt.bodySmall
                                    ?.copyWith(color: ext.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: kSp4),
                          Text(
                            '$sym${nf.format(state.budget.limit.toInt())} monthly budget',
                            style: tt.bodySmall
                                ?.copyWith(color: ext.textSecondary),
                          ),
                          const SizedBox(height: kSp12),
                          _BudgetBar(
                              progress:
                                  state.budgetUsage.clamp(0.0, 1.0),
                              ext: ext),
                          const SizedBox(height: kSp8),
                          Row(
                            children: [
                              Text(
                                '$sym${nf.format(state.budgetSpent.toInt())} used',
                                style: tt.bodySmall?.copyWith(
                                    color: ext.textSecondary),
                              ),
                              const Spacer(),
                              Text(
                                '$sym${nf.format(state.budgetRemaining.toInt())} left',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom nav clearance
                const SliverToBoxAdapter(child: SizedBox(height: 92)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Month picker ────────────────────────────────────────────────────────────

  Future<void> _openMonthPicker(BuildContext context, AppState state) async {
    final result = await showMonthPickerSheet(
      context,
      initialMonth: state.selectedMonth,
      initialYear: state.selectedYear,
    );
    if (result != null && context.mounted) {
      context.read<AppState>().setSelectedMonth(result.month, result.year);
    }
  }

  // ── Bar chart builder ───────────────────────────────────────────────────────

  BarChartData _buildBarData({
    required List<double> income,
    required List<double> expense,
    required List<String> xLabels,
    required double maxY,
    required double interval,
    required AppThemeExt ext,
  }) {
    return BarChartData(
      maxY: maxY,
      barGroups: List.generate(
        income.length,
        (i) => BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: [
            BarChartRodData(
              toY: income[i],
              color: ext.income,
              width: 11,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4)),
            ),
            BarChartRodData(
              toY: expense[i],
              color: ext.expense,
              width: 11,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4)),
            ),
          ],
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (_) => FlLine(
          color: ext.divider,
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: interval,
            getTitlesWidget: (v, meta) => SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                v == 0
                    ? '0'
                    : v >= 1000
                        ? '${(v / 1000).toInt()}k'
                        : v.toInt().toString(),
                style: TextStyle(
                  fontSize: 11,
                  color: ext.textSecondary,
                ),
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (v, meta) {
              final i = v.toInt();
              if (i < 0 || i >= xLabels.length) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  xLabels[i],
                  style: TextStyle(
                    fontSize: 11,
                    color: ext.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String _monthAbbr(int m) {
    const n = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return n[m - 1];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.monthLabel,
    required this.onMonthTap,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final String monthLabel;
  final VoidCallback onMonthTap;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSp16, kSp16, kSp16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports',
                  style: tt.titleLarge?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: kFontScreenTitle,
                  ),
                ),
                Text(
                  'Where did it go?',
                  style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onMonthTap,
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily / Weekly / Monthly segmented toggle
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({
    required this.selected,
    required this.onChanged,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final String selected;
  final ValueChanged<String> onChanged;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  static const _options = ['Daily', 'Weekly', 'Monthly'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(kRadiusButton),
        border: Border.all(color: ext.cardBorder),
      ),
      child: Row(
        children: _options.map((opt) {
          final sel = opt == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: kSp10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? cs.primary : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(kRadiusButton - 4),
                ),
                child: Text(
                  opt,
                  style: tt.bodyMedium?.copyWith(
                    color: sel ? Colors.white : ext.textSecondary,
                    fontWeight:
                        sel ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary mini-card  (Earned / Spent / Left)
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.amount,
    required this.color,
    this.icon,
    required this.sym,
    required this.nf,
    required this.ext,
    required this.tt,
  });
  final String label;
  final double amount;
  final Color color;
  final IconData? icon;
  final String sym;
  final NumberFormat nf;
  final AppThemeExt ext;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(kSp12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(label,
                  style: tt.bodySmall?.copyWith(color: ext.textSecondary)),
              if (icon != null) ...[
                const SizedBox(width: kSp4),
                Icon(icon, size: 13, color: color),
              ],
            ],
          ),
          const SizedBox(height: kSp4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$sym${nf.format(amount.toInt())}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Donut legend row  (● Name   pct% / ৳amount)
// ─────────────────────────────────────────────────────────────────────────────

class _DonutLegendRow extends StatelessWidget {
  const _DonutLegendRow({
    required this.name,
    required this.color,
    required this.amount,
    required this.pct,
    required this.sym,
    required this.nf,
    required this.ext,
    required this.tt,
  });
  final String name;
  final Color color;
  final double amount;
  final double pct;
  final String sym;
  final NumberFormat nf;
  final AppThemeExt ext;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: kSp6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(name,
                      style: tt.bodySmall?.copyWith(color: ext.textPrimary)),
                  const Spacer(),
                  Text(
                    '${pct.round()}%',
                    style:
                        tt.bodySmall?.copyWith(color: ext.textSecondary),
                  ),
                ],
              ),
              Text(
                '$sym${nf.format(amount.toInt())}',
                style: tt.bodySmall?.copyWith(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w700,
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
// Legend dot
// ─────────────────────────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Amber budget progress bar
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetBar extends StatelessWidget {
  const _BudgetBar({required this.progress, required this.ext});
  final double progress;
  final AppThemeExt ext;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Container(color: ext.divider),
            FractionallySizedBox(
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: Container(color: ext.warning),
            ),
          ],
        ),
      ),
    );
  }
}
